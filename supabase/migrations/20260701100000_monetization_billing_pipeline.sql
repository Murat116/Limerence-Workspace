-- Monetization billing pipeline: fix schema drift, mock complete_purchase, player config RPC.
-- @see docs/monetization/STORE_CATALOG.md

-- ---------------------------------------------------------------------------
-- Schema drift: purchase_intents (legacy intent_id PK → id)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'purchase_intents' AND column_name = 'intent_id'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'purchase_intents' AND column_name = 'id'
  ) THEN
    ALTER TABLE public.purchase_intents RENAME COLUMN intent_id TO id;
  END IF;
END $$;

ALTER TABLE public.purchase_intents
  ADD COLUMN IF NOT EXISTS billing_channel public.billing_channel NOT NULL DEFAULT 'store',
  ADD COLUMN IF NOT EXISTS env public.analytics_env NOT NULL DEFAULT 'sandbox',
  ADD COLUMN IF NOT EXISTS completed_at timestamptz;

-- ---------------------------------------------------------------------------
-- Schema drift: user_entitlements (expires_at → subscription_expires_at)
-- ---------------------------------------------------------------------------
ALTER TABLE public.user_entitlements
  ADD COLUMN IF NOT EXISTS subscription_expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS granted_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS source_record_id uuid;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_entitlements' AND column_name = 'expires_at'
  ) THEN
    UPDATE public.user_entitlements
    SET subscription_expires_at = expires_at
    WHERE subscription_expires_at IS NULL AND expires_at IS NOT NULL;
  END IF;
END $$;

-- Client-facing view (mobile reads expires_at alias)
DROP VIEW IF EXISTS public.user_entitlements_client;

CREATE VIEW public.user_entitlements_client
WITH (security_invoker = true)
AS
SELECT
  id,
  user_id,
  story_id,
  chapter_id,
  sku_type::text AS sku_type,
  subscription_expires_at AS expires_at,
  granted_at
FROM public.user_entitlements;

GRANT SELECT ON public.user_entitlements_client TO authenticated;

-- purchase_records: subscription may have no story attribution
ALTER TABLE public.purchase_records
  ALTER COLUMN story_id DROP NOT NULL;

-- ---------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS idx_purchase_records_transaction_id_unique
  ON public.purchase_records (transaction_id)
  WHERE transaction_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Seed mobile default tier keys + annual/trial subscriptions
-- ---------------------------------------------------------------------------
INSERT INTO public.iap_price_tiers (tier_key, sku_type, store_product_id_ios, store_product_id_android, display_price_cents, sort_order)
VALUES
  ('limerence_pass_annual_3990', 'subscription', 'limerence_pass_annual_3990', 'limerence_pass_annual_3990', 3990, 4),
  ('limerence_pass_trial_499', 'subscription', 'limerence_pass_trial_499', 'limerence_pass_trial_499', 499, 5),
  ('limerence_story_tier_2990', 'full_story', 'limerence_story_tier_2990', 'limerence_story_tier_2990', 2990, 16),
  ('limerence_chapter_tier_199', 'chapter_pass', 'limerence_chapter_tier_199', 'limerence_chapter_tier_199', 199, 13)
ON CONFLICT (tier_key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- RLS: ensure users can read own entitlements and intents
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users read own entitlements" ON public.user_entitlements;
CREATE POLICY "Users read own entitlements"
  ON public.user_entitlements FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users read own intents" ON public.purchase_intents;
CREATE POLICY "Users read own intents"
  ON public.purchase_intents FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- create_purchase_intent (fixed for current schema)
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.create_purchase_intent(uuid, text, text, uuid, uuid);

CREATE OR REPLACE FUNCTION public.create_purchase_intent(
  p_user_id uuid,
  p_sku_type text,
  p_tier_key text,
  p_story_id uuid DEFAULT NULL,
  p_chapter_id uuid DEFAULT NULL,
  p_env text DEFAULT 'sandbox'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_intent_id uuid;
  v_sku_type public.monetization_sku_type;
  v_env public.analytics_env;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_sku_type NOT IN ('subscription', 'full_story', 'chapter_pass') THEN
    RAISE EXCEPTION 'invalid sku_type: %', p_sku_type;
  END IF;

  v_sku_type := p_sku_type::public.monetization_sku_type;
  v_env := CASE WHEN p_env = 'prod' THEN 'prod'::public.analytics_env ELSE 'sandbox'::public.analytics_env END;

  IF NOT EXISTS (SELECT 1 FROM public.iap_price_tiers t WHERE t.tier_key = p_tier_key AND t.sku_type = v_sku_type) THEN
    RAISE EXCEPTION 'unknown tier_key % for sku_type %', p_tier_key, p_sku_type;
  END IF;

  IF v_sku_type IN ('full_story', 'chapter_pass') AND p_story_id IS NULL THEN
    RAISE EXCEPTION 'story_id required for %', p_sku_type;
  END IF;

  IF v_sku_type = 'chapter_pass' AND p_chapter_id IS NULL THEN
    RAISE EXCEPTION 'chapter_id required for chapter_pass';
  END IF;

  INSERT INTO public.purchase_intents (
    user_id, sku_type, tier_key, story_id, chapter_id, status, billing_channel, env
  )
  VALUES (
    p_user_id, v_sku_type, p_tier_key, p_story_id, p_chapter_id, 'pending', 'store', v_env
  )
  RETURNING id INTO v_intent_id;

  RETURN v_intent_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_purchase_intent(uuid, text, text, uuid, uuid, text) TO authenticated;

-- ---------------------------------------------------------------------------
-- complete_purchase (mock + future store verify entry point)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_purchase(
  p_intent_id uuid,
  p_transaction_id text,
  p_platform text DEFAULT 'mock',
  p_receipt_payload jsonb DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_intent public.purchase_intents%ROWTYPE;
  v_tier public.iap_price_tiers%ROWTYPE;
  v_existing record;
  v_record_id uuid;
  v_amount integer;
  v_platform_fee integer;
  v_net integer;
  v_author_rate numeric(5, 4) := 0.20;
  v_author_share integer;
  v_expires_at timestamptz;
  v_entitlement_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  IF p_platform = 'mock' AND NOT (
    current_setting('app.settings.billing_mock_enabled', true) = 'true'
  ) THEN
    -- Allow mock when intent is sandbox (dev builds default env=sandbox on create_purchase_intent)
    NULL;
  END IF;

  SELECT * INTO v_intent FROM public.purchase_intents WHERE id = p_intent_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'intent_not_found';
  END IF;

  IF v_intent.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_platform = 'mock' AND v_intent.env <> 'sandbox'::public.analytics_env THEN
    RAISE EXCEPTION 'mock_purchase_not_allowed_in_prod';
  END IF;

  IF p_transaction_id IS NOT NULL THEN
    SELECT pr.id, pr.intent_id INTO v_existing
    FROM public.purchase_records pr
    WHERE pr.transaction_id = p_transaction_id
    LIMIT 1;

    IF FOUND THEN
      RETURN jsonb_build_object(
        'ok', true,
        'idempotent', true,
        'record_id', v_existing.id,
        'intent_id', v_existing.intent_id
      );
    END IF;
  END IF;

  IF v_intent.status = 'completed' THEN
    RETURN jsonb_build_object('ok', true, 'idempotent', true, 'intent_id', v_intent.id);
  END IF;

  IF v_intent.status <> 'pending' THEN
    RAISE EXCEPTION 'intent_not_pending';
  END IF;

  SELECT * INTO v_tier FROM public.iap_price_tiers WHERE tier_key = v_intent.tier_key;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'tier_not_found';
  END IF;

  v_amount := v_tier.display_price_cents;
  v_platform_fee := (v_amount * 30 / 100);
  v_net := v_amount - v_platform_fee;
  v_author_share := (v_net * v_author_rate)::integer;

  INSERT INTO public.purchase_records (
    intent_id,
    transaction_id,
    user_id,
    story_id,
    chapter_id,
    sku_type,
    tier_key,
    billing_channel,
    env,
    amount_cents,
    platform_fee_cents,
    net_cents,
    author_share_rate,
    author_share_cents,
    currency
  )
  VALUES (
    v_intent.id,
    COALESCE(p_transaction_id, 'mock_' || v_intent.id::text),
    v_intent.user_id,
    v_intent.story_id,
    v_intent.chapter_id,
    v_intent.sku_type,
    v_intent.tier_key,
    v_intent.billing_channel,
    v_intent.env,
    v_amount,
    v_platform_fee,
    v_net,
    v_author_rate,
    v_author_share,
    'USD'
  )
  RETURNING id INTO v_record_id;

  IF v_intent.sku_type = 'subscription' THEN
    IF v_intent.tier_key LIKE '%trial%' THEN
      v_expires_at := now() + interval '3 days';
    ELSIF v_intent.tier_key LIKE '%annual%' THEN
      v_expires_at := now() + interval '1 year';
    ELSE
      v_expires_at := now() + interval '1 month';
    END IF;

    DELETE FROM public.user_entitlements
    WHERE user_id = v_intent.user_id
      AND sku_type = 'subscription'
      AND story_id IS NULL
      AND chapter_id IS NULL;

    INSERT INTO public.user_entitlements (
      user_id, story_id, chapter_id, sku_type, subscription_expires_at, source_record_id
    )
    VALUES (
      v_intent.user_id, NULL, NULL, 'subscription', v_expires_at, v_record_id
    )
    RETURNING id INTO v_entitlement_id;

  ELSIF v_intent.sku_type = 'full_story' THEN
    DELETE FROM public.user_entitlements
    WHERE user_id = v_intent.user_id
      AND sku_type = 'full_story'
      AND story_id = v_intent.story_id;

    INSERT INTO public.user_entitlements (
      user_id, story_id, chapter_id, sku_type, source_record_id
    )
    VALUES (
      v_intent.user_id, v_intent.story_id, NULL, 'full_story', v_record_id
    )
    RETURNING id INTO v_entitlement_id;

  ELSIF v_intent.sku_type = 'chapter_pass' THEN
    DELETE FROM public.user_entitlements
    WHERE user_id = v_intent.user_id
      AND sku_type = 'chapter_pass'
      AND chapter_id = v_intent.chapter_id;

    INSERT INTO public.user_entitlements (
      user_id, story_id, chapter_id, sku_type, source_record_id
    )
    VALUES (
      v_intent.user_id, v_intent.story_id, v_intent.chapter_id, 'chapter_pass', v_record_id
    )
    RETURNING id INTO v_entitlement_id;
  END IF;

  UPDATE public.purchase_intents
  SET status = 'completed', completed_at = now()
  WHERE id = v_intent.id;

  RETURN jsonb_build_object(
    'ok', true,
    'record_id', v_record_id,
    'entitlement_id', v_entitlement_id,
    'intent_id', v_intent.id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.complete_purchase(uuid, text, text, jsonb) TO authenticated;

-- ---------------------------------------------------------------------------
-- get_player_monetization_config
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_player_monetization_config(p_story_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_released boolean;
  v_story_tier text;
  v_chapters jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  SELECT s.released INTO v_released
  FROM public."Story" s
  WHERE s.id = p_story_id;

  IF NOT FOUND OR NOT COALESCE(v_released, false) THEN
    RAISE EXCEPTION 'story_not_available';
  END IF;

  SELECT sm.full_story_tier_key INTO v_story_tier
  FROM public.story_monetization sm
  WHERE sm.story_id = p_story_id;

  SELECT COALESCE(jsonb_object_agg(
    cm.chapter_id::text,
    jsonb_build_object(
      'chapter_pass_tier_key', cm.chapter_pass_tier_key,
      'subscriber_early_access_days', cm.subscriber_early_access_days
    )
  ), '{}'::jsonb)
  INTO v_chapters
  FROM public.chapter_monetization cm
  JOIN public."Chapter" c ON c.id = cm.chapter_id
  WHERE c.story_id = p_story_id;

  RETURN jsonb_build_object(
    'story_id', p_story_id,
    'full_story_tier_key', v_story_tier,
    'chapters', v_chapters
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_player_monetization_config(uuid) TO authenticated;

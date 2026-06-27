-- Monetization v1: price tiers, story/chapter config, billing tables, analytics RPC.

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.monetization_sku_type AS ENUM (
    'subscription',
    'story_pass',
    'chapter_pass',
    'subscription_pool'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.billing_channel AS ENUM ('store', 'web');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.analytics_env AS ENUM ('prod', 'sandbox');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- iap_price_tiers
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.iap_price_tiers (
  tier_key text PRIMARY KEY,
  sku_type public.monetization_sku_type NOT NULL,
  store_product_id_ios text NOT NULL,
  store_product_id_android text NOT NULL,
  display_price_cents integer NOT NULL CHECK (display_price_cents >= 0),
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- story_monetization (1:1 Story)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.story_monetization (
  story_id uuid PRIMARY KEY REFERENCES public."Story" (id) ON DELETE CASCADE,
  enabled boolean NOT NULL DEFAULT false,
  story_pass_tier_key text REFERENCES public.iap_price_tiers (tier_key),
  free_chapters_count integer NOT NULL DEFAULT 0 CHECK (free_chapters_count >= 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- chapter_monetization (1:1 Chapter)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chapter_monetization (
  chapter_id uuid PRIMARY KEY REFERENCES public."Chapter" (id) ON DELETE CASCADE,
  is_free boolean NOT NULL DEFAULT false,
  chapter_pass_tier_key text REFERENCES public.iap_price_tiers (tier_key),
  subscriber_early_access_days integer NOT NULL DEFAULT 0
    CHECK (subscriber_early_access_days >= 0 AND subscriber_early_access_days <= 30),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- purchase_intents (server-side billing)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_intents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  sku_type public.monetization_sku_type NOT NULL,
  tier_key text NOT NULL REFERENCES public.iap_price_tiers (tier_key),
  story_id uuid REFERENCES public."Story" (id) ON DELETE SET NULL,
  chapter_id uuid REFERENCES public."Chapter" (id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  billing_channel public.billing_channel NOT NULL DEFAULT 'store',
  env public.analytics_env NOT NULL DEFAULT 'prod',
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

-- ---------------------------------------------------------------------------
-- purchase_records (revenue source of truth)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  intent_id uuid REFERENCES public.purchase_intents (id) ON DELETE SET NULL,
  transaction_id text,
  user_id uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  story_id uuid NOT NULL REFERENCES public."Story" (id) ON DELETE CASCADE,
  chapter_id uuid REFERENCES public."Chapter" (id) ON DELETE SET NULL,
  sku_type public.monetization_sku_type NOT NULL,
  tier_key text REFERENCES public.iap_price_tiers (tier_key),
  billing_channel public.billing_channel NOT NULL DEFAULT 'store',
  env public.analytics_env NOT NULL DEFAULT 'prod',
  amount_cents integer NOT NULL DEFAULT 0 CHECK (amount_cents >= 0),
  platform_fee_cents integer NOT NULL DEFAULT 0 CHECK (platform_fee_cents >= 0),
  net_cents integer NOT NULL DEFAULT 0 CHECK (net_cents >= 0),
  author_share_rate numeric(5, 4) NOT NULL DEFAULT 0 CHECK (author_share_rate >= 0 AND author_share_rate <= 1),
  author_share_cents integer NOT NULL DEFAULT 0 CHECK (author_share_cents >= 0),
  currency text NOT NULL DEFAULT 'USD',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_purchase_records_story_env_created
  ON public.purchase_records (story_id, env, created_at DESC);

-- ---------------------------------------------------------------------------
-- user_entitlements
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_entitlements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  story_id uuid REFERENCES public."Story" (id) ON DELETE CASCADE,
  chapter_id uuid REFERENCES public."Chapter" (id) ON DELETE CASCADE,
  sku_type public.monetization_sku_type NOT NULL,
  subscription_expires_at timestamptz,
  granted_at timestamptz NOT NULL DEFAULT now(),
  source_record_id uuid REFERENCES public.purchase_records (id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_user_entitlements_user_story
  ON public.user_entitlements (user_id, story_id);

-- ---------------------------------------------------------------------------
-- Variant: drop legacy per-choice IAP columns
-- ---------------------------------------------------------------------------
ALTER TABLE public."Variant"
  DROP COLUMN IF EXISTS premium_price,
  DROP COLUMN IF EXISTS iap_product_id;

-- ---------------------------------------------------------------------------
-- Drop legacy story_purchases
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS public.story_purchases;

-- ---------------------------------------------------------------------------
-- Seed iap_price_tiers (idempotent)
-- ---------------------------------------------------------------------------
INSERT INTO public.iap_price_tiers (tier_key, sku_type, store_product_id_ios, store_product_id_android, display_price_cents, sort_order)
VALUES
  ('limerence_pass_monthly_499', 'subscription', 'limerence_pass_monthly_499', 'limerence_pass_monthly_499', 499, 1),
  ('limerence_pass_monthly_599', 'subscription', 'limerence_pass_monthly_599', 'limerence_pass_monthly_599', 599, 2),
  ('limerence_pass_monthly_699', 'subscription', 'limerence_pass_monthly_699', 'limerence_pass_monthly_699', 699, 3)
ON CONFLICT (tier_key) DO NOTHING;

INSERT INTO public.iap_price_tiers (tier_key, sku_type, store_product_id_ios, store_product_id_android, display_price_cents, sort_order)
SELECT
  'limerence_chapter_tier_' || n,
  'chapter_pass',
  'limerence_chapter_tier_' || n,
  'limerence_chapter_tier_' || n,
  (99 + ((999 - 99) * (n - 1) / 11))::integer,
  n
FROM generate_series(1, 12) AS n
ON CONFLICT (tier_key) DO NOTHING;

INSERT INTO public.iap_price_tiers (tier_key, sku_type, store_product_id_ios, store_product_id_android, display_price_cents, sort_order)
SELECT
  'limerence_story_tier_' || n,
  'story_pass',
  'limerence_story_tier_' || n,
  'limerence_story_tier_' || n,
  (199 + ((4999 - 199) * (n - 1) / 14))::integer,
  n
FROM generate_series(1, 15) AS n
ON CONFLICT (tier_key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public.iap_price_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_monetization ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chapter_monetization ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_intents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_entitlements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS iap_price_tiers_select_authenticated ON public.iap_price_tiers;
CREATE POLICY iap_price_tiers_select_authenticated ON public.iap_price_tiers
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS story_monetization_author_all ON public.story_monetization;

CREATE OR REPLACE FUNCTION public._is_story_author(p_story_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  PERFORM public._assert_story_author(p_story_id);
  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public._is_story_author(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._is_story_author(uuid) TO authenticated;

DROP POLICY IF EXISTS story_monetization_author_select ON public.story_monetization;
CREATE POLICY story_monetization_author_select ON public.story_monetization
  FOR SELECT TO authenticated USING (public._is_story_author(story_id));

DROP POLICY IF EXISTS story_monetization_author_insert ON public.story_monetization;
CREATE POLICY story_monetization_author_insert ON public.story_monetization
  FOR INSERT TO authenticated WITH CHECK (public._is_story_author(story_id));

DROP POLICY IF EXISTS story_monetization_author_update ON public.story_monetization;
CREATE POLICY story_monetization_author_update ON public.story_monetization
  FOR UPDATE TO authenticated
  USING (public._is_story_author(story_id))
  WITH CHECK (public._is_story_author(story_id));

DROP POLICY IF EXISTS story_monetization_author_delete ON public.story_monetization;
CREATE POLICY story_monetization_author_delete ON public.story_monetization
  FOR DELETE TO authenticated USING (public._is_story_author(story_id));

DROP POLICY IF EXISTS chapter_monetization_author_select ON public.chapter_monetization;
CREATE POLICY chapter_monetization_author_select ON public.chapter_monetization
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public."Chapter" c
      WHERE c.id = chapter_id AND public._is_story_author(c.story_id)
    )
  );

DROP POLICY IF EXISTS chapter_monetization_author_insert ON public.chapter_monetization;
CREATE POLICY chapter_monetization_author_insert ON public.chapter_monetization
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public."Chapter" c
      WHERE c.id = chapter_id AND public._is_story_author(c.story_id)
    )
  );

DROP POLICY IF EXISTS chapter_monetization_author_update ON public.chapter_monetization;
CREATE POLICY chapter_monetization_author_update ON public.chapter_monetization
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public."Chapter" c
      WHERE c.id = chapter_id AND public._is_story_author(c.story_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public."Chapter" c
      WHERE c.id = chapter_id AND public._is_story_author(c.story_id)
    )
  );

DROP POLICY IF EXISTS chapter_monetization_author_delete ON public.chapter_monetization;
CREATE POLICY chapter_monetization_author_delete ON public.chapter_monetization
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public."Chapter" c
      WHERE c.id = chapter_id AND public._is_story_author(c.story_id)
    )
  );

DROP POLICY IF EXISTS purchase_records_author_select ON public.purchase_records;
CREATE POLICY purchase_records_author_select ON public.purchase_records
  FOR SELECT TO authenticated USING (public._is_story_author(story_id));

DROP POLICY IF EXISTS user_entitlements_author_select ON public.user_entitlements;
CREATE POLICY user_entitlements_author_select ON public.user_entitlements
  FOR SELECT TO authenticated
  USING (story_id IS NOT NULL AND public._is_story_author(story_id));

-- ---------------------------------------------------------------------------
-- Analytics RPC: get_story_revenue_overview
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_story_revenue_overview(uuid, integer, text);

CREATE OR REPLACE FUNCTION public.get_story_revenue_overview(
  p_story_id uuid,
  p_days integer DEFAULT NULL,
  p_env text DEFAULT 'prod'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_enabled boolean := false;
  v_env public.analytics_env;
  v_since timestamptz;
  v_author_share bigint := 0;
  v_purchases bigint := 0;
  v_payers bigint := 0;
  v_readers bigint := 0;
  v_min_readers integer := 10;
  v_by_sku jsonb := '[]'::jsonb;
  v_by_channel jsonb := '[]'::jsonb;
  v_daily jsonb := '[]'::jsonb;
  v_pool_cents bigint := 0;
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  v_env := CASE WHEN p_env = 'sandbox' THEN 'sandbox'::public.analytics_env ELSE 'prod'::public.analytics_env END;
  IF v_env = 'sandbox' THEN
    v_min_readers := 1;
  END IF;

  SELECT COALESCE(sm.enabled, false) INTO v_enabled
  FROM public.story_monetization sm
  WHERE sm.story_id = p_story_id;

  IF NOT v_enabled THEN
    RETURN jsonb_build_object(
      'enabled', false,
      'reason', 'monetization_disabled',
      'message', 'Монетизация не включена для этой истории'
    );
  END IF;

  v_since := CASE
    WHEN p_days IS NULL THEN '-infinity'::timestamptz
    ELSE now() - (p_days || ' days')::interval
  END;

  SELECT
    COALESCE(SUM(pr.author_share_cents), 0),
    COUNT(*),
    COUNT(DISTINCT pr.user_id)
  INTO v_author_share, v_purchases, v_payers
  FROM public.purchase_records pr
  WHERE pr.story_id = p_story_id
    AND pr.env = v_env
    AND pr.created_at >= v_since
    AND pr.sku_type IN ('story_pass', 'chapter_pass', 'subscription_pool');

  SELECT COALESCE(SUM(pr.author_share_cents), 0) INTO v_pool_cents
  FROM public.purchase_records pr
  WHERE pr.story_id = p_story_id
    AND pr.env = v_env
    AND pr.created_at >= v_since
    AND pr.sku_type = 'subscription_pool';

  SELECT COUNT(DISTINCT ae.user_id) INTO v_readers
  FROM public.analytics_events ae
  WHERE ae.story_id = p_story_id
    AND ae.env = v_env::text
    AND ae.event = 'story_reading_started'
    AND ae.client_created_at >= v_since;

  IF v_readers < v_min_readers AND v_purchases = 0 THEN
    RETURN jsonb_build_object(
      'enabled', true,
      'has_data', false,
      'reason', 'insufficient_readers',
      'message', 'Недостаточно читателей для отображения статистики'
    );
  END IF;

  IF v_purchases = 0 THEN
    RETURN jsonb_build_object(
      'enabled', true,
      'has_data', false,
      'message', 'За выбранный период покупок не было'
    );
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb ORDER BY t.sku_type), '[]'::jsonb)
  INTO v_by_sku
  FROM (
    SELECT pr.sku_type::text AS sku_type,
           COUNT(*)::bigint AS count,
           COALESCE(SUM(pr.author_share_cents), 0)::bigint AS author_share_cents
    FROM public.purchase_records pr
    WHERE pr.story_id = p_story_id
      AND pr.env = v_env
      AND pr.created_at >= v_since
      AND pr.sku_type IN ('story_pass', 'chapter_pass', 'subscription_pool')
    GROUP BY pr.sku_type
  ) t;

  SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb ORDER BY t.channel), '[]'::jsonb)
  INTO v_by_channel
  FROM (
    SELECT pr.billing_channel::text AS channel,
           COALESCE(SUM(pr.author_share_cents), 0)::bigint AS author_share_cents
    FROM public.purchase_records pr
    WHERE pr.story_id = p_story_id
      AND pr.env = v_env
      AND pr.created_at >= v_since
    GROUP BY pr.billing_channel
  ) t;

  SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb ORDER BY t.date), '[]'::jsonb)
  INTO v_daily
  FROM (
    SELECT to_char(date_trunc('day', pr.created_at), 'YYYY-MM-DD') AS date,
           COALESCE(SUM(pr.author_share_cents), 0)::bigint AS author_share_cents,
           COUNT(*)::bigint AS purchases_count
    FROM public.purchase_records pr
    WHERE pr.story_id = p_story_id
      AND pr.env = v_env
      AND pr.created_at >= v_since
    GROUP BY date_trunc('day', pr.created_at)
  ) t;

  RETURN jsonb_build_object(
    'enabled', true,
    'has_data', true,
    'author_share_cents', v_author_share,
    'purchases_count', v_purchases,
    'unique_payers', v_payers,
    'payer_rate', CASE WHEN v_readers > 0 THEN round((v_payers::numeric / v_readers), 4) ELSE 0 END,
    'revenue_per_read_cents', CASE WHEN v_readers > 0 THEN round((v_author_share::numeric / v_readers), 2) ELSE 0 END,
    'subscription_pool_cents', v_pool_cents,
    'by_sku_type', v_by_sku,
    'by_billing_channel', v_by_channel,
    'daily', v_daily
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Analytics RPC: get_story_premium_choice_stats
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_story_premium_choice_stats(uuid, uuid, integer, text);

CREATE OR REPLACE FUNCTION public.get_story_premium_choice_stats(
  p_story_id uuid,
  p_chapter_id uuid DEFAULT NULL,
  p_days integer DEFAULT NULL,
  p_env text DEFAULT 'prod'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_enabled boolean := false;
  v_env text := CASE WHEN p_env = 'sandbox' THEN 'sandbox' ELSE 'prod' END;
  v_since timestamptz;
  v_choices jsonb := '[]'::jsonb;
  v_by_category jsonb := '[]'::jsonb;
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  SELECT COALESCE(sm.enabled, false) INTO v_enabled
  FROM public.story_monetization sm
  WHERE sm.story_id = p_story_id;

  IF NOT v_enabled THEN
    RETURN jsonb_build_object('enabled', false, 'choices', '[]'::jsonb);
  END IF;

  v_since := CASE
    WHEN p_days IS NULL THEN '-infinity'::timestamptz
    ELSE now() - (p_days || ' days')::interval
  END;

  SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
  INTO v_choices
  FROM (
    SELECT
      v.uuid::text AS variant_id,
      d.uuid::text AS dialog_id,
      v.premium_category,
      COALESCE((
        SELECT COUNT(*)::bigint FROM public.analytics_events ae
        WHERE ae.story_id = p_story_id
          AND ae.env = v_env
          AND ae.event = 'paywall_shown'
          AND ae.client_created_at >= v_since
          AND (ae.properties->>'variant_id') = v.uuid::text
      ), 0) AS paywall_impressions,
      COALESCE((
        SELECT COUNT(*)::bigint FROM public.analytics_events ae
        WHERE ae.story_id = p_story_id
          AND ae.env = v_env
          AND ae.event = 'variant_selected'
          AND ae.client_created_at >= v_since
          AND (ae.properties->>'variant_id') = v.uuid::text
      ), 0) AS premium_selected,
      COALESCE((
        SELECT COUNT(*)::bigint FROM public.analytics_events ae
        JOIN public."Variant" fv ON fv.uuid::text = (ae.properties->>'variant_id')
        WHERE ae.story_id = p_story_id
          AND ae.env = v_env
          AND ae.event = 'variant_selected'
          AND ae.client_created_at >= v_since
          AND fv.dialog_uuid = d.uuid
          AND fv.is_premium = false
      ), 0) AS free_selected
    FROM public."Variant" v
    JOIN public."Dialog" d ON d.uuid = v.dialog_uuid
    JOIN public."DialogList" dl ON dl.uuid = d.dialog_list_uuid
    JOIN public."Scene" s ON s.uuid = dl.scene_uuid
    WHERE v.story_id = p_story_id
      AND v.is_premium = true
      AND (p_chapter_id IS NULL OR s.chapter_id = p_chapter_id)
  ) t;

  SELECT COALESCE(jsonb_agg(row_to_json(c)::jsonb), '[]'::jsonb)
  INTO v_by_category
  FROM (
    SELECT
      COALESCE(v.premium_category, 'unknown') AS category,
      COUNT(*)::bigint AS variant_count
    FROM public."Variant" v
    WHERE v.story_id = p_story_id AND v.is_premium = true
    GROUP BY COALESCE(v.premium_category, 'unknown')
  ) c;

  RETURN jsonb_build_object(
    'enabled', true,
    'choices', v_choices,
    'by_category', v_by_category
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_story_revenue_overview(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_story_premium_choice_stats(uuid, uuid, integer, text) TO authenticated;

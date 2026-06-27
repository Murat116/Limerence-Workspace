-- Monetization access model v2: remove enabled/free_chapters/is_free, add requires_pass_to_read, story_pass → full_story

-- ---------------------------------------------------------------------------
-- Enum: story_pass → full_story
-- ---------------------------------------------------------------------------
ALTER TYPE public.monetization_sku_type RENAME VALUE 'story_pass' TO 'full_story';

-- ---------------------------------------------------------------------------
-- story_monetization
-- ---------------------------------------------------------------------------
ALTER TABLE public.story_monetization
  ADD COLUMN IF NOT EXISTS requires_pass_to_read boolean NOT NULL DEFAULT false;

ALTER TABLE public.story_monetization
  RENAME COLUMN story_pass_tier_key TO full_story_tier_key;

ALTER TABLE public.story_monetization
  DROP COLUMN IF EXISTS enabled,
  DROP COLUMN IF EXISTS free_chapters_count;

-- ---------------------------------------------------------------------------
-- chapter_monetization
-- ---------------------------------------------------------------------------
ALTER TABLE public.chapter_monetization
  ADD COLUMN IF NOT EXISTS requires_pass_to_read boolean NOT NULL DEFAULT false;

ALTER TABLE public.chapter_monetization
  DROP COLUMN IF EXISTS is_free;

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
  v_configured boolean := false;
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

  SELECT (
    sm.full_story_tier_key IS NOT NULL
    OR sm.requires_pass_to_read
    OR EXISTS (
      SELECT 1 FROM public.chapter_monetization cm
      JOIN public."Chapter" c ON c.id = cm.chapter_id
      WHERE c.story_id = p_story_id
        AND (cm.chapter_pass_tier_key IS NOT NULL OR cm.requires_pass_to_read)
    )
    OR EXISTS (
      SELECT 1 FROM public."Variant" v
      WHERE v.story_id = p_story_id AND v.is_premium = true
    )
  ) INTO v_configured
  FROM public.story_monetization sm
  WHERE sm.story_id = p_story_id;

  IF NOT COALESCE(v_configured, false) THEN
    SELECT EXISTS (
      SELECT 1 FROM public.chapter_monetization cm
      JOIN public."Chapter" c ON c.id = cm.chapter_id
      WHERE c.story_id = p_story_id
        AND (cm.chapter_pass_tier_key IS NOT NULL OR cm.requires_pass_to_read)
    )
    OR EXISTS (
      SELECT 1 FROM public."Variant" v WHERE v.story_id = p_story_id AND v.is_premium = true
    ) INTO v_configured;
  END IF;

  IF NOT COALESCE(v_configured, false) THEN
    RETURN jsonb_build_object(
      'enabled', false,
      'reason', 'monetization_not_configured',
      'message', 'Монетизация не настроена для этой истории'
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
    AND pr.sku_type IN ('full_story', 'chapter_pass', 'subscription_pool');

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
      AND pr.sku_type IN ('full_story', 'chapter_pass', 'subscription_pool')
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
  v_configured boolean := false;
  v_env text := CASE WHEN p_env = 'sandbox' THEN 'sandbox' ELSE 'prod' END;
  v_since timestamptz;
  v_choices jsonb := '[]'::jsonb;
  v_by_category jsonb := '[]'::jsonb;
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  SELECT (
    sm.full_story_tier_key IS NOT NULL
    OR sm.requires_pass_to_read
    OR EXISTS (
      SELECT 1 FROM public."Variant" v WHERE v.story_id = p_story_id AND v.is_premium = true
    )
  ) INTO v_configured
  FROM public.story_monetization sm
  WHERE sm.story_id = p_story_id;

  IF NOT COALESCE(v_configured, false) THEN
    SELECT EXISTS (
      SELECT 1 FROM public."Variant" v WHERE v.story_id = p_story_id AND v.is_premium = true
    ) INTO v_configured;
  END IF;

  IF NOT COALESCE(v_configured, false) THEN
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

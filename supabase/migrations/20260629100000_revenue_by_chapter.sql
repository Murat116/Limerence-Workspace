-- Revenue overview: add per-chapter breakdown (Chapter Pass purchases)

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
  v_by_chapter jsonb := '[]'::jsonb;
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

  SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb ORDER BY t.chapter_order), '[]'::jsonb)
  INTO v_by_chapter
  FROM (
    SELECT
      c.id::text AS chapter_id,
      c.title,
      COALESCE(c.chapter_order, 0)::integer AS chapter_order,
      COUNT(pr.id)::bigint AS purchases_count,
      COALESCE(SUM(pr.author_share_cents), 0)::bigint AS author_share_cents,
      COUNT(DISTINCT pr.user_id)::bigint AS unique_payers
    FROM public."Chapter" c
    LEFT JOIN public.purchase_records pr
      ON pr.chapter_id = c.id
      AND pr.story_id = p_story_id
      AND pr.env = v_env
      AND pr.created_at >= v_since
      AND pr.sku_type = 'chapter_pass'
    WHERE c.story_id = p_story_id
    GROUP BY c.id, c.title, c.chapter_order
  ) t;

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
      'message', 'Недостаточно читателей для отображения статистики',
      'by_chapter', v_by_chapter
    );
  END IF;

  IF v_purchases = 0 THEN
    RETURN jsonb_build_object(
      'enabled', true,
      'has_data', false,
      'message', 'За выбранный период покупок не было',
      'by_chapter', v_by_chapter
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
    'by_chapter', v_by_chapter,
    'daily', v_daily
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_story_revenue_overview(uuid, integer, text) TO authenticated;

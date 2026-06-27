DROP FUNCTION IF EXISTS public.get_story_platform_breakdown(uuid, integer, text);
DROP FUNCTION IF EXISTS public.get_story_session_stats(uuid, integer, text);

CREATE OR REPLACE FUNCTION public.get_story_platform_breakdown(
  p_story_id uuid,
  p_days integer DEFAULT NULL,
  p_env text DEFAULT 'prod'
)
RETURNS TABLE (
  platform text,
  readers integer,
  pct numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_total integer;
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  SELECT count(DISTINCT COALESCE(ae.user_id::text, ae.device_id))::integer INTO v_total
  FROM public.analytics_events ae
  WHERE ae.story_id = p_story_id
    AND ae.env = p_env
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval);

  IF v_total = 0 THEN
    v_total := 1;
  END IF;

  RETURN QUERY
  SELECT
    COALESCE(ae.properties->>'platform', 'unknown') AS platform,
    count(DISTINCT COALESCE(ae.user_id::text, ae.device_id))::integer AS readers,
    round(
      count(DISTINCT COALESCE(ae.user_id::text, ae.device_id))::numeric / v_total::numeric * 100,
      1
    ) AS pct
  FROM public.analytics_events ae
  WHERE ae.story_id = p_story_id
    AND ae.env = p_env
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval)
  GROUP BY 1
  ORDER BY readers DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_story_session_stats(
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
  v_avg numeric;
  v_median numeric;
  v_count integer;
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  SELECT
    round(avg((ae.properties->>'duration_ms')::numeric), 0),
    percentile_cont(0.5) WITHIN GROUP (ORDER BY (ae.properties->>'duration_ms')::numeric),
    count(*)::integer
  INTO v_avg, v_median, v_count
  FROM public.analytics_events ae
  WHERE ae.story_id = p_story_id
    AND ae.env = p_env
    AND ae.event = 'quest_session_end'
    AND ae.properties ? 'duration_ms'
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval);

  RETURN jsonb_build_object(
    'avg_duration_ms', COALESCE(v_avg, 0),
    'median_duration_ms', COALESCE(v_median, 0),
    'session_count', COALESCE(v_count, 0)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_story_platform_breakdown(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_story_session_stats(uuid, integer, text) TO authenticated;

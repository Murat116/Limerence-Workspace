DROP FUNCTION IF EXISTS public.get_story_discovery_funnel(uuid, integer, text);
DROP FUNCTION IF EXISTS public.get_story_replay_stats(uuid, integer, text);
DROP FUNCTION IF EXISTS public.get_story_retention_cohorts(uuid, text);
DROP FUNCTION IF EXISTS public.get_story_ending_stats(uuid, uuid, integer, text);

CREATE OR REPLACE FUNCTION public.get_story_discovery_funnel(
  p_story_id uuid,
  p_days integer DEFAULT NULL,
  p_env text DEFAULT 'prod'
)
RETURNS TABLE (
  step text,
  readers integer,
  pct_of_previous numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_opened integer;
  v_start_tapped integer;
  v_reading_started integer;
  v_ch1_completed integer;
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  SELECT count(DISTINCT COALESCE(ae.user_id::text, ae.device_id))::integer INTO v_opened
  FROM public.analytics_events ae
  WHERE ae.story_id = p_story_id AND ae.env = p_env AND ae.event = 'story_opened'
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval);

  SELECT count(DISTINCT COALESCE(ae.user_id::text, ae.device_id))::integer INTO v_start_tapped
  FROM public.analytics_events ae
  WHERE ae.story_id = p_story_id AND ae.env = p_env AND ae.event = 'chapter_start_tapped'
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval);

  SELECT count(DISTINCT COALESCE(ae.user_id::text, ae.device_id))::integer INTO v_reading_started
  FROM public.analytics_events ae
  WHERE ae.story_id = p_story_id AND ae.env = p_env AND ae.event = 'story_reading_started'
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval);

  SELECT count(DISTINCT COALESCE(ae.user_id::text, ae.device_id))::integer INTO v_ch1_completed
  FROM public.analytics_events ae
  JOIN public."Chapter" c ON c.id = ae.chapter_id AND c.chapter_order = (
    SELECT min(ch.chapter_order) FROM public."Chapter" ch WHERE ch.story_id = p_story_id
  )
  WHERE ae.story_id = p_story_id AND ae.env = p_env AND ae.event = 'chapter_completed'
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval);

  RETURN QUERY
  SELECT 'story_opened'::text, v_opened, 100::numeric
  UNION ALL
  SELECT 'chapter_start_tapped', v_start_tapped,
    CASE WHEN v_opened > 0 THEN round(v_start_tapped::numeric / v_opened * 100, 1) ELSE 0 END
  UNION ALL
  SELECT 'story_reading_started', v_reading_started,
    CASE WHEN v_start_tapped > 0 THEN round(v_reading_started::numeric / v_start_tapped * 100, 1) ELSE 0 END
  UNION ALL
  SELECT 'chapter_1_completed', v_ch1_completed,
    CASE WHEN v_reading_started > 0 THEN round(v_ch1_completed::numeric / v_reading_started * 100, 1) ELSE 0 END;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_story_replay_stats(
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
  v_restarts integer;
  v_starters integer;
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  SELECT count(*)::integer INTO v_restarts
  FROM public.analytics_events ae
  WHERE ae.story_id = p_story_id AND ae.env = p_env AND ae.event = 'chapter_restarted'
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval);

  SELECT count(DISTINCT COALESCE(ae.user_id::text, ae.device_id))::integer INTO v_starters
  FROM public.analytics_events ae
  WHERE ae.story_id = p_story_id AND ae.env = p_env AND ae.event = 'quest_session_start'
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval);

  RETURN jsonb_build_object(
    'restart_count', COALESCE(v_restarts, 0),
    'unique_starters', COALESCE(v_starters, 0),
    'replay_rate', CASE WHEN v_starters > 0 THEN round(v_restarts::numeric / v_starters * 100, 1) ELSE 0 END
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_story_retention_cohorts(
  p_story_id uuid,
  p_env text DEFAULT 'prod'
)
RETURNS TABLE (
  cohort_week date,
  cohort_size integer,
  retained_d1 integer,
  retained_d7 integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  RETURN QUERY
  WITH first_read AS (
    SELECT
      COALESCE(ae.user_id::text, ae.device_id) AS reader_key,
      min(ae.client_created_at) AS first_at
    FROM public.analytics_events ae
    WHERE ae.story_id = p_story_id
      AND ae.env = p_env
      AND ae.event = 'story_reading_started'
    GROUP BY 1
  ),
  cohorts AS (
    SELECT
      date_trunc('week', fr.first_at)::date AS week,
      fr.reader_key,
      fr.first_at
    FROM first_read fr
  )
  SELECT
    c.week,
    count(*)::integer,
    count(*) FILTER (
      WHERE EXISTS (
        SELECT 1 FROM public.analytics_events ae
        WHERE ae.story_id = p_story_id AND ae.env = p_env
          AND ae.event = 'quest_session_start'
          AND COALESCE(ae.user_id::text, ae.device_id) = c.reader_key
          AND ae.client_created_at BETWEEN c.first_at + interval '1 day' AND c.first_at + interval '2 days'
      )
    )::integer,
    count(*) FILTER (
      WHERE EXISTS (
        SELECT 1 FROM public.analytics_events ae
        WHERE ae.story_id = p_story_id AND ae.env = p_env
          AND ae.event = 'quest_session_start'
          AND COALESCE(ae.user_id::text, ae.device_id) = c.reader_key
          AND ae.client_created_at BETWEEN c.first_at + interval '7 days' AND c.first_at + interval '8 days'
      )
    )::integer
  FROM cohorts c
  GROUP BY c.week
  ORDER BY c.week DESC
  LIMIT 12;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_story_ending_stats(
  p_story_id uuid,
  p_chapter_id uuid DEFAULT NULL,
  p_days integer DEFAULT NULL,
  p_env text DEFAULT 'prod'
)
RETURNS TABLE (
  ending_id text,
  views integer,
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

  SELECT count(*)::integer INTO v_total
  FROM public.analytics_events ae
  WHERE ae.story_id = p_story_id
    AND ae.env = p_env
    AND ae.event = 'chapter_ending_viewed'
    AND (p_chapter_id IS NULL OR ae.chapter_id = p_chapter_id)
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval);

  IF v_total = 0 THEN
    v_total := 1;
  END IF;

  RETURN QUERY
  SELECT
    COALESCE(ae.properties->>'ending_id', 'unknown') AS ending_id,
    count(*)::integer AS views,
    round(count(*)::numeric / v_total::numeric * 100, 1) AS pct
  FROM public.analytics_events ae
  WHERE ae.story_id = p_story_id
    AND ae.env = p_env
    AND ae.event = 'chapter_ending_viewed'
    AND (p_chapter_id IS NULL OR ae.chapter_id = p_chapter_id)
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval)
  GROUP BY 1
  ORDER BY views DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_story_discovery_funnel(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_story_replay_stats(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_story_retention_cohorts(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_story_ending_stats(uuid, uuid, integer, text) TO authenticated;

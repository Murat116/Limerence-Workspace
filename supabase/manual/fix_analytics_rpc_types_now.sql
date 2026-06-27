-- Supabase Dashboard → SQL Editor → Run (fixes 42804 yellow banner errors)

-- Fix PostgREST 42804: return types must match exactly (bigint→integer, uuid→text in COALESCE).

CREATE OR REPLACE FUNCTION public.get_story_chapter_funnel(
  p_story_id uuid,
  p_days integer DEFAULT NULL,
  p_env text DEFAULT 'prod'
)
RETURNS TABLE (
  chapter_id uuid,
  title text,
  chapter_order integer,
  started integer,
  completed integer,
  completion_pct numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  RETURN QUERY
  WITH progress AS (
    SELECT * FROM public._filtered_user_progress(p_story_id, p_days, p_env)
  ),
  chapter_stats AS (
    SELECT
      c.id AS ch_id,
      c.title AS ch_title,
      COALESCE(c.chapter_order, 0)::integer AS ch_order,
      count(DISTINCT ucp.user_progress_id)::integer AS started_count,
      count(DISTINCT CASE
        WHEN p.completed_chapter_ids IS NOT NULL AND c.id = ANY (p.completed_chapter_ids)
        THEN p.id
      END)::integer AS completed_count
    FROM public."Chapter" c
    LEFT JOIN public."UserChapterProgress" ucp ON ucp.chapter_id = c.id
      AND ucp.user_progress_id IN (SELECT id FROM progress)
    LEFT JOIN progress p ON p.id = ucp.user_progress_id
    WHERE c.story_id = p_story_id
    GROUP BY c.id, c.title, c.chapter_order
  )
  SELECT
    cs.ch_id,
    cs.ch_title,
    cs.ch_order,
    cs.started_count,
    cs.completed_count,
    CASE WHEN cs.started_count > 0
      THEN round((cs.completed_count::numeric / cs.started_count::numeric) * 100, 1)
      ELSE 0::numeric
    END
  FROM chapter_stats cs
  ORDER BY cs.ch_order, cs.ch_title;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_story_analytics_trend(
  p_story_id uuid,
  p_days integer DEFAULT 30,
  p_env text DEFAULT 'prod'
)
RETURNS TABLE (
  date date,
  readers integer,
  starts integer,
  completions integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  RETURN QUERY
  WITH days AS (
    SELECT generate_series(
      date_trunc('day', now() - make_interval(days => COALESCE(p_days, 30))),
      date_trunc('day', now()),
      interval '1 day'
    )::date AS day
  ),
  daily AS (
    SELECT
      date_trunc('day', ae.client_created_at)::date AS day,
      count(DISTINCT COALESCE(ae.user_id::text, ae.device_id::text))::integer AS readers_count,
      count(*) FILTER (WHERE ae.event = 'story_reading_started')::integer AS starts_count,
      count(*) FILTER (WHERE ae.event = 'chapter_completed')::integer AS completions_count
    FROM public.analytics_events ae
    WHERE ae.story_id = p_story_id
      AND ae.env = p_env
      AND (p_days IS NULL OR ae.client_created_at >= now() - make_interval(days => p_days))
    GROUP BY 1
  )
  SELECT
    d.day,
    COALESCE(daily.readers_count, 0)::integer,
    COALESCE(daily.starts_count, 0)::integer,
    COALESCE(daily.completions_count, 0)::integer
  FROM days d
  LEFT JOIN daily ON daily.day = d.day
  ORDER BY d.day;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_story_chapter_funnel(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_story_analytics_trend(uuid, integer, text) TO authenticated;

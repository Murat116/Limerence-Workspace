DROP FUNCTION IF EXISTS public.get_story_analytics_trend(uuid, integer, text);
DROP FUNCTION IF EXISTS public.get_story_dialog_dropoff(uuid, uuid, integer, text);

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

CREATE OR REPLACE FUNCTION public.get_story_dialog_dropoff(
  p_story_id uuid,
  p_chapter_id uuid,
  p_days integer DEFAULT NULL,
  p_env text DEFAULT 'prod'
)
RETURNS TABLE (
  dialog_list_id uuid,
  title text,
  readers_reached integer,
  pct_of_starters numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_starters integer;
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  SELECT count(DISTINCT COALESCE(ae.user_id::text, ae.device_id))::integer INTO v_starters
  FROM public.analytics_events ae
  WHERE ae.story_id = p_story_id
    AND ae.chapter_id = p_chapter_id
    AND ae.env = p_env
    AND ae.event = 'quest_session_start'
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval);

  IF v_starters = 0 THEN
    v_starters := 1;
  END IF;

  RETURN QUERY
  SELECT
    dl.uuid AS dialog_list_id,
    dl.title,
    count(DISTINCT COALESCE(ae.user_id::text, ae.device_id))::integer AS readers_reached,
    round(
      count(DISTINCT COALESCE(ae.user_id::text, ae.device_id))::numeric / v_starters::numeric * 100,
      1
    ) AS pct_of_starters
  FROM public."DialogList" dl
  LEFT JOIN public.analytics_events ae
    ON ae.story_id = p_story_id
    AND ae.chapter_id = p_chapter_id
    AND ae.env = p_env
    AND ae.event = 'quest_dialog_list_entered'
    AND (ae.properties->>'dialog_list_id')::uuid = dl.uuid
    AND (p_days IS NULL OR ae.client_created_at >= now() - (p_days || ' days')::interval)
  WHERE dl.story_id = p_story_id
    AND dl.scene_uuid IN (
      SELECT s.uuid FROM public."Scene" s WHERE s.chapter_id = p_chapter_id
    )
  GROUP BY dl.uuid, dl.title
  ORDER BY readers_reached DESC, dl.title;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_story_analytics_trend(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_story_dialog_dropoff(uuid, uuid, integer, text) TO authenticated;

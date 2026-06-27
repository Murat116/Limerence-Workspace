CREATE OR REPLACE FUNCTION public._assert_story_author(p_story_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.story_permissions sp
    WHERE sp.story_id = p_story_id
      AND sp.user_id = auth.uid()
  ) THEN
    RETURN;
  END IF;

  -- Same access as HomePage / get_editable_stories()
  IF EXISTS (
    SELECT 1
    FROM public.get_editable_stories() es
    WHERE COALESCE(
      to_jsonb(es)->>'id',
      to_jsonb(es)->>'story_id',
      to_jsonb(es)->>'uuid'
    ) = p_story_id::text
  ) THEN
    RETURN;
  END IF;

  RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
END;
$$;

REVOKE ALL ON FUNCTION public._assert_story_author(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._assert_story_author(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public._filtered_user_progress(
  p_story_id uuid,
  p_days integer,
  p_env text
)
RETURNS SETOF public."UserProgress"
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT up.*
  FROM public."UserProgress" up
  WHERE up.story_id = p_story_id
    AND (p_days IS NULL OR up.last_accessed_at >= now() - (p_days || ' days')::interval)
    AND (
      p_env IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.analytics_events ae
        WHERE ae.story_id = p_story_id
          AND ae.env = p_env
          AND ae.user_id = up.user_id
      )
      OR NOT EXISTS (
        SELECT 1 FROM public.analytics_events ae2
        WHERE ae2.story_id = p_story_id AND ae2.env = p_env
      )
    );
$$;

REVOKE ALL ON FUNCTION public._filtered_user_progress(uuid, integer, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._filtered_user_progress(uuid, integer, text) TO authenticated;

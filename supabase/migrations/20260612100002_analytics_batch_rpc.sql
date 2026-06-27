DROP FUNCTION IF EXISTS public.insert_analytics_events_batch(jsonb);

CREATE OR REPLACE FUNCTION public.insert_analytics_events_batch(p_events jsonb)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count integer;
BEGIN
  IF p_events IS NULL OR jsonb_typeof(p_events) <> 'array' THEN
    RAISE EXCEPTION 'p_events must be a JSON array';
  END IF;

  v_count := jsonb_array_length(p_events);
  IF v_count = 0 THEN
    RETURN 0;
  END IF;
  IF v_count > 50 THEN
    RAISE EXCEPTION 'batch limit exceeded (max 50)';
  END IF;

  INSERT INTO public.analytics_events (
    user_id, device_id, session_id, event, env, context_scope,
    story_id, chapter_id, properties, client_created_at
  )
  SELECT
    NULLIF(elem->>'user_id', '')::uuid,
    elem->>'device_id',
    elem->>'session_id',
    elem->>'event',
    elem->>'env',
    elem->>'context_scope',
    NULLIF(elem->>'story_id', '')::uuid,
    NULLIF(elem->>'chapter_id', '')::uuid,
    COALESCE(elem->'properties', '{}'::jsonb),
    (elem->>'client_created_at')::timestamptz
  FROM jsonb_array_elements(p_events) AS elem
  WHERE elem->>'env' IN ('sandbox', 'prod');

  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.insert_analytics_events_batch(jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.insert_analytics_events_batch(jsonb) TO authenticated, anon;

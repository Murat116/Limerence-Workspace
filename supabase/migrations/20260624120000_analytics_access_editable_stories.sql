-- Author analytics access aligned with editor HomePage (get_editable_stories).
-- Legacy story_permissions may only have (user_id, story_id).

CREATE OR REPLACE FUNCTION public._assert_story_author(p_story_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_json jsonb;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.story_permissions sp
    WHERE sp.story_id = p_story_id
      AND sp.user_id = v_uid
  ) THEN
    RETURN;
  END IF;

  FOR v_json IN SELECT to_jsonb(es) FROM public.get_editable_stories() es
  LOOP
    IF COALESCE(v_json->>'id', v_json->>'story_id', v_json->>'uuid') = p_story_id::text THEN
      RETURN;
    END IF;
  END LOOP;

  RAISE EXCEPTION 'forbidden: user % has no access to story %', v_uid, p_story_id
    USING ERRCODE = '42501';
END;
$$;

CREATE OR REPLACE FUNCTION public.ensure_story_analytics_access(p_story_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_json jsonb;
  v_editable boolean := false;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'not_authenticated');
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.story_permissions sp
    WHERE sp.story_id = p_story_id AND sp.user_id = v_uid
  ) THEN
    RETURN jsonb_build_object('ok', true, 'reason', 'permission_exists', 'user_id', v_uid);
  END IF;

  FOR v_json IN SELECT to_jsonb(es) FROM public.get_editable_stories() es
  LOOP
    IF COALESCE(v_json->>'id', v_json->>'story_id', v_json->>'uuid') = p_story_id::text THEN
      v_editable := true;
      EXIT;
    END IF;
  END LOOP;

  IF v_editable THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.story_permissions sp
      WHERE sp.story_id = p_story_id AND sp.user_id = v_uid
    ) THEN
      INSERT INTO public.story_permissions (story_id, user_id)
      VALUES (p_story_id, v_uid);
    END IF;
    RETURN jsonb_build_object('ok', true, 'reason', 'granted_from_editable', 'user_id', v_uid);
  END IF;

  RETURN jsonb_build_object(
    'ok', false,
    'reason', 'forbidden',
    'user_id', v_uid,
    'story_id', p_story_id
  );
END;
$$;

REVOKE ALL ON FUNCTION public._assert_story_author(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.ensure_story_analytics_access(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._assert_story_author(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_story_analytics_access(uuid) TO authenticated;

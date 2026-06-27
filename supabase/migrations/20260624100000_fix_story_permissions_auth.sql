-- Cloud story_permissions existed without `role` column; _assert_story_author referenced sp.role → SQL error on every RPC.
-- SUPERSEDED by 20260624120000_analytics_access_editable_stories.sql — do not apply role-based check without ADD COLUMN first.

ALTER TABLE public.story_permissions
  ADD COLUMN IF NOT EXISTS role text;

UPDATE public.story_permissions
SET role = 'owner'
WHERE role IS NULL;

ALTER TABLE public.story_permissions
  ALTER COLUMN role SET DEFAULT 'owner';

-- Not NOT NULL yet — avoid breaking if legacy rows appear during deploy.

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

  RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
END;
$$;

REVOKE ALL ON FUNCTION public._assert_story_author(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._assert_story_author(uuid) TO authenticated;

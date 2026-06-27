-- Minimal auth: legacy story_permissions has only (user_id, story_id) — no role column.

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

  RAISE EXCEPTION 'forbidden: no story_permissions for user % story %', auth.uid(), p_story_id
    USING ERRCODE = '42501';
END;
$$;

REVOKE ALL ON FUNCTION public._assert_story_author(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._assert_story_author(uuid) TO authenticated;

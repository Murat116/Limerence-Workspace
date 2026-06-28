-- Early access window is platform-fixed 3 days (paywall.md Q-09); drop author-configurable column.
-- @see docs/specs/monetization/paywall.md Q-09

CREATE OR REPLACE FUNCTION public.get_player_monetization_config(p_story_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_released boolean;
  v_story_tier text;
  v_chapters jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  SELECT s.released INTO v_released
  FROM public."Story" s
  WHERE s.id = p_story_id;

  IF NOT FOUND OR NOT COALESCE(v_released, false) THEN
    RAISE EXCEPTION 'story_not_available';
  END IF;

  SELECT sm.full_story_tier_key INTO v_story_tier
  FROM public.story_monetization sm
  WHERE sm.story_id = p_story_id;

  SELECT COALESCE(jsonb_object_agg(
    cm.chapter_id::text,
    jsonb_build_object(
      'chapter_pass_tier_key', cm.chapter_pass_tier_key
    )
  ), '{}'::jsonb)
  INTO v_chapters
  FROM public.chapter_monetization cm
  JOIN public."Chapter" c ON c.id = cm.chapter_id
  WHERE c.story_id = p_story_id;

  RETURN jsonb_build_object(
    'story_id', p_story_id,
    'full_story_tier_key', v_story_tier,
    'chapters', v_chapters
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_player_monetization_config(uuid) TO authenticated;

ALTER TABLE public.chapter_monetization
  DROP COLUMN IF EXISTS subscriber_early_access_days;

-- Sandbox: all UserProgress for story (no analytics_events env gate).
-- Sandbox: variant stats without k-anonymity floor.

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
      p_env = 'sandbox'
      OR p_env IS NULL
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

CREATE OR REPLACE FUNCTION public.get_story_variant_stats(
  p_story_id uuid,
  p_chapter_id uuid DEFAULT NULL,
  p_min_readers integer DEFAULT 10,
  p_env text DEFAULT 'prod',
  p_days integer DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_readers integer;
  v_variants jsonb;
  v_min_readers integer;
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  v_min_readers := CASE WHEN p_env = 'sandbox' THEN 1 ELSE p_min_readers END;

  SELECT count(DISTINCT ucp.user_progress_id)::integer INTO v_readers
  FROM public."UserChapterProgress" ucp
  WHERE ucp.user_progress_id IN (
      SELECT id FROM public._filtered_user_progress(p_story_id, p_days, p_env)
    )
    AND (p_chapter_id IS NULL OR ucp.chapter_id = p_chapter_id)
    AND ucp.chosen_variant_ids IS NOT NULL
    AND cardinality(ucp.chosen_variant_ids) > 0
    AND (p_days IS NULL OR ucp.updated_at >= now() - (p_days || ' days')::interval);

  IF v_readers < v_min_readers THEN
    RETURN jsonb_build_object(
      'suppressed', true,
      'min_readers', v_min_readers,
      'actual_readers', v_readers,
      'variants', '[]'::jsonb
    );
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb ORDER BY t.picks DESC), '[]'::jsonb) INTO v_variants
  FROM (
    SELECT
      v.uuid AS variant_id,
      v.text,
      count(*)::integer AS picks,
      round(
        count(*)::numeric * 100.0 / NULLIF(sum(count(*)) OVER (), 0),
        1
      ) AS pct
    FROM public."UserChapterProgress" ucp
    CROSS JOIN LATERAL unnest(ucp.chosen_variant_ids) AS picked(variant_id)
    JOIN public."Variant" v ON v.uuid = picked.variant_id
    WHERE ucp.user_progress_id IN (
        SELECT id FROM public._filtered_user_progress(p_story_id, p_days, p_env)
      )
      AND (p_chapter_id IS NULL OR ucp.chapter_id = p_chapter_id)
      AND (p_days IS NULL OR ucp.updated_at >= now() - (p_days || ' days')::interval)
    GROUP BY v.uuid, v.text
  ) t;

  RETURN jsonb_build_object(
    'suppressed', false,
    'min_readers', v_min_readers,
    'actual_readers', v_readers,
    'variants', v_variants
  );
END;
$$;

-- Per-reader breakdown for sandbox debugging (no k-anonymity).
CREATE OR REPLACE FUNCTION public.get_story_sandbox_readers(
  p_story_id uuid,
  p_days integer DEFAULT NULL,
  p_env text DEFAULT 'sandbox'
)
RETURNS TABLE (
  user_id uuid,
  last_accessed_at timestamptz,
  chapters_started integer,
  chapters_completed integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  IF p_env <> 'sandbox' THEN
    RAISE EXCEPTION 'sandbox readers only available for env=sandbox' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    up.user_id,
    up.last_accessed_at,
    (
      SELECT count(*)::integer
      FROM public."UserChapterProgress" ucp
      WHERE ucp.user_progress_id = up.id
        AND ucp.viewed_scene_ids IS NOT NULL
        AND cardinality(ucp.viewed_scene_ids) > 0
    ) AS chapters_started,
    COALESCE(cardinality(up.completed_chapter_ids), 0)::integer AS chapters_completed
  FROM public._filtered_user_progress(p_story_id, p_days, p_env) up
  WHERE up.user_id IS NOT NULL
  ORDER BY up.last_accessed_at DESC NULLS LAST;
END;
$$;

REVOKE ALL ON FUNCTION public.get_story_sandbox_readers(uuid, integer, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_story_sandbox_readers(uuid, integer, text) TO authenticated;

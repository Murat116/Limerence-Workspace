-- Drop prior overloads/signatures before recreate (cloud may have older return types).
DROP FUNCTION IF EXISTS public.get_story_analytics_overview(uuid, integer, text);
DROP FUNCTION IF EXISTS public.get_story_chapter_funnel(uuid, integer, text);
DROP FUNCTION IF EXISTS public.get_story_scene_dropoff(uuid, uuid, integer, text);
DROP FUNCTION IF EXISTS public.get_story_variant_stats(uuid, uuid, integer, text);
DROP FUNCTION IF EXISTS public.get_story_variant_stats(uuid, uuid, integer, text, integer);

-- Author read analytics from UserProgress / UserChapterProgress.

CREATE OR REPLACE FUNCTION public.get_story_analytics_overview(
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
  v_total integer;
  v_active_7d integer;
  v_active_30d integer;
  v_completed integer;
  v_completion_rate numeric;
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  SELECT count(*)::integer INTO v_total
  FROM public._filtered_user_progress(p_story_id, p_days, p_env) up;

  SELECT count(*)::integer INTO v_active_7d
  FROM public._filtered_user_progress(p_story_id, p_days, p_env) up
  WHERE up.last_accessed_at >= now() - interval '7 days';

  SELECT count(*)::integer INTO v_active_30d
  FROM public._filtered_user_progress(p_story_id, p_days, p_env) up
  WHERE up.last_accessed_at >= now() - interval '30 days';

  SELECT count(*)::integer INTO v_completed
  FROM public._filtered_user_progress(p_story_id, p_days, p_env) up
  WHERE up.completed_chapter_ids IS NOT NULL
    AND cardinality(up.completed_chapter_ids) > 0;

  IF v_total > 0 THEN
    v_completion_rate := round((v_completed::numeric / v_total::numeric) * 100, 1);
  ELSE
    v_completion_rate := 0;
  END IF;

  RETURN jsonb_build_object(
    'total_readers', v_total,
    'active_7d', v_active_7d,
    'active_30d', v_active_30d,
    'completion_rate', v_completion_rate
  );
END;
$$;

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
      ELSE 0
    END
  FROM chapter_stats cs
  ORDER BY cs.ch_order, cs.ch_title;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_story_scene_dropoff(
  p_story_id uuid,
  p_chapter_id uuid,
  p_days integer DEFAULT NULL,
  p_env text DEFAULT 'prod'
)
RETURNS TABLE (
  scene_id uuid,
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

  SELECT count(DISTINCT ucp.user_progress_id)::integer INTO v_starters
  FROM public."UserChapterProgress" ucp
  WHERE ucp.chapter_id = p_chapter_id
    AND ucp.user_progress_id IN (
      SELECT id FROM public._filtered_user_progress(p_story_id, p_days, p_env)
    )
    AND ucp.viewed_scene_ids IS NOT NULL
    AND cardinality(ucp.viewed_scene_ids) > 0;

  IF v_starters = 0 THEN
    v_starters := 1;
  END IF;

  RETURN QUERY
  SELECT
    s.uuid AS scene_id,
    s.title,
    count(DISTINCT ucp.user_progress_id)::integer AS readers_reached,
    round(
      (count(DISTINCT ucp.user_progress_id)::numeric / v_starters::numeric) * 100,
      1
    ) AS pct_of_starters
  FROM public."Scene" s
  LEFT JOIN public."UserChapterProgress" ucp
    ON ucp.chapter_id = p_chapter_id
    AND ucp.user_progress_id IN (
      SELECT id FROM public._filtered_user_progress(p_story_id, p_days, p_env)
    )
    AND s.uuid = ANY (ucp.viewed_scene_ids)
  WHERE s.chapter_id = p_chapter_id
    AND s.story_id = p_story_id
  GROUP BY s.uuid, s.title
  ORDER BY readers_reached DESC, s.title;
END;
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
BEGIN
  PERFORM public._assert_story_author(p_story_id);

  SELECT count(DISTINCT ucp.user_progress_id)::integer INTO v_readers
  FROM public."UserChapterProgress" ucp
  WHERE ucp.user_progress_id IN (
      SELECT id FROM public._filtered_user_progress(p_story_id, p_days, p_env)
    )
    AND (p_chapter_id IS NULL OR ucp.chapter_id = p_chapter_id)
    AND ucp.chosen_variant_ids IS NOT NULL
    AND cardinality(ucp.chosen_variant_ids) > 0
    AND (p_days IS NULL OR ucp.updated_at >= now() - (p_days || ' days')::interval);

  IF v_readers < p_min_readers THEN
    RETURN jsonb_build_object(
      'suppressed', true,
      'min_readers', p_min_readers,
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
    'min_readers', p_min_readers,
    'actual_readers', v_readers,
    'variants', v_variants
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_story_analytics_overview(uuid, integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_story_chapter_funnel(uuid, integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_story_scene_dropoff(uuid, uuid, integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_story_variant_stats(uuid, uuid, integer, text, integer) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_story_analytics_overview(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_story_chapter_funnel(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_story_scene_dropoff(uuid, uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_story_variant_stats(uuid, uuid, integer, text, integer) TO authenticated;

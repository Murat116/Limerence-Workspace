-- Monetization foundation (billing not implemented yet).

CREATE TABLE IF NOT EXISTS public.story_purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id uuid NOT NULL,
  user_id uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  variant_id uuid,
  amount_cents integer NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'USD',
  category text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public."Variant"
  ADD COLUMN IF NOT EXISTS is_premium boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS premium_price integer,
  ADD COLUMN IF NOT EXISTS premium_category text,
  ADD COLUMN IF NOT EXISTS iap_product_id text;

DROP FUNCTION IF EXISTS public.get_story_revenue_overview(uuid, integer, text);
DROP FUNCTION IF EXISTS public.get_story_premium_choice_stats(uuid, uuid, integer, text);

CREATE OR REPLACE FUNCTION public.get_story_revenue_overview(
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
BEGIN
  PERFORM public._assert_story_author(p_story_id);
  RETURN jsonb_build_object(
    'enabled', false,
    'message', 'Monetization is not enabled yet'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_story_premium_choice_stats(
  p_story_id uuid,
  p_chapter_id uuid DEFAULT NULL,
  p_days integer DEFAULT NULL,
  p_env text DEFAULT 'prod'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  PERFORM public._assert_story_author(p_story_id);
  RETURN jsonb_build_object(
    'enabled', false,
    'choices', '[]'::jsonb
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_story_revenue_overview(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_story_premium_choice_stats(uuid, uuid, integer, text) TO authenticated;

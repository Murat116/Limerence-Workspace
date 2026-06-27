ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_permissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS analytics_events_insert_own ON public.analytics_events;
CREATE POLICY analytics_events_insert_own ON public.analytics_events
  FOR INSERT TO authenticated
  WITH CHECK (user_id IS NULL OR user_id = auth.uid());

DROP POLICY IF EXISTS analytics_events_insert_anon ON public.analytics_events;
CREATE POLICY analytics_events_insert_anon ON public.analytics_events
  FOR INSERT TO anon
  WITH CHECK (user_id IS NULL);

DROP POLICY IF EXISTS analytics_events_select_none ON public.analytics_events;
CREATE POLICY analytics_events_select_none ON public.analytics_events
  FOR SELECT TO authenticated
  USING (false);

DROP POLICY IF EXISTS story_permissions_select_own ON public.story_permissions;
CREATE POLICY story_permissions_select_own ON public.story_permissions
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

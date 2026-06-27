-- Supplemental indexes for author analytics event aggregation.

CREATE INDEX IF NOT EXISTS analytics_events_user_story_env_idx
  ON public.analytics_events (user_id, story_id, env)
  WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS analytics_events_event_created_idx
  ON public.analytics_events (event, client_created_at DESC);

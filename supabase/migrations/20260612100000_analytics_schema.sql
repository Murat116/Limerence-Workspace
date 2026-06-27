CREATE TABLE IF NOT EXISTS public.analytics_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  device_id text NOT NULL,
  session_id text NOT NULL,
  event text NOT NULL,
  env text NOT NULL CHECK (env IN ('sandbox', 'prod')),
  context_scope text NOT NULL,
  story_id uuid,
  chapter_id uuid,
  properties jsonb NOT NULL DEFAULT '{}'::jsonb,
  client_created_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS analytics_events_story_env_created_idx
  ON public.analytics_events (story_id, env, client_created_at DESC)
  WHERE story_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS analytics_events_story_env_event_idx
  ON public.analytics_events (story_id, env, event)
  WHERE story_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.story_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('owner', 'editor', 'viewer')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (story_id, user_id)
);

CREATE INDEX IF NOT EXISTS story_permissions_user_id_idx ON public.story_permissions (user_id);
CREATE INDEX IF NOT EXISTS story_permissions_story_id_idx ON public.story_permissions (story_id);

-- Remote minimum app version policy (singleton row).
-- @see Спецификация/Требования к версии приложения.md

CREATE TABLE IF NOT EXISTS public."AppVersionPolicy" (
  id text PRIMARY KEY DEFAULT 'default',
  is_enabled boolean NOT NULL DEFAULT true,
  min_version_ios text NOT NULL DEFAULT '0.0.0',
  min_version_android text NOT NULL DEFAULT '0.0.0',
  title text NOT NULL DEFAULT 'Требуется обновление',
  message text NOT NULL DEFAULT 'Ваша версия приложения больше не поддерживается. Пожалуйста, обновите приложение, чтобы продолжить.',
  store_url_ios text,
  store_url_android text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public."AppVersionPolicy" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "AppVersionPolicy_select_anon"
  ON public."AppVersionPolicy"
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "AppVersionPolicy_select_authenticated"
  ON public."AppVersionPolicy"
  FOR SELECT
  TO authenticated
  USING (true);

INSERT INTO public."AppVersionPolicy" (
  id,
  is_enabled,
  min_version_ios,
  min_version_android,
  title,
  message
)
VALUES (
  'default',
  true,
  '0.0.0',
  '0.0.0',
  'Требуется обновление',
  'Ваша версия приложения больше не поддерживается. Пожалуйста, обновите приложение, чтобы продолжить.'
)
ON CONFLICT (id) DO NOTHING;

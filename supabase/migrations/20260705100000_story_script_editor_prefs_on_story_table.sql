-- Коррекция: колонка prefs должна быть на "Story" (PascalCase), не public.story.
-- @see supabase/migrations/20260704100000_story_script_editor_prefs.sql

ALTER TABLE "Story"
  ADD COLUMN IF NOT EXISTS script_editor_prefs JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN "Story".script_editor_prefs IS
  'Prefs текстового редактора: blankLinesAfterScene/List/Dialog, editorFontSizePx.';

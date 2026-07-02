-- Настройки текстового редактора сценариста на уровне истории.
-- @see docs/web/text-editor-mode.md#scenarist-ux
-- @see .cursor/feature-work/web-script-editor-scenarist-ux/03-approved-spec.md

ALTER TABLE "Story"
  ADD COLUMN IF NOT EXISTS script_editor_prefs JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN "Story".script_editor_prefs IS
  'Prefs текстового редактора: blankLinesAfterScene/List/Dialog, editorFontSizePx. Не влияет на gameplay store сущностей.';

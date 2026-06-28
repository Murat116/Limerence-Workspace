-- Author-only metadata for asset generation prompts (web constructor)
-- @see docs/web/scenario-import/

ALTER TABLE "Person" ADD COLUMN IF NOT EXISTS asset_description text;

ALTER TABLE "Scene" ADD COLUMN IF NOT EXISTS asset_description text;
ALTER TABLE "Scene" ADD COLUMN IF NOT EXISTS bgm_description text;

ALTER TABLE "Story" ADD COLUMN IF NOT EXISTS style_reference text;

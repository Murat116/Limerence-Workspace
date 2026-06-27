-- Источник истины — только layout_data (в т.ч. base svg внутри JSON).
-- Если колонка svg ещё есть: переносим в layout_data и удаляем колонку.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_attribute a
    JOIN pg_class c ON a.attrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public'
      AND c.relname = 'DialogFrame'
      AND a.attname = 'svg'
      AND a.attnum > 0
      AND NOT a.attisdropped
  ) THEN
    UPDATE "DialogFrame"
    SET layout_data = coalesce(layout_data, '{}'::jsonb) || jsonb_build_object('svg', svg)
    WHERE svg IS NOT NULL
      AND btrim(svg) <> ''
      AND (
        layout_data IS NULL
        OR NOT (coalesce(layout_data, '{}'::jsonb) ? 'svg')
        OR coalesce(layout_data->>'svg', '') = ''
      );

    ALTER TABLE "DialogFrame" DROP COLUMN svg;
  END IF;
END $$;

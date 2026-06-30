## Резюме

Синхронизировано **4 документа** в `docs/web/`. Notion не подключен. Supabase и `docs/specs/` не менялись — в approved-spec не требовалось. `story-constructor-spec.md` в репо отсутствует.

## Записи

### 1. Новый: текстовый режим

- **Файл:** `docs/web/text-editor-mode.md`
- **Что изменили:** Каноническое описание режима «Текст»: переключатель Граф/Текст, Inspector, два класса полей, порядковый merge, source map, валидация, импорт без модалки, переходы сцен только на графе.
- **Пункт approved-spec:** Решения #1–#9, «Синхронизировать» п.1

### 2. DSL: import-text-guide

- **Файл:** `docs/web/import-text-guide.md`
- **Что изменили:** Переименован фокус (DSL, не «импорт»); ссылка на text-editor-mode; editable vs inspector-only; `#Мысли` алиас; убраны автосвязи и устаревший layout; переходы сцен только на графе; stat gates как текстовые v1; экспорт/Apply вместо модалки.
- **Пункт approved-spec:** п.2 «import-text-guide»

### 3. Бизнес-описание Builder

- **Файл:** `docs/web/user-functionality.md`
- **Что изменили:** §3.4 — текстовый режим peer flow; `TextFormatService`; legacy `ImportTextModal` / `ParserText.ts` помечены устаревшими.
- **Пункт approved-spec:** п.3

### 4. AI-pipeline для авторов

- **Файл:** `docs/web/scenario-import/README.md`
- **Что изменили:** Шаг 4 — загрузка через текстовый режим + Apply; таблица шагов; ссылка на text-editor-mode; предупреждение про legacy-модалку.
- **Пункт approved-spec:** п.4

## Не синхронизировали (и почему)

| Источник | Причина |
|----------|---------|
| `docs/web/story-constructor-spec.md` | Файла нет в репо |
| `docs/specs/gameplay/entities/` | В approved-spec не было пункта; runtime-контракт покрыт через `docs/web/` |
| Notion | `notionPageUrl: null` в meta.json |
| Supabase | Миграции не требуются (approved #10) |
| `.cursor/rules/` | Устойчивый паттерн для кода — после implement |
| `docs/_meta/discrepancy-matrix.md` | Нет закрытого cross-repo конфликта |

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| text-editor-mode.md | Канон UI и поведения текстового режима |
| import-text-guide.md | Синтаксис DSL |
| ImportTextModal | Legacy, в docs помечен к удалению |

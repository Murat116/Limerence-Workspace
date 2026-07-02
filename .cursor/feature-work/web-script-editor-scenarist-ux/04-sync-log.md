## Резюме

Синхронизировано **5 документов**, **1 миграция**, **amendment** parent-spec. Notion не подключен. Код (`src/`) не менялся — по правилам feature-sync.

**Уточнение схемы:** в approved-spec указано `stories`; в коде и DTO таблица — **`story`** (singular). Миграция на `public.story`.

---

## Записи

### 1. Текстовый режим — scenarist UX

- **Файл:** `docs/web/text-editor-mode.md`
- **Что изменили:** Секция «Scenarist UX»: IDE-подсветка, autocomplete, narrator, meta-чипы, spacing/prefs, navigation, preview diff, toolbar. Amendment note для inspector meta.
- **Пункт approved-spec:** «Синхронизировать» п.1

### 2. DSL — рассказчик и stat gates

- **Файл:** `docs/web/import-text-guide.md`
- **Что изменили:** `#Речь, текст` vs `#Речь, Имя, текст`; stat gates — текст + highlight; убран дубликат строки про список 2.
- **Пункт approved-spec:** п.2

### 3. Бизнес-описание Builder

- **Файл:** `docs/web/user-functionality.md`
- **Что изменили:** §2.4 вкладка «Редактор»; §3.4 scenarist UX; восстановлен §2.3 визуальный стиль.
- **Пункт approved-spec:** п.3

### 4. Runtime entity — рассказчик

- **Файл:** `docs/specs/gameplay/entities/Диалог.md`
- **Что изменили:** Примечание про конструктор: DSL без имени → `person_uuid = null`.
- **Пункт approved-spec:** п.5

### 5. Parent spec amendment

- **Файл:** `.cursor/feature-work/web-constructor-text-editor/03-approved-spec.md`
- **Что изменили:** Секция «Amendment: scenarist UX» — widgets vs gates vs narrator.
- **Пункт approved-spec:** п.7

### 6. Supabase migration

- **Файл:** `supabase/migrations/20260704100000_story_script_editor_prefs.sql`
- **Что изменили:** `story.script_editor_prefs JSONB DEFAULT '{}'`.
- **Пункт approved-spec:** п.4

---

## Не синхронизировали

| Источник | Причина |
|----------|---------|
| Notion | `notionPageUrl: null` |
| `DatabaseDTOs.ts` / mappers | Код — на `feature-implement` |
| `.cursor/rules/` | После implement |
| Figma | Не в scope |

---

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| `script_editor_prefs` | JSONB на `story` — настройки редактора |
| `story` (таблица) | История в Supabase (не `stories`) |

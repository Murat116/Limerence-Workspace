## Резюме

Доработка **текстового режима** веб-конструктора под сценариста: autocomplete (must-have), рассказчик как `#Речь, текст` без имени, read-only и stat gates как **inline-чипы**, двусторонняя навигация outline ↔ текст (только сцена/список), типографика, размер шрифта, cosmetic spacing через prefs проекта, basename медиа.

Базовый text mode — [`web-constructor-text-editor`](../web-constructor-text-editor/). Эта фича — **UX поверх v1**.

**Предусловие (N3):** закрыть 2 blocker в parent-фиче — иначе jump из анализа и ветки `(список N)` ломаются при правке текста. См. раздел «Предусловие».

**Пользователь:** автор в конструкторе (сценарист).

---

## Решения (зафиксировано)

| Тема | Решение |
|------|---------|
| Meta / inspector-only | **Inline-чипы** (CodeMirror widgets) |
| Stat gates | **Теги** (не редактируемый `; stat:` текст) |
| Рассказчик | Только **`#Речь, текст`** без имени; legacy-абзацы без заголовка — **нет** |
| Outline | Только **сцена + список**; реплики в дереве — **нет** (список реплик нечитаем) |
| Spacing prefs | **Настройки проекта** (Supabase) |
| Figma | **Нет** — UI чипов в reconcile/коде |
| E1 Cmd+click `(список N)` | **Не делаем** — дублирует outline → scroll |
| H1–H6 | **Вне scope** |

---

## Что делаем

Сценарист пишет главу в CodeMirror. Убираем «технический» вид: подсказки DSL, чипы вместо `; meta`, скрытый рассказчик, синхрон outline ↔ курсор, комфорт чтения (шрифт, отступы).

---

## Текущее состояние (кратко)

| Область | Сейчас |
|---------|--------|
| Редактор | `ScriptEditor.tsx` + CodeMirror 6, `chapterText/*` |
| Outline | `ScriptOutline.tsx` — `###` / `##`; клик → scroll есть |
| Read-only meta | Строки `; …`; stat gates — текст `; stat:` |
| Рассказчик | `#Речь, Рассказчик` в export |
| Навигация | Outline → текст есть; текст → outline частично (сцена/список) |
| Типографика / размер | Только Inspector; 13px hardcode |
| Spacing / медиа | Нет cosmetic spacing; URL в meta |

---

## Acceptance criteria

### Из исходного запроса

- [ ] **Autocomplete (must-have):** `#Речь`, `#Мысль`, `#Выбор`, gates, персонажи — единый справочник из `import-text-guide` + `project.characters`.
- [ ] **Рассказчик:** export `#Речь, <текст>` без имени для `char-narrator`; parse без имени → рассказчик; старый текст с «Рассказчик» нормализуется при Apply.
- [ ] **Read-only чипы:** сцена (тип, фон, переходы, BGM), список, реплика (рамка, позиция, weight/style) — **inline widgets**, клик → Inspector.
- [ ] **Stat / variant gates:** **теги-чипы** (редактирование через Inspector или отдельный UX тега, не сырой `; stat:` в тексте).
- [ ] **Outline → текст:** клик по сцене/списку скроллит к строке в редакторе.
- [ ] **Текст → outline:** курсор в тексте подсвечивает и скроллит узел **сцены или списка** (реплик в дереве нет).
- [ ] **textWeight / textStyle** видны в редакторе (чипы или стиль заголовка реплики).
- [ ] **Размер шрифта** редактора — slider в toolbar.
- [ ] **Пустые строки вручную** — cosmetic, не влияют на Apply/store.
- [ ] **Prefs пустых строк** между сценами/списками/репликами — в настройках проекта (Supabase).
- [ ] **Медиа:** basename файла, не полный path/URL.

### Дополнительно (согласовано)

- [ ] **Preview diff перед Apply** — сколько create/delete/patch; подтверждение перед merge.
- [ ] **Breadcrumb** «Сцена › Список › …» по курсору (E2).
- [ ] **Fold** по `###` / `##` (E3).
- [ ] **Цветовая подсветка** `#Речь` / `#Мысль` / `#Выбор` (E5).

### Качество

- [ ] Cosmetic spacing strip при parse/merge; Apply стабилен.
- [ ] Autocomplete без UUID, не ломает порядковый merge.
- [ ] Документация: `docs/web/text-editor-mode.md`, `import-text-guide.md`.

---

## Предусловие (N3 — что это значит)

Две **незакрытые** ошибки в базовой фиче [`06-review-notes.md`](../web-constructor-text-editor/06-review-notes.md):

| # | Проблема | Почему мешает UX-фиче |
|---|----------|------------------------|
| **8** | Jump из анализа (`R`) при несохранённом черновике ведёт на **старую** строку | Навигация — ключевой UX; сценарист правит текст и не может доверять jump |
| **9** | Apply **не удаляет** старые рёбра `(список N)` | Ветки на графе расходятся с текстом |

**Решение:** закрыть #8 и #9 в `web-constructor-text-editor` **до или в первом спринте** scenarist UX (отдельные PR, не смешивать с чипами).

---

## В scope — доп. улучшения

| # | Что |
|---|-----|
| N2 | Decoration widgets вместо `; …` (ядро п.3) |
| N4 | Autocomplete из `import-text-guide` — **must-have** |
| N5 | Preview diff перед Apply |
| E2–E5 | Breadcrumb, fold, slider шрифта, цвета заголовков |

## Не делаем

| # | Что | Почему |
|---|-----|--------|
| E1 | Cmd+click `(список N)` | Есть outline → scroll |
| N1 | Реплики в outline | Список реплик нечитаем |
| H1–H6 | Plain narration, live preview, multi-cursor, Fountain, dictation… | Явно вне scope |
| Figma | Макет чипов | Проектируем в reconcile |
| Legacy narration | Абзацы без `#Речь` | Только `#Речь, текст` |
| Мобильное приложение, монетизация в DSL, WYSIWYG, co-editing | — | Как в v1 text mode |

---

## Вне scope (кратко)

- Переходы **сцена → сцена** в тексте.
- AI-pipeline, импорт Fountain/FDX.
- Spacing как поля entity в БД (только prefs проекта).

---

## Связанные артефакты

| Артефакт | Путь |
|----------|------|
| Базовая фича | `.cursor/feature-work/web-constructor-text-editor/` |
| Open blockers | `…/06-review-notes.md` #8, #9 |
| Spec | `docs/web/text-editor-mode.md` |
| DSL | `docs/web/import-text-guide.md` |
| Код | `web/editor-app/src/components/script/`, `…/chapterText/` |

---

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| Cosmetic spacing | Пустые строки только в редакторе; strip при Apply |
| Inline chip | CodeMirror widget — badge, не plain text |
| `char-narrator` | Системный «Рассказчик»; в тексте без имени |
| Preview diff | Сводка изменений перед Apply |
| Prefs проекта | Настройки истории в Supabase (spacing и т.д.) |

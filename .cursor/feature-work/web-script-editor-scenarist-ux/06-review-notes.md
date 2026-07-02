## Резюме

**Готово к merge:** да — все blockers/major закрыты после финальной итерации (selection, list titles, breadcrumb, debug cleanup).

---

## Сводная таблица

| # | Severity | Статус | О чём |
|---|----------|--------|-------|
| 1 | 🔴 blocker | **closed** | CM meta-widgets crash (`StateField`) |
| 2 | 🟠 major | **closed** | Панель ошибок — resize + scroll |
| 3 | 🟠 major | **closed** | Narrator parse disambiguation |
| 4 | 🟠 major | **closed** | Source map drift → `presentedSourceMapByEntityId` + `mapSourceMapToPresentedLines` |
| 5 | 🟠 major | **closed** | Breadcrumb — последняя подходящая сцена + название списка |
| 6 | 🟠 major | **closed** | Selection: tree/outline/editor; списки по `scene.dialogLists[li]`, не по `## N` |
| 7 | 🟠 major | **closed** | Заголовок списка в тексте = **title из Inspector**, не «Список диалогов N» |
| 8 | 🔴 blocker | **closed** | Debug ingest / `.cursor/debug-*.log` убраны из кода |

---

## #7 — Заголовки списков по названию (closed)

**По-человечески:** в тексте было `## Список диалогов 1`, а в Inspector — «Илья забрал». Клик по списку открывал не тот объект (глобальный номер ≠ позиция в сцене).

**Ожидалось:** как в Inspector — `## <название списка>`.

**Сделано:**
- Export: `## ${list.title}`
- Merge: сопоставление по индексу в сцене → по title → legacy `listNumber`
- Outline / breadcrumb: показывают title
- Parse: legacy `Список диалогов N` сохранён; `(список N)` в вариантах без изменений
- Docs: `text-editor-mode.md`, `import-text-guide.md`

---

## #6 — Selection sync (closed)

**Сделано:** `resolveSelectionFromOutline` по AST; project tree deferred focus; parent scene highlight в дереве/outline.

---

## #4 — Presentation source map (closed)

**Сделано:** `mapSourceMapToPresentedLines`, store `presentedSourceMapByEntityId`, meta-чипы и scroll на presented lines.

---

## #5 — Breadcrumb (closed)

**Сделано:** `resolveBreadcrumb` берёт последнюю сцену с `scene.line <= cursorLine`; список — `list.title`.

---

## Checklist spec

| Критерий | Статус |
|----------|--------|
| IDE-подсветка DSL | ✅ |
| Meta-чипы | ✅ |
| Рассказчик | ✅ |
| Prefs + «Редактор» | ✅ |
| Parent #8 / #9 | ✅ |
| Outline ↔ текст | ✅ (title-based lists) |
| Presentation spacing | ✅ |
| Breadcrumb | ✅ |
| Preview diff | ✅ |
| Fold / autocomplete | ✅ |

**Amend к spec §2/§11:** заголовок списка в DSL — `## <title>`, не `## Список диалогов N` (см. docs sync).

**Amend (draft inspector, 2026-06-29):** checklist «Meta-чипы ✅» покрывал UUID-реплики из store. Черновые реплики до Apply (`draft-dialog:{line}`), sidecar inspector-meta и audio в чипах — отдельная фича `web-script-editor-draft-inspector` (см. `03-approved-spec.md`, sync в `text-editor-mode.md`).

---

## Глоссарий

| Термин | Значение |
|--------|----------|
| Presented source map | entityId → line в draftText после `injectPresentation` |
| List title header | `## Илья забрал` = `dialogLists[].title` |
| Global list number | только для `(список N)` в вариантах и merge legacy |

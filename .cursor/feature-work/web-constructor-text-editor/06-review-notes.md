## Резюме

**Re-review (2026-06-29): 7 closed + 2 новых open. Готово к merge: нет.**

Первый раунд закрыт. Bugbot на новом diff нашёл 2 регрессии v1: jump из анализа при dirty-черновике в script mode и append-only рёбра при смене `(список N)`.

---

## Сводка

| # | О чём | Важность | Статус |
|---|-------|----------|--------|
| 1 | `(список N)` на вариантах не пишется в store после Apply | 🔴 blocker | closed |
| 2 | Экспорт не восстанавливает `(список N)` в тексте | 🔴 blocker | closed |
| 3 | `#Выбор` после Apply/patch становится `#Речь` | 🔴 blocker | closed |
| 4 | Отмена смены главы — рассинхрон дерева и черновика | 🔴 blocker | closed |
| 5 | Несколько новых списков — одна позиция на графе | 🟠 major | closed |
| 6 | Повторный вход в «Текст» сбрасывает dirty без confirm | 🟠 major | closed |
| 7 | Подсветка ошибок в CodeMirror отстаёт от debounced validation | 🟠 major | closed |
| 8 | Jump из анализа при dirty-черновике уже в script mode | 🔴 blocker | **open** |
| 9 | Apply не снимает старые рёбра при смене `(список N)` | 🔴 blocker | **open** |

---

## Замечания

### 1. Ветки вариантов не попадают в store

**По-человечески:** Автор пишет `- Вариант (список 2)` под `#Выбор`, жмёт Apply — переход на графе не появляется.

**Ожидалось (из approved-spec):** Переходы **список → список** через `(список N)` в тексте; после Apply рёбра в store.

**Сейчас в коде:** `resolveVariantLinks` заполняет `byDialogId`, но `applyResolvedListEdges` применяет только `bySourceListId` (заголовки списков).

**Что сделать:** В `applyResolvedListEdges` записывать `nextAvailableDialogListUUID` (или эквивалент на variant) из `byDialogId`; тест round-trip с `#Выбор` + `(список N)`.

<details>
<summary>Детали для агента</summary>

- `web/editor-app/src/services/chapterText/resolveVariantLinks.ts:30-43, 61-73`
- `web/editor-app/src/store/slices/chapterTextSlice.ts:239-241`

</details>

### 2. Round-trip теряет `(список N)` в экспорте

**По-человечески:** После сохранения и повторного открытия текста метки переходов у вариантов пропадают.

**Ожидалось:** Экспорт отражает рёбра store; `injectListTargetsInText` или аналог в `formatVariantLine`.

**Сейчас:** `formatVariantLine` без `(список N)`; `injectListTargetsInText` нигде не вызывается.

**Что сделать:** При export строить map variant → listNumber из `nextAvailableDialogListUUID` / variant edges; подставлять в строки `- ...`.

<details>
<summary>Детали для агента</summary>

- `web/editor-app/src/services/chapterText/chapterTextExport.ts:160-170, 176-199`
- Acceptance: approved-spec §2, §6, criteria «`(список N)` — в тексте»

</details>

### 3. `#Выбор` схлопывается в обычную речь

**По-человечески:** Блок выбора после Apply выглядит как обычная реплика персонажа.

**Ожидалось:** Тип choice сохраняется; экспорт даёт `#Выбор`.

**Сейчас:** В `patchDialog` `replicaType` сводится к `thought | speech`, choice теряется.

**Что сделать:** `replicaType: parsed.replicaType` (или явная ветка для `choice`).

<details>
<summary>Детали для агента</summary>

- `web/editor-app/src/services/chapterText/chapterTextMerge.ts:257`
- Create-path (`addDialogCreate`) передаёт `replicaType` корректно — баг только на patch

</details>

### 4. Отмена смены главы ломает контекст

**По-человечески:** В тексте правишь главу 1, кликаешь главу 2, в confirm жмёшь «Отмена» — в дереве уже глава 2, а черновик и Apply всё ещё про главу 1.

**Ожидалось:** Либо не менять активную главу до confirm, либо откатить `activeChapterId` при отмене.

**Сейчас:** `activeChapterId` уже новый; `loadFromChapter` не вызывается; `chapterIdLoaded` старый.

**Что сделать:** Двухфазная смена главы (pending + confirm) или revert `activeChapterId` в `ProjectTree` при `!ok`.

<details>
<summary>Детали для агента</summary>

- `web/editor-app/src/pages/EditorLayout.tsx:36-44`

</details>

### 5. Batch-create списков — одна координата

**По-человечески:** Добавил в тексте два новых списка — на графе оба в одной точке.

**Ожидалось:** Каждый новый список со смещением (как при поочерёдном create).

**Сейчас:** `layoutNewDialogList` вызывается с одним и тем же `dialogLists.length` для всех creates в сцене.

**Что сделать:** Инкрементировать виртуальный счётчик списков в цикле `applyLayoutToCreates`.

<details>
<summary>Детали для агента</summary>

- `web/editor-app/src/services/chapterText/chapterTextLayout.ts:86-95`

</details>

### 6. Dirty draft при повторном входе в «Текст»

**По-человечески:** Ушёл на граф без guard, вернулся в «Текст» — несохранённый черновик затёрт export из store.

**Ожидалось:** Symmetric dirty-guard как при выходе (`tryLeaveScript`).

**Сейчас:** `tryEnterScript` всегда `loadFromChapter`.

**Что сделать:** Если `isDirty` — confirm перед `loadFromChapter`.

<details>
<summary>Детали для агента</summary>

- `web/editor-app/src/components/editor/ViewModeToggle.tsx:27-31`

</details>

### 7. Подсветка синтаксиса отстаёт от validation store

**По-человечески:** Ошибка появилась в панели, в редакторе подчёркивание — только после следующего keystroke.

**Ожидалось:** Inline validation с номером строки (approved-spec §8).

**Сейчас:** CodeMirror plugin слушает только `docChanged` / `viewportChanged`, не debounced `validationIssues`.

**Что сделать:** Dispatch custom effect / пересборка extension при обновлении issues в `scriptEditorStore`.

<details>
<summary>Детали для агента</summary>

- `web/editor-app/src/components/script/useScriptEditorExtensions.ts:61-64`

</details>

---

## Re-review (2026-06-29) — новые замечания

### 8. Jump из анализа при несохранённом черновике

**По-человечески:** Правишь текст, не жмёшь Apply, жмёшь jump из `R` — курсор уезжает на старую строку.

**Ожидалось:** approved-spec §8 — jump-to-line по актуальному тексту или `apply_first`.

**Сейчас:** `jumpToAnalysisElement` проверяет `isDirty` только при переходе **с графа** в script; если уже в script — берёт устаревший `sourceMapByEntityId` (приоритетнее `approximateLineFromEntity`).

**Что сделать:** При `viewMode === 'script' && isDirty` → `return 'apply_first'`; либо в `resolveLineForEntity` при dirty не доверять source map, парсить `draftText`.

<details>
<summary>Детали для агента</summary>

- `web/editor-app/src/store/scriptEditorStore.ts:197-218`
- `web/editor-app/src/services/chapterText/analysisJumpToLine.ts:22-24`

</details>

### 9. Старые рёбра не удаляются при Apply

**По-человечески:** Убрал `(список 3)` из варианта, Apply — на графе ветка на список 3 осталась.

**Ожидалось:** editable `(список N)` — store отражает текст после Apply.

**Сейчас:** `applyResolvedListEdges` только **добавляет** в `nextAvailableDialogListUUID` и обновляет `nextDialogId` для индексов из плана; старые цели не сбрасываются.

**Что сделать:** Для списков главы, затронутых `variantLinks` / `listHeaderLinks`, **replace** рёбер из плана (не merge); очистить `nextDialogId` у вариантов без target в плане.

<details>
<summary>Детали для агента</summary>

- `web/editor-app/src/services/chapterText/resolveVariantLinks.ts:79-120`

</details>

---

## Acceptance criteria (сверка)

| Критерий | Статус |
|----------|--------|
| Переключатель Граф/Текст + Inspector | ✅ |
| Monospace + outline | ✅ |
| Текстовые vs inspector-only поля | ✅ (meta overlay) |
| Apply только активная глава | ✅ |
| Порядковый merge + source map + jump | ⚠️ #8 open |
| `(список N)` в тексте | ⚠️ #9 open (replace edges) |
| Переходы сцен только граф | ✅ |
| `#Мысль` / `#Мысли`, экспорт `#Мысль` | ✅ |
| ImportTextModal удалена | ✅ |
| Документация `docs/web/` | ✅ |

**Тесты:** 12 unit в `chapterText/` проходят; choice + variant edges покрыты.

---

## Fix log (2026-06-29)

| # | Fix |
|---|-----|
| 1 | `applyResolvedListEdges`: `byDialogId` → `nextAvailableDialogListUUID` + `variant.nextDialogId` |
| 2 | `exportChapterToText`: `(список N)` из `nextDialogId` / рёбер списка |
| 3 | `patchDialog`: choice не пишет `replicaType: speech` |
| 4 | `EditorLayout`: revert `activeChapterId` при отмене confirm |
| 5 | `applyLayoutToCreates`: инкремент pending count per scene |
| 6 | `ViewModeToggle.tryEnterScript`: dirty confirm |
| 7 | `refreshValidationDecorationsEffect` + `ScriptEditor` useEffect |

---

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| `byDialogId` | Карта переходов вариантов → uuid списка |
| `createMinimalChapterProject` | Тестовая фикстура минимального проекта |
| `ScriptInspectorPanel` | Inspector в script mode с guard по UUID |
| Round-trip | export → edit → apply → export без потери DSL |

## Статистика

blocker: 2 open | major: 0 | minor: 0 | info: 0

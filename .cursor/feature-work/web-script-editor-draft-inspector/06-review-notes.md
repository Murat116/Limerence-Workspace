## Резюме

**4 замечания:** 3 blocker и 1 major — **закрыты в review-сессии**.  
**Готово к merge:** да, после ручного smoke (новая реплика + UUID без регрессии).

---

## Сводка

| # | О чём | Важность | Статус |
|---|-------|----------|--------|
| 1 | Sidecar не попадал в Dialog при Apply (presented vs canonical line) | 🔴 blocker | **closed** |
| 2 | После rekey sidecar selection оставался на старом `draft-dialog:{line}` | 🔴 blocker | **closed** |
| 3 | Debug `fetch` на localhost:7402 в production UI | 🔴 blocker | **closed** |
| 4 | Нет unit-тестов `buildMetaChipsForChapter` для draft + audio | 🟠 major | **closed** (waived — покрыто через `mergeDialogViewModel`) |
| 5 | Smoke UUID-реплика не автоматизирован | 🟡 minor | open (manual) |
| 6 | `FlowEditor` сбрасывает pending focus до отрисовки узла | 🟡 minor | open (вне scope draft-inspector, scenarist-ux) |

---

## Acceptance criteria (approved-spec)

| AC | Статус |
|----|--------|
| Sidecar `draftDialogInspectorMetaByLine` в store | ✅ |
| Draft: frame, weight, style сохраняются до Apply | ✅ |
| Draft: VisualTab (позиция, camera, ассеты) | ✅ |
| Draft: audioEvents в sidecar и чипах | ✅ |
| Draft: «Добавить вариант» + premium в sidecar | ✅ |
| Meta-чипы для draft-строк | ✅ |
| Meta-чипы UUID + audio; refresh inspector-only | ✅ |
| Apply create: overlay sidecar → Dialog | ✅ (после #1) |
| Sidecar rekey при правке текста | ✅ (после #2) |
| Unit-тесты rekey, overlay, patch | ✅ (10 tests) |
| Smoke UUID без регрессии | ⏳ manual |

---

## Замечания

### 1. Sidecar терялся при Apply (closed)

**По-человечески:** автор задавал рамку и аудио в инспекторе новой реплики, нажимал Apply — в графе Dialog создавался только с текстом.

**Ожидалось:** все inspector-only поля из sidecar переносятся при create.

**Сейчас было:** `runValidation` парсит **presented** `draftText` (с cosmetic blank lines), Apply — `stripExtraBlankLines` + parse → другие номера строк → `sidecarByLine[headerLine]` = `undefined`.

**Сделано:** в `applyDraft` sidecar rekey из presented AST в canonical AST перед `applyChapterText`.

<details>
<summary>Детали для агента</summary>

- `web/editor-app/src/store/scriptEditorStore.ts` — `applyDraft`: `stripExtraBlankLines` + `rekeyDraftDialogMeta(parsedOutline, canonicalTree, meta)`
- `web/editor-app/src/store/slices/chapterTextSlice.ts:234-235` — lookup по `headerLine` из merge

</details>

---

### 2. Selection не следовал за rekey (closed)

**По-человечески:** вставка строки выше реплики сдвигала sidecar, но выделение оставалось `draft-dialog:10` — инспектор показывал пустую meta.

**Сделано:** после `rekeyDraftDialogMeta` в `runValidation` обновляется `selectionStore.select(draft-dialog:{newLine})` по `DraftDialogBlockKey`.

<details>
<summary>Детали для агента</summary>

- `scriptEditorStore.runValidation` — `enumerateDialogBlocks` + `resolveDialogHeaderLine`

</details>

---

### 3. Debug ingest в UI (closed)

**По-человечески:** в консоли/network висели POST на `127.0.0.1:7402/ingest/...` от agent debug.

**Сделано:** удалены fetch из `ScriptEditorLayout.tsx`, `editLineInteractionExtension.ts`.

---

### 4. Тесты meta chips (closed, waived)

**По-человечески:** в plan — `buildMetaChipsForChapter` draft line test; не написан.

**Решение review:** waive — логика draft chips идёт через `mergeDialogViewModel` + `buildDialogMetaChips`, покрыты `draftDialogMeta.test.ts`. Отдельный chips test — nice-to-have.

---

### 5. Smoke UUID (open, manual)

**Что проверить вручную:**

1. Открыть главу с UUID-репликой, задать frame/audio в инспекторе графа.
2. Текстовый режим → изменить только текст реплики → Apply.
3. Убедиться: `frameId`, `audioEvents` в store **не сброшены**.

---

## Bugbot (initial pass)

Subagent: [Bugbot review](fd679959-e797-4458-890e-c6e19c0b484b) — findings #1–#3 подтверждены и закрыты; #4 (FlowEditor) — minor, out of scope.

---

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| `draftDialogInspectorMetaByLine` | Sidecar inspector-meta по номеру строки |
| Presented vs canonical | Editor text с отступами vs DSL для merge |
| `rekeyDraftDialogMeta` | Перепривязка sidecar при сдвиге AST |
| `overlaySidecarOnDialog` | Подмешивание sidecar при create на Apply |

---

## Статистика

blocker: 0 (3 closed) | major: 0 (1 waived) | minor: 2 open (manual smoke + FlowEditor)

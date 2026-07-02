## Резюме

**8 расхождений:** 2 blocker, 5 major, 1 minor, 3 info.

Планировать **полную реализацию без решений нельзя**: нужно выбрать, где хранить inspector-only данные черновых реплик до Apply, и согласовать состав meta-чипов (аудио на реплике). Остальные расхождения — следствие отсутствующего слоя хранения и неполного merge при создании реплики.

---

## Сводка (читать первым)

| # | О чём спор | Насколько важно | Нужно твоё решение? |
|---|------------|-----------------|---------------------|
| 1 | Где хранить рамку, шрифт, ассеты и аудио для **новой** реплики до Apply | 🔴 blocker | Да |
| 2 | Apply создаёт реплику только с текстом — inspector-meta **теряется** | 🔴 blocker | Да (следствие #1) |
| 3 | Инспектор показывает полный UI, но сохраняет только персонажа и текст | 🟠 major | Нет (технический долг) |
| 4 | Кнопка «Добавить вариант» завязана на UUID в store | 🟠 major | Нет |
| 5 | Вкладка «Визуал» для черновика — заглушка, ассеты недоступны | 🟠 major | Нет |
| 6 | Meta-чипы не строятся для строк без UUID в source map | 🟠 major | Нет |
| 7 | Аудио-события реплики: в brief — в чипах; в doc scenarist UX — не перечислены; в коде — нет | 🟠 major | Да |
| 8 | Чипы не обновляются при смене толщины/стиля шрифта в инспекторе (даже у UUID) | 🟠 major | Нет (можно в той же задаче) |
| 9 | Entity-спека `Диалог.md` не перечисляет textWeight / audioEvents | 🟡 minor | Нет |
| 10 | Родительский review «Meta-чипы ✅» не покрывает черновые реплики | ⚪ info | Нет |
| 11 | Notion / Figma | ⚪ info | Нет |
| 12 | Mobile: draft-реплик нет (ожидаемо) | ⚪ info | Нет |

---

## Расхождения (подробно)

### 1. Нет модели хранения inspector-meta для черновых реплик

**По-человечески:** автор настраивает рамку и шрифт в инспекторе, но системе некуда записать эти значения, пока у реплики нет UUID в проекте.

**Что говорит каждый источник:**

- **Brief (01-brief.md):** нужен sidecar / overlay в сессии редактора; открытый вопрос — `Map<line, InspectorMeta>` vs provisional UUID.
- **Спека scenarist UX (§8–9):** inspector-only поля — inline-чипы; правка только в Inspector; для реплики — рамка, позиция, fontSize, weight, style.
- **Конструктор для авторов (`text-editor-mode.md`, §Два класса полей):** реплика inspector-only — `frameId`, `textWeight`, `textStyle`, `characterPosition`, `cameraPositionX`, `assetChanges`, `audioEvents`.
- **Конструктор для авторов (`scriptEditorStore.ts`):** есть `draftText`, `sourceMapByEntityId`, `metaWidgetsVersion`; **`draftInspectorMetaByLine` / overlay sidecar отсутствуют**.
- **Конструктор для авторов (`draftDialogPatch.ts`):** патч в DSL — только `characterId | text | replicaType`.
- **База данных:** колонки `frame_id`, `text_weight`, `text_style`, `asset_changes`, `character_position` в `DialogDTO` — persist после Apply; до Apply sidecar в БД **не описано**.
- **Макет:** не описано.
- **Задача в Notion:** не описано.
- **Приложение (mobile):** draft-концепции нет — не описано (не применимо).

**Что это значит для задачи:** без выбранной модели хранения нельзя ни сохранять рамку, ни показывать чипы, ни переносить данные на Apply.

**Вопрос к тебе:** sidecar в `scriptEditorStore` по номеру строки, временный объект в `storyStore`, или гибрид (DSL для вариантов + sidecar для inspector-only)?

<details>
<summary>Детали для агента</summary>

| Источник | Значение | Путь |
|----------|----------|------|
| Brief | sidecar / overlay | `01-brief.md` §Открытые вопросы |
| Store | нет draft meta map | `web/editor-app/src/store/scriptEditorStore.ts` |
| Patch | `Partial<Pick<Dialog, 'characterId' \| 'text' \| 'replicaType'>>` | `web/editor-app/src/services/chapterText/draftDialogPatch.ts:46` |
| Plan (не реализован) | `overlayInspectorMetaLines` | `web-script-editor-scenarist-ux/05-plan-technical.md` (упоминание в brief) |

</details>

---

### 2. Apply при создании реплики не переносит inspector-only поля

**По-человечески:** даже если автор как-то настроил рамку до Apply, при первом Apply новая реплика в проекте получит только текст, персонажа и тип — рамка и шрифт обнулятся.

**Что говорит каждый источник:**

- **Brief:** AC — после Apply все inspector-only поля совпадают с тем, что было до Apply.
- **Спека v1 parent (`web-constructor-text-editor/03-approved-spec.md`):** «inspector-поля остаются в БД, текст их не затирает при apply» — для **существующих** реплик.
- **Конструктор для авторов (`chapterTextMerge.ts`, `patchDialog`):** update — `text`, `characterId`, `replicaType`, `variants`; create payload — те же текстовые поля, **без** `frameId`, `textWeight`, `textStyle`, `audioEvents`, `assetChanges`, `characterPosition`.
- **Конструктор для авторов (`chapterTextSlice.ts`, create dialog):** новый `Dialog` — `uuid`, `characterId`, `text`, `orderIndex`, `replicaType`, `variants` (text/notification/statChanges).
- **База данных:** колонки для inspector-only **есть** в `DialogDTO` (`frame_id`, `text_weight`, `text_style`, `asset_changes`, `character_position`); merge просто **не заполняет** их при create.
- **Макет / Notion:** не описано.

**Что это значит для задачи:** sidecar без доработки Apply — половина фикса; merge/create pipeline обязан принимать overlay meta.

**Вопрос к тебе:** переносить overlay только для **новых** creates (scope brief) или заложить общий hook на будущее?

<details>
<summary>Детали для агента</summary>

| Источник | Значение | Путь |
|----------|----------|------|
| patchDialog fields | text, characterId, replicaType, variants | `chapterTextMerge.ts:260–274` |
| addDialogCreate payload | без inspector-only | `chapterTextMerge.ts:307–314` |
| Apply create | Dialog без frameId/textWeight/… | `chapterTextSlice.ts:214–226` |
| DialogDTO | frame_id, text_weight, text_style, asset_changes | `DatabaseDTOs.ts:126–141` |

</details>

---

### 3. UI инспектора обещает больше, чем сохраняет

**По-человечески:** автор видит те же контролы, что на графе (рамка, толщина, стиль, аудио), но для черновика они не работают — только персонаж и текст пишутся в файл.

**Что говорит каждый источник:**

- **Brief:** BaseTab рендерится целиком; баннер говорит «рамка, позиция и ассеты — после Apply».
- **Конструктор для авторов (`DraftDialogInspector.tsx`):** `handleUpdate` → `patchDraftDialogAtLine`; `parsedDialogToViewModel` — `uuid: 'draft'`, без `frameId`, `textWeight`, `textStyle`, `audioEvents`.
- **Конструктор для авторов (`DialogInspector.tsx`, UUID):** `updateDialog(uuid, data)` — все поля в store.
- **Спека scenarist UX:** полный инспектор для новой реплики — ожидание автора из brief.
- **Макет / Notion:** не описано.

**Что это значит для задачи:** либо подключить sidecar к `handleUpdate`, либо явно disable контролы до Apply (ухудшение UX, против brief).

<details>
<summary>Детали для агента</summary>

| Источник | Значение | Путь |
|----------|----------|------|
| Draft banner | «Рамка, позиция и ассеты — после Apply» | `DraftDialogInspector.tsx:98–99` |
| View-model | только parse-поля | `draftDialogPatch.ts:19–36` |
| UUID path | `Object.assign(dialog, data)` | `dialogSlice.ts:96–100` |

</details>

---

### 4. Варианты ответов требуют UUID в store

**По-человечески:** кнопка «+» в блоке вариантов вызывает API/store по id реплики; у черновика id = `'draft'`, записи в проекте нет — вариант не создаётся.

**Что говорит каждый источник:**

- **Brief:** варианты должны синхронизироваться с DSL (`#Выбор`, `- …`, `; stat:`).
- **Конструктор для авторов (`VariantsEditor.tsx`):** `addVariant(dialog?.uuid, …)` → `CreateService.createVariant(projectId, dialogId, …)`.
- **Конструктор для авторов (`dialogSlice.ts`, `addVariant`):** `const dialog = project.dialogs[dialogId]` — при `'draft'` dialog **undefined**; `createVariant` всё равно вызывается с невалидным id.
- **Спека v1:** варианты — **текстовые** поля (text, stat gates, notification) — должны жить в DSL.
- **Спека v1:** premium варианта — inspector-only (не в scope brief, кроме блокировки).
- **Макет / Notion:** не описано.

**Что это значит для задачи:** для черновика нужен отдельный редактор вариантов, патчащий DSL, а не `VariantsEditor` → store.

<details>
<summary>Детали для агента</summary>

| Источник | Значение | Путь |
|----------|----------|------|
| VariantsEditor | store-only | `VariantsEditor.tsx:24–26, 41` |
| Draft uuid | `'draft'` | `draftDialogPatch.ts:20` |
| addVariant | ищет dialog в project | `dialogSlice.ts:210–212` |

</details>

---

### 5. Визуальные настройки (ассеты, позиция) заблокированы для черновика

**По-человечески:** автор не может выбрать костюм/ассет персонажа, пока не нажмёт Apply — вкладка «Визуал» показывает текст-заглушку.

**Что говорит каждый источник:**

- **Brief:** AC — VisualTab работает до Apply и переживает Apply.
- **Конструктор для авторов (`DraftDialogInspector.tsx`):** вкладка `visual` — заглушка, не `VisualTab.tsx`.
- **Конструктор для авторов (`VisualTab.tsx` + `DialogInspector.tsx`):** ассеты через `toggleDialogAsset(dialogId)` — только UUID.
- **Спека `text-editor-mode.md`:** `assetChanges`, `characterPosition` — inspector-only для реплики.
- **Макет / Notion:** не описано.

**Что это значит для задачи:** разблокировать VisualTab только после появления sidecar (#1) и патча Apply (#2).

<details>
<summary>Детали для агента</summary>

| Источник | Значение | Путь |
|----------|----------|------|
| Draft stub | «будут доступны после Apply» | `DraftDialogInspector.tsx:117–121` |
| Assets | `toggleDialogAsset(dialogId)` | `dialogSlice.ts:123–126` |

</details>

---

### 6. Meta-чипы не показываются для новых реплик

**По-человечески:** в тексте рядом с новой репликой нет чипов «рамка: …», «bold», «italic» — потому что чипы строятся только для реплик, уже лежащих в проекте с UUID.

**Что говорит каждый источник:**

- **Brief / scenarist UX §8–9:** чипы с рамкой, fontSize, weight, style для реплики.
- **Конструктор для авторов (`buildMetaChips.ts`):** `buildMetaChipsForChapter` итерирует `sourceMapByEntityId` → `project.dialogs[entityId]`; draft-строк (`draft-dialog:*`) **нет** в map.
- **Конструктор для авторов (`resolveSelectionFromOutline.ts`):** при dirty / новой строке — `draft-dialog:{line}`.
- **Спека parent review (`06-review-notes.md`):** «Meta-чипы ✅» — без упоминания draft.
- **Макет / Notion:** не описано.

**Что это значит для задачи:** `buildMetaChipsForChapter` (или слой выше) должен читать sidecar по line + merge с store.

<details>
<summary>Детали для агента</summary>

| Источник | Значение | Путь |
|----------|----------|------|
| Chips source | только sourceMap + store | `buildMetaChips.ts:64–83` |
| Dialog chips | frame, fontSize, weight, style, pos | `buildMetaChips.ts:42–60` |

</details>

---

### 7. Аудио-события реплики в meta-чипах — расхождение brief vs doc vs код

**По-человечески:** автор ожидает видеть настроенное аудио в тегах у строки реплики; ни док scenarist UX, ни код это явно не делают; brief требует.

**Что говорит каждый источник:**

- **Brief (AC):** аудио настраивается в BaseTab и видно в meta-чипах (basename).
- **Спека scenarist UX (§8):** реплика в чипах — «рамка, позиция, размер шрифта, weight, style, premium…»; **audioEvents не названы**.
- **Конструктор (`text-editor-mode.md`, §Inspector-meta чипы):** реплика — рамка, позиция, fontSize, weight, style; **audioEvents не в списке чипов**, но в §Два класса полей — inspector-only.
- **Спека gameplay (`full-description.md`):** на реплике `audioEvents` — stop_all, play_overlay, stop_other_play.
- **Конструктор (`buildDialogMetaChips`):** **нет** ветки для `audioEvents` (BGM для **сцены** есть в `buildSceneMetaChips`).
- **Конструктор (`BaseTab.tsx`):** `AudioEventsSection` → `onUpdate({ audioEvents })` — UI есть для UUID и draft.
- **База данных:** отдельная таблица/DTO для dialog audio (через CreateService) — persist после save; не в DSL.
- **Макет / Notion:** не описано.

**Что это значит для задачи:** нужно решить, входят ли audio-чипы в контракт этой задачи для **всех** реплик или только draft; и обновить doc на sync.

**Вопрос к тебе:** показывать audio в чипах для всех реплик (рекомендация brief) или только для черновика до стабилизации sidecar?

<details>
<summary>Детали для агента</summary>

| Источник | Значение | Путь |
|----------|----------|------|
| Scene BGM in chips | да | `buildMetaChips.ts:27–31` |
| Dialog audio in chips | нет | `buildDialogMetaChips` — нет audioEvents |
| Export meta lines | только рамка + позиция | `chapterTextExport.ts:124–136` |
| Runtime spec | audioEvents на реплике | `docs/specs/gameplay/full-description.md` |

</details>

---

### 8. Чипы не реагируют на смену толщины/стиля шрифта в инспекторе

**По-человечески:** автор меняет bold/italic в инспекторе, а теги в тексте могут не обновиться — система следит только за рамкой и позицией.

**Что говорит каждый источник:**

- **Brief:** «в текстовом редакторе реплики не отображают реальный выбранной толщины шрифта и выбранного стиля».
- **Конструктор (`ScriptInspectorPanel.tsx`):** `inspectorMetaKey` для dialog — только `{ frame, pos }`; **`textWeight`, `textStyle`, `audioEvents` не входят**.
- **Конструктор:** `notifyInspectorMetaChanged()` для draft **не вызывается** — `canOpenInspector` false для `draft-dialog:*`.
- **Спека scenarist UX §9:** weight/style должны быть видны в чипах (read-only).
- **Макет / Notion:** не описано.

**Что это значит для задачи:** даже для UUID-реплик refresh meta неполный; фикс `inspectorMetaKey` + draft notify — часть той же задачи (brief scope: smoke на UUID, не менять поведение).

<details>
<summary>Детали для агента</summary>

| Источник | Значение | Путь |
|----------|----------|------|
| inspectorMetaKey | frame + pos only | `ScriptInspectorPanel.tsx:36–40` |
| Draft notify skip | `canOpenInspector` guard | `ScriptInspectorPanel.tsx:45–47` |
| metaWidgetsVersion | инкремент в store | `scriptEditorStore.ts:39–40, notifyInspectorMetaChanged` |

</details>

---

### 9. Entity-спека `Диалог.md` неполная относительно конструктора

**По-человечески:** в канонической entity-спеке нет полей толщины/стиля шрифта и аудио — они описаны в других документах; это не блокирует код, но создаёт путаницу при sync.

**Что говорит каждый источник:**

- **Спека в репо (`Диалог.md`):** text, character_position, camera_position_x, frame_id, person, asset_changes, variants — **без** textWeight, textStyle, audioEvents.
- **Спека в репо (`РамкаДиалога.md`):** «реплика учитывает replica.textWeight / textStyle из модели диалога».
- **Спека gameplay (`full-description.md`):** audioEvents на реплике.
- **Конструктор (`text-editor-mode.md`):** полный список inspector-only.
- **Приложение (mobile):** все поля в domain model и mapper — `StoryDomainMapper.ts`, `dialog.tsx`.

**Что это значит для задачи:** на `feature-sync` стоит дополнить `Диалог.md` или явная ссылка на web-only inspector fields.

<details>
<summary>Детали для агента</summary>

| Источник | Значение | Путь |
|----------|----------|------|
| Диалог.md fields | без weight/style/audio | `docs/specs/gameplay/entities/Диалог.md:7–14` |
| Mobile Dialog | textWeight, textStyle, audioEvents | `mobile/src/Common/models/dialog.tsx` |

</details>

---

### 10. Родительский review отмечает meta-чипы выполненными

**По-человечески:** чеклист scenarist UX говорит «Meta-чипы ✅», но сценарий «новая реплика до Apply» в review не проверялся.

**Что говорит каждый источник:**

- **Конструктор (`06-review-notes.md`):** «Meta-чипы | ✅».
- **Brief / код:** для draft-строк чипов нет (#6).
- **Notion / Figma:** не описано.

**Что это значит для задачи:** info — не противоречие spec, а gap в review coverage; не блокирует approve.

---

### 11–12. Notion, Figma, mobile draft

**Notion / Figma:** не описано — нет ссылок в `meta.json`.

**Приложение (mobile):** draft-реплик и `draft-dialog:*` **нет** — ожидаемо; runtime читает только persisted Dialog из БД. Поля frame/textWeight/audio используются при показе реплики (`DialogFrameView.tsx`, `enterReplicaSession.ts`).

**Что это значит для задачи:** фича **только web**; mobile — эталон persisted shape после Apply, не источник draft UX.

---

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| Sidecar / overlay | Inspector-meta черновой строки в памяти редактора до Apply |
| Source map | UUID сущности → номер строки в presented тексте |
| `draft-dialog:{line}` | Выделение реплики без UUID |
| Inspector-only | Поля только через инспектор, не в plain DSL |
| Create (merge) | Первая Apply для новой строки → новый Dialog в store |
| Meta-чип | Read-only виджет в CodeMirror |

---

## Открытые вопросы

- [ ] **#1** — модель хранения draft inspector-meta (sidecar vs provisional UUID vs гибрид)
- [ ] **#2** — hook overlay только на creates или общий контракт merge
- [ ] **#7** — audio в чипах: все реплики или только draft
- [ ] **Premium варианты** в черновике — sidecar или отложить до Apply (brief: «только если блокирует»)

---

## Статистика

blocker: 2 | major: 5 | minor: 1 | info: 3

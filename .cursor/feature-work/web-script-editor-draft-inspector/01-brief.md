## Резюме

В текстовом редакторе сценарист может выбрать **новую реплику** (ещё без UUID в проекте) и открыть полный инспектор — но правки **рамки, толщины и стиля шрифта, вариантов ответов, ассетов и аудио** не сохраняются до Apply. В тексте реплики **meta-чипы** не показывают выбранную типографику; **аудио-события** в чипах отсутствуют даже по задумке scenarist UX.

Корневая причина: inspector-only поля живут в **store проекта** (`dialogs[uuid]`), а черновая реплика идентифицируется как `draft-dialog:{номер строки}` и патчится в DSL только по **персонажу и тексту**. Варианты ответов пишутся в store по `uuid`, которого у черновика нет.

Задача — закрыть разрыв между UI инспектора и хранением данных **до Apply**, чтобы после Apply ничего не терялось. Родительская фича `web-script-editor-scenarist-ux` помечена done, но acceptance по чипам и черновому инспектору фактически не выполнен для новых реплик.

**Главный риск:** выбрать модель хранения (sidecar в сессии редактора vs временный объект в store vs расширение DSL) без поломки merge и без дублирования источников правды.

---

## Что делаем

Автор в режиме «Текст» добавляет реплику (`#Речь`, `#Мысль`, `#Выбор`), выделяет её и настраивает в инспекторе так же, как на графе: **рамка**, **толщина/стиль шрифта**, **варианты ответов**, **ассеты персонажа**, **аудио-события**. Сейчас BaseTab отображается, но изменения либо сбрасываются при перепарсе, либо уходят в никуда (варианты → `addVariant('draft')`). Вкладка «Визуал» для черновика — заглушка.

Нужно:

1. **Сохранять** все перечисленные поля для `draft-dialog:*` в сессии текстового редактора до Apply.
2. **Показывать** в тексте read-only чипы с актуальной рамкой, типографикой и аудио (как в утверждённом scenarist UX).
3. **Переносить** накопленные inspector-only поля в store при Apply для **вновь созданных** реплик (merge сейчас создаёт диалог только с текстовыми полями).

Для **уже существующих** реплик с UUID поведение не меняем в этой задаче (по уточнению автора).

---

## Для кого / зачем

**Автор истории** в веб-конструкторе, который пишет сценарий линейно в текстовом режиме и ожидает паритет с flow-инспектором: настроил реплику → видит результат в чипах → Apply без сюрпризов.

Без фикса автор вынужден сначала Apply, потом снова искать реплику на графе или в тексте после появления UUID — ломает сценарный flow.

---

## Acceptance criteria

- [ ] Новая реплика до Apply: выбор **рамки** в инспекторе сохраняется при смене выделения и перезагрузке черновика в той же сессии редактора.
- [ ] Новая реплика до Apply: **толщина** (`regular` / `semibold` / `bold`) и **стиль** (`normal` / `italic`) сохраняются и отображаются в **meta-чипах** рядом со строкой реплики.
- [ ] Новая реплика до Apply: кнопка **«Добавить вариант»** создаёт вариант; текст варианта, stat gates и уведомления синхронизируются с DSL (`#Выбор`, `- …`, `; stat:`).
- [ ] Новая реплика до Apply: вкладка **«Визуал»** — выбор **ассетов** и позиции персонажа работает и переживает Apply.
- [ ] Новая реплика до Apply: **аудио-события** настраиваются в BaseTab и видны в **meta-чипах** (имена ассетов / basename).
- [ ] После **Apply** для впервые созданной реплики: `frameId`, `textWeight`, `textStyle`, `characterPosition`, `assetChanges`, `audioEvents`, варианты и premium-поля вариантов совпадают с тем, что было до Apply.
- [ ] Клик по meta-чипу черновой реплики открывает инспектор с теми же значениями.
- [ ] Существующие реплики с UUID: регрессий нет (smoke: правка текста + inspector-only в store как сейчас).

---

## Вне scope

- Правки поведения **существующих** реплик с UUID в текстовом режиме (кроме smoke-регрессии).
- Отдельное поле «сценическая ремарка» — в модели `Dialog` его нет; под «ремаркой» здесь понимается **рамка диалога** (`frameId`).
- Premium-варианты и аналитика реплики — только если блокируют сохранение вариантов; отдельная вкладка «Аналитика» для черновика остаётся после Apply.
- Мобильное приложение (runtime) — только конструктор `web/editor-app`.
- Round-trip inspector-meta в plain `;` строках DSL (fallback export) — опционально в reconcile, не обязательно в v1 фикса.
- Снятие debug-логов из `ScriptEditor.tsx` — отдельный housekeeping, не часть продукта.

---

## Ссылки

- Родитель: `.cursor/feature-work/web-script-editor-scenarist-ux/03-approved-spec.md` (§8–9: чипы, типографика)
- Контракт полей: `docs/web/text-editor-mode.md` (текстовые vs inspector-only)
- Сущность диалог: `docs/specs/gameplay/entities/Диалог.md`
- Notion / Figma: нет

---

## Открытые вопросы

- [ ] **Модель хранения черновика:** `Map<line, InspectorMeta>` в `scriptEditorStore` vs provisional UUID в store vs гибрид (reconcile должен выбрать).
- [ ] **Аудио в чипах для UUID-реплик:** сейчас `buildDialogMetaChips` не добавляет audio — включать в эту задачу для всех реплик или только draft (рекомендация: для всех, иначе UX расходится со spec §8).
- [ ] **Обновление чипов при правке в инспекторе:** подписка только на `frame`/`pos` — нужен единый `inspectorMetaVersion` (из плана `overlayInspectorMetaLines`, не реализован).
- [ ] **Premium варианты** в черновике: inspector-only в store или sidecar вместе с текстом варианта.

---

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| Apply | Применить текст главы к проекту в store (merge по порядку блоков) |
| Inspector-only | Поля, которые не редактируют в plain-тексте, только в инспекторе |
| Meta-чип | Read-only виджет в CodeMirror рядом со строкой сцены/реплики |
| `draft-dialog:{line}` | Синтетический id выделения для реплики без UUID в source map |
| Source map | Соответствие `entityId → номер строки` после последнего export/apply |
| Рамка (`frameId`) | Визуальный шаблон реплики (в т.ч. размер шрифта из `dialogFrames`) |
| `textWeight` / `textStyle` | Толщина и начертание текста реплики |
| Sidecar / overlay | Данные inspector-meta для черновых строк, живущие отдельно от DSL и store до Apply |

---

## Диагностика (текущее состояние кода)

<details>
<summary>Детали для агента — пути и разрывы</summary>

### Симптом → причина

| Симптом | Причина | Файлы |
|---------|---------|--------|
| Рамка / weight / style не держатся | `patchDraftDialogAtLine` принимает только `characterId`, `text`, `replicaType`; view-model без inspector-полей | `draftDialogPatch.ts`, `DraftDialogInspector.tsx` |
| Кнопка вариантов не работает | `VariantsEditor` → `addVariant(dialog.uuid)`; у черновика `uuid: 'draft'`, записи в `project.dialogs` нет | `VariantsEditor.tsx`, `parsedDialogToViewModel` |
| Ассеты не выбрать | VisualTab — заглушка «после Apply» | `DraftDialogInspector.tsx` |
| Чипы без типографики у новой реплики | `buildMetaChipsForChapter` только по `sourceMapByEntityId`; draft-строк нет в map | `buildMetaChips.ts`, `metaWidgetsExtension.ts` |
| Аудио нет в чипах | `buildDialogMetaChips` не включает `audioEvents` | `buildMetaChips.ts` |
| После Apply теряется meta | `chapterTextMerge` / create dialog — текстовые поля; inspector-only на create не подмешиваются | `chapterTextMerge.ts`, `chapterTextSlice` / merge pipeline |
| Чипы не обновляются после правки weight/style | Триггер refresh meta, вероятно, не покрывает все inspector-поля | `ScriptInspectorPanel.tsx`, `scriptEditorStore` |

### Уже работает для черновика

- Персонаж и текст реплики → DSL через `patchDraftDialogAtLine`
- Полный UI BaseTab (визуально как на графе)
- Выделение `draft-dialog:{line}` и полный Inspector shell

### Запланировано, но не сделано

- `overlayInspectorMetaLines` из technical plan parent/scenarist — нет в `scriptEditorStore`
- Export `buildDialogMetaLines` — только рамка и позиция, без weight/style/audio (`chapterTextExport.ts`)

### Направления реализации (для reconcile / plan, не решение)

1. **`draftInspectorMetaByLine`** в `scriptEditorStore` + merge при Apply для creates.
2. **`DraftVariantsEditor`** — патч DSL и sidecar для premium, без `storyStore.addVariant` до UUID.
3. Разблокировать **VisualTab** с записью в sidecar.
4. **`buildMetaChipsForChapter`** — merge store + sidecar по line; добавить audio labels.
5. **`notifyInspectorMetaChanged`** — единый ключ на все inspector-only поля реплики.

</details>

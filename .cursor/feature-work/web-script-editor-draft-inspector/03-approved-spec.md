## Резюме

Утверждён контракт **inspector-meta для новых реплик до Apply** в текстовом редакторе: каждая распознанная строка реплики без UUID — **объект в store редактора** с полным набором полей инспектора; при **Apply** все накопленные значения **переносятся** в `storyStore` / БД. Meta-чипы показывают то же, что инспектор, включая аудио; refresh чипов — по всем inspector-only полям.

**Статус:** approved  
**Дата:** 2026-06-29  
**Родитель:** `web-script-editor-scenarist-ux`

---

## Решения

### 1. Хранение до Apply — sidecar в store редактора (discrepancy #1)

**Решение:** если строка DSL распознана как реплика и выделена как `draft-dialog:{line}`, её inspector-meta хранится в **`scriptEditorStore`** как объект, ключ — **номер строки заголовка** реплики (1-based, тот же `line`, что в `draft-dialog:{line}`).

Структура sidecar повторяет поля, которые показывает инспектор реплики на графе (см. §«Полный набор полей»).

**Обоснование (пользователь):** «если определили строку как объект — записываем в store редактора с её значениями». Provisional UUID в `storyStore` **не используем** — один источник правды для черновика: DSL (текстовые поля) + sidecar (inspector-only).

**Не делаем:** запись inspector-only в plain `;` строки DSL как обязательный путь (fallback export — опционально на implement).

### 2. Apply — перенос всех изменений (discrepancy #2)

**Решение:** при Apply для **вновь созданных** реплик merge подмешивает sidecar по сопоставлению **номер строки заголовка** → create payload → финальный `Dialog` в store со **всеми** inspector-only полями и premium-полями вариантов.

Для **существующих** UUID-реплик: поведение merge **не меняем** (текстовые поля из DSL; inspector-only в store не перезаписываются, как в v1).

**Обоснование (пользователь):** «все изменения надо перенести».

### 3. Полный инспектор = полное сохранение (discrepancies #3–5)

**Решение:** `DraftDialogInspector` использует те же табы **Base** и **Visual**, что `DialogInspector`; каждое изменение пишет либо в DSL (текстовые поля), либо в sidecar (inspector-only). Заглушки «после Apply» **убираем**.

**Обоснование (пользователь):** «надо сохранять всё, что показывает инспектор».

**Analytics-таб** для черновика — по-прежнему после Apply (вне scope, как в brief).

### 4. Варианты ответов для черновика (discrepancy #4)

**Решение:**

| Поле варианта | Где до Apply |
|---------------|--------------|
| `text`, `notification`, `statChanges`, `(список N)` | DSL (как сейчас в parse/export) |
| `isPremium`, `premiumCategory` | sidecar (inspector-only) |
| CRUD вариантов | патч DSL + sidecar; **не** `storyStore.addVariant` до UUID |

Кнопка «Добавить вариант» для `draft-dialog:*` обязана работать.

### 5. Meta-чипы для черновых и UUID-реплик (discrepancies #6–8, #7)

**Решение:**

- Чипы строятся из **store + sidecar** по line (presented draftText).
- Состав чипов реплики: **рамка** (+ fontSize из рамки), **textWeight**, **textStyle**, **позиция**, **аудио-события** (имена ассетов / basename) — для **всех** реплик, не только draft.
- Клик по чипу → тот же инспектор (draft или UUID).
- `inspectorMetaKey` / `notifyInspectorMetaChanged` — учитывают **все** inspector-only поля реплики (frame, weight, style, position, camera, assets, audio); для draft — notify без `canOpenInspector` guard.

**Обоснование:** «всё, что показывает инспектор» + паритет scenarist UX §8–9; audio явно в brief.

### 6. Смена номера строки (sidecar rekey)

**Решение:** при `setDraftText` / правках, сдвигающих AST, sidecar **перепривязывается** к новым номерам строк заголовков реплик (match по стабильному ключу блока: содержимое заголовка + parent list + index в списке — детали в technical plan).

**Обоснование:** ключ `line` ломается при вставке строк; без rekey sidecar потеряется.

### 7. Entity-спека `Диалог.md` (discrepancy #9)

**Решение:** на **feature-sync** дополнить `docs/specs/gameplay/entities/Диалог.md` полями `text_weight`, `text_style`, `audio_events` со ссылкой на web inspector-only контракт.

### 8. Аудио в scenarist doc (discrepancy #7)

**Решение:** на **feature-sync** обновить `docs/web/text-editor-mode.md` §Inspector-meta — явно включить **audioEvents** в чипы реплики.

---

## Полный набор полей (что сохраняем)

### Текстовые → DSL (как v1)

- тип реплики (`#Речь` / `#Мысль` / `#Выбор`)
- персонаж, `text`
- варианты: текст, `[уведомление]`, `; stat:`, `(список N)`

### Inspector-only → sidecar до Apply, store после Apply

| Поле | Base / Visual |
|------|---------------|
| `frameId` | Base |
| `textWeight`, `textStyle` | Base |
| `audioEvents` | Base |
| `characterPosition` | Visual |
| `cameraPositionX` | Visual (preview) |
| `assetChanges` | Visual |

### Варианты — premium (inspector-only)

| Поле | Где до Apply |
|------|--------------|
| `isPremium`, `premiumCategory` | sidecar (per variant index / temp id) |

---

## Поведение (итог)

1. Автор добавляет `#Речь` / `#Выбор` в текст; выделяет строку → `draft-dialog:{line}`.
2. Инспектор **Base + Visual** — полный, как на графе; правки не теряются при смене выделения в той же сессии.
3. Текстовые поля синхронизируются с DSL; inspector-only — в **sidecar** `scriptEditorStore`.
4. Meta-чипы у строки показывают рамку, типографику, позицию, аудио; обновляются при правке в инспекторе.
5. Варианты: добавление/удаление/правка через DSL + sidecar для premium; кнопка «+» работает.
6. **Apply:** новые реплики создаются в store **со всеми** полями из sidecar; sidecar для перенесённых строк очищается / rekey после успешного Apply.
7. UUID-реплики: без регрессии; inspector-only по-прежнему только в store, merge не затирает.
8. Analytics черновика — после Apply.

---

## Acceptance criteria (финальные)

- [ ] Sidecar `draftDialogInspectorMetaByLine` в `scriptEditorStore`; ключ — line заголовка реплики.
- [ ] Draft: рамка, textWeight, textStyle сохраняются при смене выделения и остаются до Apply.
- [ ] Draft: VisualTab (позиция, camera, ассеты) работает; значения в sidecar.
- [ ] Draft: audioEvents в sidecar; видны в meta-чипах.
- [ ] Draft: «Добавить вариант» работает; DSL + sidecar для premium.
- [ ] Meta-чипы для draft-строк (без UUID в source map).
- [ ] Meta-чипы для UUID-реплик включают audio; refresh при смене weight/style/frame/audio/position/assets.
- [ ] Apply create: все sidecar-поля попадают в `Dialog` / variants в store.
- [ ] Sidecar rekey при изменении draftText не теряет meta.
- [ ] Smoke: UUID-реплика — правка текста + inspector-only в store без регрессии.
- [ ] Unit-тесты: sidecar patch, rekey, merge overlay, meta chips draft line.

---

## Синхронизировать в источники (feature-sync)

- [ ] `docs/web/text-editor-mode.md` — sidecar, полный draft inspector, audio в чипах
- [ ] `docs/specs/gameplay/entities/Диалог.md` — text_weight, text_style, audio_events
- [ ] `.cursor/feature-work/web-script-editor-scenarist-ux/06-review-notes.md` — amend: meta-чипы для draft (optional note)

---

## Вне scope (зафиксировано)

- Analytics-таб для черновика
- Provisional UUID в `storyStore`
- Обязательный round-trip inspector-meta в plain `;` DSL
- Изменение merge для **существующих** UUID-реплик (кроме smoke)
- Mobile runtime

---

## Глоссарий

| Термин в коде | По-русски | Где живёт |
|---------------|-----------|-----------|
| `draftDialogInspectorMetaByLine` | Sidecar inspector-meta по номеру строки | `scriptEditorStore` |
| `draft-dialog:{line}` | Выделение черновой реплики | `selectionStore` / resolve |
| Inspector-only | Поля только через инспектор | sidecar → store после Apply |
| Meta-чип | Read-only виджет в CodeMirror | `buildMetaChips` + extension |
| Rekey | Перепривязка sidecar при сдвиге строк | `setDraftText` pipeline |

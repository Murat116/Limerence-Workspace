## Резюме

Найдено **12 расхождений**: **4 blocker**, **5 major**, **2 minor**, **1 info**. Планировать реализацию **нельзя без решений** по round-trip (экспорт теряет связи и поля), границам расширенного DSL v1 и стратегии применения текста к **одной главе** без затирания остального проекта. Notion и Figma не подключены. Схема БД менять не требует — текстовый режим работает поверх существующих таблиц сцен и диалогов.

## Сводка (читать первым)

| # | О чём спор | Насколько важно | Нужно твоё решение? |
|---|------------|-----------------|---------------------|
| 1 | Нет режима «Текст» — только заготовка в store | 🔴 blocker | Да |
| 2 | Экспорт в текст не восстанавливает связи и поля инспектора | 🔴 blocker | Да |
| 3 | Парсер каждый раз создаёт новые ID — нельзя править главу «на месте» | 🔴 blocker | Да |
| 4 | Импорт и «сохранить текст» ведут себя по-разному (merge vs replace) | 🔴 blocker | Да |
| 5 | Какие поля инспектора обязательны в DSL v1 | 🟠 major | Да |
| 6 | Три описания формата расходятся: guide, парсер, AI-pipeline | 🟠 major | Да |
| 7 | Спека сущностей требует полей, которых нет в import-text-guide | 🟠 major | Желательно |
| 8 | Два графа (сцены и списки диалогов) — в guide только второй | 🟠 major | Да |
| 9 | Ошибки анализа графа не привязаны к строкам текста | 🟠 major | Желательно |
| 10 | Спека конструктора описывает только визуальный flow | 🟡 minor | Нет |
| 11 | Дока ссылается на пустой `ParserText.ts` | 🟡 minor | Нет |
| 12 | База данных | ⚪ info | Нет |

---

## Расхождения (подробно)

### 1. Режим «Текст» объявлен, но не существует в UI

**По-человечески:** Brief требует переключатель «Граф / Текст» и полноэкранный редактор главы. В коде режим `script` записан в store, но ни один компонент его не показывает и не переключает.

**Что говорит каждый источник:**
- **Конструктор для авторов:** тип `viewMode: 'flow' | 'script' | 'characterEditor'` — `web/editor-app/src/store/selectionStore.ts`, строки 33–35:
  > `viewMode: 'flow' | 'script' | 'characterEditor';`
- **Конструктор для авторов:** `EditorLayout` рендерит только `flow` и `characterEditor` — `web/editor-app/src/pages/EditorLayout.tsx`:
  > `{viewMode === 'flow' && <FlowEditor />}`
- **Задача в Notion:** не описано
- **Макет:** не описано
- **Спека в репо:** `docs/web/user-functionality.md` — визуальный flow как «главная фишка»; текстовый режим peer не описан

**Что это значит для задачи:** Весь UI текстового режима (переключатель, редактор, скрытие Inspector) — новая работа; опереться можно только на `setViewMode` и паттерн `CharacterEditor`.

**Вопрос к тебе:** Inspector справа в текстовом режиме скрыт полностью или остаётся узкая панель (например, ошибки валидации)?

<details>
<summary>Детали для агента</summary>

| Источник | Значение | Путь |
|----------|----------|------|
| viewMode script | 0 вызовов setViewMode('script') | `selectionStore.ts`, grep по `editor-app` |
| CharacterEditor peer | setViewMode('characterEditor') из CharactersPanel | `CharactersPanel.tsx` |
| Brief AC | Переключатель Граф/Текст | `01-brief.md` |

</details>

---

### 2. Round-trip текст ↔ проект сломан: экспорт неполный

**По-человечески:** Переключение Граф ↔ Текст подразумевает: открыл текст — увидел то же, что на графе; сохранил — граф не сломался. Сейчас экспорт всегда пишет `#Речь` без типа реплики, без `(список N)`, без stat gates, scene type, audio, рамок и слоёв.

**Что говорит каждый источник:**
- **Конструктор для авторов:** export вариантов без целевого списка — `TextFormatService.ts`:
  > `result += \`- ${variant.text}\n\`` — без `(список N)`
- **Конструктор для авторов:** при парсе `statChanges: null`, `sceneType: 'regular'` всегда
- **Спека в репо:** `docs/web/import-text-guide.md` — `(список N)` как ключевая связь:
  > `- Подойти к незнакомцу (список 2)`
- **Приложение (как сейчас работает):** RN читает `minimumRequiredStats`, `sceneType`, `availableSceneIds` из БД — `mobile/src/App/store/helpers/mapper.ts`
- **Задача в brief:** «экспорт теряет связи» — подтверждено кодом

**Что это значит для задачи:** Без расширения `TextFormatService` (или преемника) переключатель Граф→Текст→Граф **уничтожит** ветки и метаданные сцены.

**Вопрос к тебе:** v1 обязан быть **lossless** round-trip для всех полей инспектора или допустим «текстовый режим только для сюжета» (реплики + ветки), а фон/audio/gates правятся только на графе?

<details>
<summary>Детали для агента</summary>

| Поле | Parse | Export |
|------|-------|--------|
| `(список N)` | ✅ | ❌ |
| `replicaType` | ✅ | ❌ (всегда `#Речь`) |
| `minimumRequiredStats` | ❌ | ❌ |
| `sceneType`, wardrobe | ❌ | ❌ |
| `backgroundImage`, `audioTracks` | ❌ | ❌ |
| `frameId`, layers, camera | ❌ | ❌ |
| `statChanges` на вариантах | ❌ | ❌ |
| Chapter scope | весь текст | весь проект |

</details>

---

### 3. Парсер создаёт новые UUID — нельзя редактировать существующую главу

**По-человечески:** Brief хочет править **активную главу** в тексте и синхронизировать с store. Текущий парсер строит проект с нуля: новые UUID сцен, списков и реплик. Повторный parse той же главы не сохранит идентичность узлов — сломаются связи с другими главами, позиции на графе и аналитика.

**Что говорит каждый источник:**
- **Конструктор для авторов:** `parseTextToProject(text, project?)` — второй аргумент используется частично (персонажи), не для сохранения ID существующих сцен
- **Конструктор для авторов:** `storyStore` — нет `applyTextToChapter(chapterId)`; есть только `setProject` / slice `updateScene` по одному полю — `storyStore.ts`, `chapterSlice.ts`
- **Спека в репо:** не описано

**Что это значит для задачи:** Нужна стратегия **stable ID**: либо parse-in-place по существующей главе, либо source map «строка → entityId», либо diff-merge. Без этого текстовый режим = только создание с нуля, не редактирование.

**Вопрос к тебе:** При первом открытии текста главы — сериализуем существующие UUID в скрытые якоря (`@id:uuid` в заголовках) или матчим по порядку и названиям?

<details>
<summary>Детали для агента</summary>

| Источник | Значение | Путь |
|----------|----------|------|
| Brief scope | только activeChapterId | `01-brief.md` |
| nodePositions | в flowStore, привязаны к scene/dialogList uuid | `flowStore.ts`, `flowUtils.ts` |
| Import merge | spread новых chapters/scenes поверх старых | `ImportTextModal.tsx` L74–79 |

</details>

---

### 4. Импорт файла и «сохранить отредактированный текст» ведут себя по-разному

**По-человечески:** Кнопка «Импортировать» **добавляет** главы к проекту. Кнопка «Сохранить изменения» в том же окне **затирает** все главы/сцены/диалоги проекта содержимым парсера. Brief требует согласованное поведение с текстовым режимом и pipeline `canonical.txt`.

**Что говорит каждый источник:**
- **Конструктор для авторов:** merge при импорте — `ImportTextModal.tsx`:
  > `chapters: { ...project.chapters, ...parsedData.chapters }`
- **Конструктор для авторов:** replace при save edited — `ImportTextModal.tsx`:
  > `chapters: parsedData.chapters || {}`
- **Спека в репо:** `docs/web/scenario-import/README.md` — импорт **добавляет** главу к проекту
- **Задача в brief:** AC «merge vs replace согласовано»

**Что это значит для задачи:** Текстовый режим должен явно выбрать: **replace одной главы** vs merge. Иначе авторы AI-pipeline и авторы текстового режима получат разный и непредсказуемый результат.

**Вопрос к тебе:** Текстовый режим всегда **перезаписывает только активную главу**, а `ImportTextModal` остаётся для **добавления новых глав** из файла?

<details>
<summary>Детали для агента</summary>

| Действие | chapters | Остальной проект |
|----------|----------|------------------|
| handleImport | merge | userStats, nodePositions сохраняются |
| handleSaveCurrentText | replace all parsed | userStats сохраняются |
| Brief text mode | replace active chapter only | остальные главы нетронуты |

</details>

---

### 5. Границы расширенного DSL v1 не зафиксированы

**По-человечески:** Brief обещает DSL «как инспектор», но инспектор редактирует ~25+ полей, а canonical сегодня покрывает ~8. Неясно, что входит в первую версию.

**Что говорит каждый источник:**
- **Конструктор для авторов:** полный список полей Scene / DialogList / Dialog / Variant — инспекторы в `SceneInspector.tsx`, `DialogListInspector.tsx`, `DialogInspector.tsx`, `VariantsEditor.tsx`
- **Спека в репо:** entity specs требуют `sceneType`, stat gates, граф сцен — `docs/specs/gameplay/entities/Сцена.md`, `Диалог.md`
- **Задача в brief:** «перечень полей финализируется на reconcile» — открытый вопрос

**Поля инспектора (кандидаты в DSL):**

| Сущность | Поля в UI |
|----------|-----------|
| Сцена | `sceneType`, `title`, `initialSceneId`, `allowWardrobeAccess`, `backgroundImage`, `assetDescription`, `bgmDescription`, `minimumRequiredStats`, `requiredSelectedVariants`, `availableAssets` (wardrobe), `audioTracks[]` |
| Список диалогов | `title`, `initialDialogListId`, `minimumRequiredStats`, `requiredSelectedVariants` |
| Реплика | `characterId`, `frameId`, `text`, `textWeight`, `textStyle`, `variants[]`, `audioEvents[]`, `characterPosition`, `cameraPositionX`, `assetChanges[]` |
| Вариант | `text`, `statChanges`, `notification`, `isPremium` |

**Только на графе (не в инспекторе):** `nextAvailableScenesUUID`, `nextAvailableDialogListUUID`, `position`, `columnCount`

**Что это значит для задачи:** Без списка «обязательно в v1» нельзя оценить объём парсера, валидатора и документации.

**Вопрос к тебе:** Предлагаемый минимум v1: **сюжет + ветки** (реплики, типы, `(список N)`, stat gates на списках) **без** медиа-URL, гардероба и audio events — согласен?

<details>
<summary>Детали для агента</summary>

| Источник | Значение | Путь |
|----------|----------|------|
| replicaType | парсится, селектора в UI нет | `TextFormatService.ts` |
| premiumCategory | в модели, UI нет | `data/story.ts`, `VariantsEditor.tsx` |
| Brief out of scope | генерация арта v1 нет; descriptions «если reconcile решит» | `01-brief.md` |

</details>

---

### 6. Три описания текстового формата расходятся

**По-человечески:** Автор может получить три разных «правильных» формата: дока import-text-guide, реальный парсер и инструкции AI-pipeline для `canonical.txt`.

**Что говорит каждый источник:**
- **Спека в репо:** `#Мысль` — `docs/web/import-text-guide.md`
- **Конструктор для авторов:** парсер принимает `#Мысли` — `TextFormatService.ts`
- **Спека в репо:** `#Выбор` в guide; export даёт `##Выбор`; pipeline — `docs/web/scenario-import/prompt-conventions.md`:
  > `thought` → `#Мысль, Имя, текст`
- **Конструктор для авторов:** автосвязи «последовательно без (список N)» в guide; в коде удалены — комментарий `// (Удалено) Автосвязи`
- **Спека в репо:** сетка 3 колонки в guide; код — 5 колонок, 260px

**Что это значит для задачи:** Расширенный DSL нужно описать **одним** документом и синхронизировать парсер + scenario-import; иначе AI-pipeline и встроенный редактор дадут несовместимые файлы.

**Вопрос к тебе:** Канонический маркер мыслей — `#Мысль` (guide + pipeline) с алиасом `#Мысли` в парсере?

<details>
<summary>Детали для агента</summary>

| Маркер | import-text-guide | TextFormatService | prompt-conventions |
|--------|-------------------|-------------------|---------------------|
| Мысли | `#Мысль` | `#Мысли` | `#Мысль` |
| Выбор | `#Выбор` | `## Выбор` / `-` | `#Выбор` блок |
| Действие | `#Действие` | не парсится | `#Действие` |

</details>

---

### 7. Entity specs требуют полей, которых нет в import-text-guide

**По-человечески:** Игрок в приложении ожидает cutscene, гардероб, gates по статам и переходы между сценами. Текстовый guide знает только реплики и `(список N)` между списками диалогов.

**Что говорит каждый источник:**
- **Спека в репо:** `sceneType: regular | cutscene | wardrobe` — `docs/specs/gameplay/entities/Сцена.md`
- **Спека в репо:** `availableSceneIds` — граф сцен — там же
- **Спека в репо:** `minmumRequiredStats`, `requerdSelectedVariants` на сцене и списке — `Сцена.md`, `Диалог.md`
- **Спека в репо:** `docs/web/import-text-guide.md` — не описано
- **Приложение (как сейчас работает):** mapper читает все поля — `mobile/src/App/store/helpers/mapper.ts`

**Что это значит для задачи:** Extended DSL из brief — это не «улучшение удобства», а **закрытие контракта** с runtime. Иначе текстовый режим создаст истории, которые в приложении ведут себя иначе, чем из графа.

**Вопрос к тебе:** Переходы между **сценами** в DSL — отдельный синтаксис `(сцена N)` или только через граф после импорта текста?

<details>
<summary>Детали для агента</summary>

| Поле runtime | В guide | В парсере |
|--------------|---------|-----------|
| sceneType | ❌ | всегда regular |
| availableSceneIds | ❌ | ❌ |
| stat gates | ❌ | ❌ |
| frame_id, camera | ❌ | ❌ |
| notification на варианте | `[уведомление]` | ✅ parse |
| statsChanges | ❌ | null при parse |

RN модели с полями вне entity-md: `textWeight`, `textStyle` — `mobile/src/Common/models/dialog.tsx`

</details>

---

### 8. Два уровня графа — в guide описан только один

**По-человечески:** История — это граф **сцен** и внутри каждой сцены граф **списков диалогов**. `(список N)` в guide — только второй уровень. Переход «закончили диалог → другая сцена» в тексте не описан.

**Что говорит каждый источник:**
- **Спека в репо:** `Глава → Сцена (граф) → DialogList → Диалог → Исход` — `docs/specs/gameplay/full-description.md`
- **Спека в репо:** `(список N)` — `docs/web/import-text-guide.md`
- **Конструктор для авторов:** рёбра сцен — drag на FlowEditor; `nextAvailableScenesUUID` не в инспекторе

**Что это значит для задачи:** Автор в текстовом режиме не сможет задать структуру главы целиком, если переходы между сценами останутся только на графе — это противоречит brief «альтернатива визуальному флоу».

**Вопрос к тебе:** В v1 переходы между сценами остаются **только на графе** (текст = диалоги внутри сцен) или сцены тоже связываем в DSL?

<details>
<summary>Детали для агента</summary>

| Уровень | Поле модели | Как задаётся сейчас |
|---------|-------------|---------------------|
| Scene graph | `nextAvailableScenesUUID` | React Flow edges |
| DialogList graph | `nextAvailableDialogListUUID` | edges + `(список N)` в тексте |

</details>

---

### 9. Валидация: inline по строкам vs анализ графа без привязки к тексту

**По-человечески:** Brief хочет ошибки с номером строки в редакторе и те же классы ошибок, что `AnalysisService` (hotkey `R`). Сейчас парсер не возвращает errors; анализ выдаёт `elementId` (UUID), без `lineNumber`.

**Что говорит каждый источник:**
- **Конструктор для авторов:** fake validation в модалке — `ImportTextModal.tsx`:
  > `warnings: ['Импорт выполнен успешно, но проверьте структуру в консоли браузера']`
- **Конструктор для авторов:** `AnalysisService` — коды `ORPHANED_NODE`, `DEAD_END`, `INFINITE_LOOP`, `DIALOG_TEXT_*` и др.; `meta` без line — `AnalysisService.ts`
- **Задача в brief:** inline-валидация + анализ из текстового режима

**Что это значит для задачи:** Нужны два слоя: **синтаксис/ссылки** (новый, с line) и **структура графа** (существующий, нужен source map UUID→line при сериализации).

**Вопрос к тебе:** Ошибки анализа в текстовом режиме — **jump to line** обязателен в v1 или достаточно списка с UUID + кнопка «показать на графе»?

<details>
<summary>Детали для агента</summary>

| Слой | Есть | Нужно |
|------|------|-------|
| Syntax | ❌ | regex/grammar + line |
| Unknown character | ❌ | match project.characters |
| Broken (список N) | частично в parse | explicit errors |
| Graph analysis | ✅ AnalysisService | source map |

</details>

---

### 10. Спека конструктора не описывает текстовый режим как peer flow

**По-человечески:** Официальное описание Builder позиционирует визуальный граф как ядро; импорт текста — вспомогательная модалка, не режим редактирования.

**Что говорит каждый источник:**
- **Спека в репо:** `docs/web/user-functionality.md` §3.1 — Flow Editor «главная фишка»; §3.4 — ImportTextModal
- **Спека в репо:** `docs/web/story-constructor-spec.md` — не описано (grep по text/import пуст)
- **Задача в brief:** peer-режим «Текст»

**Что это значит для задачи:** После approve нужно обновить `docs/web/` — иначе расхождение doc vs продукт повторится.

<details>
<summary>Детали для агента</summary>

| Документ | Упоминание text mode |
|----------|---------------------|
| user-functionality.md | только ImportTextModal |
| story-constructor-spec.md | не описано |
| import-text-guide.md | формат импорта, не UI режим |

</details>

---

### 11. Документация ссылается на пустой ParserText.ts

**По-человечески:** В описании функционала указан `ParserText.ts` как парсер; файл пустой, реальная логика в `TextFormatService.ts`.

**Что говорит каждый источник:**
- **Спека в репо:** `docs/web/user-functionality.md` §3.4:
  > `ImportTextModal.tsx` и сервис-парсер (`ParserText.ts`)
- **Конструктор для авторов:** `web/editor-app/src/services/ParserText.ts` — пустой

**Что это значит для задачи:** При реализации — мигрировать ссылки в docs на актуальный сервис; не восстанавливать legacy-файл.

<details>
<summary>Детали для агента</summary>

| Файл | Состояние |
|------|-----------|
| ParserText.ts | empty |
| TextFormatService.ts | ~936 строк, parse + export |

</details>

---

### 12. База данных — схема не блокирует фичу

**По-человечески:** Текстовый режим не требует новых таблиц: сцены, диалоги, варианты уже хранят все поля, которые парсер должен заполнять.

**Что говорит каждый источник:**
- **База данных:** миграции с `asset_description`, `bgm_description`, `dialog_audio` — `supabase/migrations/20260630100000_asset_descriptions.sql`, `20260603120000_dialog_audio_play_mode.sql`; отдельной «text format» таблицы нет
- **Конструктор для авторов:** `DataMappingService` мапит scene/dialog поля в Postgres
- **Задача в Notion:** не описано

**Что это значит для задачи:** Работа на уровне editor-app + docs; Supabase sync — только если появятся новые поля в DSL, которых ещё нет в DTO (на текущий момент не выявлено).

<details>
<summary>Детали для агента</summary>

| Слой | Изменения для text mode |
|------|-------------------------|
| supabase/migrations | не требуются (info) |
| DataMappingService | может понадобиться при новых полях DSL |
| UpdateService | без изменений схемы |

</details>

---

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| Round-trip | Текст → проект → тот же текст без потери данных |
| Merge import | Добавление распарсенных глав к существующему проекту |
| Replace import | Замена всех глав/сцен содержимым парсера |
| Stable ID | Сохранение UUID сущностей при повторном parse |
| Source map | Соответствие строки текста и UUID для jump-to-error |
| Extended DSL | Расширенный формат поверх canonical с полями инспектора |
| DialogList graph | Ветвление между списками диалогов `(список N)` |
| Scene graph | Переходы между сценами `availableSceneIds` |
| AnalysisService | Симуляция прохождения и поиск циклов/тупиков на графе |

## Открытые вопросы

- [ ] Lossless round-trip v1 или «сюжет only» в тексте?
- [ ] Стабильные UUID: якоря в тексте vs match по порядку?
- [ ] Текстовый режим replace активной главы; ImportTextModal — только add?
- [ ] Минимальный набор полей DSL v1 (предложение: реплики + ветки + stat gates)
- [ ] Переходы между сценами в DSL v1 или только на графе?
- [ ] Jump-to-line для ошибок AnalysisService в v1?
- [ ] Inspector виден в текстовом режиме?
- [ ] Канон `#Мысль` vs `#Мысли`

## Статистика

blocker: 4 | major: 5 | minor: 2 | info: 1

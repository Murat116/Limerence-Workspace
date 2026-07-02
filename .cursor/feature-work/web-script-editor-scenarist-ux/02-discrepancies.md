## Резюме

**12 расхождений: 3 blocker, 6 major, 2 minor, 1 info.**

Brief scenarist UX согласован внутри себя, но **конфликтует с утверждённым v1 text mode** по stat gates и частично по формату рассказчика. В **БД нет** места для spacing prefs. **Parent blockers #8/#9** не закрыты — без них навигация и ветки ненадёжны.

**Можно ли планировать без решений:** **нет** — нужны решения по stat gates (текст vs теги), схеме prefs в Supabase, контракту рассказчика и порядку закрытия parent blockers.

---

## Сводка (читать первым)

| # | О чём спор | Насколько важно | Нужно твоё решение? |
|---|------------|-----------------|---------------------|
| 1 | Stat gates: в v1 **текст**, в brief — **теги** | 🔴 blocker | Да |
| 2 | Parent blockers #8/#9 не закрыты | 🔴 blocker | Да (порядок работ) |
| 3 | Spacing prefs в Supabase — **схемы нет** | 🔴 blocker | Да |
| 4 | Рассказчик: `char-narrator` vs `person = null` vs `#Речь, Имя, текст` | 🟠 major | Да |
| 5 | Формат `#Речь, текст` без имени vs `import-text-guide` | 🟠 major | Да |
| 6 | Cosmetic spacing vs пересборка draft после Apply | 🟠 major | Да |
| 7 | Meta: `;` строки vs inline widgets | 🟠 major | Нет (brief уже решил widgets) |
| 8 | textWeight/textStyle: inspector-only vs чипы в редакторе | 🟠 major | Нет (расширение read-only) |
| 9 | Текст → outline: курсор на реплике не подсвечивает список | 🟠 major | Нет (implement) |
| 10 | `import-text-guide` противоречит сам себе про stat gates | 🟡 minor | Нет |
| 11 | Autocomplete / preview diff / fold — везде «не описано» | ⚪ info | Нет |
| 12 | Макет / Notion | ⚪ info | Нет |

---

## Расхождения (подробно)

### 1. Stat gates: редактируемый текст или теги-чипы

**По-человечески:** В brief stat gates — теги. В утверждённом v1 и в коде — строки `; stat:` / `; variant:`, которые можно править клавиатурой.

**Что говорит каждый источник:**
- **Конструктор (код):** `formatStatGateLines` → `; stat: …`; в `isReadOnlyMetaLine` stat/variant **не** read-only — `useScriptEditorExtensions.ts`
- **Спека v1 (approved):** `minimumRequiredStats`, `requiredSelectedVariants` — **текстовые поля v1**, редактируются в тексте — `web-constructor-text-editor/03-approved-spec.md` §2
- **Доки:** `import-text-guide.md:112-114` — «редактируются в тексте»
- **Brief scenarist:** stat gates — **теги-чипы**, не сырой текст

**Что это значит для задачи:** Нужно **явно изменить контракт v1** на approve (amend parent spec / новый spec): gates уходят из editable DSL в chip + Inspector UX. Иначе implement противоречит approved-spec.

**Вопрос к тебе:** Подтверждаем смену класса поля: gates **больше не текст**, только теги + Inspector?

---

### 2. Parent blockers #8 и #9 не закрыты

**По-человечески:** Базовая text mode фича ещё не merge-ready; scenarist UX опирается на jump и `(список N)`.

**Что говорит каждый источник:**
- **Brief scenarist:** предусловие — закрыть до/в первом спринте
- **Review parent:** `06-review-notes.md` #8 open (jump при dirty), #9 open (replace рёбер)
- **Конструктор (код):** `jumpToAnalysisElement` не проверяет `isDirty` в script mode; `applyResolvedListEdges` append-only

**Что это значит для задачи:** План должен включать **отдельный этап/PR** на parent fixes **до** чипов и autocomplete, иначе сценарист получит polish поверх багов.

**Вопрос к тебе:** Строго «сначала parent PR» или допускаем один combined PR?

---

### 3. Spacing prefs в Supabase — нет схемы и UI

**По-человечески:** Brief хочет настройки пустых строк между блоками в настройках проекта с синхроном через Supabase.

**Что говорит каждый источник:**
- **Brief:** prefs проекта (Supabase)
- **Конструктор (код):** `Project` в `story.ts` — нет полей editor/spacing; Story Settings: `general | frames | colors | monetization | analytics` — без вкладки редактора
- **База данных:** в `supabase/migrations/` колонок/таблиц под script editor prefs **не найдено**
- **Макет / Notion:** не описано

**Что это значит для задачи:** Нужна **миграция** (колонка JSON на `stories` / отдельная таблица) + UI в Story Settings + mapper. Без решения на approve нельзя оценить scope.

**Вопрос к тебе:** JSON на `stories` (`script_editor_prefs`) или отдельная таблица? Новая вкладка «Редактор» в settings?

---

### 4. Рассказчик: три модели в разных слоях

**По-человечески:** Runtime знает «нет персонажа = рассказчик»; конструктор — `char-narrator`; brief — `#Речь, текст` без имени.

**Что говорит каждый источник:**
- **Спека (runtime):** реплика без `person` → рассказчик, спрайт скрыт — `docs/specs/gameplay/entities/Диалог.md`
- **Конструктор (код):** `char-narrator`, `name: 'Рассказчик'` — `StoryMapper.ts`, export `#Речь, Рассказчик, …`
- **Brief:** `#Речь, <текст>` без имени → `char-narrator` в store
- **Спека в репо:** `char-narrator` как id — **не описано**

**Что это значит для задачи:** На approve зафиксировать маппинг: `char-narrator` в store ↔ narrator в runtime ↔ синтаксис без имени в DSL. Обновить `import-text-guide`.

**Вопрос к тебе:** При export в runtime/БД narrator всегда `person_uuid = null` или остаётся `char-narrator` в конструкторе?

---

### 5. Синтаксис `#Речь, текст` vs документация DSL

**По-человечески:** Brief разрешает только `#Речь, текст` без имени. Гайд и parse сейчас ждут `#Речь, Имя, текст`.

**Что говорит каждый источник:**
- **Brief:** только `#Речь, текст`; legacy-абзацы — нет
- **Доки:** `import-text-guide.md:48-49` — `#Речь, Имя персонажа, текст`
- **Конструктор (parse):** если одна запятая — весь хвост = `characterName` → ошибка `CHARACTER_UNKNOWN`

**Что это значит для задачи:** Parse/export/validator нужно менять согласованно; доки — на approve/sync.

---

### 6. Cosmetic spacing и пересборка draft после Apply

**По-человечески:** Автор вставляет пустые строки для читаемости; после Apply draft пересобирается из export — ручные пустые строки пропадут, если нет отдельного слоя.

**Что говорит каждый источник:**
- **Brief:** cosmetic spacing не влияет на store; strip при parse/merge; prefs задают количество при display/export
- **Конструктор (код):** parse пропускает пустые строки; успешный Apply → `draftText` из `exportChapterToText` (без cosmetic)
- **Спека / доки:** cosmetic spacing — **не описано**

**Что это значит для задачи:** Нужна архитектура **двух слоёв**: canonical DSL + presentation layer (вставка `\n` по prefs + сохранение ручных blank в сессии или re-inject после export). Решение на approve.

**Вопрос к тебе:** Ручные пустые строки живут только до следующего Apply или переживают Apply (re-inject после export)?

---

### 7. Meta: plain `;` vs inline widgets

**По-человечески:** Сейчас meta — текстовые строки с блокировкой ввода; brief — CodeMirror widgets-чипы.

**Что говорит каждый источник:**
- **Конструктор (код):** `buildSceneMetaLines` / `buildDialogMetaLines` → `; …`
- **Доки v1:** «badge / комментарий» — `text-editor-mode.md:58`
- **Brief:** inline widgets, клик → Inspector

**Что это значит для задачи:** Эволюция v1, не блокер, если approve явно заменяет «badge» на «widget». Технически: export может оставаться `;` под капотом + decoration layer, или смена формата export.

---

### 8. textWeight / textStyle в редакторе

**По-человечески:** Brief показывает weight/style в тексте; v1 spec — только Inspector.

**Что говорит каждый источник:**
- **Спека v1:** `textWeight`/`textStyle` — inspector-only
- **Brief:** видимость в редакторе (чипы)
- **Конструктор (код):** в `buildDialogMetaLines` — только рамка и позиция

**Что это значит для задачи:** Допустимо как **read-only чипы** без смены класса поля (правка всё ещё в Inspector). Согласовать на approve.

---

### 9. Текст → outline: реплика не подсвечивает родительский список

**По-человечески:** Brief хочет highlight сцены/списка при курсоре в тексте; код выбирает UUID реплики — outline её не показывает.

**Что говорит каждый источник:**
- **Brief:** highlight + scroll **сцены или списка**; реплик в дереве нет
- **Конструктор (код):** `findEntityIdAtLine` → `select(dialogId)`; `ScriptOutline` highlight только scene/list UUID; scroll outline отсутствует

**Что это значит для задачи:** Implement: map cursor line → parent list/scene для selection + `scrollIntoView` в outline. Источники не спорят — gap в коде.

---

### 10. Противоречие внутри `import-text-guide`

**По-человечески:** В одном файле stat gates и «редактируются в тексте», и «read-only сводка при экспорте».

**Что говорит источник:**
- **Доки:** `import-text-guide.md:112-114` — оба утверждения в соседних строках

**Что это значит для задачи:** При sync после approve вычистить формулировку под выбранную модель (теги или текст).

---

### 11. Новые UX-фичи нигде не описаны (info)

**По-человечески:** Autocomplete, preview diff, breadcrumb, fold, цвета заголовков — только в brief.

**Источники:** `docs/specs/`, `docs/web/` — **не описано**; код — **нет**.

**Что это значит для задачи:** Нормально для новой фичи; описать в approve-spec и `text-editor-mode.md` на sync.

---

### 12. Notion / Figma (info)

- **Задача в Notion:** не подключена (`meta.notionPageUrl` null)
- **Макет:** brief — без Figma; чипы проектируем в коде/reconcile

---

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| Stat gate | Условие показа списка по стату или выбранному варианту |
| Cosmetic spacing | Пустые строки только для отображения в редакторе |
| `char-narrator` | Системный персонаж «Рассказчик» в конструкторе |
| `person = null` | Рассказчик в runtime (мобильная спека) |
| Parent blockers #8/#9 | Открытые баги базовой text mode фичи |
| Inline widget | CodeMirror chip вместо plain text meta |

## Открытые вопросы (для feature-approve)

- [x] Stat gates: **остаются текстом** + IDE-подсветка (не теги)
- [x] Parent #8/#9: **combined PR**
- [x] Supabase: **`stories.script_editor_prefs` JSONB** + вкладка «Редактор» + ссылка из text toolbar
- [x] Narrator: **`person_uuid = null`** в БД; DSL `#Речь, текст`
- [x] Cosmetic blank lines: **переживают Apply** (re-inject)
- [x] Meta: **inline widgets**; stat gates — текст
- [x] Типографика: **fontSize + weight + style** в чипах реплики
- [x] Новые UX (#11): описаны в `03-approved-spec.md` §11

## Статистика

blocker: 3 | major: 6 | minor: 1 | info: 2

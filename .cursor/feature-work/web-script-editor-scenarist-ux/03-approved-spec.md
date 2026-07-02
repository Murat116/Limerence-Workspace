## Резюме

Утверждён **UX-слой текстового редактора** для сценариста поверх v1 text mode: IDE-подсветка DSL, autocomplete, рассказчик как `#Речь, текст` → `person_uuid = null`, inspector-meta как **inline-чипы**, stat gates **остаются текстом** с отдельной подсветкой, cosmetic spacing переживает Apply, prefs в `stories.script_editor_prefs`, вкладка «Редактор» в настройках + ссылка из toolbar.

**Один combined PR** включает закрытие parent blockers #8/#9 и scenarist UX.

**Статус:** approved

**Дата:** 2026-06-29

**Родительская фича:** `web-constructor-text-editor` (v1 text mode)

---

## Решения

### 1. Stat gates — текст + подсветка (не теги)

**Решение:** `; stat:` и `; variant:` остаются **редактируемым DSL-текстом** (класс поля v1 parent-spec **не меняем**). Дополнительно — **syntax highlighting** (приглушённый фон/цвет, как gate-аннотации в IDE).

**Обоснование:** Сценарист правит условия клавиатурой; визуально отличаем от сюжета и от read-only meta-чипов.

### 2. IDE-подсветка типов элементов

**Решение:** CodeMirror **line/syntax decorations** по типу блока:

| Элемент | Пример | Визуал (концепт) |
|---------|--------|------------------|
| Сцена | `### Сцена:` | отдельный цвет заголовка |
| Список | `## Список диалогов N` | свой цвет |
| Речь | `#Речь` | нейтральный акцент |
| Мысль | `#Мысль` | italic / холодный тон |
| Выбор | `#Выбор` | акцент ветвления |
| Вариант | `- …` | приглушённый |
| Stat gate | `; stat:` | warning-тон, лёгкий фон |
| Variant gate | `; variant:` | warning-тон |
| Read-only meta | widget-чипы | не plain `;` prose |

Точные токены — в theme; контраст и читаемость обязательны.

### 3. Parent blockers #8/#9 — combined PR

**Решение:** Исправления из `web-constructor-text-editor/06-review-notes.md` (#8 jump при dirty, #9 replace рёбер) входят в **тот же PR**, что scenarist UX.

**Обоснование:** Пользователь; один review cycle.

### 4. Prefs редактора в Supabase

**Решение:**

- Миграция: колонка `stories.script_editor_prefs` **JSONB** (default `{}`).
- Схема prefs (v1):

```json
{
  "blankLinesAfterScene": 1,
  "blankLinesAfterDialogList": 1,
  "blankLinesAfterDialog": 0,
  "editorFontSizePx": 13
}
```

- Story Settings: новая вкладка **«Редактор»** (`editor` tab).
- Из текстового режима: кнопка/ссылка **«Настройки редактора»** в toolbar → `/story/:id/settings/editor`.

**Обоснование:** Синхрон между устройствами; не засоряем entity tables.

### 5. Рассказчик — `person_uuid = null`

**Решение:**

- **DSL:** `#Речь, <текст>` без имени персонажа = рассказчик.
- **Parse:** одна запятая после `#Речь` → весь хвост = текст реплики; `characterId` в store → sentinel `char-narrator` **только в памяти конструктора** для Inspector/UI.
- **Persist (Supabase):** `dialogs.person_uuid = **null**` (не `char-narrator`).
- **Export:** `#Речь, <текст>` без «Рассказчик»; старый текст с именем «Рассказчик» нормализуется при Apply.
- **Runtime:** согласовано с `docs/specs/gameplay/entities/Диалог.md` — реплика без person.

**Обоснование:** Единая модель с мобильным runtime.

### 6. Синтаксис `#Речь, Имя, текст` для персонажей

**Решение:** Для не-рассказчика — `#Речь, Имя, текст` (две запятые). Обновить `import-text-guide.md` на sync.

### 7. Cosmetic spacing переживает Apply

**Решение:** Двухслойная модель:

1. **Canonical DSL** — parse/merge игнорирует лишние пустые строки.
2. **Presentation layer** — после export/Apply **re-inject**:
   - prefs из `script_editor_prefs` (между scene/list/dialog);
   - **ручные** extra blank lines автора (хранятся в prefs-сессии черновика или diff-карте «между entityId A и B +N пустых»).

Ручные пустые строки **не** пишутся в store сущностей; **переживают Apply** в черновике редактора.

### 8. Inspector-only meta — inline widgets

**Решение:** Сцена (тип, фон basename, переходы, BGM имена), реплика (рамка, позиция, **размер шрифта, weight, style**), premium и т.д. — **CodeMirror inline widgets** (чипы), клик → Inspector. Под капотом export может генерировать `;` для round-trip fallback, но UI показывает чипы.

**Stat gates** — **не** widgets (см. §1).

### 9. Типографика реплики в тексте

**Решение:** Read-only отображение в чипах или рядом с заголовком реплики:

- `textWeight` (regular / semibold / bold)
- `textStyle` (normal / italic)
- **Размер шрифта реплики** — из `dialog.frameId` → `dialogFrames[id].replica.text.fontSize` (px); если нет рамки/поля — не показываем.

Правка — только Inspector; в тексте read-only.

### 10. Навигация outline ↔ текст

**Решение:**

- **Outline → текст:** без изменений контракта (scroll к строке).
- **Текст → outline:** курсор на реплике/варианте → highlight **родительского списка** (или сцены); `scrollIntoView` в outline. Реплик в дереве **нет**.

### 11. Новые UX-фичи (описание для implement)

#### Autocomplete (must-have)

- Триггеры: начало строки `#` → типы реплики; после `#Речь,` / `#Мысль,` → имена персонажей (без «Рассказчик» в списке); `; stat` / `; variant` → подсказки stat/variant; `-` под `#Выбор` → шаблон варианта.
- Источник: `import-text-guide.md` + `project.characters` + `userStats`.
- Без UUID в подсказках.

#### Preview diff перед Apply

- Модалка/панель: `+N создать`, `~M изменить`, `-K удалить` по типам (сцена/список/реплика); список warnings.
- Delete с связями — confirm как сейчас, но после общего preview.
- Кнопки: «Применить» / «Отмена».

#### Breadcrumb

- Строка над редактором: `Сцена: … › Список N › #Речь` по позиции курсора (из AST + source map).

#### Fold

- Сворачивание блоков `###` и `##` (foldGutter on).

#### Медиа basename

- В чипах фона/BGM — только имя файла (`url.split('/').pop()` или `projectAssets[name]`).

#### Font size slider

- В toolbar script mode; пишет в `script_editor_prefs.editorFontSizePx` + local apply к `.cm-editor`.

---

## Поведение (итог)

1. Сценарист открывает «Текст»; видит цветовую разметку DSL как в IDE; stat gates редактирует текстом с отдельной подсветкой.
2. `#` + autocomplete подсказывает типы; персонажи — после запятой; рассказчик — `#Речь, текст` без имени.
3. Inspector-only поля — чипы в тексте; stat gates — не чипы.
4. Чипы реплики показывают рамку, позицию, размер шрифта, weight, style (read-only).
5. Outline ↔ текст синхронны на уровне сцена/список; курсор в реплике подсвечивает список.
6. Пустые строки (ручные + prefs) сохраняются в черновике после Apply; merge их не трогает.
7. Apply показывает preview diff; затем merge; parent bugs #8/#9 исправлены в том же релизе.
8. Настройки редактора — вкладка в Story Settings + ссылка из toolbar; JSON в `stories.script_editor_prefs`.
9. В БД рассказчик — `person_uuid = null`.

---

## Acceptance criteria (финальные)

- [ ] Syntax highlighting по типам DSL + отдельная подсветка `; stat:` / `; variant:`.
- [ ] Autocomplete: типы реплики, персонажи, gates (must-have).
- [ ] Рассказчик: `#Речь, текст`; export без имени; DB `person_uuid` null.
- [ ] Inspector-meta: inline widgets; клик → Inspector; медиа — basename.
- [ ] Stat gates: editable текст + highlight (не widgets).
- [ ] Типографика реплики в чипах: fontSize (из рамки), textWeight, textStyle.
- [ ] Outline ↔ текст: scroll + highlight сцена/список (реплики в дереве нет).
- [ ] Cosmetic spacing + prefs: re-inject после Apply; prefs в JSONB + UI вкладка «Редактор» + ссылка из toolbar.
- [ ] Font size slider в toolbar.
- [ ] Preview diff перед Apply.
- [ ] Breadcrumb, fold `###`/`##`, цвета заголовков реплик.
- [ ] Parent #8 (jump dirty) и #9 (replace edges) закрыты в том же PR.
- [ ] Миграция `stories.script_editor_prefs`.
- [ ] Документация обновлена на sync.

---

## Синхронизировать в источники

- [x] `docs/web/text-editor-mode.md` — scenarist UX, widgets, highlighting, prefs, narrator
- [x] `docs/web/import-text-guide.md` — `#Речь, текст` vs `#Речь, Имя, текст`; stat gates highlight
- [x] `docs/web/user-functionality.md` — вкладка «Редактор» в settings
- [x] `supabase/migrations/` — `script_editor_prefs JSONB`
- [x] `docs/specs/gameplay/entities/Диалог.md` — примечание: конструктор map narrator → null (если нужно)
- [x] Notion — не подключен
- [x] Amend note в `web-constructor-text-editor/03-approved-spec.md` — scenarist supersede read-only meta display (widgets), не меняя текстовые поля gates

---

## Вне scope (зафиксировано)

- Stat gates как non-editable теги
- Реплики в outline
- Plain narration без `#Речь`
- H1–H6 из brief (Fountain, live preview, dictation…)
- Отдельный PR только для parent blockers
- `char-narrator` в `person_uuid` в БД

---

## Глоссарий

| Термин в коде | По-русски | Где живёт |
|---------------|-----------|-----------|
| `script_editor_prefs` | Настройки текстового редактора истории | `stories` JSONB |
| Presentation layer | Пустые строки и отступы поверх canonical DSL | `scriptEditorStore` |
| `char-narrator` | Sentinel в UI конструктора | in-memory only |
| `person_uuid = null` | Рассказчик в БД/runtime | `dialogs` |
| Meta widget | Read-only chip для inspector-only | CodeMirror decoration |
| Gate highlight | Подсветка `; stat:` / `; variant:` | CM theme |
| Preview diff | Сводка merge plan перед Apply | UI modal |

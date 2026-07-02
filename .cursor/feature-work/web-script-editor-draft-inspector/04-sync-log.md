## Резюме

Синхронизированы **3 источника** в репо по approved-spec `web-script-editor-draft-inspector`. Notion, Supabase migrations и Figma — пропущены (нет URL / не в scope). Код не менялся.

---

## Записи

### 1. Конструктор — `docs/web/text-editor-mode.md`

- **Что изменили:** раздел «Черновые реплики до Apply» (sidecar `draftDialogInspectorMetaByLine`, инспектор Base+Visual, rekey, варианты); уточнён Apply для creates vs UUID; в §Inspector-meta — **audioEvents** в чипах, store+sidecar, refresh всех inspector-only полей.
- **Пункт approved-spec:** §8, «Синхронизировать» #1

### 2. Спека в репо — `docs/specs/gameplay/entities/Диалог.md`

- **Что изменили:** поля `text_weight`, `text_style`, `audio_events`; абзац «Конструктор (веб)» — inspector-only + sidecar до Apply.
- **Пункт approved-spec:** §7, «Синхронизировать» #2

### 3. Feature work — `web-script-editor-scenarist-ux/06-review-notes.md`

- **Что изменили:** amend — checklist «Meta-чипы ✅» не покрывал draft; ссылка на `web-script-editor-draft-inspector`.
- **Пункт approved-spec:** «Синхронизировать» #3 (optional)

### 4. Notion

- **Статус:** пропущено — `meta.json.notionPageUrl` = null.

### 5. База данных (Supabase)

- **Статус:** пропущено — миграции не требуются; колонки `text_weight`, `text_style`, `frame_id`, `asset_changes` уже в `dialogs`.

### 6. Figma

- **Статус:** пропущено — не в approved-spec.

---

## Глоссарий

| Термин | Синхронизировано в |
|--------|-------------------|
| `draftDialogInspectorMetaByLine` | `text-editor-mode.md` §Черновые реплики |
| Sidecar | `text-editor-mode.md`, `Диалог.md` |
| audioEvents в чипах | `text-editor-mode.md` §Inspector-meta |

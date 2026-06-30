## Резюме

**5 источников** обновлено. **Notion:** пропущено (нет `notionPageUrl`). **Figma:** не автоправили (ручные задачи дизайнеру). **Код:** не трогали (фаза implement).

**Дата sync:** 2026-06-29

## Записи

### 1. Spec настроек (новый)

- **Файл:** `docs/specs/mobile/settings.md`
- **Что изменили:** создан canonical spec — IA hub (6 строк), Storage / About / Account, restore states, PW-08 cross-ref, компоненты Figma, вне scope v1
- **Пункт approved-spec:** #12, чеклист sync

### 2. Paywall PW-08

- **Файл:** `docs/specs/monetization/paywall.md`
- **Что изменили:** таблица PW-08 — hub rows → Push¹; секция PW-08 — подписка/покупки push на legacy screens, restore action на hub с 4 состояниями; `@see settings.md`
- **Пункт approved-spec:** #9, #3, чеклист sync

### 3. Brief

- **Файл:** `.cursor/feature-work/mobile-settings-redesign/01-brief.md`
- **Что изменили:** убран Playback; 6 строк hub; покупки → push; email на hub; AC и IA как approved
- **Пункт approved-spec:** чеклист sync

### 4. Discrepancies

- **Файл:** `.cursor/feature-work/mobile-settings-redesign/02-discrepancies.md`
- **Что изменили:** таблица решений; все 13 пунктов закрыты; остаток — Figma typo/error, i18n, delete API
- **Пункт approved-spec:** чеклист sync

### 5. Entity index (rules)

- **Файл:** `.cursor/rules/common.mdc`
- **Что изменили:** добавлена строка Settings → `docs/specs/mobile/settings.md`
- **Пункт approved-spec:** опционально по sync matrix

## Не синхронизировали (и почему)

| Источник | Причина |
|----------|---------|
| Notion | `notionPageUrl: null` в meta.json |
| Figma | skill: не автоправить макеты; typo + restore error — ручная задача |
| `mobile/src/i18n` | на фазе **implement** (в approved-spec) |
| `supabase/migrations` | delete account API TBD; схема не менялась |
| `mobile/src/**` | sync = docs only |
| Web constructor docs | вне scope фичи |

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| feature-sync | Запись approved-spec в docs/rules, без кода |
| PW-08 | Restore + вход в покупки из настроек |

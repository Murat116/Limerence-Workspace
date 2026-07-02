## Резюме

**7 замечаний:** 0 blocker, 3 major, 3 minor, 1 info.

**Готово к merge:** нет — restore error по spec недостижим; delete flow без visible processing.

**Дата review:** 2026-06-30

---

## Сводка

| # | О чём | Важность | Статус |
|---|-------|----------|--------|
| 1 | Restore error в UI никогда не срабатывает | 🟠 major | open |
| 2 | Delete account: нет processing в UI | 🟠 major | open |
| 3 | Push MySubscription/MyPurchases из nested stack — не проверено на девайсе | 🟠 major | open (QA) |
| 4 | «Выйти» с chevron (navigation row) | 🟡 minor | open |
| 5 | Subtitle storage при 0 историй без «· 0 ГБ» | 🟡 minor | open |
| 6 | `SETTINGS_LEGAL_URLS` vs spec `MONETIZATION_LEGAL_URLS` | 🟡 minor | open |
| 7 | `planStatus: draft` при `phase: implement` | ⚪ info | open |

---

## Acceptance criteria (сверка)

| AC | Статус | Комментарий |
|----|--------|-------------|
| Таб «Настройки», hub title | ✅ | `navigation.settings`, `hub.title` |
| Hub 6 строк, 3 grouped cards | ✅ | порядок как Figma |
| StorageScreen empty/list/delete Alert | ✅ | |
| Подписка/покупки → push legacy | ⚠️ | код есть; nested nav — smoke QA |
| Restore idle/loading/success/**error** | ⚠️ | error UI есть, backend не даёт rejected |
| About version + legal placeholder | ✅ | Alert при пустом URL |
| Account email, logout, 2× Alert delete | ⚠️ | alerts ok; processing UI слабый |
| Email hub + Account | ✅ | |
| Header title + «Назад» под title | ✅ | `SettingsHeader` |
| Нет Playback | ✅ | |
| Figma typo + restore error frame | — | вне кода (дизайнер) |

---

## Замечания

### 1. Restore всегда success

**По-человечески:** Строка «Восстановить покупки» показывает галочку даже когда restore реально упал — красный error из макета пользователь не увидит.

**Ожидалось (spec):** idle / loading / success / **error** на hub; error при сбое Store + server sync.

**Сейчас в коде:** `useRestorePurchasesRow` полагается на `restorePurchasesThunk().unwrap()`. `RestoreService` глотает ошибки Store; `EntitlementSyncService.syncFromServer` при сетевой ошибке возвращает пустые entitlements без throw → thunk всегда fulfilled.

**Что сделать:** Пробросить ошибку из `RestoreService` / `restorePurchasesThunk` при полном провале (offline + sync fail), либо возвращать результат `{ ok: boolean }` и в hook выставлять error.

<details>
<summary>Детали для агента</summary>

- `mobile/src/Feature/Settings/hooks/useRestorePurchasesRow.ts:41-50`
- `mobile/src/Service/Monetization/RestoreService.ts:18-24`
- `mobile/src/Service/Monetization/EntitlementSyncService.ts:17-25`
- `docs/specs/mobile/settings.md` § Restore

</details>

---

### 2. Delete account без processing в UI

**По-человечески:** После второго Alert пользователь не видит, что удаление идёт — только disabled rows.

**Ожидалось:** processing → success / error после confirm.

**Сейчас:** `isDeleting` дизейблит строки, но нет spinner на destructive row.

**Что сделать:** `SettingsRow` destructive + `trailing` ActivityIndicator при `isDeleting`; при API — `signOut().unwrap()` перед success Alert.

<details>
<summary>Детали для агента</summary>

- `mobile/src/Feature/Settings/screens/SettingsAccountScreen.tsx:57-75, 126-133`

</details>

---

### 3. Push на MySubscription / MyPurchases — smoke QA

**По-человечески:** Hub на один уровень глубже (SettingsStack внутри tab). Раньше `SettingsScreen` был прямым child таба.

**Ожидалось:** tap → push на legacy screens (PW-08).

**Сейчас:** `navigation.navigate(ROUTES.MY_SUBSCRIPTION)` из `SettingsHubScreen` — паттерн как в старом монолите, но nested stack может потребовать `getParent()?.navigate(...)`.

**Что сделать:** Smoke на симуляторе; при ошибке навигации — explicit parent navigate.

<details>
<summary>Детали для агента</summary>

- `mobile/src/Feature/Settings/screens/SettingsHubScreen.tsx:63-69`
- `mobile/src/navigation/SettingsStackNavigator.tsx`

</details>

---

### 4. «Выйти» с chevron

**По-человечески:** Logout выглядит как переход на другой экран (chevron справа), хотя это action + Alert.

**Ожидалось (Figma Account):** кнопка/строка без chevron.

**Сейчас:** `variant="navigation"` на logout row.

**Что сделать:** `variant="action"` без trailing или отдельный action variant без chevron.

---

### 5. Subtitle storage при нуле историй

**По-человечески:** При 0 историй hub показывает «0 историй» без «· 0 ГБ».

**Ожидалось:** формат «N историй · X ГБ» (spec hub table).

**Сейчас:** `hub.storageSubtitle_zero` = «0 историй» без size.

**Что сделать:** `«0 историй · {{size}} ГБ»` в ru/en/tr plural keys.

---

### 6. Имя константы legal URL

**Ожидалось (settings.md):** `MONETIZATION_LEGAL_URLS` в monetizationConstants.

**Сейчас:** `SETTINGS_LEGAL_URLS` в `settingsConstants.ts`.

**Что сделать:** переименовать/алиас к monetization constants или обновить spec.

---

### 7. План не approved

**Процесс:** `meta.json` — `planStatus: draft`, `planApprovedAt: null`, при этом код в `implement`.

**Что сделать:** approve `05-plan-*.md` или явный waive от владельца фичи.

---

## Bugbot (сводка)

| Severity | Location | Finding |
|----------|----------|---------|
| high | `useRestorePurchasesRow.ts:41` | restore error unreachable |
| medium | `ru/settings.json:5` | storageSubtitle_zero без size |
| medium | `SettingsAccountScreen.tsx:57` | signOut без unwrap после delete |

---

## Готово / не трогали

- ✅ Монолит удалён, legacy scroll path нет
- ✅ Playback не добавлен
- ✅ `@see docs/specs/mobile/settings.md` на экранах и ключевых hooks
- ✅ i18n hub/storage/account/about (ru/en/tr)
- ✅ Unit tests добавлены (jest env: `react-native-localize` mock — CI отдельно)
- — Figma typo + restore error frame (ручное)
- — Delete account API (TBD, `AccountDeletionNotConfiguredError` — ок для v1)

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| Restore row | Строка «Восстановить покупки» на hub |
| SettingsStack | Вложенный navigator вкладки Настройки |
| PW-08 | Restore + push на экраны покупок |

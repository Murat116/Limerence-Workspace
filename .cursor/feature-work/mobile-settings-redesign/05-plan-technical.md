## Резюме

Рефакторинг `Feature/Settings`: hub + 3 nested screen + 2 shared UI-компонента; nested **Settings stack** в табе; restore UI на hub поверх существующего `restorePurchasesThunk` (Redux-thunk восстановления покупок). **~15–20 файлов**, без Builder/Supabase в основном объёме (delete account — отдельный подпункт с заглушкой до RPC).

**planStatus:** draft

**Спека:** `docs/specs/mobile/settings.md`, `03-approved-spec.md`, `05-plan-human.md`

---

## Архитектура

```
TabNavigator
└─ SettingsStack (native-stack, headerShown: false)
   ├─ SettingsHubScreen          ← бывший монолитный SettingsScreen
   ├─ SettingsStorageScreen
   ├─ SettingsAboutScreen
   ├─ SettingsAccountScreen
   └─ SettingsLegalWebViewScreen  ← params: { title, url }

MainStack (существующий)
├─ MySubscriptionScreen          ← push с hub, без изменений UI
└─ MyPurchasesScreen
```

Hub и nested screens используют `useStoryStylePalette` (палитра от storyStyle активной истории на Home). Покупки — `navigation.navigate` на route MainStack (как сейчас в монолите).

---

## Фазы implement

| # | Блок | Зависимости |
|---|------|-------------|
| 1 | UI primitives + i18n keys | — |
| 2 | SettingsStack + hub | 1 |
| 3 | StorageScreen | 1, 2 |
| 4 | Restore row на hub | 2, monetization thunk |
| 5 | About + Legal WebView | 1, 2 |
| 6 | Account + logout | 2, auth thunk |
| 7 | Delete account service (stub → API) | 6 |
| 8 | Tab label «Настройки», cleanup монолита | 2 |
| 9 | Unit tests pure helpers | параллельно |

---

## Изменения по слоям

### Navigation (`mobile/src/navigation/`)

| Файл | Действие |
|------|----------|
| `types.ts` (или `RootStackParamList`) | Добавить `SettingsStackParamList`: `SettingsHub`, `SettingsStorage`, `SettingsAbout`, `SettingsAccount`, `SettingsLegalWebView: { title: string; url: string }` |
| `SettingsStackNavigator.tsx` | **Новый** — stack из 5 экранов |
| `TabNavigator.tsx` | Tab `Settings` → `SettingsStackNavigator` вместо плоского `SettingsScreen` |
| `components/AnimatedTabBar.tsx` | Label `profile` → `settings` (i18n key `tabs.settings`) |
| `MainStackNavigator.tsx` | Убедиться, что `MySubscription` / `MyPurchases` доступны с hub (`navigation.navigate('MySubscription')` или nested navigate к parent) |

**Правило:** не дублировать route для legacy purchase screens — переиспользовать существующие имена из MainStack.

### Service (`mobile/src/Service/`)

| Модуль | Действие |
|--------|----------|
| `Settings/SettingsService.ts` | Без изменений BR; опционально экспорт `getDownloadedStoriesSummary()` → `{ count, totalBytes }` для hub subtitle |
| `Settings/__tests__/SettingsService.test.ts` | Расширить если добавлен summary |
| `Account/AccountDeletionService.ts` | **Новый** facade: `deleteAccount(): Promise<void>` → пока вызывает Supabase edge/RPC или бросает `AccountDeletionNotConfiguredError` |
| `Account/AccountDeletionRepository.ts` | **Новый** — HTTP/RPC слой (TBD) |

`SettingsService.clearStoryData(storyId)` — без изменений (@see settings.md).

### Redux (`mobile/src/App/store/`)

| Модуль | Действие |
|--------|----------|
| `monetization/monetizationThunks.ts` | `restorePurchasesThunk` — **без изменений**; hub диспатчит и читает `fulfilled/rejected` |
| `auth/authThunks.ts` (или аналог) | `signOutThunk` — переиспользовать для logout |
| `monetization/monetizationSelectors.ts` | **Новый или расширить** `selectSubscriptionStatusLabel` — текст subtitle подписки на hub |

Restore UI state — **локальный** в `useRestorePurchasesRow` (не в slice): `idle | loading | success | error`. При unmount hub — сброс в idle.

### Utils / mappers (`mobile/src/Feature/Settings/utils/`)

| Файл | Действие |
|------|----------|
| `formatStorageSubtitle.ts` | Pure: `(count, bytes) => string` — «N историй · X ГБ» |
| `formatAppVersion.ts` | Pure: из `DeviceInfo.getVersion()` + build |
| `restoreRowStateMachine.ts` | Pure reducer: transitions idle→loading→success|error→idle (timeout) |

### UI — shared components (`mobile/src/Feature/Settings/components/`)

| Компонент | Figma | Варианты |
|-----------|-------|----------|
| `SettingsHeader` | 5073:1227 | `title`, `onBack`, palette |
| `SettingsRow` | 5071:1460 | `navigation` (chevron + subtitle), `action` (trailing slot), `destructive`, `value` (read-only right text) |
| `SettingsGroupedCard` | hub cards | `children` rows, radius 16, bg `rgba(255,255,255,0.03)` |
| `SettingsHubTitle` | hub 34px bold | «Настройки» |

Все — named exports, `StyleSheet.create`, palette props (не хардкод цветов).

### UI — screens (`mobile/src/Feature/Settings/screens/`)

| Screen | Файл | Ключевая логика |
|--------|------|-----------------|
| Hub | `SettingsHubScreen.tsx` | 6 rows, 3 grouped cards; subtitles; restore row; `PaywallDebugMenu` в `__DEV__` внизу scroll |
| Storage | `SettingsStorageScreen.tsx` | `useFocusEffect` → load list via `SettingsService`; delete → `Alert` → `clearStoryData` |
| About | `SettingsAboutScreen.tsx` | version row + legal rows → navigate `SettingsLegalWebView` |
| Account | `SettingsAccountScreen.tsx` | email из auth selector; logout/delete flows |
| Legal WebView | `SettingsLegalWebViewScreen.tsx` | `react-native-webview`; loading indicator; empty url guard |

Удалить или свести к re-export старый `SettingsScreen.tsx` → `SettingsHubScreen` (no legacy branch).

### Hooks (`mobile/src/Feature/Settings/hooks/`)

| Hook | Роль |
|------|------|
| `useSettingsHubData` | storage summary, subscription label, email, app version — агрегат для hub |
| `useRestorePurchasesRow` | dispatch restore + local status + auto-reset timer |
| `useStoryStylePaletteForSettings` | thin wrapper: active story from Home selector → palette |

### i18n (`mobile/src/i18n/locales/{ru,en,tr}/`)

| Файл | Ключи (примеры) |
|------|-----------------|
| `tabs.json` | `settings` (вместо/рядом с `profile`) |
| `settings.json` | `hub.title`, `hub.storage`, `hub.subscription`, `hub.purchases`, `hub.restore`, `hub.account`, `hub.about`, `storage.*`, `about.*`, `account.*`, `alerts.*`, `subscriptionStatus.*` |

### Constants

| Файл | Действие |
|------|----------|
| `monetizationConstants.ts` или `settingsConstants.ts` | `SETTINGS_LEGAL_URLS = { privacy: '', terms: '' }` — placeholder до legal |

---

## Delete account (подпункт)

**Сейчас:** RPC/edge для delete user в репо не найден.

**Implement v1:**
1. UI flow полностью по spec (2× Alert → processing).
2. `AccountDeletionService.deleteAccount()`:
   - если endpoint нет → `rejected` с понятным кодом → Alert error.
3. **Follow-up task** (вне этого PR или хвост фазы 7):
   - Supabase edge `delete-user-account` + RLS cleanup
   - migration только если нужны таблицы audit

Не оставлять stub Alert «скоро» — явная ошибка после confirm.

---

## Поведение restore row (детально)

```ts
// useRestorePurchasesRow
onPress:
  if status === 'loading' → return
  setStatus('loading')
  dispatch(restorePurchasesThunk())
    .unwrap()
    .then(() => { setStatus('success'); scheduleReset(3000) })
    .catch(() => { setStatus('error'); scheduleReset(5000) })
```

Trailing UI в `SettingsRow` action variant:
- loading → `ActivityIndicator`
- success → checkmark icon (SVG)
- error → warning/error icon

---

## Тесты (pure logic)

| Файл | Что |
|------|-----|
| `utils/__tests__/formatStorageSubtitle.test.ts` | 0 историй, 1 история, plural, GB rounding |
| `utils/__tests__/restoreRowStateMachine.test.ts` | transitions, reset timer mock |
| `utils/__tests__/formatAppVersion.test.ts` | mock DeviceInfo |

Не snapshot-тестить целые экраны в v1.

---

## Manual QA checklist

- [ ] Tab «Настройки», hub 6 строк, порядок Figma
- [ ] Storage empty + list + delete confirm
- [ ] Push MySubscription / MyPurchases
- [ ] Restore: все 4 состояния
- [ ] About → WebView (placeholder ok)
- [ ] Logout confirm + sign out
- [ ] Delete: 2 Alert + error без API
- [ ] Email на hub и Account
- [ ] Palette меняется при смене активной истории на Home
- [ ] `__DEV__` PaywallDebugMenu на месте
- [ ] Нет строки «Воспроизведение»

---

## Файлы — сводная таблица

| Действие | Путь |
|----------|------|
| New | `navigation/SettingsStackNavigator.tsx` |
| New | `Feature/Settings/screens/*.tsx` (5) |
| New | `Feature/Settings/components/*.tsx` (4) |
| New | `Feature/Settings/hooks/*.ts` (3) |
| New | `Feature/Settings/utils/*.ts` (3) |
| New | `Service/Account/AccountDeletionService.ts` |
| Edit | `navigation/TabNavigator.tsx`, `AnimatedTabBar.tsx`, types |
| Edit | `i18n/locales/*/settings.json`, `tabs.json` |
| Remove/replace | `Feature/Settings/SettingsScreen.tsx` → hub screen |

**Builder / Supabase:** вне scope, кроме optional delete-account follow-up.

---

## Глоссарий

| Термин в коде | По-русски | Где живёт |
|---------------|-----------|-----------|
| `SettingsHubScreen` | Главный экран вкладки «Настройки» | `Feature/Settings/screens/` |
| `SettingsStackNavigator` | Вложенная навигация настроек (hub → дочерние) | `navigation/` |
| `SettingsRow` | Строка списка: chevron, delete или значение справа | `Feature/Settings/components/` |
| `SettingsHeader` | Заголовок экрана + «Назад» под title | `Feature/Settings/components/` |
| `useStoryStylePalette` | Цвета UI от оформления истории | `Common/hooks/` |
| `restorePurchasesThunk` | Запрос восстановления покупок Store + сервер | `App/store/monetization/` |
| `useRestorePurchasesRow` | Локальное состояние строки restore на hub | `Feature/Settings/hooks/` |
| `SettingsService` | Локальное хранилище скачанных историй | `Service/Settings/` |
| `selectSubscriptionStatusLabel` | Текст статуса подписки для subtitle | monetization selectors |
| `signOutThunk` | Выход из аккаунта и очистка локальных данных | auth store |
| `AccountDeletionService` | Удаление аккаунта на сервере | `Service/Account/` |
| `SettingsLegalWebViewScreen` | In-app браузер для privacy/terms | `Feature/Settings/screens/` |
| `SETTINGS_LEGAL_URLS` | Placeholder URL legal-страниц | constants |
| `PaywallDebugMenu` | Dev-меню превью paywall | `Feature/Monetization/` |
| `MySubscriptionScreen` | Экран «Моя подписка» (legacy UI) | `Feature/Monetization/` |
| `MyPurchasesScreen` | Экран «Мои покупки» (legacy UI) | `Feature/Monetization/` |
| `scenario_id: subscription_hub` | Monetization-сценарий экрана подписки | monetization-ios.mdc |
| `scenario_id: my_purchases` | Monetization-сценарий экрана покупок | monetization-ios.mdc |

## Резюме

Редизайн вкладки «Настройки» для авторизованного читателя: hub по Figma + вложенные Storage / About / Account. Покупки — строки на hub с chevron → push на существующие `MySubscription` / `MyPurchases` (без их редизайна). Экран «Воспроизведение» **снят** (вне scope v1). Палитра от активной истории на Home.

**Canonical spec:** `docs/specs/mobile/settings.md`  
**Статус brief:** синхронизирован с `03-approved-spec.md` (2026-06-29)

## Что делаем

Переименовываем вкладку «Профиль» → **«Настройки»**. Вместо длинного scroll — **двухуровневая навигация**: hub (6 строк) + дочерние экраны. Блок профиля (аватар, имя) **не делаем**; email показываем на hub (subtitle) и на AccountScreen.

**Зафиксированные решения:**

| Вопрос | Решение |
|--------|---------|
| Имя вкладки и заголовка | **Настройки** |
| Гость без логина | **Невозможен** |
| Покупки | Chevron → **push** на `MySubscriptionScreen` / `MyPurchasesScreen` |
| Restore | Action на hub; idle / loading / success / **error** |
| Удаление аккаунта | **Два Alert**; без Face ID, без ввода «УДАЛИТЬ» |
| Legal | **In-app WebView** (URL placeholder ok) |
| Confirms | Нативные **Alert** |
| Палитра | От активной истории на Home |
| Playback / язык / звук | **Вне scope v1** |

## Для кого / зачем

**Авторизованный читатель** iOS/Android: управление скачанным контентом, покупками и аккаунтом через понятный hub.

## Текущее состояние (код до implement)

| Что есть | Где |
|----------|-----|
| Монолитный `SettingsScreen` | `mobile/src/Feature/Settings/SettingsScreen.tsx` |
| Storage logic | `mobile/src/Service/Settings/SettingsService.ts` |
| Legacy push-экраны покупок | `MySubscriptionScreen`, `MyPurchasesScreen` |
| i18n RU/EN/TR | `mobile/src/i18n/locales/*/settings.json` |
| PW-08 | `docs/specs/monetization/paywall.md` |
| Spec настроек | `docs/specs/mobile/settings.md` |

## Информационная архитектура

```
Таб «Настройки»
│
├─ [HUB] 6 строк (порядок как Figma 5072:1095)
│     ├─ Сохранённые истории     → StorageScreen
│     ├─ Моя подписка            → MySubscriptionScreen (legacy)
│     ├─ Мои покупки             → MyPurchasesScreen (legacy)
│     ├─ Восстановить покупки    → action на hub
│     ├─ Аккаунт                 → AccountScreen (subtitle: email)
│     └─ О приложении            → AboutScreen (subtitle: version)
│
├─ StorageScreen
├─ AboutScreen
└─ AccountScreen
```

**Не входит:** PlaybackScreen, in-app язык, toggle «Звук».

### StorageScreen

Список скачанных историй, empty state, delete по истории → Alert confirm. Прогресс на сервере не теряется.

### Покупки на hub

- Подписка / покупки — chevron → push legacy screens
- Restore — на hub, 4 состояния UI

### AboutScreen

Версия read-only; privacy / terms → WebView. Заголовок: **«О приложении»**.

### AccountScreen

«Вы вошли как {email}»; logout → Alert; delete → два Alert → API (TBD на implement).

## Acceptance criteria (финальные)

- [ ] Таб «Настройки», hub title «Настройки»
- [ ] Hub: 6 строк, порядок и группировка как Figma 5072:1095
- [ ] StorageScreen: empty + list + delete Alert
- [ ] Подписка / покупки: chevron → push legacy screens
- [ ] Restore: idle / loading / success / error на hub
- [ ] About: версия + WebView legal (placeholder URL)
- [ ] Account: email, logout Alert, delete double Alert + processing
- [ ] Email на hub (subtitle) и AccountScreen
- [ ] Header: title + «Назад» под title (Figma 5073:1227)
- [ ] **Нет** PlaybackScreen / строки «Воспроизведение»

## Вне scope

- PlaybackScreen, язык in-app, toggle «Звук»
- Редизайн `MySubscriptionScreen` / `MyPurchasesScreen`
- Блок профиля (аватар, имя)
- Face ID / ввод «УДАЛИТЬ»
- Отдельные Figma-фреймы для Alert
- Web-конструктор
- Изменение monetization BR

## Ссылки

- Notion: нет
- Figma: [hub 5072:1095](https://www.figma.com/design/l9ZhjUKBTAQNe3Vc5GHaul/Limerence-Design-Template--Copy-?node-id=5072-1095)
- Spec: `docs/specs/mobile/settings.md`
- PW-08: `docs/specs/monetization/paywall.md`

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| Settings hub | Корневой экран вкладки «Настройки» |
| SettingsRow | Ячейка списка (Figma 5071:1460) |
| SettingsHeader | Заголовок + «Назад» (Figma 5073:1227) |
| PW-08 | Restore + вход в покупки из настроек |
| Story style palette | Цвета от истории на Home |

## Резюме

Редизайн вкладки «Настройки»: hub по макету Figma + вложенные Storage / About / Account. Покупки — строки на hub с chevron → существующие push-экраны (`MySubscription`, `MyPurchases`). Экран «Воспроизведение» **снят**. Палитра от активной истории на Home.

**Статус:** approved  
**Дата:** 2026-06-29

## Решения

### 1. «Воспроизведение» (PlaybackScreen)

**Решение:** экран и строка на hub **не делаем** (вне scope v1).  
**Обоснование:** пользователь: «удалить этот экран, он не нужен». В brief это был экран с языком интерфейса (ru/en/tr) и одним toggle «Звук» — отдельная настройка не входит в v1.

### 2. Порядок и группировка hub

**Решение:** как в [Figma hub 5072:1095](https://www.figma.com/design/l9ZhjUKBTAQNe3Vc5GHaul/Limerence-Design-Template--Copy-?node-id=5072-1095).  
**Порядок:** Сохранённые истории → блок покупок (подписка, покупки, restore) → Аккаунт → О приложении.

### 3. Chevron на «Моя подписка» / «Мои покупки»

**Решение:** chevron **оставить**; tap → push на существующие `MySubscriptionScreen` / `MyPurchasesScreen` (без их редизайна).  
**Обоснование:** пользователь явно выбрал push.

### 4. Restore на hub

**Решение:** строка-action на hub; состояния idle / loading / success / **error** (error — добавить в Figma).  
**Обоснование:** пользователь подтвердил error state.

### 5. Delete account

**Решение:** два последовательных `Alert` (предупреждение → финальное подтверждение). Без Face ID, без ввода «УДАЛИТЬ».  
**Состояния:** processing / success / error после второго confirm.

### 6. Legal (privacy, terms)

**Решение:** in-app **WebView** с URL. URL пока placeholder (константы из monetization или TBD до публикации legal).  
**Обоснование:** пользователь — «просто WebView, ссылки пока нет».

### 7. Confirm dialogs

**Решение:** logout, delete storage, delete account — нативные **`Alert`**, отдельные фреймы в Figma не обязательны.

### 8. Email пользователя

**Решение:** показывать **и на hub** (subtitle строки «Аккаунт»), **и на AccountScreen** («Вы вошли как …»).  
**Не делаем:** блок профиля (аватар, имя).

### 9. PW-08 vs brief

**Решение:** **PW-08 остаётся Push** — hub-строки «Моя подписка» / «Мои покупки» ведут на существующие экраны. Brief v1 формулировку «без вложенного экрана» **отменяем**.  
**Обоснование:** согласовано с paywall.md и решением #3.

### 10. Header (дочерние экраны)

**Решение:** компонент Figma [5073:1227](https://www.figma.com/design/l9ZhjUKBTAQNe3Vc5GHaul/Limerence-Design-Template--Copy-?node-id=5073-1227) — title сверху, «Назад» под title. Canonical.

### 11. Копирайт About

**Решение:** заголовок **«О приложении»** (исправить опечатку в Figma).

### 12. Spec в репо

**Решение:** создать `docs/specs/mobile/settings.md` на фазе **feature-sync** (не в implement).

## Поведение (итог)

1. Таб и заголовок hub — **«Настройки»** (не «Профиль»).
2. Только авторизованный пользователь; гостевых состояний нет.
3. **Hub** — 6 строк в grouped cards: storage (chevron), подписка (chevron + subtitle статуса), покупки (chevron), restore (action, 4 состояния), аккаунт (chevron + email subtitle), о приложении (chevron + version subtitle).
4. **StorageScreen** — список скачанных историй, empty, delete по истории → Alert confirm.
5. **MySubscription / MyPurchases** — существующие push-экраны, UI не редизайним.
6. **Restore** — на hub, без перехода; feedback в строке (spinner / check / error).
7. **AboutScreen** — версия read-only, legal rows → WebView (URL placeholder ok).
8. **AccountScreen** — «Вы вошли как email», logout → Alert, delete → два Alert → API (TBD) + processing states.
9. Палитра — `useStoryStylePalette` от активной истории Home на hub и всех nested screens.
10. Компоненты: `SettingsRow` (variants из Figma 5071:1460), `SettingsHeader` (5073:1227).

## Acceptance criteria (финальные)

- [ ] Таб «Настройки», hub title «Настройки»
- [ ] Hub: 6 строк, порядок и группировка как Figma 5072:1095
- [ ] StorageScreen: empty + list + delete Alert
- [ ] Подписка / покупки: chevron → push legacy screens
- [ ] Restore: idle / loading / success / error на hub
- [ ] About: версия + WebView legal (placeholder URL)
- [ ] Account: email, logout Alert, delete double Alert + processing
- [ ] Email на hub (subtitle) и AccountScreen
- [ ] Header: title + «Назад» под title
- [ ] Figma: исправить «О приложении»; добавить restore error state
- [ ] **Нет** PlaybackScreen / строки «Воспроизведение»

## Синхронизировать в источники (feature-sync)

- [x] `docs/specs/mobile/settings.md` — новый spec
- [x] `docs/specs/monetization/paywall.md` — PW-08: hub rows → Push (уточнить текст)
- [x] `01-brief.md` — убрать Playback, обновить IA и AC
- [x] `02-discrepancies.md` — закрыть решения
- [ ] Figma — typo + restore error (ручное / дизайнер)
- [ ] `mobile/src/i18n` — ключи settings (на implement)

## Вне scope (зафиксировано)

- PlaybackScreen, язык in-app, toggle «Звук»
- Редизайн `MySubscriptionScreen` / `MyPurchasesScreen`
- Блок профиля (аватар, имя)
- Face ID / ввод «УДАЛИТЬ» при delete
- Отдельные Figma-фреймы для Alert (используем системные)
- Web-конструктор

## Глоссарий

| Термин | По-русски | Где |
|--------|-----------|-----|
| Settings hub | Корневой экран вкладки | `SettingsScreen` → hub |
| SettingsRow | Ячейка списка (chevron / delete / value) | Figma 5071:1460 |
| SettingsHeader | Заголовок + «Назад» | Figma 5073:1227 |
| PW-08 | Restore + вход в покупки из настроек | paywall.md |
| Story style palette | Цвета от истории на Home | `useStoryStylePalette` |

## Резюме

**13 расхождений** — все **закрыты** на фазе approve (2026-06-29).  
**Можно планировать:** да → `feature-plan` / implement.

**Figma file:** [Limerence Design Template](https://www.figma.com/design/l9ZhjUKBTAQNe3Vc5GHaul/Limerence-Design-Template--Copy-)

---

## Решения (approve → sync)

| # | Было | Решение | Spec |
|---|------|---------|------|
| 1 | Нет «Воспроизведение» на hub | **Снято** — PlaybackScreen вне v1 | settings.md § IA |
| 2 | Порядок hub ≠ brief | **Как в Figma** (account перед about) | settings.md § Hub |
| 3 | Chevron на покупках | **Оставить** → push legacy screens | settings.md, paywall PW-08 |
| 4 | Нет PlaybackScreen | **Не делаем** | settings.md § вне scope |
| 5 | Restore без error | **Error state** на hub; добавить в Figma вручную | settings.md § Restore |
| 6 | Delete flow | **Два Alert**; без Face ID / ввода «УДАЛИТЬ» | settings.md § Account |
| 7 | Нет WebView макета | **WebView в коде**; отдельный Figma-фрейм не обязателен | settings.md § About |
| 8 | Нет confirm dialogs | **Системные Alert** | settings.md § Confirms |
| 9 | Email на hub | **На hub и AccountScreen** | settings.md § Hub, Account |
| 10 | PW-08 vs brief | **PW-08 Push** — brief v1 отменён | paywall.md PW-08 |
| 11 | Header над «Назад» | **Canonical** (Figma 5073:1227) | settings.md § UI |
| 12 | «О приложение» | **«О приложении»** — правка в Figma | settings.md § About |
| 13 | Нет spec | **`docs/specs/mobile/settings.md`** создан | sync 2026-06-29 |

---

## Сводка (историческая)

| # | О чём спор | Было | Статус |
|---|------------|------|--------|
| 1 | «Воспроизведение» на hub | 🔴 blocker | ✅ Закрыто — снято |
| 2 | Порядок hub | 🔴 blocker | ✅ Figma |
| 3 | Chevron покупки | 🔴 blocker | ✅ Push |
| 4 | PlaybackScreen | 🟠 major | ✅ Вне scope |
| 5 | Restore error | 🟠 major | ✅ Error на hub |
| 6 | Delete flow | 🟠 major | ✅ 2× Alert |
| 7 | WebView макет | 🟠 major | ✅ Код WebView |
| 8 | Confirm dialogs | 🟠 major | ✅ Alert |
| 9 | Email на hub | 🟠 major | ✅ Hub + Account |
| 10 | PW-08 | 🟠 major | ✅ paywall обновлён |
| 11 | Header layout | 🟡 minor | ✅ Canonical |
| 12 | Опечатка About | 🟡 minor | ✅ Figma TBD |
| 13 | Spec в репо | ⚪ info | ✅ settings.md |

---

## Что совпало (не спор)

| Тема | Brief | Figma | Код |
|------|-------|-------|-----|
| Заголовок hub «Настройки» | ✅ | ✅ | ❌ таб «Профиль» — на implement |
| StorageScreen empty / list | ✅ | ✅ | partial |
| Restore idle/loading/success | ✅ | ✅ | ❌ UI — на implement |
| About: version + legal rows | ✅ | ✅ | ❌ — на implement |
| Account: logout + delete | ✅ | ✅ | delete stub — на implement |
| Grouped cards, SettingsRow | ✅ | ✅ | ❌ — на implement |
| Story palette от Home | ✅ | ✅ | ✅ |

---

## Осталось вручную (не sync)

- [ ] Figma: typo «О приложении»
- [ ] Figma: restore **error** state (5069:1427)
- [ ] i18n ключи — на **implement**
- [ ] Delete account API — TBD на implement

## Глоссарий

| Термин | По-русски |
|--------|-----------|
| Settings hub | Корневой экран вкладки «Настройки» |
| PW-08 | Monetization: restore + покупки из настроек |

<details>
<summary>Детали для агента (архив)</summary>

### Figma nodes

| Frame | Node |
|-------|------|
| Settings hub | 5072:1095 |
| Storage empty | 5073:1244 |
| Storage list | 5069:1271 |
| About | 5069:1381 |
| Account | 5069:1408 |
| Restore states | 5069:1427 |
| Header | 5073:1227 |
| SettingsRow | 5071:1460 |

### Key mobile paths

- `mobile/src/Feature/Settings/SettingsScreen.tsx`
- `docs/specs/mobile/settings.md`
- `docs/specs/monetization/paywall.md` § PW-08

</details>

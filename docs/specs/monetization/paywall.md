# Paywall — конечные бизнес-требования

@see [IOS_IMPL_PLAN.md](../../monetization/IOS_IMPL_PLAN.md) — технический план store-IAP  
@see [paywall-ux.md](paywall-ux.md) — UX, иерархия офферов, конверсия  
@see [RUSSIA_BILLING.md](../../monetization/RUSSIA_BILLING.md) — RU web checkout (**после запуска**, не сейчас)  
@see [analytics-events.md](../analytics-events.md)  
@see [Глава.md](../gameplay/entities/Глава.md)

**Статус:** утверждено для реализации store-monetization. Все вопросы Q-01…Q-22 закрыты.

**Notion:** актуальность сверяет продукт; расхождения с этим документом — править Notion или здесь явно.

---

## Scope


| Фаза              | Что входит                                                                                              |
| ----------------- | ------------------------------------------------------------------------------------------------------- |
| **Запуск**        | Store-IAP (`react-native-iap`), PW-01, PW-02, **PW-11**, PW-07, PW-08; `billing_channel = store` |
| **После запуска** | PW-09 (skip tokens), [RUSSIA_BILLING.md](../../monetization/RUSSIA_BILLING.md) (PW-10)                                     |
| **Снято**         | PW-03 (paywall на «Читать»), PW-04, PW-05 (gate на download), PW-06 (Story Description)                 |


---

## 1. Продукты и access model

### SKU


| SKU            | UI-название                         | Что даёт                                                                                                                       |
| -------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `subscription` | **Story Pass**                      | Весь платный контент истории; **месяц / год / trial 3 дня**                                                                    |
| `full_story`   | **Купить навсегда** (Полный доступ) | Вся история навсегда, разовая покупка                                                                                          |
| `chapter_pass` | **Chapter Pass**                    | **Только эта глава:** скрытые пути + ранний доступ + офлайн главы. **Не** блокирует онлайн-чтение сюжета после `releaseDate` |


**Приоритет entitlement:** `full_story` > `chapter_pass` (глава) > `subscription` > free.

**Цены:** price tier catalog + `purchase_intent` на сервере. В клиенте не хардкодить.


| Каталог (пример)           | Назначение                        |
| -------------------------- | --------------------------------- |
| `limerence_pass_monthly_`* | Story Pass, месяц                 |
| `limerence_pass_annual_*`  | Story Pass, год                   |
| `limerence_pass_trial_*`   | Story Pass, trial 3 дня → monthly |
| `limerence_story_tier_*`   | Полный доступ (навсегда)          |
| `limerence_chapter_tier_*` | Chapter Pass на главу             |


### Что бесплатно / платно


| Контент                                  | Бесплатно        | Нужен Pass                                             |
| ---------------------------------------- | ---------------- | ------------------------------------------------------ |
| Чтение главы после `releaseDate`         | ✅ всем           | —                                                      |
| Скрытый путь в диалоге                   | free alternative | Story Pass / Полный доступ / Chapter Pass **на главу** |
| Premium-гардероб                         | бесплатный образ | **Только** Story Pass или Полный доступ                |
| Ранний доступ до `releaseDate`           | —                | Story Pass / Полный доступ / Chapter Pass на главу     |
| Offline **чтение** главы без entitlement | —                | Limerence Plus (Story Pass) / Полный доступ / Chapter Pass (см. PW-11) |
| Offline **download**                     | ✅ всем           | —                                                      |


**Запрещено:** исключительно платные главы; paywall на CTA «Читать» за доступ к тексту; `requires_pass_to_read` / `paywall_locked` для блокировки чтения.

### Ранний доступ (Q-09)

- Окно: `now >= releaseDate - subscriberEarlyAccessDays`
- С Pass — читать **до** `releaseDate`
- После `releaseDate` — **все** читают бесплатно; paywall только на скрытые пути внутри главы

### Story Pass trial (Q-12)

- **3 дня** бесплатно; product ids `_499` / `_599` / `_699`
- Push-напоминание за 1 день до конца (day 2)
- Настройка в App Store Connect / Play

---

## 2. Архитектура и инфраструктура


| Решение          | Значение                                                                                                  |
| ---------------- | --------------------------------------------------------------------------------------------------------- |
| IAP-стек (Q-01)  | `react-native-iap` + Supabase Edge verify                                                                 |
| Платформы (Q-04) | iOS + Android, единый flow                                                                                |
| Backend (Q-03)   | `Supabase/` рядом с `LemereceRN/` и `LimerenceBuilder/` — migrations, Edge Functions                      |
| Entitlements     | `EntitlementResolver.canAccess()` — **единый gate**; при `allowed: true` paywall **не показываем** (C-03) |
| Auth             | Supabase Auth обязателен для покупки                                                                      |


```
limerenceProject/
├── LemereceRN/
├── LimerenceBuilder/
└── Supabase/
    ├── migrations/
    └── functions/
```

---

## 3. Принципы paywall

1. **Store-only при запуске** — RU web → [RUSSIA_BILLING.md](../../monetization/RUSSIA_BILLING.md) позже.
2. **Чтение бесплатно** — Chapter Pass не продаёт доступ к тексту главы.
3. **Нет paywall подписчику** — Story Pass / Полный доступ закрывают gates без UI покупки.
4. **Server-driven** — `PaywallConfig`: офферы, copy, experiments.
5. **Mixed format** — sheet / modal / push per PW.
6. **Story-themed** UI — палитра истории (Q-13).
7. **Soft skip** — PW-01, PW-02: можно продолжить без покупки.
8. **Иерархия офферов на paywall** — см. [paywall-ux.md](paywall-ux.md): блок подписки (год / месяц / trial) + «навсегда» + контекстный Chapter Pass.
9. **Контекстный copy** — заголовок и subtitle зависят от `paywall_id`.
10. **Начальное состояние paywall** — оффер **не предвыбран**; trial-switch **выключен**; CTA disabled до выбора оффера.

---

## 4. Карта paywall (запуск)


| ID         | Триггер                                  | Формат       | Офферы               | Dismiss   |
| ---------- | ---------------------------------------- | ------------ | -------------------- | --------- |
| **PW-01**  | Тап скрытого пути                        | Sheet        | Гибрид²              | Soft skip |
| **PW-02**  | Тап premium в гардеробе                  | Sheet        | Подписка + навсегда¹ | Soft skip |
| **PW-11**  | Offline **чтение** главы без entitlement | Sheet (info) | —³                   | Да        |
| **PW-11b** | Онлайн после PW-11 (deferred)            | Sheet        | Гибрид²              | Да        |
| **PW-07**  | «Читать» при `early_access` без Pass     | Modal        | Гибрид²              | Да        |
| **PW-08**  | Настройки → покупки                      | Push         | —                    | Back      |


¹ PW-02: без Chapter Pass — только блок подписки + «Купить навсегда».  
² **Гибрид** — структура офферов в [paywall-ux.md](paywall-ux.md) §«Иерархия офферов».  
³ PW-11 offline: **без StoreKit** — информационная шторка; покупка при появлении сети → PW-11b.

**Trial switch** — OFF по умолчанию; trial только с годовой подпиской (отдельный product id).

---

## 5. Детали по PW

### PW-01 — Скрытый путь

- **Gate:** `premium_variant` без entitlement (скрытый путь в диалоге)
- **Офферы:** Chapter Pass + Полный доступ + Story Pass
- **Dismiss:** «Продолжить бесплатно» → free variant
- **После покупки:** auto-select скрытый путь
- **Copy:** «Открой скрытый путь истории» / «Скрытый путь в главе «{chapter_title}»»

### PW-02 — Wardrobe

- **Gate:** `wardrobe_premium`; только Story Pass или Полный доступ
- **Dismiss:** «Оставить текущий образ»
- **Copy:** «Этот образ — premium»

### PW-11 — Offline read (без сети)

- **Gate:** пользователь **офлайн**, пытается **начать чтение** главы без entitlement на offline (нужен Chapter Pass / Полный доступ / **Limerence Plus**)
- **Формат:** информационная sheet — **покупка недоступна без интернета**
- **Copy:** «Читать офлайн можно с подпиской» / «Подключитесь к интернету, чтобы оформить Story Pass»
- **Dismiss:** закрыть; остаётся офлайн / возврат в оглавление
- **Флаг:** `pending_offline_paywall = true` (storyId, chapterId) — для deferred offer

### PW-11b — Deferred после офлайна

- **Триггер:** сеть восстановилась + есть `pending_offline_paywall` без покупки
- **Офферы:** гибрид; highlight Story Pass trial на 1-м показе
- **Copy:** «Теперь можно оформить подписку и читать офлайн»
- **Dismiss:** сбросить pending или отложить до следующего reconnect

### PW-07 — Early access

- **Триггер:** `early_access` в оглавлении, нет Pass → CTA «Читать» → PW-07
- **UI:** ячейка `early access:` + дата; с Pass → сразу `ChapterStart`
- **Copy:** «Ранний доступ» / «Глава выйдет {release_date}»

### PW-08 — Настройки

- Store restore + server merge
- Управление подпиской → App Store / Play settings

### Снятые

- **PW-03** — paywall на «Читать» (Q-22)
- **PW-06** — Story Description (Q-14)
- **PW-05** — paywall на offline download (скачивание без entitlement)
- **PW-10** — [RUSSIA_BILLING.md](../../monetization/RUSSIA_BILLING.md), после запуска

---

## 6. Оглавление (ChaptersScreen)


| status               | Ячейка                            | CTA «Читать»                            |
| -------------------- | --------------------------------- | --------------------------------------- |
| `available` / `read` | Pressable                         | → ChapterStart                          |
| `early_access`       | Pressable, `early access:` + дата | Без Pass → PW-07; с Pass → ChapterStart |
| `locked` (release)   | Не pressable                      | Скрыт                                   |


---

## 7. PaywallConfig (server-driven)

```ts
PaywallConfig {
  paywall_id: 'PW-01' | 'PW-02' | 'PW-07' | 'PW-11b'
  template: 'sheet' | 'modal' | 'fullscreen' | 'info'
  offer_groups: OfferGroup[]   // subscription | lifetime | chapter — см. Paywall-UI-UX.md
  offers: Offer[]              // sku_type, tier_key, period?: monthly | annual | trial
  highlight_sku?: SkuType
  exposure_index?: number      // 0 = первый показ; >0 = ротация highlight
  billing_channel: 'store'
  copy: PaywallCopy            // контекстный per paywall_id + exposure_index
  experiment_id?: string
}
```

---

## 8. Аналитика

События: `paywall_shown`, `paywall_cta_tapped`, `paywall_dismissed`, `purchase_started`, `purchase_completed`, `purchase_failed`, `subscription_*`, `restore_*`, `experiment_assigned`.

`billing_channel` при запуске = `store`. + `premium_choice_skipped` для PW-01 soft skip.

Дополнить [analytics-events.md](../analytics-events.md).

---

## 9. Figma (Phase 0.5)

- PW-01, PW-02, PW-07, PW-11, PW-11b, PW-08
- Story-themed; trial badge «3 дня бесплатно»
- Ячейка `early access:` в оглавлении
- Состояния: loading, error, success

---

## 10. Acceptance criteria (запуск)

- [ ] Premium variant: PW-01, soft skip работает
- [ ] Wardrobe: PW-02, soft skip работает
- [ ] Early access: PW-07 только без Pass; с Story Pass — без paywall
- [ ] Подписчик не видит paywall на покрытый контент
- [ ] Чтение главы после релиза бесплатно для всех
- [ ] Chapter Pass открывает скрытые пути в главе + early access, не текст главы
- [ ] Restore merges store + server entitlements
- [ ] Offline только с entitlement
- [ ] Trial 3 дня + месяц + год на Story Pass в сторе
- [ ] Offline read: PW-11 offline info + PW-11b при появлении сети
- [ ] Повторный тап скрытого пути после dismiss — другой highlight (ротация)

---

## Реестр решений (архив)


| #         | Ответ                                                                                |
| --------- | ------------------------------------------------------------------------------------ |
| Q-01      | `react-native-iap` + Edge                                                            |
| Q-02      | ЮKassa (самозанятый) — для **web фазы**, см. WebBilling-RU                           |
| Q-03      | `Supabase/` на уровне с app и Builder                                                |
| Q-04      | Android в scope                                                                      |
| Q-05      | Notion — сверка на стороне продукта                                                  |
| Q-06      | Story Pass = весь платный контент                                                    |
| Q-07      | Premium: Story Pass / Полный доступ / Chapter Pass на главу                          |
| Q-08      | Гардероб: только Story Pass / Полный доступ                                          |
| Q-09      | Early access — см. §1                                                                |
| Q-10      | Свой tier на главу; non-consumable                                                   |
| Q-11      | Offline при Chapter Pass / full / Story Pass                                         |
| Q-12      | Trial 3 дня                                                                          |
| Q-13      | Story-themed                                                                         |
| Q-14      | Нет paywall на Story Description                                                     |
| Q-15      | PW-09 после запуска                                                                  |
| Q-16      | Highlight per PW + experiment override                                               |
| Q-17–Q-21 | См. [RUSSIA_BILLING.md](../../monetization/RUSSIA_BILLING.md)                                           |
| Q-22      | Нет платных глав; Chapter Pass = скрытые пути + early access                         |
| Q-23      | Иерархия офферов: подписка (год/месяц/trial) + навсегда + chapter — Paywall-UI-UX.md |
| Q-24      | PW-11 offline read + PW-11b deferred при online                                      |
| Q-25      | Ротация highlight при повторном показе без покупки                                   |


---

## Несостыковки: спека ↔ код


| #    | Суть                                                  | Действие                                        |
| ---- | ----------------------------------------------------- | ----------------------------------------------- |
| C-01 | Нет paywall на «Читать»; убрать `paywall_locked` gate | Удалить PW-03 path в коде                       |
| C-02 | `Глава.md` без `early_access`                         | Обновить спеку главы                            |
| C-03 | Story Pass → без paywall если resolver OK             | `canAccess` перед `paywall_shown`; fix resolver |
| C-04 | Нет `wardrobe_premium` в resolver                     | Добавить type + gate                            |
| C-05 | Resolver не подключён к UI                            | Phase 5–6 wiring                                |
| C-06 | Нет UI `early access:` в оглавлении                   | `ChapterListItem`                               |
| C-07 | Нет analytics paywall/purchase                        | Phase 8                                         |
| C-08 | Два источника статусов                                | Только `EntitlementResolver` → UI               |


---

## Связанные документы


| Документ                                          | Назначение                           |
| ------------------------------------------------- | ------------------------------------ |
| [RUSSIA_BILLING.md](../../monetization/RUSSIA_BILLING.md)            | RU web checkout (будущее)            |
| [paywall-ux.md](paywall-ux.md)            | UX, офферы, ротация, success screens |
| `docs/monetization/ENTITLEMENTS.md`        | Resolver, формулы (создать)          |
| [Глава.md](../gameplay/entities/Глава.md) | UI оглавления                        |


---

## Чеклист

### Документация

- [x] Конечные бизнес-требования
- [x] RU web вынесен в отдельный план
- [ ] Notion синхронизирован с Q-22 / снятием PW-03
- [ ] Figma Phase 0.5
- [ ] Entitlements.md

### Реализация (запуск)

- [ ] C-01…C-08
- [ ] Store products + Edge verify
- [ ] PaywallPresenter + PW-01…08

### После запуска

- [ ] [RUSSIA_BILLING.md](../../monetization/RUSSIA_BILLING.md)
- [ ] PW-09
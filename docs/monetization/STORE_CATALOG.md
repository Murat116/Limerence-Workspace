# Store Catalog — price tiers + purchase intent + restore

## Проблема

App Store / Google Play требуют **предсозданные** product ids. Нельзя auto-generate SKU per UGC-историю.

## Решение: Price Tier Catalog + Purchase Intent

Один store SKU = **ценовая ступень**. Привязка к story/chapter/variant — на сервере через `purchase_intents`.

### Каталог v1

**Подписка (Story Pass):** `limerence_pass_monthly_499`, `_599`, `_699`, `limerence_pass_annual_3990`, `limerence_pass_trial_499`

**Chapter Pass:** `limerence_chapter_tier_1` … `tier_12` ($0.99 … $9.99) + mobile defaults `limerence_chapter_tier_199`

**Полный доступ (full_story):** `limerence_story_tier_1` … `tier_15` ($1.99 … $49.99) + mobile default `limerence_story_tier_2990`

### SKU types (`monetization_sku_type`)

| `sku_type` | User-facing | Описание |
|------------|-------------|----------|
| `subscription` | Story Pass | Платформенная подписка |
| `full_story` | Полный доступ | Разовая покупка всей истории |
| `chapter_pass` | Chapter Pass | Покупка одной главы |

### Таблицы Supabase

- `iap_price_tiers` — справочник tier_key ↔ store product ids
- `purchase_intents` — pending purchase, `id` = `appAccountToken`
- `purchase_records` — transaction_id, billing_channel, intent_id
- `user_entitlements` — subscription_expires_at, story/chapter grants
- `user_entitlements_client` — view для mobile (`expires_at` alias)

### Purchase flow (production)

1. `create_purchase_intent(...)` → `intent_id`, `store_product_id`
2. StoreKit purchase с `appAccountToken = intent_id`
3. Edge Function `verify-purchase` → `complete_purchase(..., platform=app_store)` → grant entitlement

### Mock flow (dev / до StoreKit)

1. `create_purchase_intent(..., p_env='sandbox')` → `intent_id`
2. `MockBillingAdapter.purchaseProduct(tierKey, intentId)` — симуляция StoreKit
3. `complete_purchase(intent_id, transaction_id, platform='mock')` — grant + `purchase_records`
4. Mobile: `fetchEntitlements` из `user_entitlements_client`

**Guard:** `complete_purchase` с `platform='mock'` разрешён только для intents с `env=sandbox`.

### Player config RPC

`get_player_monetization_config(story_id)` → `full_story_tier_key`, map chapter tiers (только `Story.released = true`).

### Restore

| Тип | Механизм |
|-----|----------|
| Subscription (Story Pass) | StoreKit `currentEntitlements` + server verify |
| Полный доступ / Chapter Pass | intent record + `purchase_records` (сервер — source of truth) |
| Web (РФ) | Server sync по `user_id` |
| Mock | Server sync по `user_id` (без Store restore) |

**UX:** Settings → «Восстановить покупки»; при логине — auto-sync entitlements с сервера.

### Конструктор

Автор выбирает **price tier** из dropdown, не вводит product id и не задаёт произвольную цену.

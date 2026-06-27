# Store Catalog — price tiers + purchase intent + restore

## Проблема

App Store / Google Play требуют **предсозданные** product ids. Нельзя auto-generate SKU per UGC-историю.

## Решение: Price Tier Catalog + Purchase Intent

Один store SKU = **ценовая ступень**. Привязка к story/chapter/variant — на сервере через `purchase_intents`.

### Каталог v1

**Подписка (Story Pass):** `limerence_pass_monthly_499`, `_599`, `_699`

**Chapter Pass:** `limerence_chapter_tier_1` … `tier_12` ($0.99 … $9.99)

**Полный доступ (full_story):** `limerence_story_tier_1` … `tier_15` ($1.99 … $49.99)

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

### Purchase flow

1. `create_purchase_intent(sku_type, story_id, chapter_id?)` → `intent_id`, `store_product_id`  
   `sku_type`: `full_story` | `chapter_pass` | `subscription` only
2. StoreKit purchase с `appAccountToken = intent_id`
3. Edge Function `verify_receipt` → grant entitlement → `intent.status = completed`

### Restore

| Тип | Механизм |
|-----|----------|
| Subscription (Story Pass) | StoreKit `currentEntitlements` + server verify |
| Полный доступ / Chapter Pass | intent record + `purchase_records` (сервер — source of truth) |
| Web (РФ) | Server sync по `user_id` |

**UX:** Settings → «Восстановить покупки»; при логине — auto-sync entitlements с сервера.

### Конструктор

Автор выбирает **price tier** из dropdown, не вводит product id и не задаёт произвольную цену.

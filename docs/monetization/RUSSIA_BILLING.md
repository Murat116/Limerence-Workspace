# Россия — Web Billing

## Контекст

Apple IAP недоступен для RU Apple ID. Google Play нестабилен. Покупки — через web.

## billing_channel detection

| Сигнал | channel |
|--------|---------|
| `Storefront.countryCode == RUS` | `web` |
| StoreKit IAP unavailable + locale RU | `web` |
| User: «Оплатить на сайте» | `web` |
| Иначе | `app_store` / `google_play` |

Не использовать IP-only.

## Web flow

1. Paywall PW-10: CTA «Перейти к оплате»
2. `https://limerence.app/pay?intent={id}&token={auth}`
3. Checkout (ЮKassa / CloudPayments — TBD при реализации)
4. Webhook → Edge Function → grant entitlement
5. Deep link `limerence://purchase/success?intent_id=...`
6. App polling entitlement sync

## Единый аккаунт

Entitlements на `user_id` (Supabase). Логин в app и web — один аккаунт.

## Restore в РФ

«Обновить покупки» = server entitlement sync (не Store restore).

## RuStore

v2, опционально. Тот же `purchase_intent`, `billing_channel = rustore`.

## Unit-экономика

Трекать `billing_channel` отдельно: web commission ~3–5% vs store 15–30%.

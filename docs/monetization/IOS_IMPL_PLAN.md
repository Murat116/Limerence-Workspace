# iOS Store-IAP Implementation Plan

Технический план реализации store-monetization в React Native приложении.

@see [paywall.md](../specs/monetization/paywall.md) — бизнес-требования paywall UI  
@see [PRODUCT_MODEL.md](./PRODUCT_MODEL.md) — SKU и entitlements  
@see [STORE_CATALOG.md](./STORE_CATALOG.md) — price tiers, purchase intent, mock flow  
@see [PAYWALLS.md](./PAYWALLS.md) — PW-01…PW-11 сценарии

## Current status (mock billing — done)

Server-backed mock billing работает end-to-end без StoreKit:

| Layer | Status |
|-------|--------|
| Supabase RPC | `create_purchase_intent`, `complete_purchase`, `get_player_monetization_config` |
| Mobile billing | `BillingMode` mock/store, `MockBillingAdapter`, unified `PurchaseService` pipeline |
| Entitlements | Server sync on login, purchase, restore; `user_entitlements_client` view |
| Paywall | Dynamic tier keys from author config + defaults |
| Analytics | `intent_id` on purchase events |

**Billing mode:** `EXPO_PUBLIC_BILLING_MODE=mock` (default in `__DEV__`) | `store` (release).

## Code map (mobile)

| Concern | Path |
|---------|------|
| Billing adapters | `mobile/src/Service/Monetization/billingMode.ts`, `MockBillingAdapter.ts`, `StoreBillingAdapter.ts` |
| Purchase pipeline | `PurchaseService.ts`, `MonetizationRepository.ts` |
| Config | `MonetizationConfigService.ts`, `PaywallConfigService.ts` |
| Redux | `mobile/src/App/store/monetization/` |
| UI | `mobile/src/Feature/Monetization/` |
| Gates | `mobile/src/Common/hooks/useEntitlementGate.ts` |

## StoreKit Go-Live (not implemented yet)

### 1. App Store Connect / Play Console

- [ ] Products 1:1 с `iap_price_tiers` seed (`supabase/migrations/20260701100000_monetization_billing_pipeline.sql`)
- [ ] Subscription group «Limerence Plus»: monthly `_499/_599/_699`, annual `_3990`, trial `_499` (3 days)
- [ ] Chapter tiers 1–12, Story tiers 1–15
- [ ] Sandbox testers configured

### 2. Mobile switch

```bash
cd mobile && npm install react-native-iap
```

- [ ] Implement `StoreBillingAdapter` in `StorePurchaseAdapter.ts`:
  - `getProducts`, `requestPurchase({ sku, appAccountToken: intentId })`, `getAvailablePurchases`
- [ ] Set `EXPO_PUBLIC_BILLING_MODE=store` in release builds
- [ ] `BillingSegmentService`: storefront country for RU promo (replace locale stub)

**Interface unchanged:** `PurchaseService` stays `intent → adapter → complete → sync`.

### 3. Supabase verify (replace mock)

- [ ] Edge Function `verify-purchase`:
  - iOS: App Store Server API v2 (JWS transaction)
  - Android: Play Developer API
  - Calls `complete_purchase(..., platform='app_store'|'google_play', env='prod')`
- [ ] Disable mock path for `env=prod` intents
- [ ] Subscription renewal webhook / cron for `subscription_expires_at`

### 4. Go-live checklist

- [ ] Sandbox E2E: PW-01, PW-02, PW-07, PW-11/11b, PW-08 restore
- [ ] Entitlements survive reinstall (server sync)
- [ ] Author revenue in `get_story_revenue_overview`
- [ ] Mock RPC blocked in production

## Scope (launch paywalls)

- Paywalls: PW-01, PW-02, PW-11, PW-07, PW-08
- `billing_channel = store`
- Entitlement sync через Supabase

## Out of scope (v1)

- PW-10 RU web billing → [RUSSIA_BILLING.md](./RUSSIA_BILLING.md)
- PW-09 skip tokens
- Server-driven `paywall_config` A/B

# iOS Store-IAP Implementation Plan

Технический план реализации store-monetization в React Native приложении.

@see [Paywall.md](../product/monetization/Paywall.md) — бизнес-требования paywall UI  
@see [PRODUCT_MODEL.md](./PRODUCT_MODEL.md) — SKU и entitlements  
@see [STORE_CATALOG.md](./STORE_CATALOG.md) — price tiers, purchase intent  
@see [PAYWALLS.md](./PAYWALLS.md) — PW-01…PW-11 сценарии

## Scope (запуск)

- `react-native-iap` — StoreKit integration
- Paywalls: PW-01, PW-02, PW-11, PW-07, PW-08
- `billing_channel = store`
- Entitlement sync через Supabase (`supabase/migrations/*monetization*`)

## Code map (mobile)

| Concern | Path |
|---------|------|
| Service layer | `mobile/src/Service/Monetization/` |
| Redux | `mobile/src/App/store/monetization/` |
| UI | `mobile/src/Feature/Monetization/` |
| Gates | `mobile/src/Common/hooks/useEntitlementGate.ts` |

## Implementation checklist

1. Read `docs/product/monetization/Paywall.md` before UI changes
2. Schema changes → new migration in `supabase/migrations/`
3. Store product IDs from `STORE_CATALOG.md`, never hardcode arbitrary SKUs
4. Analytics events → `docs/product/Аналитика события.md`

## Status

Stub — детализировать по мере реализации. BR source of truth: `Paywall.md`.

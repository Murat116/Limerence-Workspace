# Entitlements — resolution model

Domain reference for entitlement checks across mobile, web, and Supabase.

@see [PRODUCT_MODEL.md](./PRODUCT_MODEL.md) — SKU definitions  
@see [../specs/monetization/paywall.md](../specs/monetization/paywall.md) — paywall gates and UI  
@see [STORE_CATALOG.md](./STORE_CATALOG.md) — tiers and purchase intent

## Priority (canonical)

1. `full_story` on `story_id`
2. `chapter_pass` on `chapter_id`
3. Active `subscription` (Story Pass)
4. Free path — always available alternative variant when free-read applies

**Implementation:** `EntitlementResolver.canAccess()` — single gate. When `allowed: true`, paywall is not shown.

## Access types

| Type | Grants |
|------|--------|
| `full_story` | All chapters, all premium choices, offline, early access, wardrobe premium |
| `chapter_pass` | Hidden paths in chapter, premium choices in chapter, offline for chapter, early access for chapter |
| `subscription` | All premium content while active (Story Pass) |
| free | Read story/chapter text; premium choices need entitlement or free alternative |

## Gates (mobile)

| Gate | Required entitlement |
|------|---------------------|
| `premium_variant` | Any of full_story / chapter_pass / subscription |
| `wardrobe_premium` | full_story or subscription only |
| `early_access` | full_story / chapter_pass / subscription for chapter |
| `offline_read` | full_story / chapter_pass / subscription |

## DB tables (supabase)

- `story_monetization`, `chapter_monetization`
- `iap_price_tiers`, `purchase_intents`
- User entitlements synced from store via Edge verify

## Constructor (web)

Authors configure tiers and flags only — see [CONSTRUCTOR_IMPL_PLAN.md](./CONSTRUCTOR_IMPL_PLAN.md).

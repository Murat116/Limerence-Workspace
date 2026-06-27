# Paywall UI/UX

UX rules for mobile paywall screens. Business scenarios: [PAYWALLS.md](../../monetization/PAYWALLS.md). BR: [paywall.md](./paywall.md).

## Offer hierarchy (hybrid layout)

1. **Subscription block** — annual (highlight trial) / monthly / trial switch OFF by default
2. **Lifetime** — «Купить навсегда» (`full_story`)
3. **Chapter Pass** — contextual when PW-01 / PW-07 / PW-11b

Trial switch: OFF initially; trial only with annual subscription product.

## Initial state

- No offer pre-selected
- CTA disabled until user selects an offer
- Context copy from `PaywallConfig.copy` per `paywall_id`

## Highlight rotation

- `exposure_index`: 0 = first show; >0 = rotate highlight SKU
- Repeated tap on hidden path after dismiss → different highlight

## Story-themed UI

Palette from story `storyStyle` — not global DS colors for paywall body.

## PW-specific UX

| ID | Format | Dismiss |
|----|--------|---------|
| PW-01 | Sheet, hybrid offers | Soft skip → free variant |
| PW-02 | Sheet, sub + lifetime only | Soft skip |
| PW-07 | Modal, hybrid | Dismiss |
| PW-11 | Info sheet, no StoreKit | Close |
| PW-11b | Sheet after reconnect | Dismiss |

## Success states

Post-purchase: auto-select hidden path (PW-01); restore flows via PW-08.

@see [paywall.md](./paywall.md) §4–§5 for full scenario copy.

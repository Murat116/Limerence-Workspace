# Discrepancy matrix — monetization

Резолюции расхождений между документами. **Git docs = authority.**

| Topic | Doc A | Doc B | Resolution |
|-------|-------|-------|------------|
| Entitlement priority | `PRODUCT_MODEL.md`: full > chapter > sub > free | `paywall.md`: full > chapter > subscription > free | **Aligned** — identical |
| Story Pass scope | `PRODUCT_MODEL`: platform sub, not per-story | `paywall.md` Q-06: весь платный контент | **Aligned** |
| Free read default | `PRODUCT_MODEL` access model v2 | `paywall.md` §1, §3 | **Aligned** — free read, pass for premium |
| Chapter Pass scope | `PRODUCT_MODEL`: choices + offline + early access | `paywall.md` Q-22: hidden paths + early access, not chapter text | **Aligned** — paywall.md is authoritative for UI copy |
| Notion authority | Legacy refs in paywall.md | User decision | **Notion secondary** — update paywall checklist, no Notion sync required for code |
| Entitlements resolver | paywall.md references missing Entitlements.md | `PRODUCT_MODEL` § Entitlement resolution | **Resolved** → `docs/monetization/ENTITLEMENTS.md` |
| Paywall UX details | paywall.md refs Paywall-UI-UX.md | `PAYWALLS.md` | **Resolved** → `docs/specs/monetization/paywall-ux.md` + `PAYWALLS.md` |
| Supabase location | paywall.md §2: `limerenceProject/Supabase/` | Umbrella: `supabase/` at workspace root | **Resolved** — canonical `Limerence-Workspace/supabase/` |
| Constructor monetization | `CONSTRUCTOR_IMPL_PLAN.md` | `web.mdc` rules | **Aligned** — tier from `iap_price_tiers`, no free-form prices |
| `requires_pass_to_read` | Removed — reading always free (Q-22) | **Resolved** — column dropped; Pass unlocks premium only |
| Spec/code gaps | paywall.md C-01…C-08 | mobile code | **Track in implementation** — not doc conflict |

## Open implementation gaps (not doc conflicts)

| ID | Issue | Owner |
|----|-------|-------|
| C-01 | Remove PW-03 paywall on Read | mobile |
| C-04 | wardrobe_premium in resolver | mobile |
| C-05 | Resolver wiring to UI | mobile |
| C-06 | early access UI in ChapterListItem | mobile |

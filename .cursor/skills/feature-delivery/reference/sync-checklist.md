# Sync Checklist — после approve

Используй в `feature-sync`. Код фичи не трогать — только docs, schema, rules.

## Порядок

1. Read `03-approved-spec.md`
2. Update `docs/specs/` or `docs/monetization/` (single canonical path)
3. Check `docs/_meta/discrepancy-matrix.md` for conflicts
4. `supabase/migrations/` if schema changes
5. `.cursor/rules/` if new stable pattern
6. Run `scripts/validate-docs.sh`

## Monetization

| What | Path |
|------|------|
| Paywall BR | `docs/specs/monetization/paywall.md` |
| Domain | `docs/monetization/PRODUCT_MODEL.md` |
| Entitlements | `docs/monetization/ENTITLEMENTS.md` |
| iOS impl | `docs/monetization/IOS_IMPL_PLAN.md` |
| Constructor | `docs/monetization/CONSTRUCTOR_IMPL_PLAN.md` |
| DB | `supabase/migrations/*monetization*` |

## Gameplay

| What | Path |
|------|------|
| Entities | `docs/specs/gameplay/entities/` |
| Full flow | `docs/specs/gameplay/full-description.md` |

## Gates

- No approved spec → stop at `feature-approve`
- Item not in approved spec → do not sync

## Doc audit (post-sync)

- [ ] No broken links in changed docs (`validate-docs.sh`)
- [ ] `@see` in code points to `docs/...`
- [ ] discrepancy-matrix updated if conflict resolved

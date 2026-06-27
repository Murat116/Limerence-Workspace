# Documentation conventions

## Source of truth

**Git `docs/` in Limerence-Workspace** — единственный canonical source. Notion — для обсуждений, не для authority.

## Layers

| Layer | Prefix | Example |
|-------|--------|---------|
| **Domain** | `docs/monetization/` | PRODUCT_MODEL, STORE_CATALOG |
| **Spec** | `docs/specs/` | gameplay entities, paywall BR |
| **Impl** | `docs/monetization/*_PLAN.md`, `docs/web/` | IOS_IMPL_PLAN, constructor services |

## Scope tags

| Tag | Meaning |
|-----|---------|
| `mobile` | RN player app only |
| `web` | Author constructor only |
| `shared` | Both + supabase |
| `cross-cutting` | Spec + domain + code in multiple repos |

## Linking rules

- From code: `@see docs/specs/...` (workspace-relative)
- From docs: relative paths within `docs/`
- Cross-layer: domain doc links to spec, spec links to impl — not duplicate prose

## Change workflow

1. Update canonical doc in `docs/`
2. Update code with matching `@see`
3. Same PR/task — no spec-after-code

## Resolving conflicts

1. Check `discrepancy-matrix.md`
2. Domain layer (`PRODUCT_MODEL`) wins for SKU/entitlements
3. Spec layer (`paywall.md`) wins for UI/screen behavior
4. Update matrix with resolution

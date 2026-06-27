# Sources Map — Limerence Workspace

Workspace root: `Limerence-Workspace/`. **Git docs = source of truth.**

## Repositories

| Source | Path | Role |
|--------|------|------|
| Mobile | `mobile/` | RN player — `mobile/src/` |
| Web | `web/` | Constructor — `web/editor-app/` |
| Umbrella | `.` | `docs/`, `supabase/`, `.cursor/rules/`, `.cursor/skills/` |

## Documentation (canonical)

| Domain | Path |
|--------|------|
| Gameplay entities | `docs/specs/gameplay/entities/` |
| Gameplay flows | `docs/specs/gameplay/full-description.md`, `overview.md` |
| Paywall BR (mobile) | `docs/specs/monetization/paywall.md` |
| Paywall UX | `docs/specs/monetization/paywall-ux.md` |
| Monetization domain | `docs/monetization/` |
| Entitlements | `docs/monetization/ENTITLEMENTS.md` |
| Constructor | `docs/web/` |
| Conventions | `docs/_meta/conventions.md` |
| Discrepancies | `docs/_meta/discrepancy-matrix.md` |
| Path migration | `docs/_meta/path-mapping.md` |

## Code references

Mobile uses `@see docs/specs/...` (workspace-relative). Never `docs/specs/`.

## Supabase

Schema authority: `supabase/migrations/`. New migrations only in umbrella.

## Rules

| File | Purpose |
|------|---------|
| `documentation.mdc` | Doc system |
| `workspace-scope.mdc` | Task routing |
| `common.mdc` | Spec + comments |
| `mobile.mdc` | RN patterns |
| `web.mdc` | Constructor patterns |

## Entity index

| Entity | Spec |
|--------|------|
| Dialog | `docs/specs/gameplay/entities/Диалог.md` |
| Scene | `docs/specs/gameplay/entities/Сцена.md` |
| Chapter | `docs/specs/gameplay/entities/Глава.md` |
| Character | `docs/specs/gameplay/entities/Персонаж.md` |
| Monetization | `docs/monetization/PRODUCT_MODEL.md` |

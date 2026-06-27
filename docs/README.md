# Limerence Documentation

**Canonical source:** `Limerence-Workspace/docs/`. Notion — для обсуждений, не authority.

## Structure

| Path | Layer | Scope |
|------|-------|-------|
| [`specs/`](./specs/) | Spec | Gameplay entities, paywall BR, analytics, app policies |
| [`monetization/`](./monetization/) | Domain | SKU, catalog, entitlements, impl plans |
| [`web/`](./web/) | Impl + spec | Author constructor |
| [`architecture/`](./architecture/) | Impl | Diagrams, sequences |
| [`_meta/`](./_meta/) | Meta | Conventions, glossary, path mapping |

## Key documents

| Document | Scope | Consumers |
|----------|-------|-----------|
| [specs/gameplay/entities/Глава.md](./specs/gameplay/entities/Глава.md) | cross-cutting | mobile UI, web ChapterInspector |
| [monetization/PRODUCT_MODEL.md](./monetization/PRODUCT_MODEL.md) | shared | mobile, web, supabase |
| [specs/monetization/paywall.md](./specs/monetization/paywall.md) | mobile | Paywall UI, entitlements |
| [monetization/ENTITLEMENTS.md](./monetization/ENTITLEMENTS.md) | shared | Resolver, gates |
| [web/codebase-overview.md](./web/codebase-overview.md) | web | editor-app |
| [web/algorithm-logic.md](./web/algorithm-logic.md) | web | AnalysisService |

## Workflow

1. Read canonical doc in `docs/`
2. Implement with `@see docs/...` in code
3. Spec + code in same task

See [_meta/conventions.md](./_meta/conventions.md).

## Nested repos

Open **Limerence-Workspace** as Cursor root. Mobile `@see` paths use `docs/specs/...` (workspace-relative).

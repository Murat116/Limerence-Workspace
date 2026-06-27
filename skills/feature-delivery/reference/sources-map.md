# Sources Map — Limerence Workspace

Пути и роли источников для `feature-reconcile` и `feature-sync`. Workspace root: `Limerence-Workspace/`.

## Репозитории

| Источник | Путь (от workspace root) | Роль |
|----------|--------------------------|------|
| **Mobile (RN)** | `mobile/` | Player app — `mobile/src/`, specs via `mobile/Спецификация/` |
| **Web (constructor)** | `web/` | Author editor — `web/editor-app/` |
| **Umbrella** | `.` | `docs/`, `supabase/`, `shared/`, `.cursor/rules/`, `skills/` |

Открывай **Limerence-Workspace** как root в Cursor.

## Mobile — ключевые пути

| Область | Путь |
|---------|------|
| Спецификация | `mobile/Спецификация/` → `docs/specs/` |
| Техархитектура | `docs/specs/Техническая документация.md` |
| Features | `mobile/src/Feature/` |
| Services | `mobile/src/Service/` |
| Redux store | `mobile/src/App/store/` |
| Domain rules | `.cursor/rules/mobile.mdc` |
| Монетизация (iOS) | `docs/product/monetization/Paywall.md` |
| Supabase | `supabase/` (umbrella) |
| Артефакты workflow | `.cursor/feature-work/<feature-slug>/` |

## Web — ключевые пути

| Область | Путь |
|---------|------|
| Editor app | `web/editor-app/src/` |
| Monetization docs | `docs/monetization/` |
| Constructor docs | `docs/constructor/` |
| Domain rules | `.cursor/rules/web.mdc` |
| Supabase | `supabase/` (umbrella) |

## Shared docs

| Область | Путь |
|---------|------|
| Monetization domain | `docs/monetization/` |
| Gameplay specs | `docs/gameplay/`, `docs/specs/` |
| Product specs | `docs/product/` |
| Architecture diagrams | `docs/architecture/` |
| Notion hub (монетизация) | `docs/monetization/README.md` |

## Supabase

- **Schema authority:** `supabase/migrations/` в workspace root
- Новые migrations создавай только в `supabase/migrations/`
- Edge functions: `supabase/functions/`
- Использовать skill `supabase` для schema queries

## Figma

- URL в `meta.json` задачи (`figmaUrl`, `figmaNodeId`)
- Read-only: `get_design_context`, `get_screenshot`

## Notion

- URL в `meta.json` (`notionPageUrl`)
- Write: только в `feature-sync` после approve

## Entity index

| Сущность | Spec path |
|----------|-----------|
| Dialog | `docs/specs/Логика геймлея/Сущности/Диалог.md` |
| Dialog frame | `docs/specs/Логика геймплея/Сущности/РамкаДиалога.md` |
| Scene | `docs/specs/Логика геймплея/Сущности/Сцена.md` |
| Character | `docs/specs/Логика геймплея/Сущности/Персонаж.md` |
| Chapter | `docs/specs/Логика геймплея/Сущности/Глава.md` |
| Monetization BR | `docs/product/monetization/Paywall.md` |
| Monetization domain | `docs/monetization/` |
| Analytics | `docs/product/Аналитика события.md` |

## Domain rules (umbrella)

| Домен | Rule file |
|-------|-----------|
| Scope routing | `.cursor/rules/workspace-scope.mdc` |
| Common (specs, comments) | `.cursor/rules/common.mdc` |
| Mobile | `.cursor/rules/mobile.mdc` |
| Web | `.cursor/rules/web.mdc` |

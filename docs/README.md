# Limerence Documentation

Единый индекс документации workspace. Canonical source — эта папка `docs/`.

## Карта

| Папка | Область | Затрагивает |
|-------|---------|-------------|
| [`monetization/`](./monetization/) | SKU, paywalls, store catalog, billing, iOS impl plan | mobile + web + supabase |
| [`gameplay/`](./gameplay/) | Сущности геймплея (диалог, сцена, глава, …) | mobile (+ web preview) |
| [`product/`](./product/) | Аналитика, версии, Paywall BR | mobile |
| [`specs/`](./specs/) | Полное зеркало `Спецификация/` для symlink из mobile | mobile |
| [`constructor/`](./constructor/) | Веб-конструктор, алгоритмы, UX автора | web |
| [`architecture/`](./architecture/) | Диаграммы, sequence flows | mobile |

## Ключевые документы

| Документ | Путь |
|----------|------|
| Paywall BR (mobile UI) | `product/monetization/Paywall.md` |
| iOS IAP plan | `monetization/IOS_IMPL_PLAN.md` |
| Product model | `monetization/PRODUCT_MODEL.md` |
| Constructor codebase | `constructor/codebase-overview.md` |
| Algorithm logic | `constructor/algorithm-logic.md` |
| Gameplay overview | `specs/Логика геймплея/Логика геймплея.md` |
| Tech architecture | `specs/Техническая документация.md` |

## Правила работы со спеками

- Gameplay/product logic: spec в `docs/` → `@see` в коде → spec и код в одном PR.
- Cross-cutting фичи (monetization, analytics): сверять `docs/monetization/` и `docs/product/monetization/`.

## Symlinks

| Nested repo | Symlink | Target |
|-------------|---------|--------|
| `mobile/Спецификация` | → | `docs/specs/` |
| `mobile/docs` | → | `docs/` |
| `web/docs` | → | `docs/` |
| `web/Спецификация` | → | `docs/constructor/` |

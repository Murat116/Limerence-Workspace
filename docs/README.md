# Limerence Documentation

Единый индекс документации workspace. Canonical source — эта папка `docs/`.

## Карта

| Папка | Область | Затрагивает |
|-------|---------|-------------|
| [`monetization/`](./monetization/) | SKU, paywalls, store catalog, billing | mobile + web + supabase |
| [`gameplay/`](./gameplay/) | Сущности геймплея (диалог, сцена, глава, …) | mobile (+ web preview) |
| [`product/`](./product/) | Аналитика, версии, монетизация BR (Paywall) | mobile |
| [`constructor/`](./constructor/) | Веб-конструктор, алгоритмы, UX автора | web |
| [`architecture/`](./architecture/) | Диаграммы, sequence flows | mobile |

## Правила работы со спеками

- Gameplay/product logic: spec в `docs/` → `@see` в коде → spec и код в одном PR.
- Cross-cutting фичи (monetization, analytics): сверять `docs/monetization/` и `docs/product/monetization/`.

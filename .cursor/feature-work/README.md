# Feature Work — артефакты задач

Папка для контекста между чатами. Один slug = одна фича.

## Быстрый старт

1. Скопируй `_template/` → `<feature-slug>/`
2. Заполни `meta.json`
3. В чате: `/feature-brief`, `/feature-reconcile`, …

Полный цикл: skill **`feature-delivery`** (hub) в `.cursor/skills/feature-delivery/`.

## Структура

| Файл | Фаза |
|------|------|
| `meta.json` | метаданные, phase, ссылки |
| `01-brief.md` | feature-brief |
| `02-discrepancies.md` | feature-reconcile |
| `03-approved-spec.md` | feature-approve |
| `04-sync-log.md` | feature-sync |
| `05-plan-human.md` | feature-plan |
| `05-plan-technical.md` | feature-plan |
| `06-review-notes.md` | feature-review |

Шаблоны: `.cursor/skills/feature-delivery/reference/artifact-templates.md`

## Примеры

- `_template/` — пустые шаблоны для копирования
- `_smoke-subscription-promo-mini/` — smoke-test на реальной фиче (только brief + sample discrepancies)

## Invoke

```
/feature-delivery
/feature-brief
/feature-reconcile
/feature-approve
/feature-sync
/feature-plan
/feature-implement
/feature-review
```

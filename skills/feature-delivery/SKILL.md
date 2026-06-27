---
name: feature-delivery
description: Оркестратор полного цикла доставки фичи Limerence — brief, reconcile, approve, sync, plan, implement, review. Маршрутизирует на phase-skills, ведёт артефакты в .cursor/feature-work/. Use when user invokes /feature-delivery or starts a new screen/feature end-to-end.
disable-model-invocation: true
---

# Feature Delivery (Hub)

Оркестратор workflow. Фазы composable — можно входить с любой через `/feature-*`.

## Invoke map

| Команда | Phase skill |
|---------|-------------|
| `/feature-delivery` | hub — определяет фазу, маршрутизирует |
| `/feature-brief` | [feature-brief](../feature-brief/SKILL.md) |
| `/feature-reconcile` | [feature-reconcile](../feature-reconcile/SKILL.md) |
| `/feature-approve` | [feature-approve](../feature-approve/SKILL.md) |
| `/feature-sync` | [feature-sync](../feature-sync/SKILL.md) |
| `/feature-plan` | [feature-plan](../feature-plan/SKILL.md) |
| `/feature-implement` | [feature-implement](../feature-implement/SKILL.md) |
| `/feature-review` | [feature-review](../feature-review/SKILL.md) |

## Artifact hub

```
.cursor/feature-work/<feature-slug>/
  meta.json
  01-brief.md
  02-discrepancies.md
  03-approved-spec.md
  04-sync-log.md
  05-plan-human.md
  05-plan-technical.md
  06-review-notes.md
```

Шаблоны: [reference/artifact-templates.md](./reference/artifact-templates.md)  
Источники: [reference/sources-map.md](./reference/sources-map.md)

## Phase graph

```
brief → reconcile → approve → sync → plan → implement → review
                              ↑              ↑
                    (skip if spec ready)   review → implement (fixes)
```

Composable entry:

- Notion-задача → reconcile (brief из Notion при необходимости)
- Spec утверждён → plan
- Код готов → review

## Hub workflow (full cycle)

```
1. Определить или создать <slug>, meta.json
2. Прочитать meta.phase
3. Выполнить текущую phase skill (см. таблицу)
4. На gate — остановиться, ждать пользователя:
   - после reconcile → approve
   - после approve → sync (с подтверждением)
   - после plan draft → ревью плана
   - после implement → review
5. Обновить meta.phase и предложить следующую команду
```

## Gates (hard stops)

| Переход | Условие |
|---------|---------|
| → sync | `03-approved-spec.md` + `**Статус:** approved` |
| → implement | `planStatus: approved` в meta + оба `05-plan-*.md` |
| → done | `06-review-notes.md` без open 🔴 blockers |

## meta.json phases

`brief` | `reconcile` | `approve` | `sync` | `plan` | `implement` | `review` | `done`

## Ecosystem

| Source | Path |
|--------|------|
| RN | `/Users/anmin/iosProject/limerenceProject/LemereceRN` |
| Builder | `/Users/anmin/iosProject/limerenceProject/LimerenceBilder` |

При конфликтах: **case-by-case** — только подсветка в reconcile, решение в approve.

## Plain language

Все артефакты: [reference/plain-language-style.md](./reference/plain-language-style.md)

## New feature quick start

1. Создать slug folder + `meta.json`
2. `/feature-brief` — описание задачи
3. `/feature-reconcile` — расхождения
4. `/feature-approve` — решения
5. `/feature-sync` — docs + Notion
6. `/feature-plan` — двойной план
7. `/feature-implement` — код
8. `/feature-review` — ревью

## Do not

- Не пропускать gates без явного запроса пользователя
- Не смешивать фазы в одном шаге без подтверждения

---
name: feature-sync
description: После approve записывает утверждённый spec в Спецификация, Builder docs, Supabase migrations, Notion и rules; лог в 04-sync-log.md. Use when user invokes /feature-sync after feature-approve.
disable-model-invocation: true
---

# Feature Sync

Запись утверждённых решений во все источники. **Только документация и схема** — не код фичи.

## When to use

- `03-approved-spec.md` со статусом `approved`
- `/feature-sync` или hub после approve
- **Единственная фаза записи в Notion**

## Gate

```
IF 03-approved-spec.md missing OR status != approved
  → STOP. Message: run feature-approve first.
```

## Prerequisites

- [sync-checklist.md](../feature-delivery/reference/sync-checklist.md)
- [sources-map.md](../feature-delivery/reference/sources-map.md)
- Builder path: `/Users/anmin/iosProject/limerenceProject/LimerenceBilder` (писать из RN-сессии)

## Workflow

```
- [ ] Gate: approved-spec exists and approved
- [ ] Пройти чеклист «Синхронизировать» из 03-approved-spec
- [ ] Для каждого пункта — обновить источник, записать в 04-sync-log.md
- [ ] Notion: notion-update-page — утверждённый spec + путь к .cursor/feature-work/<slug>/
- [ ] meta.json: phase=sync
- [ ] Резюме в чат: что обновлено, что пропущено и почему
```

## Write matrix

| Источник | Действие | Примечание |
|----------|----------|------------|
| `Спецификация/` | file edit | `@see` в коде позже в implement |
| `docs/monetization/` RN | file edit | если в scope |
| `LimerenceBilder/docs/` | file edit | абсолютный путь |
| `supabase/migrations/` | new migration | skill `supabase`; сверить оба репо |
| `.cursor/rules/*.mdc` | опционально | устойчивый паттерн |
| Notion | `notion-update-page` | **только здесь** |
| Figma | комментарий | только если в approved-spec |

## Notion content template

```markdown
## Утверждённый spec
[Краткое резюме из 03-approved-spec]

## Решения
[Ключевые пункты]

## Артефакты в репо
.cursor/feature-work/<slug>/
```

## 04-sync-log.md

Plain-language резюме + по одной записи на источник. Шаблон: [artifact-templates.md](../feature-delivery/reference/artifact-templates.md).

## Do not

- Не менять `src/` (код — `feature-implement`)
- Не писать в Notion на других фазах
- Не синхронизировать пункты вне approved-spec
- Не автоправить Figma-макеты

## Next phase

→ [feature-plan](../feature-plan/SKILL.md)

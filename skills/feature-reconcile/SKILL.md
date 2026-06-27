---
name: feature-reconcile
description: Сверяет требования фичи с RN-кодом, LimerenceBilder, Supabase, Figma и Notion; пишет 02-discrepancies.md plain-language. Use when user invokes /feature-reconcile or after feature-brief.
disable-model-invocation: true
---

# Feature Reconcile

Параллельный сбор фактов из 5 источников. **Не выбирает победителя** — только расхождения и вопросы.

## When to use

- После `01-brief.md` существует
- `/feature-reconcile` или hub на фазе reconcile
- «У меня Notion-задача» — можно создать brief из Notion, затем reconcile

## Prerequisites

- `.cursor/feature-work/<slug>/01-brief.md`
- `meta.json` с путями (см. [sources-map.md](../feature-delivery/reference/sources-map.md))

## Workflow

```
- [ ] Прочитать 01-brief.md
- [ ] Запустить параллельно (readonly):
      - explore RN
      - explore Builder
      - Notion MCP (если notionPageUrl)
      - Supabase MCP / migrations в обоих репо
      - Figma MCP (если figmaUrl)
- [ ] Собрать findings в единый список
- [ ] Классифицировать severity ([discrepancy-severity.md](../feature-delivery/reference/discrepancy-severity.md))
- [ ] Записать 02-discrepancies.md ([artifact-templates.md](../feature-delivery/reference/artifact-templates.md))
- [ ] meta.json: phase=reconcile
- [ ] Резюме в чат: blocker count, нужны ли решения до плана
```

## Parallel subagents

### RN explore

```
Readonly. Path: /Users/anmin/iosProject/limerenceProject/LemereceRN
From brief: [paste acceptance criteria + feature name]
Read: Спецификация/, src/Feature/, src/Service/, src/App/store/, .cursor/rules/
Return per topic: what code does, file path, quote 1-2 lines.
Label: "Приложение (как сейчас работает)" / "Спека в репо"
```

### Builder explore

```
Readonly. Path: /Users/anmin/iosProject/limerenceProject/LimerenceBilder
Read: editor-app/src/, docs/monetization/, .cursor/rules/
Return: author-facing behavior, file path, quote.
Label: "Конструктор для авторов"
```

### Notion (MCP)

- `notion-fetch` по `meta.notionPageUrl`
- Или `notion-search` по ключевым словам из brief
- Label: «Задача в Notion»

### Supabase

- Skill `supabase` + `supabase/migrations/` в RN и Builder
- Label: «База данных»

### Figma (MCP)

- `get_design_context` с fileKey + nodeId из meta
- Label: «Макет»

## Output: 02-discrepancies.md

**Обязательно:**

1. Резюме + сводная таблица «О чём спор»
2. Карточки расхождений с «Что это значит для задачи»
3. «не описано» вместо пустых источников
4. Техтаблица только в `<details>Детали для агента</details>`
5. Глоссарий + статистика severity

См. [plain-language-style.md](../feature-delivery/reference/plain-language-style.md).

## Do not

- Не писать «правильный ответ» в reconcile
- Не обновлять Notion, spec, код
- Не использовать широкую 9-колоночную таблицу в основном тексте

## Next phase

→ [feature-approve](../feature-approve/SKILL.md)

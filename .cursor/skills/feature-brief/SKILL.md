---
name: feature-brief
description: Собирает требования к экрану или фиче Limerence, уточняет scope и acceptance criteria, пишет 01-brief.md. Use when starting a new feature, vague task without context, or when user invokes /feature-brief.
disable-model-invocation: true
---

# Feature Brief

Сбор требований перед reconcile и реализацией.

## When to use

- Сырая идея, ссылка Notion/Figma, «сделай экран X»
- `/feature-brief` или hub `feature-delivery` на фазе brief
- Пропуск reconcile невозможен без `01-brief.md`

## Prerequisites

- Создать `.cursor/feature-work/<slug>/` и `meta.json` (шаблон: [artifact-templates.md](../feature-delivery/reference/artifact-templates.md))
- Slug: kebab-case, короткий (`paywall-home-offline`, `chapter-early-access`)

## Workflow

```
- [ ] Прочитать ввод пользователя + ссылки из meta.json
- [ ] Задать уточняющие вопросы (AskQuestion): экран/фича, пользователь (читатель/автор), acceptance criteria, вне scope
- [ ] Запустить explore subagent (readonly) по RN: есть ли уже реализация?
- [ ] Записать 01-brief.md по шаблону
- [ ] Обновить meta.json: phase=brief, updatedAt
- [ ] Показать резюме пользователю; предложить /feature-reconcile
```

## Output rules

Следуй [plain-language-style.md](../feature-delivery/reference/plain-language-style.md):

- Резюме вверху — без кода
- Acceptance criteria — проверяемые чекбоксы
- «Вне scope» — явно, чтобы не раздувать задачу
- Глоссарий — любой доменный термин

## Explore subagent prompt (RN)

```
Readonly. RN repo: Limerence-Workspace/mobile
Task: find existing implementation related to [FEATURE].
Search: src/Feature/, src/Service/, docs/specs/, .cursor/rules/
Return: file paths, 1-line summary per match, gaps vs user request.
Plain Russian, no jargon without explanation.
```

## AskQuestion topics

1. Кто пользователь фичи (читатель в app / автор в Builder / оба)?
2. Что считается «готово» (3–5 критериев)?
3. Что точно не делаем в этой задаче?
4. Есть ли Notion/Figma ссылки для reconcile?

## Do not

- Не писать `02-discrepancies.md` — это `feature-reconcile`
- Не принимать решения по конфликтам источников
- Не писать код

## Next phase

→ [feature-reconcile](../feature-reconcile/SKILL.md) или hub [feature-delivery](../feature-delivery/SKILL.md)

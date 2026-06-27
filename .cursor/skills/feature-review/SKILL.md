---
name: feature-review
description: Пост-ревью реализации фичи — bugbot subagent, сверка с approved-spec и plan, замечания в 06-review-notes.md plain-language. Use when user invokes /feature-review after implement.
disable-model-invocation: true
---

# Feature Review

Ревью кода и соответствия контракту. Цикл fix → re-review до закрытия blockers.

## When to use

- Код реализован (или пользователь просит проверить diff)
- `/feature-review` или hub на фазе review
- «Код написан, проверь»

## Prerequisites

- `03-approved-spec.md`, `05-plan-technical.md`
- Желательно: `05-plan-human.md` для UX-проверки

## Workflow

```
- [ ] Прочитать approved-spec + plan
- [ ] Запустить bugbot subagent (readonly) на branch/uncommitted diff
- [ ] Сверить реализацию с acceptance criteria
- [ ] Записать 06-review-notes.md ([artifact-templates.md](../feature-delivery/reference/artifact-templates.md))
- [ ] meta.json: phase=review
- [ ] Показать сводку: open blockers
- [ ] Если blockers → feature-implement (fixes) → re-review
- [ ] Если чисто → phase=done
```

## Bugbot invocation

```
Task subagent_type: bugbot, readonly: true
Full Repository Path: Limerence-Workspace/mobile
Diff: uncommitted changes (or branch changes)
Change Description: feature <slug> per .cursor/feature-work/<slug>/03-approved-spec.md
Custom Instructions: Compare against approved-spec and 05-plan-technical. Plain Russian summaries.
```

## 06-review-notes.md structure

1. Резюме — готово к merge да/нет
2. Сводная таблица замечаний
3. Карточки: «По-человечески», ожидалось vs сейчас, что сделать
4. `<details>Детали для агента</details>` — файлы, строки
5. Severity: [discrepancy-severity.md](../feature-delivery/reference/discrepancy-severity.md)
6. Глоссарий

## Review checklist

- [ ] Все acceptance criteria из approved-spec
- [ ] Нет legacy/dead branches против spec
- [ ] `@see docs/specs/` на новой бизнес-логике
- [ ] UI copy vs Figma/spec (если применимо)
- [ ] Analytics events vs `docs/specs/analytics-events.md`
- [ ] Builder changes match approved-spec (if any)
- [ ] Tests for pure logic rules

## Fix loop

| Статус замечания | Действие |
|------------------|----------|
| 🔴 open blocker | must fix before done |
| 🟠 open major | fix unless user waives |
| closed | mark in 06-review-notes |

После fixes: обновить статусы, re-run bugbot на новый diff.

## Do not

- Не менять approved-spec без feature-approve
- Не писать vague «проверь код» без привязки к spec

## Done

Все 🔴 closed → `meta.phase = done` → сообщить пользователю.

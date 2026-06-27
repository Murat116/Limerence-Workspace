---
name: feature-plan
description: Пишет двойной план фичи — 05-plan-human.md простым языком и 05-plan-technical.md с глоссарием code-терминов. Use when user invokes /feature-plan after sync or with approved spec.
disable-model-invocation: true
---

# Feature Plan

Два плана: для человека и для реализации. Цикл ревью до `planStatus: approved`.

## When to use

- `03-approved-spec.md` approved (желательно после `feature-sync`)
- `/feature-plan` или hub на фазе plan
- «Spec утверждён, нужен только план»

## Prerequisites

- `03-approved-spec.md`
- Gate для implement: оба плана с `planStatus: approved`

## Workflow

```
- [ ] Прочитать 03-approved-spec, 01-brief, 04-sync-log
- [ ] Изучить затронутые слои RN (+ Builder если в scope)
- [ ] Написать 05-plan-human.md
- [ ] Написать 05-plan-technical.md с глоссарием
- [ ] meta.json: phase=plan, planStatus=draft
- [ ] Показать резюме; ждать ревью пользователя
- [ ] По замечаниям — править оба файла
- [ ] После OK: planStatus=approved, planApprovedAt в meta.json
```

## 05-plan-human.md

Для продакта/себя через месяц:

- User flow нумерованный
- Что увидит пользователь
- Edge cases простым языком
- Что НЕ делаем
- Резюме + глоссарий

Шаблон: [artifact-templates.md](../feature-delivery/reference/artifact-templates.md).

## 05-plan-technical.md

Для implement:

- Слои: Service → thunk → slice → Feature (см. `react-native.mdc`)
- Конкретные файлы/модули
- Builder / Supabase если в scope
- Тесты (pure logic из spec)
- **Глоссарий** — каждый code-term ([glossary-style.md](../feature-delivery/reference/glossary-style.md))

При первом упоминании термина в тексте — краткое пояснение в скобках.

## Project rules to follow

- [`react-native.mdc`](../../../rules/react-native.mdc) — layers, no legacy
- [`screen-ui.mdc`](../../../rules/screen-ui.mdc) — screens
- [`specification.mdc`](../../../rules/specification.mdc) — spec links
- Domain rules: `monetization-ios.mdc`, `quest-feature.mdc`, etc.

## Review loop

Пользователь комментирует → обновить **оба** файла → повторить до approval.

Не переходить к `feature-implement` при `planStatus: draft`.

## Do not

- Не писать production-код
- Не менять approved-spec без возврата в feature-approve
- Не оставлять технический жаргон без глоссария

## Next phase

→ [feature-implement](../feature-implement/SKILL.md)

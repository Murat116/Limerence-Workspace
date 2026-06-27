---
name: feature-implement
description: Реализует фичу в RN (и Builder если в scope) по 03-approved-spec и 05-plan-technical; следует specification.mdc и project rules. Use when user invokes /feature-implement after approved plan.
disable-model-invocation: true
---

# Feature Implement

Реализация кода по утверждённому контракту и плану.

## When to use

- `03-approved-spec.md` approved
- `05-plan-human.md` + `05-plan-technical.md` с `planStatus: approved`
- `/feature-implement` или hub на фазе implement

## Gate

```
IF planStatus != approved in meta.json
  → STOP. Run feature-plan and get user approval.
IF 03-approved-spec status != approved
  → STOP. Run feature-approve.
```

## Workflow

```
- [ ] Gate: approved spec + approved plan
- [ ] Прочитать 03-approved-spec, 05-plan-technical, 04-sync-log
- [ ] Прочитать linked specs в Спецификация/ (spec before code)
- [ ] Реализовать по слоям: Service → thunk → slice → Feature
- [ ] Builder changes — same session if in approved-spec scope
- [ ] @see Спецификация/... в новых модулях
- [ ] Тесты на pure logic из spec
- [ ] meta.json: phase=implement → review
- [ ] Предложить /feature-review
```

## Rules (mandatory)

- [`react-native.mdc`](../../../rules/react-native.mdc) — layers, **no legacy**
- [`specification.mdc`](../../../rules/specification.mdc) — spec + code together
- [`comments.mdc`](../../../rules/comments.mdc) — preserve @see and why-comments
- Domain: `monetization-ios.mdc`, `screen-ui.mdc`, `quest-feature.mdc`, etc.

## Builder

Path: `/Users/anmin/iosProject/limerenceProject/LimerenceBilder`  
Rules: `monetization-constructor.mdc` when touching monetization editor.

## Anti-patterns

```ts
// ❌ UI → Supabase directly
// ❌ Legacy branch «на всякий случай»
// ❌ Gameplay logic in reducer without thunk
// ❌ Code without spec update when BR changed
```

## Scope boundary

Только то, что в `03-approved-spec` и `05-plan-technical`.  
Вне scope → не реализовывать; предложить отдельную задачу.

## Do not

- Не менять approved-spec (нужен feature-approve)
- Не писать в Notion (уже сделано в sync)
- Не добавлять deprecated shims

## Next phase

→ [feature-review](../feature-review/SKILL.md)

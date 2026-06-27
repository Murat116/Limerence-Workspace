---
name: feature-approve
description: Проводит Q&A по расхождениям, фиксирует решения пользователя в 03-approved-spec.md — единый контракт для sync и implement. Use when user invokes /feature-approve or after feature-reconcile.
disable-model-invocation: true
---

# Feature Approve

Утверждение решений с пользователем. **Единственный контракт** для `feature-sync` и `feature-implement`.

## When to use

- `02-discrepancies.md` готов
- `/feature-approve` или hub после reconcile
- Пользователь редактирует brief/discrepancies и готов зафиксировать решения

## Prerequisites

- `01-brief.md`, `02-discrepancies.md`
- Gate для sync: без `03-approved-spec.md` со статусом `approved` → sync запрещён

## Workflow

```
- [ ] Прочитать 01-brief, 02-discrepancies
- [ ] Показать сводку: blocker/major, открытые вопросы
- [ ] AskQuestion по каждому 🔴 blocker и 🟠 major
- [ ] Принять правки пользователя в чате или файлах
- [ ] Собрать 03-approved-spec.md ([artifact-templates.md](../feature-delivery/reference/artifact-templates.md))
- [ ] Статус в файле: **approved**
- [ ] meta.json: phase=approve, approvedAt=ISO8601
- [ ] Спросить подтверждение → предложить /feature-sync
```

## AskQuestion rules

- Один вопрос — одно решение из discrepancies
- Варианты ответа — конкретные (не «как скажешь»)
- Если пользователь case-by-case: зафиксировать выбранный источник **и обоснование** в approved-spec

## 03-approved-spec.md must include

1. Резюме + `**Статус:** approved`
2. Раздел «Решения» — по каждому blocker/major
3. «Поведение (итог)» — BR простым языком
4. Финальные acceptance criteria
5. Чеклист «Синхронизировать в источники» для feature-sync
6. Глоссарий ([glossary-style.md](../feature-delivery/reference/glossary-style.md))

## Plain language

См. [plain-language-style.md](../feature-delivery/reference/plain-language-style.md). Approved-spec читается без кода — термины в глоссарии.

## Do not

- Не синхронизировать источники (это `feature-sync`)
- Не писать план и код
- Не ставить `approved` пока есть незакрытые 🔴 без явного «принимаем риск» от пользователя

## Next phase

→ [feature-sync](../feature-sync/SKILL.md)

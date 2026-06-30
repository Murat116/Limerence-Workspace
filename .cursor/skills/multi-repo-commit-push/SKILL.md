---
name: multi-repo-commit-push
description: Коммит и push изменений в трёх git-репозиториях Limerence (workspace, mobile, web). Use when user asks to commit, push, save changes to GitHub, or invokes /multi-repo-commit-push across docs/supabase/mobile/web.
disable-model-invocation: true
---

# Multi-repo commit & push

Три **независимых** git-репозитория. `mobile/` и `web/` в `.gitignore` workspace — коммитить каждый отдельно.

## Repos

| Repo | Path | Remote | Default branch |
|------|------|--------|----------------|
| **workspace** | `Limerence-Workspace/` | `Murat116/Limerence-Workspace` | `main` |
| **mobile** | `Limerence-Workspace/mobile/` | `Murat116/Limerence-RN` | `main` |
| **web** | `Limerence-Workspace/web/` | `Murat116/Limerence-Author-Web-App` | `developer` |

Подробности: [repos.md](repos.md)

## When to use

- «Закоммить и запушь»
- «Commit mobile + workspace»
- `/multi-repo-commit-push`
- После cross-cutting фичи (docs + supabase + mobile + web)

**Не использовать** без явной просьбы пользователя — см. Git Safety ниже.

## Git Safety (обязательно)

- **NEVER** `git config` (глобально или локально)
- **NEVER** `--force` push на `main`/`master`/`developer` без явного запроса
- **NEVER** `--no-verify`, `--amend` (кроме правил user rules), `push --force` на shared branches
- **NEVER** коммитить `.env`, ключи, credentials
- Коммит **только** когда пользователь попросил (этот skill = разрешение)
- Push **только** когда пользователь попросил push (по умолчанию skill включает push; если сказали «только commit» — без push)
- Сообщение коммита — HEREDOC, conventional prefix + **человекочитаемое** тело (1–2 предложения, **why** > what). См. `common.mdc` → «Commit messages — human-readable»
- После hook failure — **новый** commit, не amend (если hook не auto-fixed)

## Workflow

```
- [ ] Определить scope: все три repo или subset (workspace / mobile / web)
- [ ] Параллельно: git status + git diff + git log -5 в каждом затронутом repo
- [ ] Repo без изменений — пропустить
- [ ] Draft commit message per repo (разные сообщения — разный контекст)
- [ ] Последовательно per repo: git add → git commit → git push -u origin HEAD (если push нужен)
- [ ] После каждого commit: git status — успех
- [ ] Итог в чат: URL/branch, что закоммичено, что пропущено
```

### 1. Inspect (parallel)

```bash
git -C /Users/anmin/Limerence/Limerence-Workspace status
git -C /Users/anmin/Limerence/Limerence-Workspace diff
git -C /Users/anmin/Limerence/Limerence-Workspace log -5 --oneline

git -C /Users/anmin/Limerence/Limerence-Workspace/mobile status
git -C /Users/anmin/Limerence/Limerence-Workspace/mobile diff
git -C /Users/anmin/Limerence/Limerence-Workspace/mobile log -5 --oneline

git -C /Users/anmin/Limerence/Limerence-Workspace/web status
git -C /Users/anmin/Limerence/Limerence-Workspace/web diff
git -C /Users/anmin/Limerence/Limerence-Workspace/web log -5 --oneline
```

### 2. Map changes → repo

| Paths | Repo |
|-------|------|
| `docs/`, `supabase/`, `.cursor/`, `Makefile`, `README.md`, `scripts/` | workspace |
| `mobile/**` | mobile |
| `web/**` (обычно `web/editor-app/`) | web |

Cross-cutting monetization: часто **три коммита** — workspace (docs+migrations), mobile, web.

### 3. Commit message style

Следовать стилю последних коммитов repo и **`common.mdc` → Commit messages — human-readable**`.

- workspace: `docs: …`, `refactor(rules): …`, `chore: …`
- mobile: `feat(monetization): …`, `docs: …`
- web: `feat: …`, `docs: …`

Prefix — conventional; **тело** — полные предложения на русском (бизнес-смысл), без телеграфа и slug-цепочек.

Пример:

```bash
git -C /Users/anmin/Limerence/Limerence-Workspace commit -m "$(cat <<'EOF'
docs(monetization): чтение глав бесплатно, Pass — только premium.

Убрали requires_pass_to_read из спеки; добавили миграции billing pipeline для mock-покупок.
EOF
)"
```

### 4. Push

```bash
git -C /Users/anmin/Limerence/Limerence-Workspace push -u origin HEAD
git -C /Users/anmin/Limerence/Limerence-Workspace/mobile push -u origin HEAD
git -C /Users/anmin/Limerence/Limerence-Workspace/web push -u origin HEAD
```

**Web:** целевая ветка — `developer`, не `main`. Проверить `git branch --show-current` перед push.

### 5. Report

```markdown
## Commits pushed

| Repo | Branch | Commit | Summary |
|------|--------|--------|---------|
| workspace | main | abc1234 | … |
| mobile | main | def5678 | … |
| web | developer | … | … |

Skipped: mobile (no changes)
```

## Scope by user request

| User says | Action |
|-----------|--------|
| «всё» / без уточнения | все repo с изменениями |
| «только workspace» | только workspace |
| «mobile и web» | mobile + web |
| «commit без push» | commit only |

## Do not

- Один коммит «на всё» через workspace root — mobile/web там не tracked
- Push без проверки branch на web (`developer`)
- Смешивать unrelated changes в один repo commit «для удобства»
- Удалять чужие незакоммиченные изменения

## Failures

| Situation | Action |
|-----------|--------|
| pre-commit hook failed | fix → **new** commit |
| push rejected (non-fast-forward) | `git pull --rebase` (не force) → retry push; сообщить пользователю |
| secrets in diff | STOP, warn user, exclude files |

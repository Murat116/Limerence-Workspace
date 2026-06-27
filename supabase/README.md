# Supabase — Limerence

Schema authority для всей экосистемы Limerence. Миграции и edge functions живут здесь.

## Структура

| Папка | Назначение |
|-------|------------|
| `migrations/` | SQL migrations (история схемы) |
| `functions/` | Edge functions (Deno) |
| `manual/` | Ad-hoc SQL для ручного применения |

## Применение миграций

```bash
supabase db push
# или
supabase migration up
```

## Связь с приложениями

- `mobile/supabase` → symlink на `../supabase`
- `web/supabase` → symlink на `../supabase`

Новые migrations создавай здесь, не в nested repos.

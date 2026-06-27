# Sync Checklist — что обновлять после approve

Используй в `feature-sync`. Записывай каждое действие в `04-sync-log.md`. **Код фичи не трогать** — только docs, schema, Notion, rules.

## Общий порядок

1. Прочитать `03-approved-spec.md` — только утверждённое
2. Обновить `docs/specs/` (или `mobile/Спецификация/` symlink)
3. Обновить `docs/monetization/` / `docs/product/` при необходимости
4. Supabase migration в `supabase/migrations/` — если меняется схема
5. `.cursor/rules/*.mdc` — если новый устойчивый паттерн
6. Notion — `notion-update-page` (единственная фаза записи в Notion)

## По доменам

### Monetization

| Источник | Файлы |
|----------|-------|
| RN BR | `docs/product/monetization/Paywall.md` |
| Mobile rule | `.cursor/rules/mobile.mdc` (секция Monetization) |
| Domain docs | `docs/monetization/*.md` |
| Web rule | `.cursor/rules/web.mdc` |
| Analytics | `docs/product/Аналитика события.md` |
| DB | `supabase/migrations/*monetization*` |

### Chapter / release

| Источник | Файлы |
|----------|-------|
| Spec | `docs/specs/Логика геймплея/Сущности/Глава.md` |
| Mobile | `mobile/src/Common/models/chapter.tsx` |
| Web | `web/editor-app/src/utils/chapterRelease.ts` |

### Dialog / quest

| Источник | Файлы |
|----------|-------|
| Spec | `docs/specs/Логика геймплея/Сущности/Диалог.md`, `РамкаДиалога.md`, `Сцена.md` |
| Mobile rule | `.cursor/rules/mobile.mdc` (секция Quest) |
| Web | dialog inspectors in `web/editor-app/src/components/inspectors/` |

## Gates

- Нет `03-approved-spec.md` со статусом `approved` → **stop**, вернуть в `feature-approve`
- Пункт не в approved-spec → **не синхронизировать**

# Требования к версии приложения

@see docs/specs/Техническая документация.md

## Назначение

Удалённая политика минимальной поддерживаемой версии приложения. Пользователи с версией ниже минимальной блокируются на старте или при попытке загрузить главу.

## Источник данных

Таблица Supabase `"AppVersionPolicy"` — singleton (`id = 'default'`).

| Поле | Описание |
|------|----------|
| `is_enabled` | Включена ли проверка |
| `min_version_ios` | Минимальная semver для iOS |
| `min_version_android` | Минимальная semver для Android |
| `title`, `message` | Тексты блокирующего UI |
| `store_url_ios`, `store_url_android` | Ссылки на сторы |

## Сравнение версий

Semver `major.minor.patch`. Версия **поддерживается**, если `current >= min` для текущей платформы.

## Cold start

1. При `initializeNavigation` — fetch политики **до** auth.
2. Fetch успешен + `is_enabled` + версия устарела → fullscreen `ForceUpdateScreen` (без dismiss).
3. Fetch неуспешен + **нет** кеша историй (`@stories_domain`) → `NetworkErrorScreen` + «Обновить страницу».
4. Fetch неуспешен + **есть** кеш историй → пропуск (fail-open).
5. Fetch успешен + версия OK → обычный flow (Splash → Auth → …).

## Загрузка главы

Перед `loadCurrentChapterForStory` / `initChapterStart` prefetch — fresh fetch политики.

- Версия устарела → modal с «Обновить приложение» и «Закрыть»; глава **не** загружается.
- «Закрыть» → dismiss modal, остаёмся на ChapterStart.
- Fetch неуспешен → fail-open (глава может загрузиться).

## Аналитика

- `app_version_blocked` — `{ reason: 'outdated' | 'network', context: 'startup' | 'chapter' }`
- `app_version_update_tapped` — `{ context: 'startup' | 'chapter' }`

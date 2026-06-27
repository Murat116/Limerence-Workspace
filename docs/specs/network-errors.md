# Сетевые ошибки — поведение приложения

Документ фиксирует кейсы N-01…N-15 из инвентаря сетевых сбоев.

## N-01 — Первый запуск без интернета

Полноэкранный `NetworkErrorScreen`, retry → `checkAppVersionPolicy`. Без кеша историй вход заблокирован.

## N-02 — Запуск offline с кешем историй

`AppVersionService.resolveStartupGate` → fail-open, каталог из локального хранилища.

## N-03 — Проверка обновлений каталога

Offline → `checkUpdates` вызывает `StoriesService.checkForUpdates()`; при ошибке сети `UpdateCheckService` возвращает `storiesNeedUpdate: false` (кеш, без force-sync).

## N-04 — Прогресс при старте

`UserProgressLocalCache` (AsyncStorage). При fail `loadAllUserProgress` → локальный snapshot + merge checkpoint.

## N-05 — Ошибка входа

`LoginScreen` → `Alert` с текстом про сеть / «Попробуйте позже». Helper: `isNetworkError`.

## N-06 — Каталог offline

Без изменений — cache-first.

## N-07 — Не удалось начать чтение

`StoryDescriptionScreen` → Alert. Кнопка «Читать» disabled без `userProgress` в Redux.

## N-08 / N-09 / N-14 — Ошибки подготовки главы

`ChapterStartErrorView`: «Повторить» / «Назад». `contentUpdate.phase === 'error'` → Error view. Единый текст `CHAPTER_NETWORK_ERROR_MESSAGE`.

## N-10 — Loader в Quest

Вся подготовка на `ChapterStart` (`prepareChapterForQuest`: persons, dialog frames). `QuestScreen` без spinner.

## N-11 / N-12 — Позиция и варианты offline

`ProgressSyncQueue` + `ProgressSyncService.flush()` при foreground / online. `ReadingProgressService` — checkpoint локально, RPC в очередь.

## N-13 — Завершение главы offline

`PendingChapterCompletionManager`. `ChapterEndingScreen`: retry, «Следующая глава» disabled при ошибке.

## N-14 — Restart offline

Fail → `ChapterStart` с `initialErrorMessage`. Checkpoint clear только после успешного RPC.

## N-15 — Версия перед главой

Fail-open при offline — без изменений.

## Общие утилиты

- `isNetworkError` — эвристика для user-facing copy (Alert, сообщения ChapterStart)

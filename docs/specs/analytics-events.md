# Аналитика — каталог событий

Milestone-события RN → `analytics_events`. Не логируем каждый тап/реплику.

См. [Аналитика техническая.md](./analytics-technical.md) — pipeline, batching, `context_scope`.

---

## App / Auth

| event | scope | properties | Зачем |
|-------|-------|------------|-------|
| `app_session_start` | app | — | Cold start / новая session |
| `screen_view` | app | `screen_name` | Навигация вне quest |
| `auth_login_success` | auth | `provider` | Воронка auth |
| `auth_login_failed` | auth | `provider`, `error_code?` | Ошибки входа |
| `auth_logout` | auth | — | Выход |
| `app_version_blocked` | app | `reason`, `context` | Блокировка устаревшей версии / сети |
| `app_version_update_tapped` | app | `context` | Тап «Обновить приложение» |

---

## Discovery

| event | scope | context | properties | Зачем |
|-------|-------|---------|------------|-------|
| `story_opened` | discovery | `storyId` | — | Открытие карточки истории |
| `chapter_list_opened` | discovery | `storyId` | — | Список глав |
| `chapter_start_tapped` | discovery | `storyId` | `chapter_id` | Намерение начать главу |
| `story_reading_started` | discovery | `storyId` | — | Первый заход в чтение |

---

## Download

| event | scope | context | properties | Зачем |
|-------|-------|---------|------------|-------|
| `chapter_download_started` | quest | story + chapter | — | Начало загрузки контента |
| `chapter_download_completed` | quest | story + chapter | — | Успех |
| `chapter_download_failed` | quest | story + chapter | `error_code?` | Ошибка |
| `chapter_download_cancelled` | quest | story + chapter | — | Отмена |

---

## Quest / Reading

| event | scope | context | properties | Зачем |
|-------|-------|---------|------------|-------|
| `quest_session_start` | quest | story + chapter | — | Сессия чтения главы |
| `quest_session_end` | quest | story + chapter | `duration_sec?` | Конец сессии |
| `quest_scene_entered` | quest | story + chapter | `scene_id`, `scene_type` | Воронка сцен (author: dropoff RPC) |
| `quest_dialog_list_entered` | quest | story + chapter | `scene_id`, `dialog_list_id` | Глубина диалогов |
| `variant_selected` | quest | story + chapter | `variant_id`, `scene_id?` | Выборы (author: variant stats) |
| `wardrobe_session_completed` | quest | story + chapter | — | Гардероб |
| `cutscene_completed` | quest | story + chapter | `scene_id?` | Катсцены |
| `chapter_completed` | quest | story + chapter | — | Завершение главы (progress) |
| `chapter_restarted` | quest | story + chapter | — | Рестарт |
| `chapter_ending_viewed` | quest | story + chapter | `ending_id` | Концовка (author: ending stats) |

---

## Monetization

@see [Paywall.md](./monetization/paywall.md) — § Monetization, §8 UX

| event | scope | context | properties | Зачем |
|-------|-------|---------|------------|-------|
| `paywall_shown` | paywall | `storyId?`, `chapterId?` | `scenario_id`, `exposure_index`, `highlight_sku?`, `offer_layout?` | Показ paywall |
| `paywall_cta_tapped` | paywall | `storyId?`, `chapterId?` | `scenario_id`, `sku_type`, `tier_key?`, `period?` | Тап CTA оффера |
| `paywall_dismissed` | paywall | `storyId?`, `chapterId?` | `scenario_id`, `exposure_index` | Dismiss без покупки |
| `purchase_started` | paywall | `storyId?`, `chapterId?` | `intent_id`, `sku_type`, `tier_key` | Старт StoreKit |
| `purchase_completed` | paywall | `storyId?`, `chapterId?` | `intent_id`, `sku_type` | Успех |
| `purchase_failed` | paywall | `storyId?`, `chapterId?` | `intent_id`, `error_code?` | Ошибка / cancel |
| `premium_choice_skipped` | quest | story + chapter | `variant_id`, `paywall_id` | PW-01 soft skip |
| `offline_read_reminder_set` | paywall | `storyId?`, `chapterId?` | — | PW-11 CTA «Напомнить…» |
| `offline_subscription_banner_shown` | paywall | — | `trigger` (`offline_reminder` \| `first_home_visit_ru`), `surface` (`mini` \| `sheet`) | Баннер подписки на Home |
| `subscription_promo_mini_dismissed` | paywall | — | `trigger` | ✕ на mini-баннере |
| `subscription_info_opened` | paywall | — | `status` (`active` \| `trial` \| `expired`) | PW-12A |
| `restore_completed` | paywall | — | `restored_count?` | PW-08 |

---

## Author metrics mapping

| Author RPC | Источник данных |
|------------|-----------------|
| `get_story_analytics_overview` | `UserProgress` (filtered) |
| `get_story_chapter_funnel` | `UserProgress` + `UserChapterProgress` |
| `get_story_scene_dropoff` | `UserChapterProgress.viewed_scene_ids` |
| `get_story_variant_stats` | `UserChapterProgress.chosen_variant_ids` |
| `get_story_analytics_trend` | `analytics_events` (chapter_completed / story_reading_started) |
| `get_story_dialog_dropoff` | events + progress |
| `get_story_platform_breakdown` | `analytics_events.platform` in properties |
| `get_story_ending_stats` | `chapter_ending_viewed.ending_id` |

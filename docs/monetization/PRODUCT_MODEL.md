# Limerence — продуктовая модель монетизации (утверждено)

Статус: **утверждено** для v1. Дата: 2026-06-17 (обновлено 2026-06-28).

## SKU

### Story Pass (платформенная подписка)

Бывш. Limerence Pass. Коммерческое имя подписки, **не привязано к конкретной истории**.

- Офлайн-чтение
- Все premium-выборы бесплатны (v1: `premium_choice_mode = all_unlocked`)
- Ранний доступ к главам
- Premium-элементы гардероба
- Цена старт: **$4.99–6.99/мес** (A/B через отдельные store product ids)
- Internal `sku_type`: `subscription`

### Разовые покупки (non-consumable, per-story)

| SKU (UI) | Internal | Entitlements |
|----------|----------|--------------|
| **Полный доступ** | `full_story` | Вся история навсегда: все главы, все выборы, офлайн, ранний доступ |
| **Chapter Pass** | `chapter_pass` | Одна глава: все выборы в главе, офлайн, ранний доступ к главе |

Premium-выборы **не продаются поштучно**. Доступ: Story Pass, Полный доступ или Chapter Pass. Иначе — бесплатный alternative variant.

## Access model v2

| Режим | Поведение |
|-------|-----------|
| **По умолчанию** | История/глава читается бесплатно; без Pass/подписки недоступны premium-выборы, гардероб, ранний доступ |

Блокировка чтения текста истории/главы **запрещена** (paywall.md Q-22). Pass открывает premium-контент, не доступ к тексту.

Нет `free_chapters_count`, нет toggle `enabled` — монетизация «активна», если есть настройки (tier, флаги, premium-варианты).

## Entitlement resolution (приоритет)

1. `full_story` на `story_id`
2. `chapter_pass` на `chapter_id`
3. Активная `subscription` (Story Pass)
4. Free path (бесплатный variant всегда доступен при free-read)

## Ранний доступ

- `Chapter.release_date` — публичный релиз
- **3 дня** до `release_date` — фиксированное окно для Story Pass, Полного доступа и Chapter Pass (не настраивается авторами)

## Не входит в v1

- Виртуальная валюта (gems)
- Energy/keys
- Per-story подписка

## Связанные документы

- [STORE_CATALOG.md](./STORE_CATALOG.md)
- [PAYWALLS.md](./PAYWALLS.md)
- [RUSSIA_BILLING.md](./RUSSIA_BILLING.md)
- [REVENUE_SHARE.md](./REVENUE_SHARE.md)
- [UNIT_ECONOMICS_V2.md](./UNIT_ECONOMICS_V2.md)

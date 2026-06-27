# Paywall System — карта точек и A/B

## Paywall IDs

| ID | Триггер | Тип | Default CTA order | Hard/Soft |
|----|---------|-----|-------------------|-----------|
| PW-01 | Тап premium-variant | Inline sheet | Sub → Chapter Pass → Free | Soft |
| PW-02 | Premium wardrobe | Inline sheet | Sub → Полный доступ → Skip | Soft |
| PW-03 | Paywall-locked глава | Full modal | Chapter → Полный доступ → Sub | Hard |
| PW-05 | Офлайн download | Bottom sheet | Sub → Pass | Hard |
| PW-06 | Story detail | Banner | Полный доступ → read free | Soft |
| PW-07 | Early access teaser | Modal | Sub → Chapter → «Откроется DATE» | Hard |
| PW-08 | Settings upgrade | Screen | Sub benefits | Soft |
| PW-09 | N× premium skip | Toast | Sub | Soft |
| PW-10 | РФ / web billing | Web bridge | Web pay CTA | Hard |

**Removed:** PW-04 «конец free глав» — `free_chapters_count` больше нет; чтение бесплатно по умолчанию.

## Server-driven PaywallConfig

```typescript
type PaywallConfig = {
  paywall_id: string;
  experiment_variant?: string;
  headline: string;
  subheadline?: string;
  offers: OfferCard[];
  primary_cta: 'subscription' | 'full_story' | 'chapter_pass' | 'free' | 'web';
  show_free_path: boolean;
  dismissible: boolean;
  billing_channel: 'store' | 'web';
};
```

## A/B параметры

| Key | Эффект |
|-----|--------|
| `paywall_pw01_cta_order` | Порядок офферов на PW-01 |
| `paywall_pw01_headline` | Заголовок PW-01 |
| `paywall_pw03_hardness` | Hard vs preview на paywall-locked chapter |
| `paywall_show_full_story` | Полный доступ на chapter paywall |
| `paywall_sub_badge` | Badge «Лучшее предложение» |
| `paywall_dismiss_delay` | Задержка «Пропустить» (сек) |
| `pw09_trigger_threshold` | Skip count для PW-09 |
| `subscription_price_tier` | Sub product id |
| `premium_choice_mode` | `all_unlocked` \| `monthly_quota` |

## Analytics events

- `paywall_shown` — paywall_id, experiment_variant, offers_shown
- `paywall_cta_tapped` — paywall_id, offer_type
- `purchase_started` / `purchase_completed` / `purchase_failed`
- `subscription_started` / `subscription_renewed` / `subscription_cancelled`
- `experiment_assigned`

Scope `paywall` зарезервирован в iOS спецификации аналитики.

## Decision flow

Entitlement priority: `full_story` > `chapter_pass` > `subscription` (Story Pass) > free read.

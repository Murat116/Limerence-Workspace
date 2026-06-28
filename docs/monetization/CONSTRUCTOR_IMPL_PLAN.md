# Implementation Plan — LimerenceBilder (конструктор)

Порядок выполнения. Зависимости: [PRODUCT_MODEL.md](./PRODUCT_MODEL.md), [STORE_CATALOG.md](./STORE_CATALOG.md).

## Phase 1 — Database ✅

**Migration:** `supabase/migrations/20260628100000_monetization_access_model.sql`

- `story_monetization`: `full_story_tier_key` (no `enabled`, `free_chapters_count`)
- `chapter_monetization`: `chapter_pass_tier_key` (no `is_free`)
- `monetization_sku_type`: `full_story` (was `story_pass`)

## Phase 2 — Types & mappers ✅

- `editor-app/src/types/monetization.ts`
- `utils/monetizationActive.ts` — derived `isStoryMonetizationConfigured`
- `utils/monetizationLabels.ts` — SKU display labels

## Phase 3 — Services ✅

- `MonetizationService.ts`, `DataMappingService.ts`, `AnalysisService.ts`
- `CascadeValidationService` — premium variant MUST have free sibling

## Phase 4 — UI ✅

### Story Settings (`/story/:storyId/settings/:tab`)

Tabs: general, frames, colors, monetization, analytics. Gear icon in ProjectTree.

### Monetization tab

- Help block (Story Pass, Полный доступ, Chapter Pass, premium choices; текст истории/глав бесплатен после релиза)
- `full_story` tier dropdown (optional)
- Per-chapter `chapter_pass` tier dropdown

### ChapterInspector

- Release flag + `release_date` (единственный gate доступности текста главы)
- Подсказка: Pass/подписка — ранний доступ и premium, не блокировка текста

### VariantsEditor

- `is_premium` checkbox only (no `premium_category` in UI)

## Phase 5 — Analytics ✅

- `get_story_revenue_overview`, `get_story_premium_choice_stats` — derived `enabled`, `full_story` sku
- `RevenueTab.tsx` — `isStoryMonetizationConfigured`, `getSkuLabel`

## Phase 6 — Tests ✅

- `monetizationActive.test.ts`, `DataMappingService.test.ts`, `AnalysisService.monetization.test.ts`, `chapterRelease.test.ts`

## Acceptance criteria

- [x] Author selects tier from dropdown; no manual product id
- [x] Premium choice without free path blocked on publish
- [x] Chapter early access preview shows correct dates
- [x] Settings route replaces BookModal
- [x] No monetization toggle / free chapters count

## Out of scope (iOS team)

- StoreKit, purchase intents from client, receipt verify — see LemereceRN `IOS_IMPL_PLAN.md`

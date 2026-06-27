-- Monetization: entitlements, purchase intents, paywall config
-- @see Спецификация/Монетизация/Paywall.md §7

create table if not exists public.user_entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  sku_type text not null check (sku_type in ('subscription', 'full_story', 'chapter_pass')),
  story_id uuid null,
  chapter_id uuid null,
  expires_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists user_entitlements_user_id_idx on public.user_entitlements (user_id);

create table if not exists public.purchase_intents (
  intent_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  sku_type text not null,
  tier_key text not null,
  story_id uuid null,
  chapter_id uuid null,
  status text not null default 'pending' check (status in ('pending', 'completed', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists purchase_intents_user_id_idx on public.purchase_intents (user_id);

create table if not exists public.paywall_config (
  paywall_id text primary key,
  config jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.user_entitlements enable row level security;
alter table public.purchase_intents enable row level security;
alter table public.paywall_config enable row level security;

create policy "Users read own entitlements"
  on public.user_entitlements for select
  using (auth.uid() = user_id);

create policy "Users read own intents"
  on public.purchase_intents for select
  using (auth.uid() = user_id);

create policy "Paywall config read authenticated"
  on public.paywall_config for select
  to authenticated
  using (true);

create or replace function public.create_purchase_intent(
  p_user_id uuid,
  p_sku_type text,
  p_tier_key text,
  p_story_id uuid default null,
  p_chapter_id uuid default null
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_intent_id uuid;
begin
  if auth.uid() is distinct from p_user_id then
    raise exception 'forbidden';
  end if;

  insert into public.purchase_intents (user_id, sku_type, tier_key, story_id, chapter_id)
  values (p_user_id, p_sku_type, p_tier_key, p_story_id, p_chapter_id)
  returning intent_id into v_intent_id;

  return v_intent_id;
end;
$$;

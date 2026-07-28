-- ============================================================================
-- Mangasm — 0007 billing (Mangasm+ subscriptions)
-- Web subscription rail via Stripe Checkout. Apple IAP receipts land in the
-- same tables later (source = 'apple') so membership sync has one code path.
--
-- Money flow: stripe-checkout fn creates a Checkout Session → member pays on
-- Stripe → stripe-webhook fn upserts billing_subscriptions → trigger syncs
-- profiles.membership, which every existing is_premium() gate already reads.
-- ============================================================================

-- One Stripe customer per member.
create table if not exists public.billing_customers (
  user_id            uuid primary key references public.profiles(id) on delete cascade,
  stripe_customer_id text not null unique,
  created_at         timestamptz not null default now()
);

-- One row per subscription, keyed by the provider's subscription id.
create table if not exists public.billing_subscriptions (
  id                   text primary key,          -- e.g. Stripe sub_…
  user_id              uuid not null references public.profiles(id) on delete cascade,
  source               text not null default 'stripe' check (source in ('stripe','apple')),
  status               text not null,             -- active | trialing | past_due | canceled | …
  price_id             text,                      -- Stripe price / StoreKit product id
  current_period_end   timestamptz,
  cancel_at_period_end boolean not null default false,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create index if not exists billing_subscriptions_user_idx
  on public.billing_subscriptions (user_id);

-- Membership follows the presence of any live subscription. Grace: past_due
-- keeps access until the paid-through date so a failed card retry doesn't
-- yank features mid-cycle. Never touches plus_plus (granted elsewhere).
create or replace function public.sync_membership_from_billing(uid uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  has_active boolean;
begin
  select exists (
    select 1 from public.billing_subscriptions
    where user_id = uid
      and status in ('active','trialing','past_due')
      and (current_period_end is null or current_period_end > now())
  ) into has_active;

  if has_active then
    update public.profiles set membership = 'plus'
      where id = uid and membership = 'free';
  else
    update public.profiles set membership = 'free'
      where id = uid and membership = 'plus';
  end if;
end;
$$;

create or replace function public.tg_billing_subscriptions_sync()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.sync_membership_from_billing(coalesce(new.user_id, old.user_id));
  return coalesce(new, old);
end;
$$;

drop trigger if exists billing_subscriptions_sync on public.billing_subscriptions;
create trigger billing_subscriptions_sync
  after insert or update or delete on public.billing_subscriptions
  for each row execute function public.tg_billing_subscriptions_sync();

-- keep updated_at honest
create or replace function public.tg_touch_updated_at()
returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists billing_subscriptions_touch on public.billing_subscriptions;
create trigger billing_subscriptions_touch
  before update on public.billing_subscriptions
  for each row execute function public.tg_touch_updated_at();

-- RLS: members see their own billing state; only the service role (edge
-- functions) writes. No insert/update/delete policies on purpose.
alter table public.billing_customers    enable row level security;
alter table public.billing_subscriptions enable row level security;

drop policy if exists "own billing customer" on public.billing_customers;
create policy "own billing customer" on public.billing_customers
  for select using (auth.uid() = user_id);

drop policy if exists "own subscriptions" on public.billing_subscriptions;
create policy "own subscriptions" on public.billing_subscriptions
  for select using (auth.uid() = user_id);

comment on table public.billing_subscriptions is
  'Provider-agnostic subscription state (Stripe web + Apple IAP). Written only by edge functions with the service-role key; membership syncs via trigger.';

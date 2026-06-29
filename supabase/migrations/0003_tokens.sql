-- ============================================================================
-- Mangasm — 0003 MGC token economy
-- Wallets + an append-only transaction ledger. A trigger keeps each wallet's
-- balance in sync with the ledger, so balance is never written directly.
-- Clients can READ their own wallet/ledger; all WRITES go through service-role
-- edge functions (earning, tipping, purchases, payouts) — see RLS at the end.
-- ============================================================================

do $$ begin
  create type token_tx_type as enum (
    'earn_cam', 'earn_dare', 'earn_event', 'tip_received', 'monthly_bonus',
    'tip_sent', 'dare_spin', 'purchase', 'payout'
  );
exception when duplicate_object then null; end $$;

create table if not exists public.token_wallets (
  user_id         uuid primary key references public.profiles (id) on delete cascade,
  balance         integer not null default 0 check (balance >= 0),
  lifetime_earned integer not null default 0,
  updated_at      timestamptz not null default now()
);

create table if not exists public.token_transactions (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  amount      integer not null,                 -- positive = credit, negative = debit
  type        token_tx_type not null,
  reference   text,                             -- e.g. room id, event id, stripe id
  created_at  timestamptz not null default now()
);

create index if not exists token_tx_user_idx on public.token_transactions (user_id, created_at desc);

-- Keep the wallet balance derived from the ledger.
create or replace function public.apply_token_transaction()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.token_wallets (user_id, balance, lifetime_earned)
  values (
    new.user_id,
    greatest(0, new.amount),
    greatest(0, new.amount)
  )
  on conflict (user_id) do update set
    balance         = public.token_wallets.balance + new.amount,
    lifetime_earned = public.token_wallets.lifetime_earned + greatest(0, new.amount),
    updated_at      = now();

  if (select balance from public.token_wallets where user_id = new.user_id) < 0 then
    raise exception 'insufficient MGC balance for transaction of %', new.amount
      using errcode = 'check_violation';
  end if;
  return new;
end $$;

drop trigger if exists token_tx_apply on public.token_transactions;
create trigger token_tx_apply after insert on public.token_transactions
  for each row execute function public.apply_token_transaction();

create or replace function public.token_balance(uid uuid)
returns integer language sql stable security definer set search_path = public as $$
  select coalesce((select balance from public.token_wallets where user_id = uid), 0);
$$;

-- ------------------------------------------------------------------- RLS -----
alter table public.token_wallets      enable row level security;
alter table public.token_transactions enable row level security;

drop policy if exists wallet_select_own on public.token_wallets;
create policy wallet_select_own on public.token_wallets
  for select to authenticated using (user_id = auth.uid());

drop policy if exists token_tx_select_own on public.token_transactions;
create policy token_tx_select_own on public.token_transactions
  for select to authenticated using (user_id = auth.uid());
-- No client INSERT/UPDATE/DELETE policy: the ledger is service-role only.

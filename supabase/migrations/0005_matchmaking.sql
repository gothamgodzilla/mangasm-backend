-- ============================================================================
-- Mangasm — 0005 AI matchmaking (Plus exclusive)
-- Per-member preferences, a learned taste embedding (pgvector), and the daily
-- match results produced by the generate-daily-matches edge function.
-- ============================================================================

create extension if not exists vector;

do $$ begin
  create type match_action as enum ('pending', 'liked', 'passed', 'messaged');
exception when duplicate_object then null; end $$;

create table if not exists public.match_preferences (
  user_id          uuid primary key references public.profiles (id) on delete cascade,
  max_distance_m   integer not null default 8047 check (max_distance_m between 1609 and 80467),
  interest_tags    text[]  not null default '{}',
  weight_kink      numeric not null default 0.80 check (weight_kink between 0 and 1),
  weight_aesthetic numeric not null default 0.90 check (weight_aesthetic between 0 and 1),
  weight_behavioral numeric not null default 0.60 check (weight_behavioral between 0 and 1),
  weight_proximity numeric not null default 0.70 check (weight_proximity between 0 and 1),
  updated_at       timestamptz not null default now()
);

-- Learned taste vector — updated on every like/pass/message by the edge function.
create table if not exists public.match_vectors (
  user_id    uuid primary key references public.profiles (id) on delete cascade,
  embedding  vector(128),
  updated_at timestamptz not null default now()
);

create table if not exists public.match_results (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references public.profiles (id) on delete cascade,
  matched_user_id uuid not null references public.profiles (id) on delete cascade,
  score           integer not null check (score between 0 and 100),
  ai_insight      text,
  reasons         text[] not null default '{}',
  action          match_action not null default 'pending',
  match_date      date not null default current_date,
  created_at      timestamptz not null default now(),
  constraint no_self_match check (user_id <> matched_user_id),
  unique (user_id, matched_user_id, match_date)
);

create index if not exists match_results_user_idx on public.match_results (user_id, match_date desc);
-- Approximate-nearest-neighbour index for cosine similarity over taste vectors.
create index if not exists match_vectors_ann
  on public.match_vectors using ivfflat (embedding vector_cosine_ops) with (lists = 100);

-- ------------------------------------------------------------------- RLS -----
alter table public.match_preferences enable row level security;
alter table public.match_vectors     enable row level security;
alter table public.match_results     enable row level security;

drop policy if exists match_prefs_own on public.match_preferences;
create policy match_prefs_own on public.match_preferences
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Vectors are private and written only by the service-role edge function.
drop policy if exists match_vectors_select_own on public.match_vectors;
create policy match_vectors_select_own on public.match_vectors
  for select to authenticated using (user_id = auth.uid());

-- Members see their own daily matches and may update the action (like/pass/message).
drop policy if exists match_results_select_own on public.match_results;
create policy match_results_select_own on public.match_results
  for select to authenticated using (user_id = auth.uid());

drop policy if exists match_results_update_own on public.match_results;
create policy match_results_update_own on public.match_results
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

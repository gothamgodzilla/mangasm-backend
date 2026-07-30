-- ============================================================================
-- Mangasm — UGC safety (App Store Guideline 1.2)
--
-- Apple requires apps with user-generated content to:
--   (a) have users agree to terms (EULA) with no tolerance for objectionable
--       content or abusive users,
--   (b) provide a method to flag objectionable CONTENT (not just users),
--   (c) provide a method to block abusive users,   -> already in 0001 (blocks),
--   (d) let the developer ACT on reports within 24h by removing the content
--       and ejecting the user who posted it.
--
-- This migration adds (a), (b), and the mechanism + audit trail for (d).
-- Idempotent where practical, matching the house style of 0001/0002.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- (a) terms_acceptances — record each user's agreement to the EULA / community
--     guidelines. The iOS app must gate registration on inserting a row here.
-- ----------------------------------------------------------------------------
create table if not exists public.terms_acceptances (
  id           uuid primary key default uuid_generate_v4(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  document     text not null check (document in ('eula', 'community_guidelines')),
  version      text not null,
  accepted_at  timestamptz not null default now(),
  ip           inet,
  unique (user_id, document, version)
);

create index if not exists terms_user_idx on public.terms_acceptances (user_id);

-- ----------------------------------------------------------------------------
-- (b) content-level flagging — extend `reports` so a report can point at a
--     specific piece of content, not only at a person. `reported_id` stays the
--     content's author, so one moderation queue serves both.
-- ----------------------------------------------------------------------------
do $$ begin
  create type reported_content_type as enum ('profile', 'message', 'event', 'photo');
exception when duplicate_object then null; end $$;

alter table public.reports
  add column if not exists content_type reported_content_type,
  add column if not exists content_id   uuid;

create index if not exists reports_content_idx
  on public.reports (content_type, content_id);

-- ----------------------------------------------------------------------------
-- (d) moderation_actions — audit trail proving what was done and when. This is
--     the evidence that reports are actioned within Apple's 24-hour window.
-- ----------------------------------------------------------------------------
create table if not exists public.moderation_actions (
  id            uuid primary key default uuid_generate_v4(),
  report_id     uuid references public.reports (id) on delete set null,
  moderator_id  uuid references public.profiles (id) on delete set null,
  action        text not null check (action in ('remove_and_eject', 'remove_only', 'dismiss')),
  note          text,
  created_at    timestamptz not null default now()
);

create index if not exists modactions_report_idx on public.moderation_actions (report_id);

-- ----------------------------------------------------------------------------
-- action_report — the one-call mechanism moderation tooling uses to satisfy
-- Apple's "remove the content and eject the user" requirement.
--   remove_and_eject : delete the offending content + ban the author
--   remove_only      : delete the content, leave the account
--   dismiss          : no action, close the report
-- SECURITY DEFINER + EXECUTE revoked from clients: only the service role
-- (edge functions) may call it.
-- ----------------------------------------------------------------------------
create or replace function public.action_report(
  p_report_id  uuid,
  p_action     text default 'remove_and_eject',
  p_moderator  uuid default null,
  p_note       text default null
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  r public.reports;
begin
  select * into r from public.reports where id = p_report_id;
  if not found then
    raise exception 'report % not found', p_report_id;
  end if;

  if p_action in ('remove_and_eject', 'remove_only') then
    if r.content_type = 'message' and r.content_id is not null then
      delete from public.messages where id = r.content_id;
    elsif r.content_type = 'event' and r.content_id is not null then
      delete from public.events where id = r.content_id;
    end if;
    -- 'profile'/'photo' content is handled by ejecting the author below.
  end if;

  if p_action = 'remove_and_eject' then
    update public.profiles set is_banned = true where id = r.reported_id;
  end if;

  update public.reports
     set status = (case when p_action = 'dismiss' then 'dismissed' else 'resolved' end)::report_status
   where id = p_report_id;

  insert into public.moderation_actions (report_id, moderator_id, action, note)
    values (p_report_id, p_moderator, p_action, p_note);
end $$;

revoke all on function public.action_report(uuid, text, uuid, text) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- reports_open_sla — the queue moderators work. security_invoker=on so the
-- reports RLS still applies: a member sees only their own; the service role
-- (moderation tooling) sees all, oldest first, with an `overdue` flag once a
-- report passes 24h still open.
-- ----------------------------------------------------------------------------
create or replace view public.reports_open_sla
  with (security_invoker = true) as
  select r.*,
         now() - r.created_at                          as age,
         (now() - r.created_at) > interval '24 hours'   as overdue
  from public.reports r
  where r.status in ('open', 'reviewing')
  order by r.created_at asc;

-- ============================================================================
-- RLS for the new tables
-- ============================================================================
alter table public.terms_acceptances  enable row level security;
alter table public.moderation_actions enable row level security;

-- terms_acceptances: a user may record and read their own acceptances.
drop policy if exists terms_insert_own on public.terms_acceptances;
create policy terms_insert_own on public.terms_acceptances
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists terms_select_own on public.terms_acceptances;
create policy terms_select_own on public.terms_acceptances
  for select to authenticated
  using (user_id = auth.uid());

-- moderation_actions: internal. RLS on with no client policy denies all client
-- access; the service role bypasses RLS for tooling.

-- Supabase compatibility shim for testing migrations against vanilla Postgres.
-- Supabase provides auth.users, auth.uid(), and the authenticated/anon/service
-- roles at runtime; this recreates the minimum needed so the migrations apply
-- and RLS policies compile. NOT for production.
create schema if not exists auth;
create table if not exists auth.users (id uuid primary key default gen_random_uuid());
create or replace function auth.uid() returns uuid
  language sql stable as $$ select '00000000-0000-0000-0000-000000000000'::uuid $$;
do $$ begin create role authenticated; exception when duplicate_object then null; end $$;
do $$ begin create role anon;          exception when duplicate_object then null; end $$;
do $$ begin create role service_role;  exception when duplicate_object then null; end $$;

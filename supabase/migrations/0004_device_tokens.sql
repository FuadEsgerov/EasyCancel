-- EasyCancel — 0004 device_tokens (APNs push tokens for server-driven reminders)
-- Apply via Supabase Dashboard → SQL Editor, or `supabase db push`.
-- Idempotent and safe to run on the existing live project (jinzwwsbuwvemwmcqfqw).
-- NOT auto-applied — deploy is a manual, authorized step.

create table if not exists public.device_tokens (
  token       text primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  platform    text not null default 'ios',
  updated_at  timestamptz not null default now()
);

alter table public.device_tokens enable row level security;

-- Own-row access only (mirrors the rest of the schema's RLS).
drop policy if exists "device_tokens_select_own" on public.device_tokens;
create policy "device_tokens_select_own" on public.device_tokens
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "device_tokens_insert_own" on public.device_tokens;
create policy "device_tokens_insert_own" on public.device_tokens
  for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists "device_tokens_update_own" on public.device_tokens;
create policy "device_tokens_update_own" on public.device_tokens
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "device_tokens_delete_own" on public.device_tokens;
create policy "device_tokens_delete_own" on public.device_tokens
  for delete to authenticated using ((select auth.uid()) = user_id);

create index if not exists idx_device_tokens_user on public.device_tokens(user_id);

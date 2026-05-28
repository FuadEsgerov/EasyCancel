-- EasyCancel — 0003 RLS & integrity hardening (from the 2026-05-28 security audit)
-- Apply via Supabase Dashboard → SQL Editor, or `supabase db push`.
-- Idempotent and safe to run on the existing live project (jinzwwsbuwvemwmcqfqw).
-- NOT auto-applied — deploy is a manual, authorized step.

-- ── 1. profiles UPDATE: add WITH CHECK ─────────────────────────────────────
-- The original policy had only USING, so an UPDATE's new row values were not
-- re-validated. Add WITH CHECK so a user can never re-point their row to a
-- different id.
drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles
  for update to authenticated
  using  ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- ── 2. Block client self-granting of Pro entitlements ──────────────────────
-- subscription_tier / trial_ends_at are entitlement state. They must only be
-- set server-side (the SECURITY DEFINER signup trigger, or service-role edge
-- functions / StoreKit-verified flows) — never by a direct client UPDATE.
-- A normal client has a non-null auth.uid(); the service role has a null
-- auth.uid() (it bypasses RLS), so this fires only for real clients.
create or replace function public.prevent_entitlement_self_grant()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is not null
     and (new.subscription_tier is distinct from old.subscription_tier
          or new.trial_ends_at is distinct from old.trial_ends_at) then
    raise exception
      'subscription_tier/trial_ends_at can only be changed server-side';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_prevent_entitlement_self_grant on public.profiles;
create trigger trg_prevent_entitlement_self_grant
  before update on public.profiles
  for each row execute function public.prevent_entitlement_self_grant();

revoke execute on function public.prevent_entitlement_self_grant() from anon, authenticated, public;

-- ── 3. Indexes for user_id filters (RLS reads + delete-account erasure) ─────
-- These tables are filtered by user_id in RLS and bulk-deleted by user_id in
-- the delete-account edge function, but lacked a plain user_id index.
create index if not exists idx_attempts_user      on public.cancellation_attempts(user_id);
create index if not exists idx_parse_queue_user    on public.email_parse_queue(user_id);
create index if not exists idx_notifications_user   on public.notifications(user_id);

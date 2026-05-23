-- EasyCancel — scheduled jobs (spec §10.5). OPTIONAL.
-- Requires the pg_cron extension. Enable it first in
-- Supabase Dashboard → Database → Extensions (or the statement below),
-- then run this migration.

create extension if not exists pg_cron;

create or replace function public.cleanup_old_emails()
returns void as $$
begin
  delete from public.email_parse_queue where delete_after < now();
end;
$$ language plpgsql;

-- Harden: pin search_path and keep off the PostgREST RPC surface.
alter function public.cleanup_old_emails() set search_path = '';
revoke execute on function public.cleanup_old_emails() from anon, authenticated, public;

-- Cooling-off deadline reminders (daily 09:00 UTC)
select cron.schedule('cooling-off-reminders', '0 9 * * *', $$
  insert into public.notifications (user_id, type, title, body, related_subscription_id)
  select
    user_id,
    'cooling_off_reminder',
    'Cooling-off ends soon',
    'You have ' || (cooling_off_deadline - current_date) || ' days to cancel ' ||
      coalesce(custom_merchant_name, 'a subscription'),
    id
  from public.user_subscriptions
  where status = 'active'
    and cooling_off_deadline in (current_date + 7, current_date + 3, current_date + 1);
$$);

-- Email cleanup (daily 03:00 UTC)
select cron.schedule('cleanup-emails', '0 3 * * *', 'select public.cleanup_old_emails();');

-- Purge soft-deleted accounts 30 days after deletion request (daily 04:00 UTC)
select cron.schedule('purge-deleted-accounts', '0 4 * * *', $$
  delete from public.profiles where deleted_at < now() - interval '30 days';
$$);

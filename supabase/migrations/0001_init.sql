-- EasyCancel — initial schema (from spec §9)
-- Apply via Supabase Dashboard → SQL Editor, or `supabase db push`.
-- Safe to run once on a fresh project.

-- ── Tables ───────────────────────────────────────────────────────────────

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text,
  country_code text not null default 'UK'
    check (country_code in ('DE','UK','FR','ES','IT','NL','PL','AT','BE','IE','PT')),
  preferred_language text not null default 'en',
  forwarding_address_local text unique not null,
  subscription_tier text not null default 'free'
    check (subscription_tier in ('free','pro','family')),
  trial_ends_at timestamptz,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.merchants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  domain text,
  icon_url text,
  category text,
  country_of_registration text,
  has_withdrawal_button boolean default false,
  withdrawal_button_url text,
  has_kuendigungsbutton boolean default false,
  kuendigungsbutton_url text,
  legal_email text,
  difficulty_score integer check (difficulty_score between 1 and 5),
  notes text,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  merchant_id uuid references public.merchants(id),
  custom_merchant_name text,
  amount_cents integer not null,
  currency text not null default 'EUR',
  billing_frequency text not null
    check (billing_frequency in ('weekly','monthly','quarterly','yearly','one_time')),
  signup_date date not null,
  next_renewal_date date,
  cooling_off_deadline date generated always as (signup_date + interval '14 days') stored,
  status text not null default 'active'
    check (status in ('active','cancelled','disputed','expired')),
  cancelled_at timestamptz,
  source text check (source in ('manual','email_forward','bank_sync','gmail_scan')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cancellation_attempts (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references public.user_subscriptions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  method text not null check (method in ('button','letter_email','letter_certified')),
  letter_pdf_path text,
  sent_at timestamptz not null default now(),
  delivery_confirmed_at timestamptz,
  read_receipt_at timestamptz,
  merchant_response_at timestamptz,
  merchant_response_text text,
  outcome text check (outcome in ('pending','success','rejected','no_response','disputed')) default 'pending',
  resend_message_id text,
  legal_clause_cited text not null,
  merchant_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.email_parse_queue (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  raw_email_path text not null,
  status text not null default 'pending'
    check (status in ('pending','processing','parsed','failed','deleted')),
  parsed_subscription_id uuid references public.user_subscriptions(id),
  parse_confidence decimal(3,2),
  error_message text,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  delete_after timestamptz not null default (now() + interval '7 days')
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null
    check (type in ('cooling_off_reminder','renewal_reminder','cancellation_confirmed','letter_response')),
  title text not null,
  body text not null,
  related_subscription_id uuid references public.user_subscriptions(id),
  sent_at timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

-- ── Row-Level Security (default deny) ────────────────────────────────────

alter table public.profiles enable row level security;
alter table public.merchants enable row level security;
alter table public.user_subscriptions enable row level security;
alter table public.cancellation_attempts enable row level security;
alter table public.email_parse_queue enable row level security;
alter table public.notifications enable row level security;

create policy "Users view own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "Users update own profile" on public.profiles
  for update using (auth.uid() = id);

create policy "Anyone reads merchants" on public.merchants
  for select using (true);

create policy "Users view own subscriptions" on public.user_subscriptions
  for select using (auth.uid() = user_id);
create policy "Users insert own subscriptions" on public.user_subscriptions
  for insert with check (auth.uid() = user_id);
create policy "Users update own subscriptions" on public.user_subscriptions
  for update using (auth.uid() = user_id);
create policy "Users delete own subscriptions" on public.user_subscriptions
  for delete using (auth.uid() = user_id);

create policy "Users view own attempts" on public.cancellation_attempts
  for select using (auth.uid() = user_id);
create policy "Users insert own attempts" on public.cancellation_attempts
  for insert with check (auth.uid() = user_id);
create policy "Users delete own attempts" on public.cancellation_attempts
  for delete to authenticated using (user_id = (select auth.uid()));

create policy "Users view own queue" on public.email_parse_queue
  for select using (auth.uid() = user_id);
create policy "Users delete own queue" on public.email_parse_queue
  for delete to authenticated using (user_id = (select auth.uid()));

create policy "Users view own notifications" on public.notifications
  for select using (auth.uid() = user_id);
create policy "Users delete own notifications" on public.notifications
  for delete to authenticated using (user_id = (select auth.uid()));

-- ── Indexes ──────────────────────────────────────────────────────────────

create index if not exists idx_subs_user_status on public.user_subscriptions(user_id, status);
create index if not exists idx_subs_renewal on public.user_subscriptions(next_renewal_date) where status = 'active';
create index if not exists idx_subs_cooling_off on public.user_subscriptions(cooling_off_deadline) where status = 'active';
create index if not exists idx_attempts_sub on public.cancellation_attempts(subscription_id);
create index if not exists idx_parse_queue_status on public.email_parse_queue(status, received_at);
create index if not exists idx_notifications_user_unread on public.notifications(user_id, read_at) where read_at is null;

-- ── Auto-create profile on signup ────────────────────────────────────────

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, forwarding_address_local, country_code)
  values (
    new.id,
    coalesce(new.email, ''),
    lower(split_part(coalesce(new.email, 'user'), '@', 1)) || '-' || substring(new.id::text, 1, 8),
    coalesce(new.raw_user_meta_data->>'country_code', 'UK')
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Harden: pin search_path and keep this trigger fn off the PostgREST RPC surface.
alter function public.handle_new_user() set search_path = '';
revoke execute on function public.handle_new_user() from anon, authenticated, public;

-- ── Seed a few merchants (public-read; useful for connectivity tests) ─────

insert into public.merchants (name, category, has_withdrawal_button, difficulty_score) values
  ('Netflix', 'streaming', true, 2),
  ('Spotify', 'streaming', true, 2),
  ('NYT', 'news', false, 3),
  ('FitnessFirst', 'fitness', false, 5)
on conflict do nothing;

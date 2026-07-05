-- Run this in Supabase SQL Editor. It's additive — safe to run even though
-- you already have the "expenses" table from the first version of the app.

-- 1. INCOME -------------------------------------------------------------
create table if not exists income (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null default auth.uid(),
  income_date date not null default current_date,
  source text not null,
  amount numeric(10,2) not null check (amount > 0),
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists income_user_date_idx on income (user_id, income_date desc);

alter table income enable row level security;

create policy "Users can view own income" on income for select using (auth.uid() = user_id);
create policy "Users can insert own income" on income for insert with check (auth.uid() = user_id);
create policy "Users can update own income" on income for update using (auth.uid() = user_id);
create policy "Users can delete own income" on income for delete using (auth.uid() = user_id);

-- 2. RECURRING EXPENSE TEMPLATES ------------------------------------------
-- These are *definitions* ("Internet bill, ₹999, due on the 5th") used both
-- to quickly log the real expense each month and to trigger alerts.
create table if not exists recurring_expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null default auth.uid(),
  name text not null,
  category text not null,
  amount numeric(10,2) not null check (amount > 0),
  payment_day int not null check (payment_day between 1 and 31),
  notify_email boolean not null default true,
  notify_sms boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table recurring_expenses enable row level security;

create policy "Users can view own recurring expenses" on recurring_expenses for select using (auth.uid() = user_id);
create policy "Users can insert own recurring expenses" on recurring_expenses for insert with check (auth.uid() = user_id);
create policy "Users can update own recurring expenses" on recurring_expenses for update using (auth.uid() = user_id);
create policy "Users can delete own recurring expenses" on recurring_expenses for delete using (auth.uid() = user_id);

-- Optionally link a logged expense back to the recurring template it came from
alter table expenses add column if not exists recurring_id uuid references recurring_expenses(id) on delete set null;

-- 3. NOTIFICATION SETTINGS -------------------------------------------------
-- Where to send alerts. alert_email defaults to the account's login email
-- but can be overridden. phone_number is captured now so SMS can be turned
-- on later without a schema change.
create table if not exists notification_settings (
  user_id uuid primary key references auth.users not null default auth.uid(),
  alert_email text,
  phone_number text,
  sms_enabled boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table notification_settings enable row level security;

create policy "Users can view own notification settings" on notification_settings for select using (auth.uid() = user_id);
create policy "Users can insert own notification settings" on notification_settings for insert with check (auth.uid() = user_id);
create policy "Users can update own notification settings" on notification_settings for update using (auth.uid() = user_id);

-- 4. SERVICE-ROLE READ ACCESS FOR THE DAILY ALERT JOB ----------------------
-- The Edge Function that sends alerts runs as a backend job (not as any one
-- logged-in user), so it uses the service_role key, which already bypasses
-- Row Level Security entirely. No extra policy is required for it — just
-- keep the service_role key out of any frontend code, ever.

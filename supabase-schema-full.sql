-- ============================================================================
-- LEDGER — full database schema (Supabase / Postgres)
-- Run this ONCE in Supabase → SQL Editor → New query → paste all → Run.
-- Safe to run even on a fresh, empty project.
-- ============================================================================

-- 1. EXPENSES ----------------------------------------------------------------
create table if not exists expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null default auth.uid(),
  expense_date date not null default current_date,
  category text not null,
  description text,
  amount numeric(10,2) not null check (amount > 0),
  created_at timestamptz not null default now()
);

create index if not exists expenses_user_date_idx on expenses (user_id, expense_date desc);

alter table expenses enable row level security;

create policy "Users can view own expenses" on expenses for select using (auth.uid() = user_id);
create policy "Users can insert own expenses" on expenses for insert with check (auth.uid() = user_id);
create policy "Users can update own expenses" on expenses for update using (auth.uid() = user_id);
create policy "Users can delete own expenses" on expenses for delete using (auth.uid() = user_id);

-- 2. INCOME -------------------------------------------------------------------
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

-- 3. RECURRING EXPENSE TEMPLATES ----------------------------------------------
-- Definitions like "Internet bill, ₹999, due on the 5th" — used to trigger
-- the day-before email alert, and optionally linked to logged expenses.
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

-- Optional link from a real logged expense back to the recurring template it came from
alter table expenses add column if not exists recurring_id uuid references recurring_expenses(id) on delete set null;

-- 4. NOTIFICATION SETTINGS -----------------------------------------------------
-- Where alerts go. alert_email defaults to the account's login email but can
-- be overridden. phone_number/sms_enabled exist now so SMS can be added later
-- without another schema change.
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

-- 5. NOTE ON THE DAILY ALERT JOB ------------------------------------------------
-- The Edge Function that sends "due tomorrow" emails runs as a backend job
-- (not as any single logged-in user), so it authenticates with the
-- service_role key, which already bypasses Row Level Security. No extra
-- policy is needed for it — just never put the service_role key in any
-- frontend file, ever (see the Edge Function section of the README).

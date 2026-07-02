-- Run this once in your Supabase project's SQL Editor
-- (Dashboard -> SQL Editor -> New query -> paste -> Run)

create table if not exists expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null default auth.uid(),
  expense_date date not null default current_date,
  category text not null,
  description text,
  amount numeric(10,2) not null check (amount > 0),
  created_at timestamptz not null default now()
);

-- Speeds up "this month" and date-ordered queries
create index if not exists expenses_user_date_idx
  on expenses (user_id, expense_date desc);

-- Row Level Security: every user can only ever see/edit their own rows
alter table expenses enable row level security;

create policy "Users can view own expenses"
  on expenses for select
  using (auth.uid() = user_id);

create policy "Users can insert own expenses"
  on expenses for insert
  with check (auth.uid() = user_id);

create policy "Users can update own expenses"
  on expenses for update
  using (auth.uid() = user_id);

create policy "Users can delete own expenses"
  on expenses for delete
  using (auth.uid() = user_id);

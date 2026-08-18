-- GUY WORK OS V7.3
-- Personal Life Tracker (fully private, never merged into team Tasks/Admin views)
-- + LINE notification linking (LINE Notify is discontinued; this uses the
--   LINE Messaging API with a Official Account and a one-time linking code).

begin;

-- ============================================================
-- Personal Life Tracker
-- ============================================================
create table if not exists public.personal_logs (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('reading','exercise','sleep','health')),
  log_date date not null default current_date,
  book_title text,
  page_current integer,
  page_total integer,
  activity text,
  duration_minutes integer,
  bed_time time,
  wake_time time,
  weight_kg numeric(5,2),
  note text,
  created_at timestamptz not null default now()
);

create index if not exists personal_logs_user_date_idx on public.personal_logs(user_id, log_date desc);

alter table public.personal_logs enable row level security;

-- Deliberately no admin/super_admin bypass anywhere below: this data is
-- private to each user only, including from Super Admin / Team Overview.
drop policy if exists "personal_logs_select_own" on public.personal_logs;
create policy "personal_logs_select_own" on public.personal_logs for select using (auth.uid() = user_id);
drop policy if exists "personal_logs_insert_own" on public.personal_logs;
create policy "personal_logs_insert_own" on public.personal_logs for insert with check (auth.uid() = user_id);
drop policy if exists "personal_logs_update_own" on public.personal_logs;
create policy "personal_logs_update_own" on public.personal_logs for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "personal_logs_delete_own" on public.personal_logs;
create policy "personal_logs_delete_own" on public.personal_logs for delete using (auth.uid() = user_id);

-- ============================================================
-- LINE notification linking
-- ============================================================
create table if not exists public.line_links (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  code text not null unique,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  consumed_at timestamptz
);

alter table public.line_links enable row level security;

drop policy if exists "line_links_select_own" on public.line_links;
create policy "line_links_select_own" on public.line_links for select using (auth.uid() = user_id);
drop policy if exists "line_links_insert_own" on public.line_links;
create policy "line_links_insert_own" on public.line_links for insert with check (auth.uid() = user_id);
drop policy if exists "line_links_delete_own" on public.line_links;
create policy "line_links_delete_own" on public.line_links for delete using (auth.uid() = user_id);
-- No update policy: the line-webhook Edge Function consumes a code using the
-- service role key, which bypasses RLS by design.

create table if not exists public.line_subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  line_user_id text not null unique,
  linked_at timestamptz not null default now()
);

alter table public.line_subscriptions enable row level security;

drop policy if exists "line_subscriptions_select_own" on public.line_subscriptions;
create policy "line_subscriptions_select_own" on public.line_subscriptions for select using (auth.uid() = user_id);
drop policy if exists "line_subscriptions_delete_own" on public.line_subscriptions;
create policy "line_subscriptions_delete_own" on public.line_subscriptions for delete using (auth.uid() = user_id);
-- No insert/update policy: only the line-webhook Edge Function (service role)
-- creates this row, after the user proves ownership by messaging the OA with
-- their one-time code.

commit;

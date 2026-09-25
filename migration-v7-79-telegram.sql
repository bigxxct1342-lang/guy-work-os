-- PORKCHOP G V7.79
-- DAILY BRIEF OVER TELEGRAM
--
-- LINE needed an Official Account, a Business ID with an emailed OTP, a
-- Developers console channel and two secrets from two different pages -- and
-- the OTP never arrived. Telegram needs one bot token from @BotFather.
--
-- Linking works the same way LINE did, minus the typing: the app writes a
-- one-time code here and opens t.me/<bot>?start=<code>. Pressing Start in
-- Telegram sends that code to the telegram-webhook function, which proves the
-- chat belongs to whoever generated the code and records the chat id.
--
--   tg_links          one-time codes, 15 minutes, written by the signed-in user
--   tg_subscriptions  user -> Telegram chat id, written ONLY by the function
--
-- Nobody can link a chat to someone else's account: the browser may create a
-- code for itself, but only the function (service role) can turn a code into
-- a subscription, and only after Telegram delivered that code from the chat.
--
-- Safe to run more than once.

begin;

create table if not exists public.tg_links (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  code text not null unique,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  consumed_at timestamptz
);

alter table public.tg_links enable row level security;

drop policy if exists "tg_links_select_own" on public.tg_links;
create policy "tg_links_select_own" on public.tg_links
  for select to authenticated using (auth.uid() = user_id);
drop policy if exists "tg_links_insert_own" on public.tg_links;
create policy "tg_links_insert_own" on public.tg_links
  for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "tg_links_delete_own" on public.tg_links;
create policy "tg_links_delete_own" on public.tg_links
  for delete to authenticated using (auth.uid() = user_id);
-- No update policy: the function consumes a code with the service role.

create table if not exists public.tg_subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  chat_id bigint not null unique,
  tg_name text,
  linked_at timestamptz not null default now()
);

alter table public.tg_subscriptions enable row level security;

drop policy if exists "tg_subscriptions_select_own" on public.tg_subscriptions;
create policy "tg_subscriptions_select_own" on public.tg_subscriptions
  for select to authenticated using (auth.uid() = user_id);
drop policy if exists "tg_subscriptions_delete_own" on public.tg_subscriptions;
create policy "tg_subscriptions_delete_own" on public.tg_subscriptions
  for delete to authenticated using (auth.uid() = user_id);
-- No insert/update policy: only telegram-webhook (service role) creates a row,
-- after Telegram delivers the one-time code from that chat.

commit;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------

-- 1. Both tables exist with RLS on (two rows, rowsecurity = true).
select tablename, rowsecurity
from pg_tables
where schemaname = 'public' and tablename in ('tg_links','tg_subscriptions')
order by tablename;

-- 2. Policies: tg_links has select/insert/delete, tg_subscriptions has
--    select/delete only. Neither may show UPDATE or ALL, and
--    tg_subscriptions must not show INSERT.
select tablename, policyname, cmd
from pg_policies
where schemaname = 'public' and tablename in ('tg_links','tg_subscriptions')
order by tablename, cmd;

-- 3. profiles still has NO update policy reachable from the client (zero rows).
select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'profiles' and cmd in ('UPDATE','ALL');

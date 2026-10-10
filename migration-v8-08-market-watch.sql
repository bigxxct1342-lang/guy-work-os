-- PORKCHOP G V8.08
-- MARKET WATCH: new products seen in the market
--
-- One row per product you spotted on a shelf or online. Private to whoever
-- wrote it, exactly like KOL, PR and Product Launch (the policy goes through
-- created_by; the Super Admin can read across, as everywhere else).
--
-- The photo is a small data URL, the same way the ID photo is kept: no
-- storage bucket, no signed URLs. The browser shrinks it before sending and
-- the check below refuses anything that is not a base64 image.
--
-- The channel rule (7-Eleven / MT / Traditional Trade; online only for canned
-- seafood) lives in the app, not here, so it can be tuned without a migration.
-- The database only insists that at least one channel is named.
--
-- Safe to run more than once.
-- Run AFTER V7.72.

begin;

create table if not exists public.market_items (
  id            bigint generated always as identity primary key,
  team_id       uuid not null,
  created_by    uuid not null default auth.uid(),
  name          text not null check (length(name) between 1 and 200),
  brand         text check (brand is null or length(brand) <= 120),
  category      text not null default 'other'
                check (category in ('cockle','scallop','canned_sea','rte','snack','sauce','other')),
  channels      text[] not null default '{}'
                check (cardinality(channels) between 1 and 4
                       and channels <@ array['seven','mt','tt','online']),
  stores        text check (stores is null or length(stores) <= 300),
  size_g        numeric check (size_g is null or size_g > 0),
  price         numeric check (price is null or price >= 0),
  selling_points text check (selling_points is null or length(selling_points) <= 2000),
  shelf_life    text check (shelf_life is null or length(shelf_life) <= 120),
  maker         text check (maker is null or length(maker) <= 200),
  seen_on       date not null default current_date,
  sale_from     date,
  sale_to       date,
  source_url    text check (source_url is null or length(source_url) <= 1000),
  photo         text check (photo is null or (length(photo) <= 200000
                       and photo ~ '^data:image/(png|jpeg|webp);base64,[A-Za-z0-9+/=]+$')),
  trends        text[] not null default '{}' check (cardinality(trends) <= 10),
  verdict       text check (verdict is null or verdict in ('threat','watch','idea')),
  action        text check (action is null or length(action) <= 600),
  note          text check (note is null or length(note) <= 2000),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists market_items_owner_seen_idx
  on public.market_items (created_by, seen_on desc);

alter table public.market_items enable row level security;

drop policy if exists "market_items_owner" on public.market_items;
create policy "market_items_owner" on public.market_items for all to authenticated
  using (team_id = public.my_team_id()
         and (created_by = auth.uid() or public.is_admin()))
  with check (team_id = public.my_team_id()
         and (created_by = auth.uid() or public.is_admin()));

commit;

-- ---------------------------------------------------------------------------
-- VERIFY  (Supabase shows the last result; run each block on its own to see all)
-- ---------------------------------------------------------------------------

-- 1. The table exists with row level security on (one row, rowsecurity = true).
select tablename, rowsecurity
from pg_tables
where schemaname = 'public' and tablename = 'market_items';

-- 2. Exactly one policy on it, and it goes through created_by.
select policyname, cmd, qual
from pg_policies
where schemaname = 'public' and tablename = 'market_items';

-- 3. The channel and category rules are in place (three check rows).
select conname, pg_get_constraintdef(oid) as rule
from pg_constraint
where conrelid = 'public.market_items'::regclass and contype = 'c'
  and (pg_get_constraintdef(oid) ilike '%channels%'
    or pg_get_constraintdef(oid) ilike '%category%'
    or pg_get_constraintdef(oid) ilike '%photo%');

-- 4. profiles still has NO update policy reachable from the client (zero rows).
select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'profiles' and cmd in ('UPDATE','ALL');

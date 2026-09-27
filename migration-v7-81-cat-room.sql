-- PORKCHOP G V7.81
-- CAT ROOM
--
-- A virtual pet that has nothing to do with work. Each person keeps their
-- own cats; nobody else can read or write them -- not the other member, and
-- not the Super Admin either, because there is nothing to supervise here.
--
-- The whole room is one JSON document per person: the cats, their levels,
-- when each was last fed, the litter box, the laser plays. It is only ever
-- read and written whole by its owner, so a table of columns would add
-- nothing but migrations every time the game grows a feature.
--
-- Until this is run the app still works: the room is kept in the browser
-- only, and moves into this table on the first visit after it exists.
--
-- Safe to run more than once.

begin;

create table if not exists public.cat_rooms (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  state jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.cat_rooms enable row level security;

drop policy if exists "cat_rooms_own" on public.cat_rooms;
create policy "cat_rooms_own" on public.cat_rooms
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

commit;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------

-- 1. The table exists with RLS on (one row, rowsecurity = true).
select tablename, rowsecurity
from pg_tables
where schemaname = 'public' and tablename = 'cat_rooms';

-- 2. Exactly one policy, and it tests the owner only -- no is_admin().
select policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'cat_rooms';

-- 3. profiles still has NO update policy reachable from the client (zero rows).
select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'profiles' and cmd in ('UPDATE','ALL');

-- 4. Whose rooms exist so far, and how many cats each holds.
select p.full_name, jsonb_array_length(c.state->'cats') as cats, c.updated_at
from public.cat_rooms c
left join public.profiles p on p.user_id = c.user_id
order by c.updated_at desc;

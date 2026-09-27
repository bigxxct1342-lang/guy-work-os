-- PORKCHOP G V7.84
-- CAT ROOM: VISITS, GIFTS AND A PHOTO ALBUM
--
-- Until now nobody could see anybody else's cats. This opens exactly one
-- window, on purpose and on the cat room only: a teammate may LOOK at your
-- room (cats, their outfits, the furniture) and leave a gift once a day.
-- Nothing else about you becomes visible -- tasks, projects and the rest
-- keep the V7.72 rules untouched.
--
--   cat_room_visit()  SECURITY DEFINER, read-only. Returns the cat rooms of
--                     the OTHER people on your team, cats + furniture only.
--                     cat_rooms itself stays owner-only.
--   cat_gifts         one gift per sender, per recipient, per day. The sender
--                     writes it; only the recipient can read-and-delete it
--                     (that is how it is claimed). No updates.
--   cat_photos        the album: small pixel snapshots, owner-only.
--
-- Uses public.same_team() and public.my_team_id() from V6.8.
-- Safe to run more than once. Run AFTER V7.81.

begin;

-- 1. Looking at a teammate's room -------------------------------------------
create or replace function public.cat_room_visit()
returns table(user_id uuid, full_name text, room jsonb, updated_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select c.user_id,
         coalesce(nullif(p.full_name, ''), split_part(p.email, '@', 1)),
         jsonb_build_object(
           'cats',   c.state -> 'cats',
           'room',   c.state -> 'room',
           'active', c.state -> 'active',
           'decor',  c.state -> 'decor'),
         c.updated_at
  from public.cat_rooms c
  join public.profiles p on p.user_id = c.user_id
  where auth.uid() is not null
    and c.user_id <> auth.uid()
    and p.team_id is not null
    and p.team_id = public.my_team_id()
$$;

revoke all on function public.cat_room_visit() from public;
grant execute on function public.cat_room_visit() to authenticated;

-- 2. Gifts --------------------------------------------------------------------
create table if not exists public.cat_gifts (
  id bigint generated always as identity primary key,
  from_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  to_id uuid not null references auth.users(id) on delete cascade,
  from_name text check (from_name is null or length(from_name) <= 40),
  kind text not null check (kind in ('treat','coins','ticket')),
  day date not null,
  created_at timestamptz not null default now(),
  unique (from_id, to_id, day)
);

alter table public.cat_gifts enable row level security;

drop policy if exists "cat_gifts_send" on public.cat_gifts;
create policy "cat_gifts_send" on public.cat_gifts
  for insert to authenticated
  with check (from_id = auth.uid()
              and to_id <> auth.uid()
              and public.same_team(to_id)
              and day between current_date - 1 and current_date + 1);

drop policy if exists "cat_gifts_read" on public.cat_gifts;
create policy "cat_gifts_read" on public.cat_gifts
  for select to authenticated
  using (from_id = auth.uid() or to_id = auth.uid());

drop policy if exists "cat_gifts_claim" on public.cat_gifts;
create policy "cat_gifts_claim" on public.cat_gifts
  for delete to authenticated
  using (to_id = auth.uid());
-- No update policy: a gift is sent, then claimed (deleted). Nothing in between.

-- 3. Album --------------------------------------------------------------------
create table if not exists public.cat_photos (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  cat_id integer not null,
  caption text check (caption is null or length(caption) <= 60),
  img text not null check (length(img) <= 150000 and img like 'data:image/png;base64,%'),
  taken_at timestamptz not null default now()
);

create index if not exists cat_photos_user_idx on public.cat_photos (user_id, cat_id, taken_at desc);

alter table public.cat_photos enable row level security;

drop policy if exists "cat_photos_own" on public.cat_photos;
create policy "cat_photos_own" on public.cat_photos
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

commit;

-- ---------------------------------------------------------------------------
-- VERIFY  (Supabase shows the last result; run each block on its own to see all)
-- ---------------------------------------------------------------------------

-- 1. Both tables exist with RLS on.
select tablename, rowsecurity
from pg_tables
where schemaname = 'public' and tablename in ('cat_gifts','cat_photos','cat_rooms')
order by tablename;

-- 2. cat_rooms is still owner-only: one policy, no is_admin(), no team test.
select policyname, cmd, qual
from pg_policies
where schemaname = 'public' and tablename = 'cat_rooms';

-- 3. Gift policies: INSERT / SELECT / DELETE only, never UPDATE or ALL.
select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'cat_gifts'
order by cmd;

-- 4. The visit function is SECURITY DEFINER.
select p.proname, p.prosecdef as security_definer
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'cat_room_visit';

-- 5. profiles still has NO update policy reachable from the client (zero rows).
select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'profiles' and cmd in ('UPDATE','ALL');

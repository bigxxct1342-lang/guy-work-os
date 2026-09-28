-- PORKCHOP G V7.86
-- CAT ROOM, TOGETHER: PLAYDATES, A SHARED WEEKLY GOAL, AND A FAMILY CAT
--
--   cat_playdates      your cat goes to spend an hour in a teammate's room.
--                      You write the visit (a small snapshot of that one cat);
--                      the host can read it and see him there. Either side
--                      can end it. One visit out per person at a time.
--   cat_coop           the shared weekly goal: one counter per person per
--                      week, each written only by its owner, readable by the
--                      team, summed in the app.
--   cat_family         one cat that belongs to the whole team. Nobody writes
--                      the row directly: cat_family_get() and
--                      cat_family_act() do, one locked row at a time, so two
--                      people feeding him at once cannot overwrite each other.
--   cat_room_visit()   now also returns the owner's badge title, room look
--                      and whether the balcony is showing.
--
-- Nothing here widens what anyone can see of anyone's WORK. Uses
-- public.same_team() / public.my_team_id() from V6.8.
-- Safe to run more than once. Run AFTER V7.84.

begin;

-- 1. Playdates ----------------------------------------------------------------
create table if not exists public.cat_playdates (
  id bigint generated always as identity primary key,
  guest_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  host_id uuid not null references auth.users(id) on delete cascade,
  owner_name text check (owner_name is null or length(owner_name) <= 40),
  cat jsonb not null check (length(cat::text) <= 4000),
  started_at timestamptz not null default now(),
  ends_at timestamptz not null,
  unique (guest_id)
);

alter table public.cat_playdates enable row level security;

drop policy if exists "cat_playdates_send" on public.cat_playdates;
create policy "cat_playdates_send" on public.cat_playdates
  for insert to authenticated
  with check (guest_id = auth.uid()
              and host_id <> auth.uid()
              and public.same_team(host_id)
              and ends_at <= now() + interval '3 hours');

drop policy if exists "cat_playdates_read" on public.cat_playdates;
create policy "cat_playdates_read" on public.cat_playdates
  for select to authenticated
  using (guest_id = auth.uid() or host_id = auth.uid());

drop policy if exists "cat_playdates_end" on public.cat_playdates;
create policy "cat_playdates_end" on public.cat_playdates
  for delete to authenticated
  using (guest_id = auth.uid() or host_id = auth.uid());
-- No update policy: a visit is started, then ended.

-- 2. The shared weekly goal ---------------------------------------------------
create table if not exists public.cat_coop (
  team_id uuid not null,
  week date not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text check (name is null or length(name) <= 40),
  n integer not null default 0 check (n between 0 and 100000),
  updated_at timestamptz not null default now(),
  primary key (team_id, week, user_id)
);

alter table public.cat_coop enable row level security;

drop policy if exists "cat_coop_read" on public.cat_coop;
create policy "cat_coop_read" on public.cat_coop
  for select to authenticated
  using (team_id = public.my_team_id());

drop policy if exists "cat_coop_write" on public.cat_coop;
create policy "cat_coop_write" on public.cat_coop
  for insert to authenticated
  with check (user_id = auth.uid() and team_id = public.my_team_id());

drop policy if exists "cat_coop_update" on public.cat_coop;
create policy "cat_coop_update" on public.cat_coop
  for update to authenticated
  using (user_id = auth.uid() and team_id = public.my_team_id())
  with check (user_id = auth.uid() and team_id = public.my_team_id());

-- 3. The family cat -----------------------------------------------------------
create table if not exists public.cat_family (
  team_id uuid primary key,
  state jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.cat_family enable row level security;
-- No policies at all: the table is reached only through the two functions
-- below, which check the caller's team themselves.

create or replace function public.cat_family_get()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  t uuid := public.my_team_id();
  s jsonb;
begin
  if auth.uid() is null or t is null then
    raise exception 'no team';
  end if;
  insert into public.cat_family (team_id, state)
  values (t, jsonb_build_object('name','KATI','breed','scottish','xp',0,'h',80,'p',80,
                                't',now(),'wear','{}'::jsonb,'fed','{}'::jsonb,'petAt','{}'::jsonb))
  on conflict (team_id) do nothing;
  select state into s from public.cat_family where team_id = t;
  return s;
end;
$$;

create or replace function public.cat_family_act(p_act text, p_arg text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  t uuid := public.my_team_id();
  me text := auth.uid()::text;
  who text;
  s jsonb;
  hrs double precision;
  h double precision;
  p double precision;
  xp integer;
  msg text := 'ok';
  last_pet timestamptz;
begin
  if auth.uid() is null or t is null then
    raise exception 'no team';
  end if;
  perform public.cat_family_get();
  select state into s from public.cat_family where team_id = t for update;

  select coalesce(nullif(full_name, ''), split_part(email, '@', 1)) into who
  from public.profiles where user_id = auth.uid();

  -- hunger and happiness fall with time, exactly as a personal cat's do
  hrs := greatest(0, extract(epoch from (now() - (s->>'t')::timestamptz)) / 3600.0);
  h := greatest(0, (s->>'h')::double precision - hrs * 100.0 / 9.0);
  p := greatest(0, (s->>'p')::double precision - hrs * 10.0 / 12.0);
  xp := coalesce((s->>'xp')::integer, 0);

  if p_act = 'feed' then
    if h >= 85 then msg := 'full';
    else
      h := 100; p := least(100, p + 5); xp := xp + 12;
      s := jsonb_set(s, array['fed', me], to_jsonb(coalesce((s->'fed'->>me)::integer, 0) + 1));
    end if;
  elsif p_act = 'pet' then
    last_pet := (s->'petAt'->>me)::timestamptz;
    if last_pet is not null and now() - last_pet < interval '20 minutes' then msg := 'cooldown';
    else
      p := least(100, p + 15); xp := xp + 6;
      s := jsonb_set(s, array['petAt', me], to_jsonb(now()));
    end if;
  elsif p_act = 'rename' then
    if p_arg is null or p_arg !~ '^[A-Za-z0-9 ]{1,12}$' then raise exception 'bad name'; end if;
    s := jsonb_set(s, '{name}', to_jsonb(upper(p_arg)));
  elsif p_act in ('wear_head','wear_neck','wear_face') then
    if p_arg is null or p_arg !~ '^[a-z]{0,12}$' then raise exception 'bad item'; end if;
    s := jsonb_set(s, array['wear', substr(p_act, 6)], to_jsonb(p_arg));
  elsif p_act <> 'look' then
    raise exception 'unknown act';
  end if;

  s := s || jsonb_build_object('h', h, 'p', p, 'xp', xp, 't', now());
  if msg = 'ok' and p_act <> 'look' then
    s := s || jsonb_build_object('by', who, 'act', p_act, 'at', now());
  end if;
  update public.cat_family set state = s, updated_at = now() where team_id = t;
  return s || jsonb_build_object('msg', msg);
end;
$$;

revoke all on function public.cat_family_get() from public;
revoke all on function public.cat_family_act(text, text) from public;
grant execute on function public.cat_family_get() to authenticated;
grant execute on function public.cat_family_act(text, text) to authenticated;

-- 4. Visiting shows a little more of the room (still only the room) ----------
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
           'decor',  c.state -> 'decor',
           'look',   c.state -> 'look',
           'scene',  c.state -> 'scene',
           'title',  c.state -> 'title'),
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

commit;

-- ---------------------------------------------------------------------------
-- VERIFY  (Supabase shows the last result; run each block on its own to see all)
-- ---------------------------------------------------------------------------

-- 1. The three tables exist with RLS on.
select tablename, rowsecurity
from pg_tables
where schemaname = 'public' and tablename in ('cat_playdates','cat_coop','cat_family')
order by tablename;

-- 2. cat_family has NO policies (reachable only through its functions).
select count(*) as cat_family_policies
from pg_policies
where schemaname = 'public' and tablename = 'cat_family';

-- 3. The family functions are SECURITY DEFINER.
select p.proname, p.prosecdef as security_definer
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname in ('cat_family_get','cat_family_act','cat_room_visit')
order by p.proname;

-- 4. profiles still has NO update policy reachable from the client (zero rows).
select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'profiles' and cmd in ('UPDATE','ALL');

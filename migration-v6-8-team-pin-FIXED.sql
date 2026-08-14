-- GUY WORK OS V6.8
-- TEAM CODE + PERSONAL 4-DIGIT PIN
-- Run AFTER V6.7.
-- Creates Marketing team and assigns the Super Admin to it.
-- Team Code starts unset; set it from Team Overview after deploying V6.8.

begin;

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  team_code_hash text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists team_id uuid references public.teams(id) on delete set null;

create table if not exists public.user_pins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  pin_hash text not null,
  updated_at timestamptz not null default now()
);

-- Create/reuse Marketing team for the single Super Admin.
do $$
declare
  v_team uuid;
begin
  select team_id into v_team
  from public.profiles
  where user_id = '4aacdd72-a121-4eb4-af36-dc36e9936409'::uuid;

  if v_team is null then
    insert into public.teams(name, created_by)
    values ('Marketing','4aacdd72-a121-4eb4-af36-dc36e9936409'::uuid)
    returning id into v_team;

    update public.profiles
    set team_id = v_team
    where user_id = '4aacdd72-a121-4eb4-af36-dc36e9936409'::uuid;
  end if;
end $$;

-- Helper: current user's team.
create or replace function public.my_team_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select p.team_id
  from public.profiles p
  where p.user_id = auth.uid()
$$;

revoke all on function public.my_team_id() from public;
grant execute on function public.my_team_id() to authenticated;

-- Helper: verify that another profile belongs to the same team.
create or replace function public.same_team(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles me
    join public.profiles other on other.user_id = p_user
    where me.user_id = auth.uid()
      and me.team_id is not null
      and other.team_id = me.team_id
  )
$$;

revoke all on function public.same_team(uuid) from public;
grant execute on function public.same_team(uuid) to authenticated;

-- Team table RLS: members can read only their own team.
alter table public.teams enable row level security;
drop policy if exists "teams_read_own" on public.teams;
create policy "teams_read_own"
on public.teams for select to authenticated
using (id = public.my_team_id());

-- Never expose PIN rows directly to clients.
alter table public.user_pins enable row level security;
drop policy if exists "user_pins_no_direct_access" on public.user_pins;
-- Intentionally no SELECT/INSERT/UPDATE/DELETE policy.

-- Does the signed-in user already have a PIN?
create or replace function public.has_my_pin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists(select 1 from public.user_pins where user_id = auth.uid())
$$;

revoke all on function public.has_my_pin() from public;
grant execute on function public.has_my_pin() to authenticated;

-- Set/change own PIN. PIN hash never leaves PostgreSQL.
create or replace function public.set_my_pin(p_pin text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_pin !~ '^[0-9]{4}$' then
    raise exception 'PIN must be exactly 4 digits';
  end if;

  insert into public.user_pins(user_id,pin_hash,updated_at)
  values(auth.uid(), extensions.crypt(p_pin, extensions.gen_salt('bf', 10)), now())
  on conflict(user_id) do update
    set pin_hash = excluded.pin_hash,
        updated_at = now();
  return true;
end;
$$;

revoke all on function public.set_my_pin(text) from public;
grant execute on function public.set_my_pin(text) to authenticated;

-- Verify own PIN.
create or replace function public.verify_my_pin(p_pin text)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select coalesce((
    select extensions.crypt(p_pin, pin_hash) = pin_hash
    from public.user_pins
    where user_id = auth.uid()
  ), false)
$$;

revoke all on function public.verify_my_pin(text) from public;
grant execute on function public.verify_my_pin(text) to authenticated;

-- Join a team using its secret code. Code/hash is never returned to the browser.
create or replace function public.join_team_with_code(p_code text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_team uuid;
begin
  if exists(select 1 from public.profiles where user_id=auth.uid() and team_id is not null) then
    return true;
  end if;

  select id into v_team
  from public.teams
  where team_code_hash is not null
    and extensions.crypt(p_code, team_code_hash) = team_code_hash
  limit 1;

  if v_team is null then
    return false;
  end if;

  update public.profiles
  set team_id = v_team
  where user_id = auth.uid();

  return true;
end;
$$;

revoke all on function public.join_team_with_code(text) from public;
grant execute on function public.join_team_with_code(text) to authenticated;

-- The one Super Admin can set team name and optionally replace the team code.
create or replace function public.admin_update_team(p_name text, p_code text default null)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_team uuid;
begin
  if not public.is_admin() then
    raise exception 'Super Admin only';
  end if;

  select team_id into v_team
  from public.profiles
  where user_id = auth.uid();

  if v_team is null then
    raise exception 'Admin has no team';
  end if;

  if nullif(trim(p_name),'') is null then
    raise exception 'Team name required';
  end if;

  if p_code is not null and length(trim(p_code)) < 4 then
    raise exception 'Team code must be at least 4 characters';
  end if;

  update public.teams
  set name = trim(p_name),
      team_code_hash = case
        when p_code is null then team_code_hash
        else extensions.crypt(trim(p_code), extensions.gen_salt('bf',10))
      end,
      updated_at = now()
  where id = v_team;

  return true;
end;
$$;

revoke all on function public.admin_update_team(text,text) from public;
grant execute on function public.admin_update_team(text,text) to authenticated;

-- Tighten profile visibility: self, or Super Admin viewing members in the same team.
drop policy if exists "profiles_read_self_or_admin" on public.profiles;
create policy "profiles_read_self_or_admin"
on public.profiles
for select to authenticated
using (
  user_id = auth.uid()
  or (public.is_admin() and public.same_team(user_id))
);

-- Tasks: Member = own only. Super Admin = same-team tasks.
drop policy if exists "tasks_read_own_or_admin" on public.tasks;
drop policy if exists "tasks_insert_own_or_admin" on public.tasks;
drop policy if exists "tasks_update_own_or_admin" on public.tasks;
drop policy if exists "tasks_delete_own_or_admin" on public.tasks;

create policy "tasks_read_own_or_admin"
on public.tasks for select to authenticated
using (user_id=auth.uid() or (public.is_admin() and public.same_team(user_id)));

create policy "tasks_insert_own_or_admin"
on public.tasks for insert to authenticated
with check (user_id=auth.uid() or (public.is_admin() and public.same_team(user_id)));

create policy "tasks_update_own_or_admin"
on public.tasks for update to authenticated
using (user_id=auth.uid() or (public.is_admin() and public.same_team(user_id)))
with check (user_id=auth.uid() or (public.is_admin() and public.same_team(user_id)));

create policy "tasks_delete_own_or_admin"
on public.tasks for delete to authenticated
using (user_id=auth.uid() or (public.is_admin() and public.same_team(user_id)));

-- Categories: same rule.
drop policy if exists "categories_read_own_or_admin" on public.categories;
drop policy if exists "categories_insert_own_or_admin" on public.categories;
drop policy if exists "categories_update_own_or_admin" on public.categories;
drop policy if exists "categories_delete_own_or_admin" on public.categories;

create policy "categories_read_own_or_admin"
on public.categories for select to authenticated
using (user_id=auth.uid() or (public.is_admin() and public.same_team(user_id)));

create policy "categories_insert_own_or_admin"
on public.categories for insert to authenticated
with check (user_id=auth.uid() or (public.is_admin() and public.same_team(user_id)));

create policy "categories_update_own_or_admin"
on public.categories for update to authenticated
using (user_id=auth.uid() or (public.is_admin() and public.same_team(user_id)))
with check (user_id=auth.uid() or (public.is_admin() and public.same_team(user_id)));

create policy "categories_delete_own_or_admin"
on public.categories for delete to authenticated
using (user_id=auth.uid() or (public.is_admin() and public.same_team(user_id)));

commit;

-- VERIFY
select p.email,p.role,p.team_id,t.name as team
from public.profiles p
left join public.teams t on t.id=p.team_id
order by p.created_at;

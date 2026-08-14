-- GUY WORK OS V6 MIGRATION
-- Run this AFTER the V5 schema is already installed.
-- Adds secure admin/member roles and prepares the app for team visibility.

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'member' check (role in ('admin','member')),
  status text not null default 'active' check (status in ('active','suspended')),
  created_at timestamptz not null default now()
);

-- Backfill existing Auth users
insert into public.profiles (user_id, email, full_name)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'full_name', split_part(coalesce(u.email,''),'@',1))
from auth.users u
on conflict (user_id) do nothing;

-- Automatically create a profile whenever somebody registers.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (user_id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(coalesce(new.email,''),'@',1))
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Helper used by RLS. SECURITY DEFINER prevents recursive profile-policy lookups.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.user_id = auth.uid()
      and p.role = 'admin'
      and p.status = 'active'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

alter table public.profiles enable row level security;

drop policy if exists "profiles_read_self_or_admin" on public.profiles;
drop policy if exists "profiles_admin_update" on public.profiles;

create policy "profiles_read_self_or_admin"
on public.profiles
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy "profiles_admin_update"
on public.profiles
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Replace V5 RLS policies with admin-aware policies.
drop policy if exists "tasks_select_own" on public.tasks;
drop policy if exists "tasks_insert_own" on public.tasks;
drop policy if exists "tasks_update_own" on public.tasks;
drop policy if exists "tasks_delete_own" on public.tasks;

create policy "tasks_read_own_or_admin"
on public.tasks for select to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy "tasks_insert_own_or_admin"
on public.tasks for insert to authenticated
with check (user_id = auth.uid() or public.is_admin());

create policy "tasks_update_own_or_admin"
on public.tasks for update to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create policy "tasks_delete_own_or_admin"
on public.tasks for delete to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists "categories_select_own" on public.categories;
drop policy if exists "categories_insert_own" on public.categories;
drop policy if exists "categories_update_own" on public.categories;
drop policy if exists "categories_delete_own" on public.categories;

create policy "categories_read_own_or_admin"
on public.categories for select to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy "categories_insert_own_or_admin"
on public.categories for insert to authenticated
with check (user_id = auth.uid() or public.is_admin());

create policy "categories_update_own_or_admin"
on public.categories for update to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create policy "categories_delete_own_or_admin"
on public.categories for delete to authenticated
using (user_id = auth.uid() or public.is_admin());

-- IMPORTANT BOOTSTRAP:
-- After your own account has registered, replace YOUR_EMAIL and run this ONCE.
-- update public.profiles set role = 'admin' where email = 'YOUR_EMAIL';

create index if not exists profiles_role_idx on public.profiles(role);
create index if not exists profiles_status_idx on public.profiles(status);

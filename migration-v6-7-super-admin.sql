-- GUY WORK OS V6.7 MIGRATION
-- ONE SUPER ADMIN ONLY
-- Super Admin: bigxxct1342@gmail.com
-- User ID: 4aacdd72-a121-4eb4-af36-dc36e9936409
-- Run AFTER V6 migration.

begin;

-- Remove old role check, convert every old admin to member first.
alter table public.profiles drop constraint if exists profiles_role_check;

update public.profiles
set role = 'member'
where role <> 'member';

-- Lock the designated owner account as the only Super Admin.
update public.profiles
set role = 'super_admin',
    status = 'active'
where user_id = '4aacdd72-a121-4eb4-af36-dc36e9936409'::uuid
   or lower(email) = lower('bigxxct1342@gmail.com');

-- Role may only be member or super_admin.
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('super_admin','member'));

-- New registrations are always members.
alter table public.profiles
  alter column role set default 'member';

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(coalesce(new.email,''),'@',1)),
    'member'
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

-- RLS helper now recognizes only the one super_admin role.
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
      and p.role = 'super_admin'
      and p.status = 'active'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- Block profile role changes through the client.
drop policy if exists "profiles_admin_update" on public.profiles;

-- Super Admin may update non-role profile fields only through service/admin tooling.
-- Normal app UI has no role promotion action.

commit;

-- VERIFY: this should return exactly ONE row.
select user_id, email, full_name, role, status
from public.profiles
where role = 'super_admin';

-- VERIFY: everyone else should be member.
select role, count(*)
from public.profiles
group by role
order by role;

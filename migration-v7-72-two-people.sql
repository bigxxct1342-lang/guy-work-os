-- PORKCHOP G V7.72
-- TWO PEOPLE ON ONE TEAM, ONE WAY VISIBILITY
--
-- Both people get the whole app. Each owns their own rows. The Super Admin
-- may read and delete across; a member may not see the Super Admin's rows at
-- all, so there is nothing there for them to touch.
--
-- Tasks and Categories were already built this way. The planning tables were
-- not: they were tied to the TEAM and to nothing else, so any second member
-- could read, edit and DELETE every Project, Product, PR and KOL campaign.
-- Every one of those tables already carries created_by, so this is a policy
-- change only -- no column is added and no row is rewritten.
--
-- Safe to run more than once.
-- Run AFTER V6.8.

begin;

-- Tables that carry team_id and created_by themselves.
do $$
declare
  t text;
begin
  foreach t in array array['projects','products','purchase_requests',
                           'kol_campaigns','creative_jobs','posts']
  loop
    if to_regclass('public.'||t) is null then
      continue;
    end if;

    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t||'_team', t);
    execute format('drop policy if exists %I on public.%I', t||'_owner', t);
    execute format(
      'create policy %I on public.%I for all to authenticated
         using (team_id = public.my_team_id()
                and (created_by = auth.uid() or public.is_admin()))
         with check (team_id = public.my_team_id()
                and (created_by = auth.uid() or public.is_admin()))',
      t||'_owner', t);
  end loop;
end $$;

-- Children reach both team_id and created_by through their parent row.
do $$
declare
  spec text;
begin
  foreach spec in array array[
    'product_milestones:products:product_id',
    'product_docs:products:product_id',
    'project_items:projects:project_id'
  ]
  loop
    declare
      c  text := split_part(spec,':',1);
      pt text := split_part(spec,':',2);
      fk text := split_part(spec,':',3);
      cond text;
    begin
      if to_regclass('public.'||c) is null then
        continue;
      end if;

      cond := format(
        'exists(select 1 from public.%I p
                 where p.id = %I
                   and p.team_id = public.my_team_id()
                   and (p.created_by = auth.uid() or public.is_admin()))', pt, fk);

      execute format('alter table public.%I enable row level security', c);
      execute format('drop policy if exists %I on public.%I', c||'_team', c);
      execute format('drop policy if exists %I on public.%I', c||'_owner', c);
      execute format('drop policy if exists "milestones_team" on public.%I', c);
      execute format('drop policy if exists "docs_team" on public.%I', c);
      execute format(
        'create policy %I on public.%I for all to authenticated
           using (%s) with check (%s)', c||'_owner', c, cond, cond);
    end;
  end loop;
end $$;

-- product_steps hangs two levels down, through its milestone.
do $$
begin
  if to_regclass('public.product_steps') is not null then
    alter table public.product_steps enable row level security;
    drop policy if exists "steps_team" on public.product_steps;
    drop policy if exists "product_steps_team" on public.product_steps;
    drop policy if exists "product_steps_owner" on public.product_steps;
    create policy "product_steps_owner" on public.product_steps for all to authenticated
      using (exists(
        select 1 from public.product_milestones m
        join public.products p on p.id = m.product_id
        where m.id = milestone_id
          and p.team_id = public.my_team_id()
          and (p.created_by = auth.uid() or public.is_admin())))
      with check (exists(
        select 1 from public.product_milestones m
        join public.products p on p.id = m.product_id
        where m.id = milestone_id
          and p.team_id = public.my_team_id()
          and (p.created_by = auth.uid() or public.is_admin())));
  end if;
end $$;

-- A member may read the profile rows of their own team, name only, so the app
-- can label an owner. The Super Admin keeps full read. Nothing here exposes a
-- member's tasks -- those are governed by the tasks policy, which is unchanged.
drop policy if exists "profiles_read_self_or_admin" on public.profiles;
create policy "profiles_read_self_or_admin"
on public.profiles for select to authenticated
using (user_id = auth.uid() or public.is_admin());

commit;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------

-- 1. Every planning table should now test created_by, not just team_id.
select tablename, policyname, qual
from pg_policies
where schemaname = 'public'
  and tablename in ('projects','project_items','products','product_milestones',
                    'product_steps','product_docs','purchase_requests',
                    'kol_campaigns','creative_jobs','posts')
order by tablename;

-- 2. Tasks and Categories should still read "own row OR admin" -- unchanged.
select tablename, policyname, cmd, qual
from pg_policies
where schemaname = 'public' and tablename in ('tasks','categories')
order by tablename, cmd;

-- 3. Nothing should be left without an owner. Every row must have created_by,
--    otherwise it becomes invisible to everyone except the Super Admin.
select 'projects' as t, count(*) from public.projects where created_by is null
union all select 'products', count(*) from public.products where created_by is null
union all select 'purchase_requests', count(*) from public.purchase_requests where created_by is null
union all select 'kol_campaigns', count(*) from public.kol_campaigns where created_by is null;

-- 4. There must still be exactly one Super Admin, and it must be you.
select user_id, email, full_name, role, status
from public.profiles
where role = 'super_admin';

-- 5. Who is on the team.
select p.full_name, p.email, p.role, p.status, t.name as team
from public.profiles p
left join public.teams t on t.id = p.team_id
order by p.role desc, p.full_name;

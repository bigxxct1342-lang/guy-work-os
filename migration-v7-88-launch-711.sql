-- PORKCHOP G V7.88
-- PRODUCT LAUNCH: THE 7-11 PROCESS, AND A PLAN WITH REAL DATES
--
--   product_milestones.phase   now also 'seven' -- getting the product into
--                              7-11: present it, pass Product Selection
--                              (results come out on Tuesdays), then send QA
--                              7-11 their papers with the real mock-up.
--   product_milestones.start_on  the day this piece of work actually starts
--                              (or is planned to). Empty = "right after the
--                              one before it", as before. Filled in by hand
--                              on the plan, or by the app the first time a
--                              step under it is set to Working or Done, so
--                              a 45-day FDA that began last month stops
--                              being re-counted from today every morning.
--   product_milestones.tmpl    stable key for template milestones, so the
--                              app can find Product Selection or the QA
--                              step even after they are renamed.
--   product_steps.status       now also 'failed' -- Product Selection did
--                              not pass this round.
--
-- Nothing here changes who can see what. The rows stay under the RLS set in
-- V7.72 (owner only, through the product).
-- Safe to run more than once. Run AFTER V7.77.

begin;

alter table public.product_milestones
  add column if not exists start_on date,
  add column if not exists tmpl text;

-- Replace whatever check currently guards phase / status with the wider one.
do $$
declare r record;
begin
  for r in
    select conname from pg_constraint
    where conrelid = 'public.product_milestones'::regclass and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%phase%'
  loop
    execute format('alter table public.product_milestones drop constraint %I', r.conname);
  end loop;
  alter table public.product_milestones
    add constraint product_milestones_phase_check
    check (phase in ('formula_fda','label','carton','seven'));

  for r in
    select conname from pg_constraint
    where conrelid = 'public.product_steps'::regclass and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%status%'
  loop
    execute format('alter table public.product_steps drop constraint %I', r.conname);
  end loop;
  alter table public.product_steps
    add constraint product_steps_status_check
    check (status in ('done','working','wait','next','skipped','failed'));
end $$;

commit;

-- ---------------------------------------------------------------------------
-- VERIFY  (Supabase shows the last result; run each block on its own to see all)
-- ---------------------------------------------------------------------------

-- 1. The two new columns exist (two rows: start_on date, tmpl text).
select column_name, data_type
from information_schema.columns
where table_schema = 'public' and table_name = 'product_milestones'
  and column_name in ('start_on','tmpl')
order by column_name;

-- 2. The checks now allow 'seven' and 'failed' (two rows, both mention them).
select conname, pg_get_constraintdef(oid) as rule
from pg_constraint
where conname in ('product_milestones_phase_check','product_steps_status_check');

-- 3. RLS is still on for both tables (two rows, rowsecurity = true).
select tablename, rowsecurity
from pg_tables
where schemaname = 'public' and tablename in ('product_milestones','product_steps')
order by tablename;

-- 4. profiles still has NO update policy reachable from the client (zero rows).
select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'profiles' and cmd in ('UPDATE','ALL');

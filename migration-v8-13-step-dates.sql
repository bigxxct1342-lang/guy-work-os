-- PORKCHOP G V8.13
-- PRODUCT LAUNCH: THE DAY EACH STEP WAS ACTUALLY DONE
--
-- One date column on product_steps. When a step has it, the plan runs from
-- that real date instead of the estimate, so every step after it moves.
-- product_steps already has row level security through its milestone and
-- product (V7.72); a new column needs no new policy.
--
-- Safe to run more than once.
-- Run AFTER V7.72.

alter table public.product_steps
  add column if not exists done_on date;

comment on column public.product_steps.done_on is
  'The day this step was actually finished. The launch plan starts the next step from it.';

-- ---------------------------------------------------------------------------
-- VERIFY  (Supabase shows the last result; run each block on its own to see all)
-- ---------------------------------------------------------------------------

-- 1. The column exists and is a date (one row: done_on | date).
select column_name, data_type
from information_schema.columns
where table_schema = 'public' and table_name = 'product_steps' and column_name = 'done_on';

-- 2. product_steps still has its row level security policy (one row or more).
select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'product_steps';

-- 3. profiles still has NO update policy reachable from the client (zero rows).
select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'profiles' and cmd in ('UPDATE','ALL');

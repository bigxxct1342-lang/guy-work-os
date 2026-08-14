-- GUY WORK OS V7.0
-- Small feature migration only. No Category architecture rewrite.
-- Adds Estimated Time + simple Recurring Task support.

begin;

alter table public.tasks
  add column if not exists estimate_minutes integer;

alter table public.tasks
  add column if not exists recurring_rule text;

alter table public.tasks
  drop constraint if exists tasks_recurring_rule_check;

alter table public.tasks
  add constraint tasks_recurring_rule_check
  check (recurring_rule is null or recurring_rule in ('daily','weekly','monthly'));

alter table public.tasks
  drop constraint if exists tasks_estimate_minutes_check;

alter table public.tasks
  add constraint tasks_estimate_minutes_check
  check (estimate_minutes is null or estimate_minutes between 1 and 1440);

create index if not exists tasks_due_idx on public.tasks(due);
create index if not exists tasks_status_idx on public.tasks(status);
create index if not exists tasks_user_due_idx on public.tasks(user_id,due);

commit;

select
  count(*) as tasks_total,
  count(*) filter (where estimate_minutes is not null) as tasks_with_estimate,
  count(*) filter (where recurring_rule is not null) as recurring_tasks
from public.tasks;

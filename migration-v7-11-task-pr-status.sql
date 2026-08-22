-- GUY WORK OS V7.11
-- Purchasing status directly on a task.
--
-- Most PRs exist *because of* a job, so making the job carry its own PR status
-- avoids entering the same thing twice (once as a task, once as a PR record).
-- The standalone purchase_requests table from V7.10 stays for PRs that have no
-- job behind them; the PR / GRPO screen shows both in the same lanes.
--
-- Note the stages outlive the task: GRPO and sending documents to Accounting
-- happen after the work is finished, so a Done task whose pr_stage is not yet
-- 'done' keeps showing on the dashboard until the paperwork clears.

begin;

alter table public.tasks
  add column if not exists pr_stage text,
  add column if not exists pr_number text,
  add column if not exists po_number text,
  add column if not exists pr_stage_since date;

alter table public.tasks drop constraint if exists tasks_pr_stage_check;
alter table public.tasks add constraint tasks_pr_stage_check
  check (pr_stage is null or pr_stage in
    ('draft','wait_po','working','wait_grpo','wait_docs','done'));

-- only a small minority of tasks carry a PR, so keep the index partial
create index if not exists tasks_pr_stage_idx
  on public.tasks(pr_stage) where pr_stage is not null;

commit;

-- GUY WORK OS V7.10
-- PR / GRPO tracker: the SAP purchasing trail that runs alongside a job.
--
-- Kept separate from Tasks on purpose. These items sit idle for long
-- stretches -- waiting on a PO from Purchasing above all -- which is exactly
-- why they get forgotten when mixed into a normal task list. Each row records
-- the date it entered its current stage so the app can age it and chase.
--
-- Team-scoped, the same boundary already used by tasks/categories/products.

begin;

create table if not exists public.purchase_requests (
  id bigint generated always as identity primary key,
  team_id uuid not null references public.teams(id) on delete cascade,
  title text not null,
  pr_number text,
  po_number text,
  vendor text,
  amount numeric(14,2),
  note text,
  stage text not null default 'draft'
    check (stage in ('draft','wait_po','working','wait_grpo','wait_docs','done')),
  -- date the row entered `stage`; drives the "waiting N days" chase
  stage_since date not null default current_date,
  -- milestone stamps, kept so a finished PR still shows how long each leg took
  pr_opened_on date,
  po_received_on date,
  work_done_on date,
  grpo_on date,
  docs_sent_on date,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists purchase_requests_team_idx
  on public.purchase_requests(team_id);
create index if not exists purchase_requests_open_idx
  on public.purchase_requests(team_id, stage, stage_since);

alter table public.purchase_requests enable row level security;

drop policy if exists "purchase_requests_team" on public.purchase_requests;
create policy "purchase_requests_team" on public.purchase_requests for all
  using (team_id = public.my_team_id())
  with check (team_id = public.my_team_id());

commit;

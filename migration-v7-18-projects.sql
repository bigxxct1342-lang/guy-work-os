-- GUY WORK OS V7.18
-- Projects: an umbrella that groups work already living elsewhere.
--
-- A project is a plan -- a media plan, a year plan, anything else -- covering
-- one or more products. Work inside it is grouped by channel (KOL Review, BMN,
-- offline media, collab, ...), which is how the plan is actually written, not
-- by which table happens to store it.
--
-- The central rule: a project does NOT hold work, it points at work. Linking a
-- task leaves that task exactly where it was, still in Tasks and Calendar and
-- the dashboard; only a pointer is added. Removing it from a project deletes
-- nothing. That is what keeps projects from becoming a second, competing copy
-- of the task list.
--
-- Products are free text on purpose: plenty of them are already launched and
-- selling, so requiring a Product Launch record would exclude those.

begin;

create table if not exists public.projects (
  id bigint generated always as identity primary key,
  team_id uuid not null references public.teams(id) on delete cascade,
  name text not null,
  -- "Media Plan", "Year Plan", or anything typed in
  kind text,
  -- free text; NOT a reference to products, see note above
  products text,
  start_date date,
  note text,
  status text not null default 'active' check (status in ('active','done','cancelled')),
  -- editable list, seeded by the app with the usual channels
  channels jsonb not null default '[]'::jsonb,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists projects_team_idx on public.projects(team_id);

create table if not exists public.project_items (
  id bigint generated always as identity primary key,
  project_id bigint not null references public.projects(id) on delete cascade,
  channel text not null,
  kind text not null check (kind in ('task','kol','pr')),
  ref_id bigint not null,
  -- Only used for kol/pr rows. A linked task keeps its own due date as the
  -- single source of truth, so it stays correct in Calendar and the dashboard.
  end_date date,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists project_items_project_idx on public.project_items(project_id);

-- One piece of work belongs to at most one project, enforced here rather than
-- left to the UI, so the same task can never be counted under two plans.
create unique index if not exists project_items_unique_ref
  on public.project_items(kind, ref_id);

alter table public.projects enable row level security;
alter table public.project_items enable row level security;

drop policy if exists "projects_team" on public.projects;
create policy "projects_team" on public.projects for all
  using (team_id = public.my_team_id())
  with check (team_id = public.my_team_id());

drop policy if exists "project_items_team" on public.project_items;
create policy "project_items_team" on public.project_items for all
  using (exists(select 1 from public.projects p
                where p.id = project_id and p.team_id = public.my_team_id()))
  with check (exists(select 1 from public.projects p
                     where p.id = project_id and p.team_id = public.my_team_id()));

commit;

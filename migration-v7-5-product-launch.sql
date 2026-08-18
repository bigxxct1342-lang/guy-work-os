-- GUY WORK OS V7.5
-- Product Launch: team-wide (MKT team only) NPD tracker.
-- Separate from personal Tasks entirely. Visible only to members of the
-- signed-in user's team (same boundary already used for tasks/categories).

begin;

create table if not exists public.products (
  id bigint generated always as identity primary key,
  team_id uuid not null references public.teams(id) on delete cascade,
  name text not null,
  status text not null default 'active' check (status in ('active','draft','done')),
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists products_team_idx on public.products(team_id);

create table if not exists public.product_milestones (
  id bigint generated always as identity primary key,
  product_id bigint not null references public.products(id) on delete cascade,
  phase text not null check (phase in ('formula_fda','label','carton')),
  seq integer not null default 0,
  title text not null,
  duration_days integer,
  created_at timestamptz not null default now()
);
create index if not exists product_milestones_product_idx on public.product_milestones(product_id);

create table if not exists public.product_steps (
  id bigint generated always as identity primary key,
  milestone_id bigint not null references public.product_milestones(id) on delete cascade,
  seq integer not null default 0,
  name text not null,
  status text not null default 'next' check (status in ('done','working','wait','next','skipped')),
  owners text,
  deadline_note text,
  created_at timestamptz not null default now()
);
create index if not exists product_steps_milestone_idx on public.product_steps(milestone_id);

create table if not exists public.product_docs (
  id bigint generated always as identity primary key,
  product_id bigint not null references public.products(id) on delete cascade,
  parent_id bigint references public.product_docs(id) on delete cascade,
  seq integer not null default 0,
  label text not null,
  state text not null default 'not_yet' check (state in ('have','not_yet','na')),
  note text,
  created_at timestamptz not null default now()
);
create index if not exists product_docs_product_idx on public.product_docs(product_id);
create index if not exists product_docs_parent_idx on public.product_docs(parent_id);

-- Thai public holidays, used by the Timeline's business-day calculation.
-- Not team-scoped (just calendar data) — readable by any signed-in user,
-- editable by the Super Admin only. Extend this table every year.
create table if not exists public.thai_holidays (
  holiday_date date primary key,
  name text not null
);

insert into public.thai_holidays (holiday_date, name) values
  ('2026-10-23', 'วันปิยมหาราช'),
  ('2026-12-05', 'วันพ่อแห่งชาติ'),
  ('2026-12-10', 'วันรัฐธรรมนูญ'),
  ('2026-12-31', 'วันสิ้นปี'),
  ('2027-01-01', 'วันขึ้นปีใหม่')
on conflict (holiday_date) do nothing;

alter table public.products enable row level security;
alter table public.product_milestones enable row level security;
alter table public.product_steps enable row level security;
alter table public.product_docs enable row level security;
alter table public.thai_holidays enable row level security;

drop policy if exists "products_team" on public.products;
create policy "products_team" on public.products for all
  using (team_id = public.my_team_id())
  with check (team_id = public.my_team_id());

drop policy if exists "milestones_team" on public.product_milestones;
create policy "milestones_team" on public.product_milestones for all
  using (exists(select 1 from public.products p where p.id = product_id and p.team_id = public.my_team_id()))
  with check (exists(select 1 from public.products p where p.id = product_id and p.team_id = public.my_team_id()));

drop policy if exists "steps_team" on public.product_steps;
create policy "steps_team" on public.product_steps for all
  using (exists(
    select 1 from public.product_milestones m
    join public.products p on p.id = m.product_id
    where m.id = milestone_id and p.team_id = public.my_team_id()
  ))
  with check (exists(
    select 1 from public.product_milestones m
    join public.products p on p.id = m.product_id
    where m.id = milestone_id and p.team_id = public.my_team_id()
  ));

drop policy if exists "docs_team" on public.product_docs;
create policy "docs_team" on public.product_docs for all
  using (exists(select 1 from public.products p where p.id = product_id and p.team_id = public.my_team_id()))
  with check (exists(select 1 from public.products p where p.id = product_id and p.team_id = public.my_team_id()));

drop policy if exists "holidays_read_all" on public.thai_holidays;
create policy "holidays_read_all" on public.thai_holidays for select to authenticated using (true);

drop policy if exists "holidays_admin_write" on public.thai_holidays;
create policy "holidays_admin_write" on public.thai_holidays for all
  using (public.is_admin())
  with check (public.is_admin());

commit;

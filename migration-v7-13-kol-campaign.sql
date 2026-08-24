-- GUY WORK OS V7.13
-- KOL campaign tracker.
--
-- A KOL hire is a long relay between three parties -- us, the agency, and the
-- KOLs -- where almost every stage is spent waiting on somebody else. Unlike
-- the NPD tracker the expected duration is not fixed by process: each campaign
-- negotiates its own timings, so stage_days is per-campaign and editable
-- inline rather than a global setting.
--
-- Deliberately NO per-KOL roster. Naming every influencer is more data entry
-- than it is worth; the pain is "how many rounds of revisions has this dragged
-- through", which `revisions` captures with a single counter per stage.

begin;

create table if not exists public.kol_campaigns (
  id bigint generated always as identity primary key,
  team_id uuid not null references public.teams(id) on delete cascade,
  name text not null,
  agency text,
  budget numeric(14,2),
  note text,
  stage text not null default 'brief'
    check (stage in ('brief','proposal','review','quotation','pr_sign','kol_brief',
                     'storyline','content','ads_set','live','report','closing',
                     'done','cancelled')),
  stage_since date not null default current_date,
  -- expected days per stage, typed per campaign: {"proposal":7,"storyline":10}
  stage_days jsonb not null default '{}'::jsonb,
  -- revision rounds per stage: {"review":2,"storyline":4}
  revisions jsonb not null default '{}'::jsonb,
  -- why the campaign was dropped, when the agency is changed out
  cancel_reason text,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists kol_campaigns_team_idx
  on public.kol_campaigns(team_id);
create index if not exists kol_campaigns_open_idx
  on public.kol_campaigns(team_id, stage, stage_since);

alter table public.kol_campaigns enable row level security;

drop policy if exists "kol_campaigns_team" on public.kol_campaigns;
create policy "kol_campaigns_team" on public.kol_campaigns for all
  using (team_id = public.my_team_id())
  with check (team_id = public.my_team_id());

commit;

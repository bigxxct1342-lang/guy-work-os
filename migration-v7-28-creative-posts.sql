-- PORKCHOP G V7.28
-- Creative jobs and the posting schedule.
--
-- A creative job is a short relay that LOOPS: we brief, Creative returns a
-- draft, we either approve it or ask for another. Three rounds is typical and
-- there is no ceiling, so the rounds are an array rather than columns -- a
-- schema with draft_1 / draft_2 / draft_3 would have to be migrated the first
-- time a job needed a fourth.
--
-- No comment text is stored. The feedback is a file that already lives inside
-- the company's own systems, and copying it here would add a step without
-- adding an answer. What the app keeps is the shape of the relay: how many
-- rounds, how long each one took, and who is holding it right now.
--
-- One date, not two. "The day we need the artwork" and "the day it is
-- approved" are the same day in practice, so due_date is the target and
-- approved_on records what actually happened against it.

begin;

create table if not exists public.creative_jobs (
  id bigint generated always as identity primary key,
  team_id uuid not null references public.teams(id) on delete cascade,
  title text not null,
  -- optional: plenty of creative work is not part of a formal plan
  project_id bigint references public.projects(id) on delete set null,
  -- A creative job usually starts life as an ordinary task ("ทำ KV หม่าล่า").
  -- Pointing at that task instead of retyping its name keeps one piece of work
  -- as one record: the task stays in Tasks, Calendar and the dashboard, and
  -- the creative job is the relay running alongside it.
  task_id bigint references public.tasks(id) on delete set null,
  brief_note text,
  brief_url text,
  brief_sent_on date,
  -- the day the artwork must be approved by; left null when a linked post
  -- supplies it instead
  due_date date,
  approved_on date,
  status text not null default 'briefing'
    check (status in ('briefing','waiting','reviewing','done','cancelled')),
  -- who the job is sitting with right now
  waiting_on text not null default 'us' check (waiting_on in ('us','creative')),
  -- [{"n":1,"sent":"2026-09-03","back":"2026-09-06","outcome":"revise"}, ...]
  -- unbounded on purpose: see the note above
  rounds jsonb not null default '[]'::jsonb,
  note text,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists creative_jobs_team_idx on public.creative_jobs(team_id);
create index if not exists creative_jobs_project_idx on public.creative_jobs(project_id);
-- One task drives at most one creative job, enforced here rather than left to
-- the UI, so the same work can never be tracked twice.
create unique index if not exists creative_jobs_task_unique
  on public.creative_jobs(task_id) where task_id is not null;

create table if not exists public.posts (
  id bigint generated always as identity primary key,
  team_id uuid not null references public.teams(id) on delete cascade,
  title text not null,
  project_id bigint references public.projects(id) on delete set null,
  -- linking a post to its artwork is what lets the calendar say
  -- "posting on the 15th, artwork still on draft 2"
  creative_id bigint references public.creative_jobs(id) on delete set null,
  channel text,
  kind text not null default 'post' check (kind in ('post','event')),
  post_date date not null,
  -- length in days for an event; a plain post is 1. Stored as a count rather
  -- than an end date because that is how the work is actually described.
  days integer not null default 1 check (days >= 1),
  caption_ready boolean not null default false,
  boost boolean not null default false,
  boost_from date,
  boost_to date,
  status text not null default 'planned' check (status in ('planned','posted','cancelled')),
  note text,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists posts_team_idx on public.posts(team_id);
create index if not exists posts_date_idx on public.posts(post_date);

alter table public.creative_jobs enable row level security;
alter table public.posts enable row level security;

drop policy if exists "creative_jobs_team" on public.creative_jobs;
create policy "creative_jobs_team" on public.creative_jobs for all
  using (team_id = public.my_team_id())
  with check (team_id = public.my_team_id());

drop policy if exists "posts_team" on public.posts;
create policy "posts_team" on public.posts for all
  using (team_id = public.my_team_id())
  with check (team_id = public.my_team_id());

commit;

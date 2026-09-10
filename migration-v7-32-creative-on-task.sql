-- PORKCHOP G V7.32
-- Creative work and its post become part of the task, not records beside it.
--
-- v7.28 made creative_jobs a table of its own and posts another, with a
-- task_id pointing back. That is three records for one piece of work, and it
-- showed: a picker to link them, a unique index to stop them being linked
-- twice, a separate table to read the post details, and no single place that
-- said "this job is at this stage and its caption is still missing".
--
-- The app already had the right pattern and it was not used: a task carries
-- its own purchasing trail in pr_stage / pr_number / po_number. A creative
-- track and a post are the same shape of thing. So they go on the task, one
-- record, and every join disappears with them.
--
-- The old tables are left in place and simply stop being read. Drop them once
-- you are satisfied nothing is missing -- the statements are at the bottom,
-- commented out.

begin;

alter table public.tasks
  -- creative track
  add column if not exists cv_on boolean not null default false,
  add column if not exists cv_status text,
  add column if not exists cv_waiting_on text,
  add column if not exists cv_brief_url text,
  add column if not exists cv_brief_sent_on date,
  add column if not exists cv_approved_on date,
  -- [{"n":1,"sent":"2026-09-03","back":"2026-09-06","outcome":"revise"}, ...]
  -- unbounded: the number of rounds is not knowable in advance
  add column if not exists cv_rounds jsonb not null default '[]'::jsonb,
  -- the post this work goes out as
  add column if not exists post_on boolean not null default false,
  add column if not exists post_channel text,
  add column if not exists post_kind text,
  add column if not exists post_date date,
  -- length in days for an event; a plain post is 1
  add column if not exists post_days integer not null default 1,
  add column if not exists post_caption boolean not null default false,
  add column if not exists post_boost boolean not null default false,
  add column if not exists post_boost_from date,
  add column if not exists post_boost_to date;

alter table public.tasks drop constraint if exists tasks_cv_status_check;
alter table public.tasks add constraint tasks_cv_status_check
  check (cv_status is null or cv_status in ('briefing','waiting','reviewing','done','cancelled'));

alter table public.tasks drop constraint if exists tasks_cv_waiting_check;
alter table public.tasks add constraint tasks_cv_waiting_check
  check (cv_waiting_on is null or cv_waiting_on in ('us','creative'));

alter table public.tasks drop constraint if exists tasks_post_kind_check;
alter table public.tasks add constraint tasks_post_kind_check
  check (post_kind is null or post_kind in ('post','event'));

create index if not exists tasks_cv_on_idx on public.tasks(cv_on) where cv_on;
create index if not exists tasks_post_date_idx on public.tasks(post_date) where post_date is not null;

-- Carry across anything already entered under the old shape. Safe to run on an
-- empty database, and safe to run twice: it only fills columns still unset.
update public.tasks t set
  cv_on = true,
  cv_status = coalesce(t.cv_status, j.status),
  cv_waiting_on = coalesce(t.cv_waiting_on, j.waiting_on),
  cv_brief_url = coalesce(t.cv_brief_url, j.brief_url),
  cv_brief_sent_on = coalesce(t.cv_brief_sent_on, j.brief_sent_on),
  cv_approved_on = coalesce(t.cv_approved_on, j.approved_on),
  cv_rounds = case when t.cv_rounds = '[]'::jsonb then j.rounds else t.cv_rounds end
from public.creative_jobs j
where j.task_id = t.id;

update public.tasks t set
  post_on = true,
  post_channel = coalesce(t.post_channel, p.channel),
  post_kind = coalesce(t.post_kind, p.kind),
  post_date = coalesce(t.post_date, p.post_date),
  post_days = greatest(t.post_days, coalesce(p.days,1)),
  post_caption = t.post_caption or p.caption_ready,
  post_boost = t.post_boost or p.boost,
  post_boost_from = coalesce(t.post_boost_from, p.boost_from),
  post_boost_to = coalesce(t.post_boost_to, p.boost_to)
from public.posts p
join public.creative_jobs j on j.id = p.creative_id
where j.task_id = t.id;

commit;

-- Once you have checked nothing is missing:
-- drop table if exists public.posts;
-- drop table if exists public.creative_jobs;

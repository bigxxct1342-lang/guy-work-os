-- GUY WORK OS V7.14
-- KOL campaign: the agency's real working timeline.
--
-- Partway through a campaign the agency delivers a dated Gantt. Once those
-- dates exist they beat any up-front estimate, so stage_dates holds the date
-- the agency actually committed to for each stage and lateness is measured
-- against that instead of a guessed day count.
--
-- The agency's own sheet alternates "Agency proposes" / "Client feedback" row
-- by row, so the party holding a stage flips back and forth within it.
-- waiting_on records who is holding it right now, overriding the stage default.
--
-- pr_ref links the campaign to the PR it spends through, so the campaign and
-- the PR do not both raise the same alert on the dashboard.

begin;

alter table public.kol_campaigns
  -- {"storyline":"2026-08-14"} -- the date the agency committed to
  add column if not exists stage_dates jsonb not null default '{}'::jsonb,
  -- {"storyline":"รอคุณเอ๋ตอบกลับ"} -- mirrors the Remark column on their sheet
  add column if not exists remarks jsonb not null default '{}'::jsonb,
  -- 'us' | 'agency' | null (fall back to the stage's default owner)
  add column if not exists waiting_on text,
  -- 'task:123' or 'pr:45'
  add column if not exists pr_ref text;

alter table public.kol_campaigns drop constraint if exists kol_waiting_on_check;
alter table public.kol_campaigns add constraint kol_waiting_on_check
  check (waiting_on is null or waiting_on in ('us','agency'));

commit;

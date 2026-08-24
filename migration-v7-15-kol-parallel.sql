-- GUY WORK OS V7.15
-- KOL campaign: stages run in parallel, not single file.
--
-- The first model gave a campaign one current stage and derived everything
-- else from its position, which forced 1 -> 2 -> 3. In practice 2 and 3, or
-- 4 and 5, are worked at the same time. Each stage now carries its own status
-- so any number can be in flight at once, and any can be skipped outright.
--
-- stage_started records when a stage actually began, which is what the Gantt
-- draws from when no planned date has been agreed yet. waiting_map moves the
-- "who is holding this" flip down to the stage, since with parallel stages one
-- campaign-wide answer is meaningless.

begin;

alter table public.kol_campaigns
  -- {"proposal":"doing","review":"doing","brief":"done","ads_set":"skip"}
  add column if not exists stage_status jsonb not null default '{}'::jsonb,
  -- {"proposal":"2026-08-03"} -- the day the stage actually started
  add column if not exists stage_started jsonb not null default '{}'::jsonb,
  -- {"storyline":"us"} -- overrides the stage's default owner
  add column if not exists waiting_map jsonb not null default '{}'::jsonb;

commit;

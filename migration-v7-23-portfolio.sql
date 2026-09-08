-- GUY WORK OS V7.23
-- Archive becomes a record of what was achieved, not just what was ticked off.
--
-- The archive held completed TASKS and nothing else, so the things that would
-- actually go on a CV -- a campaign run end to end, a product taken to shelf,
-- a plan delivered -- never arrived there at all. A portfolio line reads
-- "launched Cockle Mala 40g, 3 SKUs", never "sent product to KOLs", and only
-- the second kind of thing was being kept.
--
-- So finished projects, campaigns and products are HIGHLIGHTS by default:
-- they are already the natural unit of a portfolio, and defaulting them true
-- means nothing has to be tagged by hand after the fact. A finished task is
-- routine unless it is promoted -- most of them are Tuesday, not an
-- achievement. Purchase requests are never highlights; they are counted in
-- the volume tally instead, which is where they belong.
--
-- portfolio_title exists because the working name is written to get work done,
-- not to be read by somebody else later. portfolio_result is the one thing the
-- app cannot derive: it has never stored an outcome or a number.

begin;

-- Routine by default: a promoted task is the exception.
alter table public.tasks
  add column if not exists is_highlight boolean not null default false,
  add column if not exists portfolio_title text,
  add column if not exists portfolio_result text;

-- A delivered plan is a portfolio line on its own.
alter table public.projects
  add column if not exists is_highlight boolean not null default true,
  add column if not exists portfolio_title text,
  add column if not exists portfolio_result text;

-- So is a campaign run from brief to closing.
alter table public.kol_campaigns
  add column if not exists is_highlight boolean not null default true,
  add column if not exists portfolio_title text,
  add column if not exists portfolio_result text;

-- So is a product taken to shelf.
alter table public.products
  add column if not exists is_highlight boolean not null default true,
  add column if not exists portfolio_title text,
  add column if not exists portfolio_result text;

commit;

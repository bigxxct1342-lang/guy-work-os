-- PORKCHOP G V7.90
-- PRODUCT LAUNCH: TASTING ROUNDS, AND OTHER RETAILERS
--
--   product_tastings            one row per tasting round of a product's
--                               formula: when it was tasted, which sample,
--                               what each person said (comments jsonb:
--                               [{who, score, text}], score 1 = ไม่ชอบ,
--                               2 = เฉยๆ, 3 = ชอบ), what is being changed
--                               because of it, when the presentation went
--                               back to the factory and a link to it, and
--                               whether this round is the formula that was
--                               confirmed (CF).
--   product_milestones.phase    now also 'retail' -- other retailers
--                               (Makro / Lotus's / Big C ...), after 7-11.
--
-- product_tastings follows the V7.72 rule for everything under a product:
-- only the product's owner (or the admin) inside the same team. Nothing here
-- widens what anyone can see.
-- Safe to run more than once. Run AFTER V7.88.

begin;

create table if not exists public.product_tastings (
  id bigint generated always as identity primary key,
  product_id bigint not null references public.products(id) on delete cascade,
  round integer not null default 1 check (round between 1 and 999),
  tasted_on date,
  sample text check (sample is null or length(sample) <= 200),
  comments jsonb not null default '[]'::jsonb check (jsonb_typeof(comments) = 'array' and length(comments::text) <= 60000),
  changes text check (changes is null or length(changes) <= 4000),
  sent_on date,
  file_url text check (file_url is null or length(file_url) <= 1000),
  is_final boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists product_tastings_product_idx on public.product_tastings(product_id, round);

alter table public.product_tastings enable row level security;

drop policy if exists "product_tastings_owner" on public.product_tastings;
create policy "product_tastings_owner" on public.product_tastings for all to authenticated
  using (exists(select 1 from public.products p
                where p.id = product_tastings.product_id
                  and p.team_id = public.my_team_id()
                  and (p.created_by = auth.uid() or public.is_admin())))
  with check (exists(select 1 from public.products p
                where p.id = product_tastings.product_id
                  and p.team_id = public.my_team_id()
                  and (p.created_by = auth.uid() or public.is_admin())));

-- widen the phase check once more
do $$
declare r record;
begin
  for r in
    select conname from pg_constraint
    where conrelid = 'public.product_milestones'::regclass and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%phase%'
  loop
    execute format('alter table public.product_milestones drop constraint %I', r.conname);
  end loop;
  alter table public.product_milestones
    add constraint product_milestones_phase_check
    check (phase in ('formula_fda','label','carton','seven','retail'));
end $$;

commit;

-- ---------------------------------------------------------------------------
-- VERIFY  (Supabase shows the last result; run each block on its own to see all)
-- ---------------------------------------------------------------------------

-- 1. The tasting table exists with RLS on (one row, rowsecurity = true).
select tablename, rowsecurity
from pg_tables
where schemaname = 'public' and tablename = 'product_tastings';

-- 2. Exactly one policy on it, and it goes through the product's owner.
select policyname, cmd, qual
from pg_policies
where schemaname = 'public' and tablename = 'product_tastings';

-- 3. The phase check now allows 'retail' (one row, mentions retail).
select conname, pg_get_constraintdef(oid) as rule
from pg_constraint
where conname = 'product_milestones_phase_check';

-- 4. profiles still has NO update policy reachable from the client (zero rows).
select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'profiles' and cmd in ('UPDATE','ALL');

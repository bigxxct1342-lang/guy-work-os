-- PORKCHOP G V7.77
-- 7-11 DOCUMENT SET, AND ASKING THE FACTORY FOR IT
--
-- The document checklist knew whether a paper was in hand. It did not know
-- who has to produce it, or that it had already been asked for -- which is
-- the part that actually stalls a listing: nine of the eleven 7-11 papers
-- come from the factory, and the chase is the work.
--
--   product_docs.src       'factory' | 'us' | null  -- who produces this paper
--   product_docs.asked_at  date                     -- first time it was asked for
--   product_docs.tmpl      text                     -- stable key for template rows,
--                                                      so the set can be found again
--                                                      without matching on labels
--   products.factory       text                     -- who to address the request to
--
-- Nothing here changes the state column or its check constraint. "Asked" is
-- not a state -- a paper that has been asked for is still not in hand, and
-- once it arrives asked_at stays behind as the record of how long it took.
--
-- Safe to run more than once.
-- Run AFTER V7.72.

begin;

alter table public.product_docs
  add column if not exists src text,
  add column if not exists asked_at date,
  add column if not exists tmpl text;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'product_docs_src_check') then
    alter table public.product_docs
      add constraint product_docs_src_check check (src is null or src in ('factory','us'));
  end if;
end $$;

alter table public.products
  add column if not exists factory text;

create index if not exists product_docs_product_tmpl_idx
  on public.product_docs (product_id, tmpl);

commit;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------

-- 1. Three new columns on product_docs, one on products.
select table_name, column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and ((table_name = 'product_docs' and column_name in ('src','asked_at','tmpl'))
    or (table_name = 'products' and column_name = 'factory'))
order by table_name, column_name;

-- 2. The state constraint is untouched -- still exactly have / not_yet / na.
select conname, pg_get_constraintdef(oid)
from pg_constraint
where conrelid = 'public.product_docs'::regclass and contype = 'c'
order by conname;

-- 3. The V7.72 ownership policies still apply to product_docs (should be one
--    row naming created_by). New columns inherit them; nothing to add.
select policyname, qual
from pg_policies
where schemaname = 'public' and tablename = 'product_docs';

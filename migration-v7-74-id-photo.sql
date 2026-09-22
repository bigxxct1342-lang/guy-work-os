-- PORKCHOP G V7.74
-- ID PHOTO ON THE PIN CARD
--
-- The unlock screen becomes an operator ID card, so each person needs a
-- photo that follows them to any device they sign in on.
--
-- The photo is NOT stored as a file. The browser downscales it to about
-- 260px on the long edge and re-encodes it before it is ever sent, so what
-- lands here is a small data URL -- a few kilobytes of text, not an upload.
-- That keeps this to one column and no storage bucket, no bucket policies
-- and no signed URLs.
--
-- profiles has had no UPDATE policy since V6.7, deliberately: nothing the
-- client can reach may touch role, status or team_id. That stays true. The
-- photo is written through a SECURITY DEFINER function that can only ever
-- write this one column, on your own row.
--
-- Safe to run more than once.
-- Run AFTER V7.72.

begin;

alter table public.profiles
  add column if not exists avatar text;

comment on column public.profiles.avatar is
  'Operator ID photo as a small data URL, written only via set_my_avatar().';

-- Write your own photo, and nothing else.
create or replace function public.set_my_avatar(p_avatar text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_avatar is not null then
    -- A downscaled JPEG lands around 4-12 kB. The ceiling is generous enough
    -- for a large portrait and still far too small to be used as file storage.
    if length(p_avatar) > 200000 then
      raise exception 'Photo too large — resize before saving';
    end if;
    if p_avatar !~ '^data:image/(png|jpeg|webp);base64,[A-Za-z0-9+/=]+$' then
      raise exception 'Photo must be a base64 image data URL';
    end if;
  end if;

  update public.profiles
  set avatar = p_avatar
  where user_id = auth.uid();

  return found;
end;
$$;

revoke all on function public.set_my_avatar(text) from public;
grant execute on function public.set_my_avatar(text) to authenticated;

commit;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------

-- 1. The column exists and is plain text.
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles' and column_name = 'avatar';

-- 2. The function exists and is SECURITY DEFINER.
select p.proname, p.prosecdef as security_definer
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'set_my_avatar';

-- 3. profiles still has NO update policy reachable from the client --
--    this should return zero rows. If it returns one, role and team_id are
--    writable from a browser and that is a problem.
select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'profiles' and cmd in ('UPDATE','ALL');

-- 4. Who has a photo so far.
select full_name, email,
       case when avatar is null then 'no photo'
            else pg_size_pretty(length(avatar)::bigint) end as photo
from public.profiles
order by role desc, full_name;

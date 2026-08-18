-- GUY WORK OS V7.4
-- PIN brute-force protection.
-- A 4-digit PIN only has 10,000 combinations. Without a lockout, anyone
-- signed in with the right email/password could script-guess the PIN.
-- This adds a 5-attempt lockout (15 minutes) tracked server-side only.

begin;

alter table public.user_pins
  add column if not exists failed_attempts integer not null default 0,
  add column if not exists locked_until timestamptz;

-- Verify own PIN, with lockout after repeated wrong guesses.
create or replace function public.verify_my_pin(p_pin text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_hash text;
  v_locked_until timestamptz;
  v_failed integer;
  v_ok boolean;
begin
  select pin_hash, locked_until, failed_attempts
    into v_hash, v_locked_until, v_failed
    from public.user_pins
    where user_id = auth.uid();

  if v_hash is null then
    return false;
  end if;

  if v_locked_until is not null and v_locked_until > now() then
    raise exception 'PIN locked from too many wrong attempts. Try again after %.', to_char(v_locked_until, 'HH24:MI');
  end if;

  v_ok := (extensions.crypt(p_pin, v_hash) = v_hash);

  if v_ok then
    update public.user_pins
      set failed_attempts = 0, locked_until = null
      where user_id = auth.uid();
    return true;
  else
    update public.user_pins
      set failed_attempts = failed_attempts + 1,
          locked_until = case when failed_attempts + 1 >= 5 then now() + interval '15 minutes' else locked_until end
      where user_id = auth.uid();
    return false;
  end if;
end;
$$;

revoke all on function public.verify_my_pin(text) from public;
grant execute on function public.verify_my_pin(text) to authenticated;

-- Changing the PIN clears any existing lockout/attempt count.
create or replace function public.set_my_pin(p_pin text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_pin !~ '^[0-9]{4}$' then
    raise exception 'PIN must be exactly 4 digits';
  end if;

  insert into public.user_pins(user_id,pin_hash,updated_at,failed_attempts,locked_until)
  values(auth.uid(), extensions.crypt(p_pin, extensions.gen_salt('bf', 10)), now(), 0, null)
  on conflict(user_id) do update
    set pin_hash = excluded.pin_hash,
        updated_at = now(),
        failed_attempts = 0,
        locked_until = null;
  return true;
end;
$$;

revoke all on function public.set_my_pin(text) from public;
grant execute on function public.set_my_pin(text) to authenticated;

commit;

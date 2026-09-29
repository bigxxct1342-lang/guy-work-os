-- PORKCHOP G -- UNLOCK A PIN THAT WAS LOCKED BY WRONG ATTEMPTS
--
-- Five wrong PINs lock the PIN screen for 15 minutes (V7.4). Waiting it out
-- works too; this clears the lock and the wrong-attempt count straight away.
-- The PIN itself is NOT changed -- the same PIN still opens the app.
--
-- Safe to run more than once. Changes nothing for anyone who is not locked.

update public.user_pins
set failed_attempts = 0,
    locked_until = null
where locked_until is not null
   or failed_attempts > 0;

-- ---------------------------------------------------------------------------
-- VERIFY: every row should show failed_attempts = 0 and locked_until empty.
-- ---------------------------------------------------------------------------
select coalesce(p.full_name, split_part(p.email, '@', 1)) as who,
       u.failed_attempts,
       u.locked_until
from public.user_pins u
left join public.profiles p on p.user_id = u.user_id
order by who;

-- Promote your existing Supabase login to ADMIN.
-- 1) Log in to the V6 app once first, so your profile row is created.
-- 2) Replace YOUR_LOGIN_EMAIL_HERE with the email you use to sign in.
-- 3) Run this in Supabase SQL Editor.

update public.profiles p
set role = 'admin',
    updated_at = now()
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('YOUR_LOGIN_EMAIL_HERE');

-- Verify:
select u.email, p.full_name, p.role
from public.profiles p
join auth.users u on u.id = p.id
where lower(u.email) = lower('YOUR_LOGIN_EMAIL_HERE');

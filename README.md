# GUY WORK OS V6

Private work dashboard with:
- Daily checklist
- Monthly calendar
- Team/member accounts
- Admin visibility across registered users
- Admin role management
- Supabase Auth + RLS
- Vercel-ready static deployment
- Mobile/iPad responsive layout

## Current Supabase project
Project URL is already configured in `config.js`.
The key in `config.js` is the Supabase publishable key (designed for client use). Security comes from Auth + RLS.

## Upgrade V5 -> V6

### 1. Back up first
From the current V5 dashboard, export your JSON backup.

### 2. Run migration
Supabase -> SQL Editor -> New query.
Paste all of `migration-v6-admin.sql` and Run.

### 3. Make yourself Admin
After your account has already registered, run:

```sql
update public.profiles
set role = 'admin'
where email = 'YOUR_EMAIL';
```

Replace `YOUR_EMAIL` with your login email.

### 4. Deploy V6
Upload this repository to GitHub, then connect that GitHub repository to the EXISTING Vercel project or create a new Vercel project.

### 5. Test
- Login as your account: Admin menu should appear.
- Register another account: it should default to Member.
- Admin can see all member tasks.
- Member can only see their own tasks.
- Calendar -> use Previous / Today / Next.
- Admin can filter Calendar by member.
- Click a date to create a task with that due date.
- Click a calendar task to edit it.

## GitHub recommendation
Create the repository as **Private**. The Supabase publishable key is intended for browser use, but the dashboard itself is personal/team software and does not need a public source repository.

## File map
- `index.html` main dashboard application
- `config.js` Supabase client configuration
- `migration-v6-admin.sql` database/admin upgrade
- `manifest.json` PWA metadata
- `sw.js` basic offline app-shell cache
- `vercel.json` Vercel config
- `.gitignore` ignores local backups/noise

## Important security behavior
Admin access is enforced by Supabase RLS policies through `public.is_admin()`. It is not merely a hidden Admin button.


## Promote yourself to Admin
1. Sign in to V6 once.
2. Open `promote-me-to-admin.sql`.
3. Replace `YOUR_LOGIN_EMAIL_HERE` with your Supabase login email.
4. Run it in Supabase SQL Editor.
5. Sign out and back in.

Your Admin menu will then show team members and allow changing member/admin roles.

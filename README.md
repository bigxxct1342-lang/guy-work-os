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


## V6.1
- Restored Settings page
- Export Cloud Backup (JSON)
- Restore V6 backup with automatic pre-restore backup
- Import legacy GUY_OLD_DASHBOARD_DATA.json
- App/schema version and last-backup status
- Updated service-worker cache version

## V6.2
- Fixed category deletion UX
- Delete a category with no tasks directly
- Move linked tasks to another category before deleting
- Or delete the category together with its linked tasks after confirmation

## V6.5
- Added GGG favicon / PWA app icons
- Category rename now updates linked tasks
- Monthly calendar day drawer shows all tasks for a date
- This Week now means Monday–Sunday
- Waiting status auto-fills Waiting Since
- Reopening a completed task restores its previous status when available
- Archive search + category filter
- Import skips obvious duplicate categories/tasks
- Quick Move buttons: Today / Tomorrow / Next Monday
- Category completion progress
- Personal Needs Attention on Dashboard
- Toast feedback for common actions

## V6.6
- Duplicate-safe category deletion
- When another category with the same name exists, deleting one duplicate keeps all Tasks
- Destructive "Delete Category + Tasks" is hidden while duplicate category names exist
- Added Settings > Scan & Clean Duplicates
- Duplicate cleanup keeps one exact copy and removes only exact imported duplicates
- Cleanup automatically exports a pre-dedupe backup first
- Exact duplicate detection includes created_at and task fields to reduce accidental deletion of legitimate repeated tasks

## V6.7
- One Super Admin only: bigxxct1342@gmail.com
- All new registrations default to Member
- Removed role promotion controls from the web UI
- Added dedicated Team Overview for Super Admin
- Team Pulse: members, active, overdue, waiting, done this week
- Member cards: workload, completion %, active/in-progress/waiting/overdue
- Member Summary drawer with Needs Attention and upcoming tasks
- Personal Dashboard remains separate from Team Overview
- Requires `migration-v6-7-super-admin.sql`

## V6.8
- Team Code gate for accounts that have not joined a team
- Super Admin owns Team Marketing and can set/replace Team Code
- Personal 4-digit PIN after Email/Password login
- Each member creates and changes their own PIN
- PIN hashes and Team Code hashes stay server-side behind Supabase RPC functions
- Sidebar displays Team name
- New accounts remain Member and cannot use Tasks until they join the team
- Team code is used once for membership; it is not displayed back to Members
- Requires migration-v6-8-team-pin.sql after V6.7

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
- `migration-v7-2-push-notifications.sql` push subscription storage for Daily Task Reminder
- `migration-v7-3-personal-line.sql` Personal Life Tracker tables + LINE linking tables
- `supabase/functions/daily-brief` Edge Function that sends the daily reminder (LINE or push)
- `supabase/functions/line-webhook` Edge Function that links a LINE account to a GUY WORK OS account
- `manifest.json` PWA metadata
- `sw.js` basic offline app-shell cache + push notification display
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

## V7.0 Major Upgrade
- No Category ID rewrite; keeps the simpler V6 architecture
- Morning Brief
- Focus Mode
- Weekly Review
- Month / Week calendar modes
- Estimated Time per task
- Daily workload visibility
- Simple recurring tasks: Daily / Weekly / Monthly
- Command Palette with Ctrl/Cmd + K
- Dark Mode
- Better mobile bottom navigation
- Duplicate Category name guard
- Keeps Super Admin, Team Code, Personal PIN, Team Overview, Backup and GGG branding
- Requires migration-v7-0.sql

## V7.2 Daily Task Reminder (Push Notifications)
- New: "Daily Task Reminder" toggle in Settings sends a push notification each morning summarizing today's tasks (and an overdue count) straight to your phone/desktop, even when the app isn't open
- Works as a home-screen PWA notification on Android/desktop Chrome, and on iOS 16.4+ after "Add to Home Screen"
- Requires `migration-v7-2-push-notifications.sql`
- Requires deploying the `supabase/functions/daily-brief` Edge Function and scheduling it (see below)
- No changes to existing V7.1 features

### Set up Daily Task Reminders
The VAPID **public** key is already committed in `config.js`. You still need to: run the migration, deploy the Edge Function, set its secrets (including the matching **private** key — see the pinned setup message / ask the developer for it, it is not stored in this repo), and schedule it.

1. Run `migration-v7-2-push-notifications.sql` in Supabase SQL Editor.
2. Deploy the Edge Function: `supabase functions deploy daily-brief`.
3. Set the function's secrets:
   ```
   supabase secrets set VAPID_PUBLIC_KEY=BLXQ2aCpZb4qFyjXIL5iqZhjasfm3GA8RuFL9udIRrOI-n59dJGPy6fJHGQd4juFP9pp7is5g0Hd4kwUd9eoWv0 VAPID_PRIVATE_KEY=your-private-key VAPID_SUBJECT=mailto:you@example.com
   ```
   Optionally set `APP_TIMEZONE` (IANA name, defaults to `Asia/Bangkok`) to control what counts as "today".
4. Schedule the function to run once a day (Supabase Dashboard → Edge Functions → `daily-brief` → Cron, or `pg_cron` + `pg_net` calling the function URL with the service role key). A time like `0 23 * * *` UTC (06:00 Asia/Bangkok) works well for a morning brief.
5. In the app, go to Settings → Daily Task Reminder → Enable Reminders, and allow the browser notification permission prompt. On iPhone, add the app to the Home Screen first (Safari share sheet → Add to Home Screen) — iOS only allows Web Push for installed PWAs.

## V7.3 Personal Life Tracker + LINE Notifications
- New "Personal Life" section, completely separate from Tasks/Categories/Team Overview: Reading progress, Exercise log, Sleep (bed/wake time), and general Health notes/weight
- Personal Life data is private to each account only — there is no admin/Super Admin visibility into it at all, by database policy, not just by hiding it in the UI
- New: LINE Notifications. LINE Notify (the old simple integration) was discontinued by LINE, so this uses a LINE Official Account + the Messaging API instead. In Settings, generate a one-time linking code, send it to the Official Account once, and daily task reminders switch to LINE instead of Web Push (no double notifications)
- Requires `migration-v7-3-personal-line.sql`
- Requires deploying `supabase/functions/line-webhook` and setting its secrets if you want LINE notifications (Personal Life Tracker works with just the migration, no extra setup)
- `daily-brief` was updated to prefer LINE over Web Push when a user has linked LINE

### Set up Personal Life Tracker
Just run `migration-v7-3-personal-line.sql` in Supabase SQL Editor. No other setup needed — it works immediately from the "Personal Life" nav item.

### Set up LINE Notifications
1. Create a LINE Official Account (free): https://www.linebiz.com/th/service/line-official-account/ → LINE Official Account Manager → create an account.
2. In the LINE Official Account Manager, go to Settings → Messaging API → Enable the Messaging API, which links it to a channel in the LINE Developers Console.
3. In the LINE Developers Console, open that channel → Messaging API tab:
   - Copy the **Channel secret** (Basic settings tab) and the **Channel access token** (issue a long-lived one on the Messaging API tab).
   - Set the **Webhook URL** to your deployed function URL: `https://<project-ref>.supabase.co/functions/v1/line-webhook`, and turn "Use webhook" on.
   - Turn off "Auto-reply messages" so it doesn't interfere with the linking flow.
4. Run `migration-v7-3-personal-line.sql` in Supabase SQL Editor (if not already run).
5. Deploy the webhook function: `supabase functions deploy line-webhook --no-verify-jwt` (must be `--no-verify-jwt` since LINE calls this directly, not through Supabase auth).
6. Set the secrets (these are project-wide, so `daily-brief` picks up `LINE_CHANNEL_ACCESS_TOKEN` automatically too — no separate step needed for it):
   ```
   supabase secrets set LINE_CHANNEL_SECRET=your-channel-secret LINE_CHANNEL_ACCESS_TOKEN=your-channel-access-token
   ```
7. Optional: put the Official Account's LINE ID (the `@...` handle, without the `@`) into `config.js` as `LINE_OA_ID` so the app can show a direct "add friend" link.
8. In the app, go to Settings → LINE Notifications → Generate Linking Code, add the Official Account as a friend in LINE, send the code as a chat message, then tap "ตรวจสอบสถานะ" to confirm.

## V7.1 Stable Interaction Build
- Rebuilt modal/drawer interaction handling
- Click outside or press Escape to close layers
- Added visible X close buttons to modal dialogs
- Fixed duplicate DOM IDs
- Added the missing Month/Week calendar selector
- Fixed Week View navigation
- Fixed Morning Brief focus list collision
- Fixed undefined Add Task command
- Fixed missing today helper that could stop rendering
- Edit Task now loads Estimated Time and Recurring values correctly
- Added robust view navigation and mobile bottom navigation
- Improved dark mode task/modal surfaces
- No new SQL migration is required if migration-v7-0.sql was already run

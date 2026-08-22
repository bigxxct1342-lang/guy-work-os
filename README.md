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
- `migration-v7-3-personal-line.sql` LINE linking tables (also created the `personal_logs` table, retired in V7.6)
- `migration-v7-4-pin-lockout.sql` PIN brute-force lockout
- `migration-v7-5-product-launch.sql` Product Launch (NPD tracker) tables + Thai holiday calendar
- `migration-v7-10-pr-grpo.sql` PR / GRPO purchasing tracker table
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

## V7.10 PR / GRPO tracker
- New "PR / GRPO" section for the SAP purchasing trail that runs alongside a job: open a PR in SAP -> wait for Purchasing to return a PO -> do the work -> receive the GRPO -> hand the paperwork to Accounting.
- Kept separate from Tasks deliberately. These items spend most of their life idle -- waiting on somebody else for days or weeks -- which is exactly how they get forgotten inside a normal task list.
- Every stage is named for **the action still owed** and counts the days it has been owed for. Each stage carries its own patience: 3 days to actually open a PR, 7 days before chasing Purchasing for a PO, 30 for the work itself, 3 to receive the GRPO, 3 to send the documents. Anything past its threshold turns red.
- **Anything overdue also surfaces on the Dashboard**, in the same ranked attention list as late tasks, under a "PR ค้าง" chip. Fixing the forgetting means the reminder has to appear where you already look, not only in a section you have to remember to open.
- One tap advances a PR to the next stage and stamps the date. If that step needs a number not recorded yet (the PR number when opening, the PO number when Purchasing replies), the form opens on that field instead, so the number is captured exactly when it arrives.
- Milestone dates are kept per leg, so a finished PR still shows how long each stage actually took.
- Requires `migration-v7-10-pr-grpo.sql`. Until it is run, the section shows a setup notice and the rest of the app is unaffected.

## V7.9 Dashboard rebuild
- The dashboard used to print **nine counters and a progress bar before a single task**, and it showed the same thing several times over: "overdue" appeared in the morning brief, again as a metric card, and a third time in Needs Attention. Waiting, high-priority and today's count were each duplicated too.
- Every flagged task now resolves to **exactly one reason** — the most severe of overdue / due today / waiting too long / high priority with no date / due within two days. The chips at the top count those reasons and **filter the list directly beneath them**, so the chips and the list are the same set counted once instead of three restatements of it.
- The dashboard now opens on the actual ranked work rather than on statistics: the most urgent items are visible without scrolling, each tagged with why it surfaced ("เลยกำหนด 5 วัน", "รอมา 7 วัน"). Clicking a row opens the task.
- Removed the "Overall Completion" bar — a lifetime percentage that only ever creeps up and never prompts an action. The four counts still worth knowing (active / in progress / waiting / done this week) are now a single muted line at the bottom of the card.
- Dropped the "Estimated 0m" tile, which read 0 whenever no task carried an estimate.
- Four separate cards (morning brief, metric row, completion bar, Needs Attention) collapse into one.

## V7.8 Archive redesign
- Completed tasks are now **grouped under their category**, as collapsible sections showing a count and the most recent completion date, with the most recently active category first.
- Archive rows no longer reuse the full task card. A finished task does not need a checkbox that is always ticked, a star, a priority pill, or a "Done" pill in a list where everything is done — each row is now a single compact line: a green check, the title, an optional note, the sub-category (only when it is not "General"), and the completion date. Roughly three times as many tasks fit on screen.
- The owner pill only appears for admins when the archive actually contains more than one person's tasks.
- Edit / Delete are revealed on row hover; on touch devices, tapping a row reveals them (one row at a time) instead of permanently occupying three lines per task.
- Added an explicit **Restore** action, since removing the always-checked checkbox removed the old way to un-complete a task.

## V7.7 Priority Matrix
- New "Priority Matrix" section: a 2x2 Eisenhower grid, red (Q1) through green (Q4). Vertical axis is importance, taken from the task's own Priority field; horizontal axis is urgency, **derived from how many days are left until the task is due** — so a task drifts toward the urgent column on its own as its deadline approaches, without anyone re-filing it.
- **Drag between quadrants edits the real task.** Dropping a task changes only the field(s) that disagree with where it landed: an already-High task dragged from Q1 to Q2 moves its due date and leaves the priority alone; dropping a task back in the quadrant it already occupies writes nothing at all. Every move shows what changed plus an Undo.
- **Time Machine** — jump the whole board forward +1 / +3 / +7 days and watch which tasks slide into Q1. Answers "what is on fire next Monday?" at a glance. Dragging is disabled while looking at the future so due dates are never edited against a shifted date.
- Tasks that will cross into urgent within a day pulse gently; tasks that newly entered Q1 in a future view get a red ring.
- Quadrant warnings: Q1 over 5 tasks flags that the problem is planning, not effort; an empty Q2 flags that no strategic work is queued.
- Uses the existing `priority` and `due` columns, so **no migration is needed** and every change is instantly reflected in Tasks, Calendar, and the daily brief.

## V7.6 Instant task updates + Personal Life retired
- Ticking, pinning, moving, editing, and deleting a task now updates the screen immediately and saves in the background, instead of re-downloading every task and repainting the whole app after each change. A failed save puts the old row back and shows the error, so the screen never drifts from the server.
- Removed the "Personal Life" section (reading/exercise/sleep/health logs) — this app is for work only.
- The `personal_logs` table and its policies are left untouched in Supabase, so any data already logged is still there. To delete it permanently, run `drop table public.personal_logs;` in the SQL Editor. Nothing in the app reads it any more.

## V7.5 Product Launch (NPD Tracker)
- New "Product Launch" section — team-wide (visible to your Marketing team only, same boundary as Tasks/Categories)
- Process & Timeline tab: Formular & FDA Process / ฉลาก (Label) / ลัง (Carton) phases, each with editable Milestones (title + duration in working days) and Steps (status: Done/Working/Wait/Next Step/Skipped, owners tag, deadline note). Milestones that are fully done collapse automatically. Add/rename/delete Milestones and Steps freely — the process isn't fixed
- Timeline auto-computes real dates from each Milestone's duration, skipping weekends and Thai public holidays (`thai_holidays` table — extend it yourself every year), and shows when the product will realistically be ready (Label is expected to land the same day as the formula/FDA track; Carton is shown separately since it's allowed to trail without delaying launch)
- "+ New Product" clones a standard template (the same phases/milestones/steps you get today) so you don't retype the process for every new SKU
- Document Checklist tab: a separate NPD document/certificate checklist (have it / don't have it yet / N/A), nested up to 3 levels, matching your existing QA 7-11 document list. This answers a different question than the Timeline ("do we have the paperwork" vs "how far along is the work") and is intentionally not linked to certificate expiry tracking — that stays RD's responsibility
- Requires `migration-v7-5-product-launch.sql`
- No file-attachment storage yet (would need a Supabase Storage bucket + its own RLS) — noted as a follow-up, not built in this version

## V7.4 Security Hardening
- PIN brute-force protection: 5 wrong PIN attempts locks that account's PIN entry for 15 minutes (server-side only, tracked in `user_pins`)
- Rotated the Web Push VAPID key pair — the previous key pair was shared in plain text during setup and should be treated as compromised
- Requires `migration-v7-4-pin-lockout.sql`
- **Action needed**: set the Supabase Edge Function secret `VAPID_PRIVATE_KEY` to the new private key (ask whoever ran the setup for it — it is intentionally not stored in this repo), matching the new `VAPID_PUBLIC_KEY` already committed in `config.js`
- **Action needed**: this GitHub repository is currently **Public**. Go to repo Settings → General → Danger Zone → Change repository visibility → Private. A public repo doesn't expose your data (Supabase RLS still protects that), but it does expose the app's full source, database schema, and internal logic to anyone on the internet — unnecessary exposure for internal company software

## V7.3 Personal Life Tracker + LINE Notifications
- New "Personal Life" section, completely separate from Tasks/Categories/Team Overview: Reading progress, Exercise log, Sleep (bed/wake time), and general Health notes/weight
- Personal Life data is private to each account only — there is no admin/Super Admin visibility into it at all, by database policy, not just by hiding it in the UI
- New: LINE Notifications. LINE Notify (the old simple integration) was discontinued by LINE, so this uses a LINE Official Account + the Messaging API instead. In Settings, generate a one-time linking code, send it to the Official Account once, and daily task reminders switch to LINE instead of Web Push (no double notifications)
- Requires `migration-v7-3-personal-line.sql`
- Requires deploying `supabase/functions/line-webhook` and setting its secrets if you want LINE notifications (Personal Life Tracker works with just the migration, no extra setup)
- `daily-brief` was updated to prefer LINE over Web Push when a user has linked LINE

### Set up Personal Life Tracker
**Retired in V7.6 — the section no longer exists in the app.** Still run `migration-v7-3-personal-line.sql` if you want LINE notifications; it also creates the now-unused `personal_logs` table.

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

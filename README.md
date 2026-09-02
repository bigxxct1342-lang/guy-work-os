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
- `migration-v7-10-pr-grpo.sql` standalone PR / GRPO records (PRs with no job behind them)
- `migration-v7-11-task-pr-status.sql` PR / GRPO status columns on `tasks`
- `migration-v7-13-kol-campaign.sql` KOL campaign tracker table
- `migration-v7-14-kol-timeline.sql` agency working-timeline dates, remarks, ball-in-court, PR link
- `migration-v7-15-kol-parallel.sql` per-stage status so campaign stages can run in parallel
- `migration-v7-18-projects.sql` projects + the links that group existing work under them
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

## V7.21 Projects: status colour, collapsible channels, started / not started
- **One dot per row on a single soft-orange ramp**, replacing the tick: pale = ยังไม่เริ่ม, mid = กำลังทำ, deep = เสร็จแล้ว, with a dark ring for เลยวันที่ประเมินไว้. Four separate hues each demanded attention on their own terms, so with a dozen channels on screen nothing stood out; one ramp reads as a *level* instead. Channel headers take the same ramp as a left accent, and both they and the project header carry the dots as a tally, so a collapsed project still shows its shape. The ramp inverts in dark mode — dim for untouched, bright for finished — since what it really encodes is distance from the background.
- **A date already past is amber, never red.** The dates in this app are estimates, and work sitting behind somebody else is usually not urgent yet rather than actually failing — a red alarm on every one of them trains you to ignore all of them. The "เลยกำหนด N" chip is gone, and the Gantt bar for a passed date is amber too.
- **"เริ่มแล้ว" is read from the work itself**, never entered twice: a task counts as started once it leaves `To Do`, a PR once it leaves `ยังไม่เปิด PR`, a KOL campaign once any stage is doing or done.
- **Channels collapse.** They all opened at once before, which turned a real project into one long wall. A channel now starts closed showing name, `เสร็จ/ทั้งหมด`, the dot tally and its last date; click to open, and several can be open together. "ลบช่องทางนี้" moved into the opened block so it cannot be hit while reaching for the header.
- **Two bands inside a channel**, split by a labelled rule: เริ่มแล้ว and ยังไม่เริ่ม. ↑ / ↓ reorder within a band only — a row crosses the line when the work actually starts or finishes, so the line always means something.
- Fixed: the on-track Gantt bar was filled `#20262d`, the dark theme's own panel colour, so it was invisible in dark mode. Bars now sit on the same ramp, pale for on-track and deep for a passed date, per theme.
- No SQL for this one.

## V7.20 Projects: progress, finished work, reordering
- **A percentage per project.** The header now reads `เสร็จ 2/4` with a `50%` chip and a progress bar, and every channel shows `done/total` instead of a bare count. A plan is judged by how much of it is finished, and that number was nowhere on the page.
- **Finished work can be linked.** The picker used to hide anything already done, which made a project look like a list of what is left rather than a picture of the whole plan. Done rows link in normally and render struck through with "· เสร็จแล้ว", so the overview shows what is finished as well as what is not.
- **Rows can be reordered.** ↑ / ↓ move an item inside its channel, and a dropdown moves it to another channel when the project has more than one. A media plan has an order to it; alphabetical-by-accident did not reflect that.
- Fixed: finished work was counted in the "เลยกำหนด" tally when its due date had passed, so completing late work never cleared the warning.
- No SQL for this one — it all reads from data already stored.

## V7.19 Removable channels, KOL folded into Projects
- **Channels can be deleted.** They could only be added before, so a mistyped channel was permanent. Deleting one that still holds work **moves that work to the remaining channel** rather than dropping it out of the project silently, and says so before doing it; the last channel cannot be removed.
- **"KOL Campaign" leaves the sidebar** — with campaigns now filed under a project's channel it was a second door to the same thing. The detailed stage tracker is not deleted: it opens by clicking a KOL row inside a project, and carries a back link. Campaigns are created from a channel with "+ สร้างแคมเปญ KOL", which links the new campaign automatically.
- Section renamed to **Projects**.

## V7.18 Projects
- New "โปรเจกต์" section: an umbrella that groups work already living elsewhere. A project is a plan — a media plan, a year plan, anything else — covering one or more products, with its work grouped by **channel** (KOL Review, BMN, สื่อออฟไลน์, Collab, อื่นๆ), which is how the plan is actually written rather than by which table happens to store it. The channel list is editable; those five are only seeds.
- **A project points at work, it never holds it.** Linking a task leaves that task exactly where it was — still in Tasks, Calendar and the dashboard — and adds only a pointer. Unlinking deletes nothing. That is what stops projects becoming a second, competing copy of the task list.
- **One piece of work belongs to at most one project**, enforced by a unique index rather than left to the UI. The picker greys out anything already spoken for and names the project holding it.
- "+ สร้างงานใหม่" creates an ordinary task and links it, so work born inside a project behaves like every other task everywhere else.
- **The date table sits at the top**, in the Product Launch style: a bar per channel running to its last due date, a line for today, and the project's finish date — the latest date across all its work — called out above the chart.
- Dates follow one source of truth. A linked task keeps its own due date, so editing it in the project also corrects Calendar and the dashboard; only KOL and PR rows, which have no due date of their own, store a date on the link. Work with no date yet is simply left blank.
- Products are free text on purpose: plenty are already launched and selling, so requiring a Product Launch record would have excluded them.
- Requires `migration-v7-18-projects.sql`.

## V7.17 WIP Review
- New read-only "WIP Review" section, built for showing the boss rather than for working in. The Dashboard answers "what must I do today"; this answers a different question asked by somebody else — where does every piece of work stand, and who is holding it up.
- **ติดอยู่ที่ใคร is the point of the page.** Blocked work is grouped by *blocker* — จัดซื้อ, Agency, KOL, พี่วาว, คนอื่น — with the longest wait first. Until it is grouped that way a list of late items reads as though the delay belongs to whoever is presenting, when most of it is spent waiting on somebody else.
- **งานที่กำลังวิ่ง** puts Product Launch, KOL campaigns, PR / GRPO and waiting tasks in one table — current stage, days elapsed, how far past due — so the whole picture is one screen instead of clicking through four sections.
- **เสร็จแล้วใน 30 วัน** gives the counterweight: what actually shipped.
- Read-only by design: it gets shown on a screen in a meeting, where a stray click must not change anything.
- Product completion is fetched for every product at once rather than one at a time, and a failed load leaves the page standing instead of blanking it.
- **No migration needed** — everything is derived from data the app already holds.

## V7.16 Explicit stage buttons + Gantt on top
- **Every stage row now carries a labelled button.** V7.15 replaced the "ไปขั้นถัดไป" button with a small status dot you had to know to click, which left no visible way to finish a stage and move on. Rows now read: ยังไม่เริ่ม → **[เริ่มขั้นนี้] [ข้าม]**, กำลังทำ → **[เสร็จ] [สลับ]**, เสร็จ → **[ย้อนกลับ]**, ข้าม → **[เอากลับมาใช้]**. The dot is now only an indicator.
- **Finishing a stage with nothing else running starts the next one**, so the ordinary single-file path is still one tap even though stages may overlap. If another stage is already in flight it does not auto-advance, since that would be guessing.
- The last row is a terminal marker rather than a stage, so it offers **[ปิดจบงาน]** alone instead of start/skip.
- **The Gantt moved above the stepper** and opens with the campaign. Buried under thirteen rows it was doing no work; the point of a timeline is to be the first thing seen.

## V7.15 Parallel stages + campaign Gantt
- **Stages no longer run single file.** The first model gave a campaign one current stage and derived the rest from its position, which forced 1 -> 2 -> 3. In practice stages 2 and 3, or 4 and 5, are worked at the same time. Each stage now carries its own status — ยังไม่เริ่ม / กำลังทำ / เสร็จ / ข้าม — so any number can be in flight at once and any can be skipped outright. Click a stage's dot to cycle it.
- Campaigns saved under the old model are read back through their single stage until first touched, so nothing needed a data migration.
- Everything downstream became per-stage: lateness, the remark, and the "รอเรา / รอ Agency" flip. With several stages live, one campaign-wide answer to "who is holding this" was meaningless. The dashboard names the specific late stage and how many others are also overdue.
- **Working-timeline Gantt**, in the same style as Product Launch. A bar is drawn from the start date agreed with the agency plus that stage's duration, falling back to the day the stage actually began, so the chart fills in as the timeline is entered. Bars are green when done, red when late, dark while in progress, with a line marking today.
- Requires `migration-v7-15-kol-parallel.sql`.

## V7.14 Agency working timeline + one row per thing
- **Fixed a real duplication on the Dashboard.** A single task that was both overdue *and* stuck in a PR stage was listed twice, once by each check. The two reasons now merge into one row ("เลยกำหนด 6 วัน · รอ PO จากจัดซื้อ 20 วัน"), so the attention list stays one row per real-world thing.
- **The agency's committed dates beat any estimate.** Partway through a campaign the agency delivers a dated working timeline; each stage now takes that date, and lateness is measured against it ("ช้ากว่าแผน 4 วัน") instead of a guessed day count. The day count remains the fallback for stages with no agreed date yet.
- **Ball-in-court toggle.** The agency's own sheet alternates "Agency proposes" / "Client feedback" row by row, so within one stage the party holding it flips back and forth. A button flips it, the card badges "รอเรา" or "รอ Agency", and the Dashboard names who is holding it up. Advancing a stage resets it to that stage's default owner.
- **Remark per stage**, mirroring the Remark column on the agency's sheet.
- **Campaigns can link to the PR they spend through.** When linked, the campaign's "เปิด PR" and "รอ PO → GRPO" stages stop raising their own alert and let the PR record raise it, so the same purchase never appears twice.
- Requires `migration-v7-14-kol-timeline.sql`.

## V7.13 KOL campaign tracker
- New "KOL Campaign" section for hiring influencers through an agency, following the real relay: brief the agency -> they propose KOLs -> review -> quotation -> PR and signing -> KOL brief and timeline -> storyline -> content -> ads set -> live and boosting -> report -> PO, invoice and GRPO.
- **Expected days are typed per campaign, not configured globally.** Every campaign negotiates its own timings, so each stage carries an editable number of days right in the stepper, pre-filled with a sensible default. A stage past its own number turns red and surfaces on the Dashboard.
- **The review stage is a fork, not a step**: ผ่าน advances, ขอแก้ sends it back to the agency and counts the round, and เปลี่ยน Agency / ปิดงานนี้ closes the campaign with a reason. The agency name is editable at any time, independently.
- **Revision counters instead of a KOL roster.** Naming every influencer is more data entry than it is worth; what actually hurts is how many rounds a stage drags through, so the storyline and content stages carry a one-tap "+1 รอบดราฟ" counter and show "แก้ N รอบ".
- Requires `migration-v7-13-kol-campaign.sql`. Until it is run the section shows a setup notice and the rest of the app is unaffected.

## V7.12 Grouped navigation
- The sidebar had grown to ten flat entries, which made unrelated things look interchangeable and closely related things look like separate features. It is now split into three labelled groups: **งานของฉัน** (Dashboard, Tasks, Calendar, Priority Matrix, Weekly Review, Archive — six views of the same task data), **ระบบติดตามงาน** (Product Launch, PR / GRPO — the two genuine pipelines), and **ตั้งค่า** (Categories, Settings, Team Overview).
- Reordered within each group by how often it is opened, so Dashboard and Tasks come first.
- Group labels are hidden in the compact horizontal bar on phones, where the bottom navigation is the primary control anyway.

## V7.11 PR status on the task itself
- A task can now carry its own **PR / GRPO status** (set in the task form), so a job that needs a PR is one record rather than two. The standalone records from V7.10 remain for PRs with no job behind them, and the PR / GRPO screen shows both in the same stage lanes, each row badged "งาน" or "PR เดี่ยว".
- **The stages deliberately outlive the task.** GRPO and sending documents to Accounting happen after the work is finished, so ticking a task Done used to make the outstanding paperwork vanish from every list — the same forgetting problem, just moved. A Done task whose PR stage is not yet finished now keeps appearing on the dashboard as "งานเสร็จแล้ว · ต้องทำ GRPO", which is exactly the moment it used to be lost.
- Advancing a stage works the same from either source; for a job-linked PR it writes back to the task, so Tasks, Calendar and the dashboard all stay in step.
- Requires `migration-v7-11-task-pr-status.sql`. Running it alone is enough for job-linked PRs; `migration-v7-10-pr-grpo.sql` is only needed for standalone ones.

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

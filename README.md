# PORKCHOP G

_Formerly GUY WORK OS. The repository keeps its old name; the app does not._

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
- `migration-v7-79-telegram.sql` Telegram linking tables
- `migration-v7-81-cat-room.sql` Cat Room, one private document per person
- `migration-v7-84-cat-friends.sql` Cat Room visits, gifts and photo album
- `migration-v7-86-cat-together.sql` playdates, weekly team goal, family cat
- `migration-v7-88-launch-711.sql` Product Launch: 7-11 phase, real start dates, "failed" step status
- `unlock-pin.sql` clears a PIN lock after five wrong tries (the PIN is unchanged)
- `migration-v7-90-tasting-retail.sql` Product Launch: tasting rounds (`product_tastings`), "ห้างอื่น" phase
- `cat-sprites.png` Cat Room sprite sheet (four amber levels)
- `art/` pictures cut from the ChatGPT designs: shop icons, PORKCHOP for empty pages, mini-game screens, shelf, and `cat-mix.webp`, the new PORKCHOP pose atlas (Arcade only)
- `supabase/functions/daily-brief` Edge Function that sends the daily reminder (Telegram, LINE or push)
- `supabase/functions/telegram-webhook` Edge Function that links a Telegram chat to a PORKCHOP G account
- `supabase/functions/line-webhook` Edge Function that links a LINE account to a PORKCHOP G account
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

## V7.33 A dashboard that says what is missing, and one header style
- **The dashboard printed a second task list, a second category breakdown and a second deadline list** — all of which Tasks and the Priority Matrix already showed. Repeating them is what made it cluttered while still not answering the question actually asked in the morning, which is not *what work exists* but *where is something missing*.
- **Each system now reports its own gaps, in its own words**, and every line is a way in rather than something else to read: Creative (รอเราตรวจ / ยังไม่ส่งบรีฟ / ยังไม่มี Caption / เลยวันโพสต์), PR / GRPO (per stage that needs you), Projects (งานเลยวันประเมิน, ช่องทางที่ยังไม่มีงาน, per project), Product Launch (เหลืออีก N จาก M ขั้น, per product), KOL. A system with nothing in it does not appear at all.
- The Morning Brief at the top stays — it was already the one part that answered "what needs me today".
- **One header style across the app**, taken from Projects: a solid orange bar with near-black text that collapses. Creative's group headings were plain text over a rule, which read as a different app; they are now the same control, and every group but จบแล้ว opens by default.
- No SQL.

## V7.32 One record: creative work and its post live on the task
- **A creative job is a task**, not a record beside one. v7.28 made `creative_jobs` a table and `posts` another, with a `task_id` pointing back — three records for one piece of work, which is what produced a picker to link them, a unique index to stop them being linked twice, a separate table to read post details from, and nowhere that said "this is at this stage and its caption is still missing".
- The app already had the right pattern and was not using it: a task carries its own purchasing trail in `pr_stage`. The creative track and the post are the same shape of thing, so they go on the task — and every join disappears with them. Bringing work into Creative is now a flag, not an insert; leaving is a flag too, and the task stays a task.
- **The post is the detail of the work, not a table beside it.** Each card carries the post date, type and length, channel, the caption tick and the boost span in one line, above the draft history. `ตารางโพสต์` is gone: it was a second place to look at the same thing.
- **One date.** The day the artwork must be approved is the day it posts, so `post_date` is the date; with no post the task's own due date stands.
- Unchanged in behaviour: the loop still has no ceiling, finished tasks still arrive already approved, and approved-with-live-ads still sits in its own group. The calendar still layers post chips, boost bars and creative markers — all now read off tasks.
- Requires `migration-v7-32-creative-on-task.sql`, which also carries across anything already entered under the old shape. The old tables are left in place and simply stop being read; drop statements are at the bottom of that file, commented out.

## V7.30 The posting table lives on Creative
- **ตารางโพสต์ sits on the Creative page**, under the jobs. Posts are the far end of the same pipeline — brief → drafts → approved → post → boost — so the whole of it is on one page. Putting the table under the Calendar had posts appearing twice on a page that is otherwise about tasks, which is the duplication this app keeps having to undo; the argument for one calendar was never an argument for a post table on it.
- **The calendar keeps the post chips.** They answer *when*, alongside task deadlines, which the table cannot. The two views link to each other: `ดูบนปฏิทิน →` from the table, `จัดการโพสต์ →` from the calendar's layer row.
- **Grouped by month, upcoming first**, with `แสดงที่ผ่านมาด้วย` for the rest — a flat list of everything loses the sense of which month is crowded, which is what a schedule is read for. The summary line reads `3 โพสต์ · มี Caption 1 · ยังไม่มี 2 · บูท 2 · กำลังรัน 1`.
- **Caption is a tick toggled in place**; a boost running today is marked `กำลังรัน` with a green edge; a post whose artwork is unapproved carries `อาร์ตเวิร์กยังไม่อนุมัติ · ดราฟต์ N`; a boost switched on with no dates is called out rather than left blank.
- **The task-link dropdown is gone from the Creative modal.** The link is made once, from "+ เลือกงานที่มีอยู่"; a second way to set it only invited linking the same work twice, which is the thing the link exists to prevent. The modal shows the linked task read-only with a "ยกเลิกการผูก" button, and hides the block when nothing is linked.
- Fixed, and pre-existing: on a phone the **Calendar scrolled the whole page sideways** instead of scrolling inside `.calendar-shell`. `main` is a grid item, and a grid item's default `min-width:auto` lets it grow to its content, so the grid's 850px minimum pushed the page out to 888px on a 390px screen. Confirmed against `main` before changing it; `min-width:0` holds it.
- No SQL.

## V7.29 Creative takes in work that is already finished
- **A task marked Done is often not over** — the artwork is delivered but the ads it feeds are still running, which is exactly when it still needs watching. The picker shows completed tasks by default rather than hiding them behind a toggle.
- **Choosing a finished task opens the job already approved**, dated from when the task actually closed. Opening it at "ยังไม่ส่งบรีฟ" would be a lie, and would ask for a brief that went out months ago.
- **Approved is not the same as over.** A job whose linked post is inside its boost window sits under *อนุมัติแล้ว · กำลังรัน Ads* with the end date on the card instead of sinking into the archive while the ads are live — read off the post's boost dates, so nothing extra is entered. The final group is renamed อนุมัติแล้ว → จบแล้ว.
- No SQL.

## V7.28 Creative jobs and the posting schedule
- **New "Creative" section.** Work with Creative is short, loops several times per job, and there can be dozens under a single project — burying it inside a project card would have made the thing you touch most often the thing hardest to reach.
- **The loop has no ceiling.** Rounds are an array, not columns: `draft_1 / draft_2 / draft_3` would need migrating the first time a job needed a fourth. Each round records only what the app can answer with — sent, returned, days taken, and whether it went back or was approved.
- **No comment text is stored.** The feedback is a file that already lives in the company's own systems; copying it here would add a step without adding an answer. What is kept is the shape of the relay — how many rounds, how long each took, who is holding it now.
- **One date, not two.** "The day we need the artwork" and "the day it is approved" are the same day, so `due_date` is the target and `approved_on` records what happened against it.
- **A job linked to a post inherits the post's date.** The artwork is needed when the post goes out, so there is no second date to keep in step — and the calendar can then say *"posting on the 15th, artwork still on draft 2"*, which is the sentence that stops a post slipping.
- **The posting schedule layers onto the existing calendar** rather than adding a second one — that duplication is what this app keeps having to undo. Filter chips read ทั้งหมด · งาน · โพสต์ · Creative, with ทั้งหมด as the way back.
  - A **post** is one chip; an **event** is stored as a start plus a **length in days** (that is how the work is described — "a three-day activity", not "ending on the 17th") and runs as a squared-off bar across its days, dimmed on continuation days and marked จบ on the last, because in a month grid an unlabelled bar explains nothing.
  - **Boost is its own span** under the post, since it usually runs past the day the post goes out.
  - **Caption** is a tick: filled dot when ready, dashed outline when not, so an unfinished post is visible without opening it.
- The app cannot send mail or write to Planner, so the brief modal offers **"คัดลอกบรีฟเป็นอีเมล"** and stamps the day it was sent, rather than a button that looks like it delivers and does not.
- **Start from a task you already have.** "+ เลือกงานที่มีอยู่" opens a picker over existing tasks, so a job that began life as *ทำ KV หม่าล่า* is not retyped into a second record. The job **points at** the task rather than copying it — the task stays in Tasks, Calendar and the dashboard — and a unique index makes one task drive at most one creative job, enforced in the database rather than left to the UI.
- **The due date now has three sources, in order of authority:** a date typed on the job, then the post it feeds, then the task it came from. Nothing is entered twice.
- An unrecognised `status` falls back to the first stage rather than throwing: it used to take the whole page down and drop the row out of every group.
- **Finished work can be pulled in, and arrives finished.** The picker shows completed tasks by default now — a task marked Done in Tasks often is not over, because the ads it feeds are still running. Choosing one opens the job **already approved**, dated from when the task actually closed; opening it at "ยังไม่ส่งบรีฟ" would be a lie and would ask for a brief sent months ago.
- **Approved is not the same as over.** A job whose linked post is inside its boost window sits under *อนุมัติแล้ว · กำลังรัน Ads* with the end date on the card, instead of sinking into the archive while the ads are still live. Read off the post's boost dates — nothing extra to enter.
- Requires `migration-v7-28-creative-posts.sql`.

## V7.27 PORKCHOP icons
- **The app icon is PORKCHOP**, replacing the old GGG mark across the favicon, the PWA icons and the iPhone home screen.
- **One mark at every size — the face, not the whole cat.** The full body is charming at poster size, but at the ~60pt a home screen actually draws it is a speck, while the face survives down to a 16px favicon. An icon that changes between sizes is not a mark.
- **A dedicated `apple-touch-icon.png` at 180×180.** iOS ignores `sizes` and takes whatever `apple-touch-icon` points at; it was pointing at the 192 and downscaling it. Saved as RGB with no alpha, since iOS renders transparency as black.
- **A separate maskable icon.** The 512 was doing double duty as `any` and `maskable`, but Android's circle mask crops roughly 20% off every edge — it was taking an ear off. `icon-maskable-512.png` holds the face at 78% inside the safe zone, cut from a wider window of the original so the padding is the picture's own background rather than a flat fill butted against it.
- `favicon.ico` is multi-resolution (16/24/32/48/64) so a browser picks a size instead of scaling one.
- The large icons are quantised to 192 colours — indistinguishable side by side, and it takes the set from 768 KB to 332 KB, all of which the service worker caches on install.
- Source art kept as `porkchop-icon-source.webp` so the set can be regenerated.
- No SQL.

## V7.26 PORKCHOP G — renamed, and a sidebar you can scan
- **The app is now PORKCHOP G** — title, both sign-in screens, sidebar, PWA manifest and the push notification title. The backup *format* string is deliberately unchanged: it identifies a file, not a brand, and renaming it would have made every backup already on disk unrestorable. The restore screen says so.
- **The sidebar was eleven flat items of identical weight**, three of them settings. It is now four clusters:
  - **Dashboard** alone at the top — it is home, so it needs no group label.
  - **งาน** — Tasks, Calendar, Priority Matrix, Weekly Review: four views of one task list, which is why they belong together.
  - **แผนงาน** — Projects, Product Launch, PR / GRPO.
  - **Portfolio** below a rule; it is a record rather than active work.
  - หมวดหมู่ · ตั้งค่า · ทีม drop into a small row at the bottom — still labelled, no longer competing with the work.
- **An icon per item**, inline stroke SVG, so the list is scanned by shape instead of read word by word.
- **A badge only when something is actually waiting on you** — overdue-or-due-today on Dashboard, work past its date on Projects, PRs needing action on PR / GRPO. A count on every item would just be more to read; this way an empty sidebar genuinely means nothing needs you.
- Fixed: the page heading rendered as `Dashboard1`, because it was read from the nav button's `textContent` and the button now also contains a badge.
- The service worker still clears caches under the old `guy-work-os-` prefix as well as the new one, so no device is left holding a stale copy of the app.
- Note: `favicon-32.png` and the app icons still carry the old GGG mark — supply a PORKCHOP icon and they can be swapped in.
- No SQL.

## V7.25 WIP Review removed
- **The section is gone.** Opening a project turned out to be the easier thing to show a reviewer, and a dedicated review page was a tenth sidebar item that duplicated what Projects already displays.
- **Two of its panels had no other home, so they moved to Projects**, collapsed above the project list: *ติดอยู่ที่ใคร* (blocked work grouped by blocker, longest wait first) and *เวลาจริงของแต่ละขั้น* (planned vs measured). Both are exactly what gets asked in a review, and both are cross-project, which is why they sit above the cards rather than inside one.
- **The rest was dropped rather than moved**: the four counters, the running list and the 30-day done list each repeated the Dashboard or the Portfolio. Carrying them along would have re-created the duplication the section was removed to end.
- Sidebar is down to nine items.

## V7.24 เวลาจริงของแต่ละขั้น — measured durations
- **Every stage in this app already stamped the day it was reached and nobody read them back.** A purchase request keeps a milestone date per leg (`pr_opened_on`, `po_received_on`, …); a campaign records when each stage started. The planned figure stayed whatever was typed once, so "late" meant late against a guess.
- **New in WIP Review: ตั้งไว้ vs จริง per stage**, worst overrun first — *"รอ PO จากจัดซื้อ · ตั้งไว้ 7 วัน · จริง 12 วัน · ช้ากว่า 5 วัน · วัดจาก 6 ครั้ง"*. That is the sentence you can take to a meeting; the app could never say it before.
- **The measured norm also rides inline** on a PR row and a KOL stage row (`ปกติ 12 วัน`), turning amber once reality runs 3+ days past the plan — so the comparison is in front of you while you work, not only in the report.
- **Median, not mean:** one PR that stalled for three months should not move the figure everyone else is judged against. Nothing shows until a stage has actually happened twice, and a negative or absurd gap is dropped as bad data rather than counted as a long wait.
- **No new field and no new typing** — the numbers had been accumulating all along.
- Note: a task carrying a `pr_stage` only records when it entered its *current* stage, never the legs before it, so it cannot contribute a completed leg and is deliberately not counted. Standalone purchase requests carry the full trail.
- No SQL.

## V7.23 Portfolio — the archive becomes a record of what was delivered
- **The archive only ever held completed tasks**, so the things that would actually go on a CV — a campaign run end to end, a product taken to shelf, a plan delivered — never arrived there at all. A portfolio line reads "launched Cockle Mala 40g, 3 SKUs", never "sent product to KOLs", and only the second kind of thing was being kept. Finished **projects, KOL campaigns and products** now land here alongside tasks.
- **Two tiers, because those are two different answers.** *ผลงานเด่น* is a handful of things worth naming, grouped by year the way a CV is read. *งานประจำ* is everything else, summarised as counts per year (`โปรเจกต์ 1 · แคมเปญ KOL 1 · งาน 47 · ใบขอซื้อ 23`) — volume is portfolio material too, it just belongs as a number rather than a list.
- **Highlights are automatic.** A finished project, campaign or product is one by default: it is already the natural unit of a portfolio, and defaulting it true means nothing has to be tagged after the fact. A finished task is routine until promoted with the star — most of them were Tuesday. Purchase requests are never highlights; they count toward the tally instead.
- **A portfolio title separate from the working name**, because the name written to get work done is not the name to be read by somebody else later, plus a one-line result — the only thing the app cannot derive, since it has never stored an outcome or a number.
- **"คัดลอกเป็น Bullet"** copies the whole thing out grouped by year, ready to paste into a CV.
- The star replaces the green tick at the front of each archive row: every row in that list was done, so the tick said nothing, while "is this portfolio material" is the one judgement worth making there — and it must not hide behind a hover.
- Dates are pinned to the Gregorian calendar (`th-TH-u-ca-gregory`): `th-TH` defaults to the Buddhist era, so month labels were coming out in พ.ศ. under year headings in ค.ศ. — the same row read 2026 and 69.
- Requires `migration-v7-23-portfolio.sql`.

## V7.22 Projects: tick work off without losing sight of it
- **A tick on every row.** Marking work done from a project finishes it where it actually lives — a task's status, a PR's stage, a campaign's stages — so it clears in Tasks, Calendar and the dashboard too, not just here. Nothing is unlinked: the row stays exactly where it was, struck through, because the point of pulling finished work into a project is to see what is done alongside what is not.
- **Unticking restores the previous state**, not a guess. A task goes back to whatever it was before (In Progress, Waiting), a PR to the stage it was at, a campaign to its stage map — stashed the same way `toggleTask` already did it.
- **A tick on the project too**, for when the whole plan is finished. The card keeps its place in the list with its name struck through.
- **A channel needs no tick**: it is struck through automatically once every piece of work under it is done, since a channel is a grouping rather than a piece of work in its own right.
- **Fixed: work reopened out of Archive looked missing from the picker.** The list arrived in creation order and never moved, so a task finished months ago and reopened today came out below every task created since — position 81 of 82 in a realistic history, which reads as "it is not there". Open work now sorts first, then whatever was touched most recently, which puts a just-reopened task at the top. A "ซ่อนงานที่เสร็จแล้ว" toggle and an "N จาก M" count sit above the list.
- No SQL — `projects.status` and every record's own done state already exist.

## V7.21 Projects: status colour, collapsible channels, started / not started
- **Two headings, two colours.** หัวข้อหลัก — the channel — is a solid orange band with near-black text. หัวข้อรอง — เริ่มแล้ว / ยังไม่เริ่ม inside it — is the same orange run much lighter. Rows stay neutral, so the only things carrying colour are the two heading levels, which is what makes them tell apart at a glance. An earlier attempt gave every channel its own step on a ramp; that answered a question nobody asked and left the levels themselves undifferentiated.
- **Status is the other axis, so it uses fill rather than hue:** hollow = ยังไม่เริ่ม, half = กำลังทำ, solid = เสร็จแล้ว, with a dark ring for เลยวันที่ประเมินไว้. Channel headers and the project header carry the dots as a tally, so a collapsed project still shows its shape.
- **Headings reorder.** ↑ / ↓ on a channel header move it up and down the project; the order lives in `projects.channels`, so it persists and the rows follow their heading by name. The arrows are handled ahead of the header's own click, so moving a heading never collapses it.
- **A date already past is amber, never red.** The dates in this app are estimates, and work sitting behind somebody else is usually not urgent yet rather than actually failing — a red alarm on every one of them trains you to ignore all of them. The "เลยกำหนด N" chip is gone, and the Gantt bar for a passed date is amber too.
- **"เริ่มแล้ว" is read from the work itself**, never entered twice: a task counts as started once it leaves `To Do`, a PR once it leaves `ยังไม่เปิด PR`, a KOL campaign once any stage is doing or done.
- **Channels collapse.** They all opened at once before, which turned a real project into one long wall. A channel now starts closed showing name, `เสร็จ/ทั้งหมด`, the dot tally and its last date; click to open, and several can be open together. "ลบช่องทางนี้" moved into the opened block so it cannot be hit while reaching for the header.
- **Two bands inside a channel**, split by a labelled rule: เริ่มแล้ว and ยังไม่เริ่ม. ↑ / ↓ reorder within a band only — a row crosses the line when the work actually starts or finishes, so the line always means something.
- Fixed: the on-track Gantt bar was filled `#20262d`, the dark theme's own panel colour, so it was invisible in dark mode. Bars now carry the heading orange, with an outline marking a passed date.
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

## V8.07 Arcade is the only look
- **Classic and dark mode are gone.** The app has one look, Arcade, set on `<body class="arcade">`. Nothing is switched on at load any more.
- **Settings:** the Appearance (dark mode) and หน้าตาแอป (Arcade/Classic) rows are removed.
- **Saved choices are forgotten.** On load the app clears `guy_theme`, `porkchop_look` and `porkchop_arcade` from the device, so an old dark or Classic choice cannot linger.
- **Code removed:** the look switch, every Classic branch in the Cat Room painters (`crArc`, `crHex`, the sepia ramp), the 33 `body.dark` rules and the Classic-only base rules. Dark mode went too because on top of Arcade it was a broken hybrid (black calendar cells, way-in screens turning brown-black).
- **What stays:** the base CSS Arcade is layered on still gives layout, so it is not deleted; only what nothing can reach any more is.
- **Arcade did not move.** 64 screenshots (desktop + phone) match the previous version apart from Settings, which is shorter by the two rows; all 116 Cat Room canvas fingerprints are identical with the clock frozen. A leftover `guy_theme=dark` on a device changes nothing.
- No SQL to run.

## V8.06 Product Launch: Pantone steps for the label and the carton
- **Label → Label Production:** a new step, **เลือกสี Pantone — สีหลักของฉลาก (2 วัน)**, sits right after Internal Approval and before Sent AW to Supplier. The milestone grows from 33 to 35 days.
- **Carton → Carton Production:** three new steps after Internal Approval and before Sent AW to Supplier:
  - **รอสี Pantone ของฉลาก** (the carton takes its colour from the label);
  - **Supplier ปาดสีลงลังให้ดู (3 วัน)**;
  - **ดูสีบนลัง + อนุมัติสี (1 วัน)**.
  The milestone grows from 19 to 23 days.
- **The wait is real in the plan.** Until the label's Pantone step is done, the carton is not planned to start earlier than it needs to for its first steps to finish when the Pantone is ready. The plan table says so on the carton row ("รอสี Pantone ฉลาก ~27 Oct"), and so does the root map (a dotted root from Label Production to Carton Production, and a note on the carton knot).
- **Ticking the label's Pantone step done ticks the carton's "รอสี Pantone" step for you**, and un-ticking it puts the carton back to waiting. The page says so when it happens.
- **New products** get all of this from the template.
- **Products made before V8.06** show a note on their Label Production and Carton Production cards with a button, **+ ใส่ขั้นตอน Pantone (ฉลาก + ลัง)**. It puts the steps in the right place and moves the later ones down.
  - It never reopens finished work: if the step that follows is already done, the new steps go in as done (or skipped).
  - Pressing it twice adds nothing the second time.
- The days in the names are my guesses (2, 3 and 1). Change a milestone's days in the plan table, or rename a step with the pencil.
- No SQL.

## V8.05 New PORKCHOP, and cats keep their own spot
- **PORKCHOP redrawn** from the user's ChatGPT pose sheet: a chubby orange tabby with folded ears, in full colour, with eleven poses (sit, look up, happy, eat ×2, sleep ×2, crouch, leap, walk ×2).
  - Walking now has two real steps, and eating and sleeping use their own second frame.
- **Drawn at full detail in Arcade.** The room is still painted in big square pixels, but the canvas now has as many pixels as the screen, so the cat is sharp instead of being blown up from a few pixels.
  - Sized to the room as in the picture: about a quarter of the room's height.
- **Everywhere he appears:** the room, the balcony, the brushing and bath close-ups, the mini games, the cat house cards, the shop outfits (hats and glasses sit on the new head), the grow-up popup, the sidebar and the dashboard widget.
- **Other breeds** keep their current look until their pose sheets arrive. Add one by cutting the sheet into `art/cat-<breed>.webp` and adding its rects to `CR_NEW`.
- **Cats no longer stand on top of each other.**
  - When a cat picks a place on the floor, sill or cat tree, it skips any spot another cat is in or heading to, keeping both widths plus a little air between them.
  - Going to sit with a friend means sitting beside them, and only if that place is free.
  - In a one-minute test with three cats, the old code had cats overlapping in 97% of samples; the new code in 0%.
- **Classic is unchanged:** the same old cats, canvas size and room renders.
- No SQL.

## V8.04 Cat Room tabs and empty pages, from the ChatGPT mockups
- **บ้านแมว (cat house):**
  - a big "1/7" count with a pink progress bar, and a shelf with a cat and plants;
  - cat cards in rotating pastel colours, with a lock on the cats not found yet;
  - the album as tilted polaroids, and each diary day as its own row with a date pill.
- **ร้านค้า (shop):**
  - items are cards with pastel backgrounds and the pixel-art pictures from the icon sheet: mystery box, cat bed for the extra slots, treat, and every room decoration including the balcony;
  - owned items show a mint tag;
  - two cards per row on a phone.
- **มินิเกม (mini games):** each game is a small arcade cabinet (pink, yellow, blue) with a picture screen, plays left, best score and a "เล่นเลย" bar.
- **ภารกิจ (quests):**
  - quest cards with thick pink progress bars;
  - the 7-day streak as paw stamps;
  - badges in gold and pink.
- **Empty pages:** where a list has nothing in it, PORKCHOP sits above the message:
  - waving where nothing has been added yet;
  - asleep where there are no tasks for the day or week;
  - cheering where nothing is left to do;
  - searching where a filter found nothing.
- New `art/` folder holds the pictures cut from the ChatGPT images (the 12 shop icons, 4 cat poses, 3 game screens and the shelf). They load only in Arcade and are not part of the offline cache.
- **Classic is unchanged.** Classic screenshots of every Cat Room tab and of the empty pages match before and after, and all 96 room renders are identical.
- No SQL.

## V8.03 Cat Room in colour
- In Arcade the Cat Room now looks like the picture made with ChatGPT.
- **The room is drawn in full colour**, with the same furniture in the same places:
  - a purple wall with sunlight across it, and blue sky and clouds over a blue city in the window;
  - green plants, a yellow poster, colourful books, a pink cushion, a cream rug with pink flecks, and a litter box with a pink stripe;
  - a pink yarn ball and bowl, and pink hearts;
  - a clock on the dresser showing the real time (only where there is room for it).
- **Also in colour:** dusk, night and rain in the window, the balcony, and the bath and litter close-ups.
- **The Cat Room is a pink game window:**
  - a pink title bar with the sound and coin buttons;
  - tabs with icons, in one row on desktop and two rows of three on a phone;
  - bars coloured per meter: XP and FULL pink, HAPPY yellow, CLEAN blue, GROOM green.
- **Classic is unchanged.** Every piece of the room still names one of the same seven tones, and Classic reads them from the old sepia palette. 96 Classic room renders were checked pixel for pixel before and after.
- No SQL.

## V8.02 Forgot password lands on "Set new password"
- **What was wrong**: a reset link that no longer works (a second reset email makes the first one dead; some mail apps open links to scan them; links expire) comes back as `#error=…otp_expired`. Supabase keeps the session the phone already had, so the app opened as if nothing happened and the password never changed.
  - Signed in: the app opens normally, through the PIN. Once the Daily Report is closed, the new "เปลี่ยนรหัสผ่าน" box opens and says why.
  - Not signed in: the Reset password card says the link is dead and to use the newest email.
- **Settings → รหัสผ่าน (Password)**: change the login password from inside the app, no email needed. You only reach it after the PIN.
- **Security**: typing `#type=recovery` into the address bar no longer brings up "Set new password" on a signed-in phone. Only Supabase's own `PASSWORD_RECOVERY` event, sent after it has checked the token, does.
- The listener for that event is attached as soon as the client is created, so it can't be missed.
- After a reset email is sent, the send button waits one minute and the message says to open the newest email only.
- Supabase → Authentication → URL Configuration must list the app's address under Redirect URLs.
- No SQL.

## V8.01 Arcade is the look
- The app opens in the Arcade theme on every device, including devices that had switched the old preview off.
- Settings → หน้าตาแอป has a button to go back to Classic, and the same button returns to Arcade. The choice is saved per device as `porkchop_look`.
- No SQL.

## V8.00 Fuller design: the Daily Report joins, display type, motion, richer Arcade
- **Daily Report** (the screen after unlocking) now lives in the new room:
  - a cream card with a pink title strip, and the cat peeking over its top edge;
  - Priority Matrix rows as sticker rows with count badges (Q1 pink, the rest mint);
  - section labels as ink tags, running ads in a yellow box with a candy-stripe bar;
  - a big pink "รับทราบ · เข้าสู่แอป" button.
- **Display type**: Bungee for the big English titles and Mitr for Thai headings and buttons, loaded from Google Fonts. If they can't load, the old fonts are used.
- **Motion** on every screen of the new design:
  - the floor grid runs toward you and the pixel sparkles blink;
  - the cat bobs gently and the PIN lanyard sways;
  - the main button pulses, and "▶ PRESS START" blinks on the first page.
  - All of it is turned off when the phone asks for reduced motion.
- **Arcade inside the app**:
  - The Dashboard banner shows the illustrated cat on his monitor.
  - Panel headers are coloured strips: Tasks yellow, Cat Room pink, Calendar sky, Note mint.
  - Page headings wear yellow label stickers, and the plate over each page is an ink tag.
  - Stat numbers use the display type.
  - Main buttons are white on pink like the entry screens, and the selected menu item is a pink sticker.
- No SQL.

## V7.99 PIN: each PIN is sent once, and the lock message tells the right time
- Every PIN check counts toward the five-strike lock. In V7.98 a PIN could be sent more than once: by the fourth-digit auto-submit, by Enter, or by tapping Unlock while a check was still running. Wrong attempts added up faster than they were typed.
  - Now one typed PIN is sent exactly once.
  - The button stays disabled while a check runs.
  - A wrong PIN is cleared from the boxes, so it can't be resent.
- A wrong PIN now says that five wrong tries lock the PIN for 15 minutes.
- The lock message showed the server's UTC time (09:32 instead of 16:32). It now shows the phone's time and the minutes left, in Thai.
- The PIN boxes no longer sit inside a cream card under dark or Arcade, and the Unlock text stays white in every theme.
- `unlock-pin.sql` clears a PIN lock straight away without changing the PIN.

## V7.98 The way in: new first page, sign-in and PIN card
- The four screens before the app share one night room: navy with stars, a glowing floor grid, and the chubby Scottish Fold on his CRT, all from the ChatGPT designs.
  - **First page**: the full hero picture, a big outlined "PORKCHOP G / WORK MONITOR" title and a big pink "เข้าสู่แอป" button.
  - **Sign in**: the cat on his monitor with a cream sign-in card below. Create account and password reset are unchanged.
  - **Team code**: the same style.
  - **PIN**: an operator ID card. A pink lanyard hangs from the top and the cat peeks over the top edge. The card shows the photo (the cat until you add one) and OPERATOR / UNIT / CLEARANCE, plus a barcode.
- The PIN is entered in four boxes.
  - When unlocking, the fourth digit submits by itself; Enter works too.
  - When setting a PIN, it still waits for the confirm boxes.
- On a desktop the picture sits on the left and the form on the right. On a phone everything fits on one screen.
- These screens look the same in every theme (classic, dark, Arcade).
- New files, cached by the service worker: `login-hero.webp`, `login-cat.webp`, `pin-cat.webp` (about 300 KB in all).
- No SQL.

## V7.97 Fix: app stuck at the start with show-off mode on
- With show-off mode left on, reloading the app ran the masking before the app's lists existed. The error stopped the rest of start-up, so "เข้าสู่แอป" did nothing.
- The fix:
  - masking now waits until start-up has finished;
  - each data list is read on its own, and a list that isn't ready is skipped;
  - masking can never throw into the page.
- Checked on a real page load with show-off mode and Arcade in all four on/off combinations: no errors, and the button goes on to sign-in.

## V7.96 Show-off mode, and plans above work in the menu
- A button at the top right (👁️ โชว์ทั้งหมด / 🙈 โหมดอวด) hides every piece of real work as XXXX. The app itself stays readable, so it can be shown to anyone.
  - Hidden: task names, notes, categories, projects, products, factories, campaigns, agencies, remarks, PR/PO numbers, vendors, amounts, tasting comments, custom steps, and people and team names.
  - Still readable: pages, stages, template steps, buttons, help text and the cat.
  - Tooltips are masked too, and typed-in fields are blurred.
- How it works: nothing changes in the data or the pages. Text on screen is checked against strings collected from the data, whenever a page draws. Turning it off restores every text exactly, and the choice is remembered on this device.
- Sidebar: the แผนงาน group (Projects, Product Launch, KOL, PR, Creative) now sits above งาน (Tasks, Calendar, Matrix, Weekly).
- No SQL.

## V7.95 Arcade theme on every page
- The Arcade look now reaches every page:
  - cards, groups, rows, stage cards, root maps and their detail cards;
  - inputs and dropdowns: cream with an ink outline and a sky-blue focus ring;
  - tabs and chips, progress bars (pink candy stripe), the calendar's ink header row;
  - dialogs, drawers and toasts, and the sign-in card.
- Cat Room keeps its pixel game on purpose; only its tabs and buttons match the theme.
- On a phone the frames get thinner borders and less padding, so content keeps its width.
- Works together with dark mode.
- The classic look was checked pixel by pixel against the previous version on all 14 pages: identical.
- No SQL.

## V7.94 Arcade theme (preview, off by default)
- Settings → "ธีม Arcade (ทดลอง)" turns on a retro-tech poster look; the same button turns it off. The choice is remembered on this device.
  - The room is night navy, with a perspective grid on the floor and pixel sparkles.
  - Every machine is flat colour with a thick ink outline and a hard offset shadow, like a sticker: the page is pink, the title bar yellow, the sidebar navy.
  - The paper inside stays cream, so text is always dark on light.
  - Cards, stat tiles, chips and buttons are stickers too, and buttons press down when clicked.
  - The Dashboard banner becomes a grid poster with a yellow outlined title.
- All of it is scoped to `body.arcade`, so the classic look is untouched.
- No SQL.

## V7.93 Icons on every busy page
- One set of emoji icons, so the same thing wears the same picture everywhere. Emoji need no download and look like the phone's own.
- **Product Launch**:
  - The main road is now a row of cards, one per stage: a big icon, the name, the date, and a badge on top (✓ done, ring = now, ! = late, + = not added yet). Stages not reached yet are greyed.
  - Phase and milestone headings carry icons, picked from the milestone's own words (formula 🧪, label 🏷️, proof 🖨️, 7-11 🏪 …).
- **Root maps**: every knot not yet done shows its icon inside the circle, on Product Launch, KOL, Creative and PR alike.
- **KOL**:
  - The 14 stages have icons in the steps list and on the "ต้องทำตอนนี้" chips.
  - The flow in the page help is a row of icon steps.
- **PR / GRPO**: stage headers and the chip row have icons, and the flow in the help is shown as icon steps.
- **Creative**:
  - Each group heading has an icon (👀 รอเราตรวจ, ⏳ รอ Creative …).
  - The flow in the help is shown as icon steps.
- **Dashboard**:
  - The filter chips have icons (🔥 เลยกำหนด, 📌 วันนี้ …).
  - Each task row starts with an icon for what it is.
  - The panel titles have icons, and so does each "ยังขาดอะไรอยู่ตรงไหน" group.
- **Settings**: every card and setting has an icon, and so does each system-check row.
- Other page headings (Tasks, Categories, Weekly Review, Portfolio, Team) have icons too.
- No SQL.

## V7.92 System check, root maps for KOL / Creative / PR, cleanup
- **Settings → เช็คระบบ**: one read-only pass that reports:
  - every SQL file, ✓ run or ✗ missing; each missing one has "คัดลอก SQL" (the file is fetched from the site) and a link to the SQL editor;
  - whether this app is the latest version;
  - the Supabase connection and its speed;
  - team, Telegram link, notification permission, how far the Thai holiday calendar reaches, and local storage.
  - "คัดลอกผลตรวจส่งให้ Dev" copies the whole report as text.
- **Root maps on KOL, Creative and PR**: the Product Launch map is now one shared component, and each page grows its own roots from its own data:
  - KOL: one branch per running campaign, with the 14 stages in three stretches (เตรียม / ผลิตคอนเทนต์ / ลง + ปิดงาน).
    - Details under each stage: start date, the agency's frame, Storyline / Draft counts, posting days, Boost, PR, remarks.
    - The card can start, finish or reopen a stage.
  - Creative: บรีฟ → every draft round (sent, back, days, outcome) → อนุมัติ → โพสต์ → บูท.
    - The card can send the brief, mark a draft received, approve or ask for changes.
  - PR / GRPO: เปิด PR → รอ PO → ทำงาน → GRPO → ส่งบัญชี, with PR and PO numbers, vendor and amount.
    - The card moves the PR to its next stage.
- On every map:
  - done and cancelled items are hidden unless "รวมที่ปิดแล้ว" is ticked;
  - "ซ่อน" folds the map away, and the choice is remembered;
  - maps open at 55% or larger, starting from the root, so words are readable;
  - "ไปที่… ›" jumps to the item in the page's own list.
- **Cleanup**: 124 CSS rules for classes nothing uses any more were removed (old Gantt, old mini-calendar, old KOL run and posts pieces), along with 7 unused functions.
  - The file is about 11 KB smaller.
  - Every page was screenshotted before and after at desktop and phone width and compared pixel by pixel: identical.
- No SQL.

## V7.91 Product Launch: the root map shows every sub-step, and zooms
- Each knot trails its sub-steps as rootlets hanging below it: the label's drafts, every proof in Label Production, and so on.
  - Upcoming steps are grey, done steps are filled with the phase colour, and a step in progress is ringed.
  - Knots not reached yet are grey too.
  - A "ขั้นย่อย" switch turns the rootlets off, and the choice is remembered.
- The map is a window onto a larger sheet:
  - Drag to pan.
  - Ctrl + scroll, a trackpad pinch or a two-finger pinch zooms around the pointer.
  - − / + buttons, a zoom percentage, and "พอดีกรอบ" to fit.
  - Double-click zooms in.
  - Step names hide when zoomed far out, leaving only the beads.
- **เต็มจอ** opens the map on its own full-screen paper; Esc closes it.
- Clicking a knot or a step opens a card showing:
  - dates and business days;
  - every sub-step with its owner and a status menu, so status can be changed right there;
  - buttons for "เปิดในรายการ ›" (jump to it in the list) and "แก้วัน / จำนวนวัน".
- On a phone the vertical tree lists each knot's sub-steps under it the same way.
- No SQL.

## V7.90 Product Launch: the main road, other retailers, and a tasting log
- **Main road**: a single row at the top of Process & Timeline listing every main stage in order:
  - สูตร → ตั้งชื่อ → โภชนาการ → อย. → ฮาลาล → ฉลาก → ลัง → 7-11 → ห้างอื่น → 🏁 วางขาย
- It includes the stages not reached yet, with their expected dates, and optional phases the product does not have yet, shown dashed with "+". Clicking a "+" adds that phase; clicking any other stage opens it below.
- Stage states:
  - Done: ✓.
  - Where the work is now: ringed.
  - Late: red, with how many days over.
- **ห้างอื่น**: a new phase after 7-11 for Makro, Lotus's, Big C and the like. It has one milestone: choose the stores, present and send documents, store approval. It shows on the plan, the calendar and table, and the root map, where it grows out of the end of 7-11.
- The finish date is the last of 7-11 and the other retailers.
- **บันทึกการชิม**: a tasting log inside Final Formulation, reached from the "สูตร" stage.
- Each tasting round records:
  - date and sample tasted;
  - each person's comment, with 👍 / 😐 / 👎;
  - what is changed for the next round;
  - when it went back to the factory and a link to the presentation;
  - whether this round is the confirmed formula (CF), which also ticks the CF step.
- Comments are added right on the round card, and names are remembered.
- "คัดลอกสรุปรอบนี้" copies the round as text to paste into the presentation.
- A table shows each person's verdict across rounds.
- Requires `migration-v7-90-tasting-retail.sql`, run after V7.88. Until then, the tasting log and ห้างอื่น say the SQL is needed; everything else works.

## V7.89 Product Launch: a root map of the whole process
- The top card of Process & Timeline now shows the launch as roots.
  - The product sits on the left and one root grows per phase: formula & FDA, 7-11, label and carton.
  - Each milestone is a knot on its root, and every root runs into the finish on the right: "ขึ้นชั้น 7-11", or "พร้อมขึ้นห้าง" when there is no 7-11 phase, with its date.
- Knot styles:
  - Filled with ✓: done.
  - Ringed and pulsing, with a "ตอนนี้" tag: where that root is now.
  - Hollow: still ahead.
  - Red: late, or Product Selection did not pass.
- The 7-11 root grows out of the confirmed formula. A dotted line shows QA 7-11 waiting on the label.
- A row of chips above the map lists where every phase is right now.
- Clicking a chip or a knot opens that milestone in the list below and scrolls to it.
- On a phone the roots hang down one under the other, as a tree.
- No SQL.

## V7.88 Product Launch: the 7-11 process, and a plan you can type dates into
- **เข้า 7-11**, a fourth phase next to formula, label and carton, in three milestones:
  - **นำเสนอสินค้า 7-11**: the presentation file plus a mock-up to show first.
  - **Product Selection**: the product-offer form from MT, a mock-up holding the confirmed formula (10 packs per SKU), tasting cups and spoons, and the messenger run. It has its own ✓ ผ่าน / ✗ ไม่ผ่าน buttons, and "ส่งเข้า Selection รอบใหม่" restarts it and counts the round.
  - **ส่งเอกสาร QA 7-11**: the 7-11 document set, which shows how many papers are ready and how many are still with the factory, plus the real mock-up.
- The plan knows 7-11's rules:
  - The phase starts once the formula is confirmed (CF).
  - Product Selection ends on the Tuesday the results come out.
  - QA waits for the label to be finished.
  - The finish box gives the date the product can be on the 7-11 shelf.
- New products get the phase automatically. Existing products have a "+ ใส่ขั้นตอน 7-11" button.
- **ตารางงาน & วันที่คาดการณ์** replaces the Gantt. It has two views:
  - **ปฏิทิน**: a month calendar in the same style as the Creative post calendar. Each piece of work is one bar across its days, coloured by phase; weekends and Thai holidays are shaded.
    - Click a bar to edit it. Click an empty weekday to add work starting that day.
  - **ตาราง**: one row per milestone showing start date, number of business days (with − / + buttons) and finish date, plus a "+ เพิ่มงาน" button for each phase. This is the default view on a phone.
- A milestone can be given a real start date. With none, it follows the one before it, as before. The first step set to Working or Done fills the start date in automatically, so dates stop sliding forward every morning.
- New milestones are added at the end of their phase. Before this they could land in the middle, because the position was taken from a count rather than from the last position used.
- Requires `migration-v7-88-launch-711.sql`. Until it is run:
  - everything else works;
  - the 7-11 phase, the start dates and "ไม่ผ่าน" say that the SQL is needed.

## V7.87 Cat Room: Scottish Folds get their own poses
- The Scottish Fold now has its own pose sheet: sit, eyes-closed sit, happy, eating (with his own bowl), sleeping curled, crouch, leap and walk. The other breeds still borrow the sit pose and move it, until their sheets arrive.
- Cats with a walk frame walk along the floor instead of hopping; hops up to the sill, the rail and the cat tree still leap. In the jump game they run on the walk frame.
- Eating and sleeping alternate with a second frame where the breed has one (chewing, breathing).
- `cat-sprites.png` grew a row; `CR_ATLAS.poses.<breed>` holds a breed's own frames. The image is loaded as `cat-sprites.png?v=787` so no browser keeps the old one.
- No SQL.

## V7.86 Cat Room: cats that live in the room, and cats that visit
- **Cats move on their own**: they hop between spots — the floor (each in its own lane), the window sill or balcony rail, the cat tree, the cushion to sleep — go and sit with each other and groom, and sleep where there is room at night.
- **Name tags** over every cat whenever there is more than one, and "LUNA · ของ FON" over a visitor, so identical-looking cats can be told apart. Tags that would overlap are stacked.
- **A ball of yarn** on the floor: drag it and let go to throw it; the cats chase and bat it for a while, then lose interest. A few XP a play, up to 30 a day.
- **Cats ask for things**: every few hours one wants something in particular — food, a pet, brushing, yarn, a laser game, a treat, a photo — shown as a bubble over his head and in the sidebar. Done within three hours: +20 XP +20 coins.
- **Diary**: a line a day, written from what actually happened (meals, pets, baths, games, gifts, level-ups, new cats, visits), last seven days in บ้านแมว.
- **Badge book**: 34 badges for things done over time, each with coins and a title to wear; the title shows over the Cat Room and on your friends' list.
- **Arrange the room**: the pencil button lets you drag the cat tree, the big plant and the picture frames sideways. **Wallpaper and floors** in the shop (dots, check, wood, panelled; tiles, carpet).
- **Balcony**: a second place, bought in the shop — mostly sky, so day, night and rain are the point; cats sit on the rail. Switch with the button on the room.
- **New เพื่อน tab**:
  - **Family cat**: one cat the whole team looks after (feed, pet, name, hat). Written only through `cat_family_act()`, one locked row, so two people feeding at once cannot overwrite each other.
  - **Weekly team goal**: 80 care actions between everyone; each person's share shown; reward 150 coins and a rare scarf.
  - **Playdates**: send one of your cats to a friend's room for an hour (once a day); he appears there with a name tag, then comes home with +40 XP +20 coins; the host gets +15.
  - Friends' rooms, gifts and visits move here from บ้านแมว.
- Requires `migration-v7-86-cat-together.sql`.

## V7.85 The sidebar portrait watches the Cat Room
- The square at the top of the sidebar is no longer a still of PORKCHOP: it is a live little window onto the Cat Room — the same room, sky, weather and outfits, the cat you are looking after in his current pose (sitting, sulking in the corner, asleep at night).
- A speech bubble over his head shows the most pressing need (hungry, dirty litter, knotted fur, lonely, something waiting in the room, a mystery box, a quest to claim) — or zzz / a heart when he wants nothing.
- Underneath: name and level, what he is doing right now, a FULL meter, and his needs in words. The frame glows while he wants something; clicking it opens the Cat Room.
- Four frames a second, paused when the tab is hidden; hidden on phones as before (the Dashboard panel covers them).
- No SQL.

## V7.84 Cat Room: a room that lives, friends, album, sound
- **Day, night and weather**: the window follows the real clock (dusk goes orange, night goes dark with stars, the lamp lights a cone of the room) and the real Bangkok sky from open-meteo (rain streaks the glass, storms flash).
- **While you were away**: the first visit of the day, and one more after four hours, finds something waiting in the room — a present on the floor (coins, or rarely an item you cannot buy), a knocked-over vase to tap clean, a bird on the sill.
- **Sound**, off by default and remembered per device: purring, meows, crunching, brushing, running water, splashes, coins, level-ups. All synthesised; no audio files.
- **Traits**: every cat is born with one — ตะกละ, ขี้เล่น, ขี้อ้อน, เกลียดน้ำ (wriggles in the tub), ขี้เซา, รักสะอาด — each changing what pays and how fast he needs you. Older cats get one on load.
- **Album**: a camera button on the room; each cat's growth into a new body and first day home are photographed on their own. Kept in `cat_photos` (or this browser until V7.84 is run); up to 60; in the backup.
- **Friends**: visit a teammate's cat room (cats, outfits, furniture — nothing else of theirs) and send one gift a day: a fish treat, coins or a game ticket. Gifts pop up for the other person on their next visit.
- **Shop**: consumables that keep coins useful (special treat 60, extra-game ticket 80) and three rare outfits that rotate every Monday (chef hat, witch hat, sunflower, heart glasses, bandana).
- **Balance**: level curve is now 70 + 14·(L−1) — first new body in about ten active days, adult in about five weeks. Mini-games give at most 20 XP a round; care pays more (pet 8, brush 20, bath 35, scoop 15, daily age 15, quests 20).
- **First-time tips** on each tab and each care scene, dismissed once.
- Requires `migration-v7-84-cat-friends.sql` for visits, gifts and a synced album.

## V7.83 Cat Room: hands-on care, and a new body every 20 levels
- **Growth**: kitten Lv 1–19, teen Lv 20–39, adult from Lv 40 — and adult is the last stage (the "boss" stage is gone).
- **Care is something you do, not a button**. Each opens a close-up where the tool follows your finger and progress is measured on the cat's own pixels:
  - **หวีขน** — brush and fine comb. Stray tufts come away where you stroke; knots only give to repeated comb strokes. The bar fills from what you actually covered.
  - **อาบน้ำ** — five steps: drag him into the tub → wet him with the shower → work up a lather with shampoo → rinse the foam off → towel dry. Each step wants its tool; the wrong one says so. Once a day.
  - **เก็บกระบะทราย** — scoop every clump out of the tray.
  - **ลูบหัว** — rub on the cat in the room (hearts follow your finger); a tap still works.
- **New stat GROOM (ขนสวย)**: drains over two days; a scruffy coat shows as tufts around the cat. Brushing +45, bathing to full.
- Two new daily quests: brush him, bath him. Care pays XP and fish coins.
- No SQL.

## V7.82 Cat Room: coins, quests, shop, more cats, more games
- **Fish coins** (เหรียญปลา): daily quests, mini-games (up to 30 a game), +50 per level-up, +5 for the first meal of the day. Balance sits top-right of the Cat Room.
- **Daily quests**: three a day, picked by date so every device shows the same three (no litter quest on a day the box cannot get dirty). Each pays coins + 15 XP; all three pay a +20 bonus. **Care streak**: any care counts the day; every 7 days in a row brings a mystery box.
- **Special quests** unlock three breeds that never come out of a box: Bombay (100 laser hits in total), Persian (14-day streak), Khao Manee (any cat to Lv 30). The box now draws only from the other breeds, then becomes a treat (+80 XP, +50 coins).
- **Shop**: mystery box 500 · room slots for a 2nd and 3rd cat (600 / 1,200) · 9 outfits (hats, bow, flower, crown, bell collar, scarf, glasses, shades; 100–400) · 7 furniture pieces (curtains, frames, string lights, big plant, patterned rug, fish tank, cat tree; 250–700), each can be put away and brought back.
- **Several cats in the room**: up to three live on the clock at once. Tap a cat to pick who you are caring for, tap again to pet. Cats in the house sleep and do not get hungry. The house moves cats in and out.
- **Outfits** are drawn in code in the four amber levels and seated on the head, eyes or neck by reading the sprite itself, so they fit every breed and stage. They show on sitting/happy poses, the house, the shop and the dashboard widget.
- **Two new mini-games**, three plays a day each alongside the laser: **จับคู่หน้าแมว** (6 pairs, 60 s, faster = more) and **แมวกระโดด** (tap/Space to jump boxes, vases and yarn; it speeds up).
- No SQL: everything lives in the same `cat_rooms` document; older saves upgrade on load.

## V7.81 Cat Room
- A virtual pet with **no connection to work**: he gets hungry on the clock, so a day with nothing due is still a day to feed him. New sidebar item **Cat Room** with three tabs — ห้องแมว, บ้านแมว, เลเซอร์ — plus a small CAT ROOM panel on the Dashboard with a feed button.
- **Stats** (0–100, shown as 10-segment meters): FULL drains 100→0 in 7 hours; HAPPY loses 10 per 12 hours; CLEAN drops to 35 once the litter box is 24 hours old. He sulks (sleeps in the corner) when FULL < 20 or HAPPY < 25, and forgives the moment he is fed. He never dies.
- **XP**: food by level (kibble 10 · mackerel 16 from Lv 5 · canned 22 from Lv 12 · lickable treat 28 from Lv 20), ×1.5 when fed at FULL ≤ 30, nothing when already full (he turns away). Petting +6 with a 30-minute cooldown (tap the cat too). Cleaning +12. Laser: score × 2, capped at 50, 3 games a day. +10 for every midnight he was not sulking at.
- **Levels**: 80+20·(L−1) to Lv 5, 180+30·(L−5) to Lv 15, 500+40·(L−15) to Lv 30, 1100+50·(L−30) after. Growth stages: ลูกแมว 1–4, วัยรุ่น 5–14, โตเต็มวัย 15–29, เจ้าถิ่น 30+. Level-up and stage-up popups.
- **Mystery box every 5 levels** hatches a breed you do not have yet (7 breeds: mix, Scottish Fold, Khao Manee, Persian, American Shorthair, Bombay, Siamese); name it, keep it or make it the active cat. Each cat keeps its own level; cats in the house sleep and do not get hungry. Once every breed is found, a box is a treat (+80 XP).
- **Laser game**: 15 seconds, tap the red dot before the cat pounces on it.
- Sprites are cut from the design sheets and quantised to the four amber levels (`cat-sprites.png`); the room is drawn in code so the bowl, litter box and cat can react. Poses only PORKCHOP has (eat, sleep, pounce) fall back to the sitting pose plus motion for the other breeds until their own sheets exist.
- The whole room is one JSON document per person in `cat_rooms`, owner-only — the other member and the Super Admin cannot see it. Until the migration is run it lives in the browser only and moves up on the first visit afterwards. The backup file now carries it too (`cat_room`), and restoring your own backup puts it back.
- Requires `migration-v7-81-cat-room.sql` for sync across devices.

## V7.80 Ask the bot what is pending
- A **📋 งานค้าง** button sits under the Telegram message box (also `/today`). It answers with the same report the app opens with after sign-in, read live: date, weather, the priority matrix counts, the Q1 and Q3 tasks by name with how late or close each is, and the ads running today.
- Same rules as the app: High priority = important, due within 2 days or overdue = urgent; ads = approved creative whose boost window covers today. Only the asker's own tasks.
- No SQL. Redeploy `telegram-webhook` and open `…/telegram-webhook?setup=1` once more so `/today` appears in the bot's menu.

## V7.79 Daily brief over Telegram
- LINE setup stalled on an emailed OTP that never arrived. Telegram needs one bot token and nothing else.
- Settings → Telegram → **เชื่อม Telegram** writes a one-time code and shows a **เปิด Telegram แล้วกด Start** link (`t.me/<bot>?start=<code>`). Pressing Start links the chat; the page notices on its own within a few seconds. Typing the code into the bot works too.
- `daily-brief` sends to Telegram first, then LINE, then Web Push — one message per person. The Telegram message lists up to 10 of today's tasks and 5 overdue ones, not just the first three. Blocking the bot (or `/stop`) unlinks it.
- Only the `telegram-webhook` function (service role) can create a link, and only after Telegram delivers the code from that chat. Webhook calls are authenticated by a secret derived from the bot token, so there is no second secret to create.
- Requires `migration-v7-79-telegram.sql`.

### Set up Telegram (Dashboard only, no CLI)
1. In Telegram, message **@BotFather** → `/newbot` → give it a name and a username ending in `bot`. Copy the token it replies with.
2. Supabase → Edge Functions → Secrets → add `TELEGRAM_BOT_TOKEN` = that token.
3. Run `migration-v7-79-telegram.sql` in the SQL Editor.
4. Edge Functions → Deploy a new function → Via Editor → name `telegram-webhook`, paste `supabase/functions/telegram-webhook/index.ts`, deploy. Then open its Details and turn **Enforce JWT verification** (called "Verify JWT with legacy secret" on newer dashboards) off (Telegram calls it directly).
5. Redeploy `daily-brief` with the current `supabase/functions/daily-brief/index.ts`.
6. Open `https://<project-ref>.supabase.co/functions/v1/telegram-webhook?setup=1` once in a browser. It should answer `"ok":true` with the bot's username.
7. In the app: Settings → Telegram → เชื่อม Telegram → เปิด Telegram แล้วกด Start.
8. The daily brief is sent by the same Cron job as before. If none was ever created: Integrations → Cron → Create job → type **Supabase Edge Function**, function `daily-brief`, method POST, schedule `0 23 * * *` (06:00 Asia/Bangkok), and add the auth header with the service role key the form offers.

### Set up LINE Notifications
> **V7.78:** `daily-brief` used to configure Web Push unconditionally at load, so with no VAPID keys it crashed before serving a request — a project set up for LINE alone never sent anything. Both channels are optional now; redeploy `daily-brief` after pulling this. Every step below can be done from the Supabase Dashboard (Edge Functions → Deploy a new function → Via Editor; Edge Functions → Secrets; Integrations → Cron) without installing the CLI.

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

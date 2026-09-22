# PORKCHOP G — working notes

## Anything the user has to run themselves

**Paste the code into the chat, in full, as a code block.**

Attaching a file is not enough and never has been. The user is on a phone as
often as a desktop; opening an attachment, finding the copy control and
getting the whole thing onto the clipboard is several steps, and every one of
them is a place to give up. Code in the message is one long-press away from
the Supabase SQL editor.

This applies to SQL migrations above all, and equally to any shell command,
config snippet or console one-liner the user is expected to execute.

Do both: paste it in the message **and** attach the file, so the repo keeps
its copy of the migration and the user still gets the fast path.

If a migration is long, still paste it whole. Do not summarise it, do not
send "the important part", and do not tell the user to open the file — they
asked for the opposite, in those words.

## Migrations

- Supabase is unreachable from the container. Every migration is run by hand
  by the user, so it must be safe to run more than once and it must end with
  `VERIFY` queries that prove what it claims.
- `profiles` has had **no client-reachable UPDATE policy since V6.7**, on
  purpose: a browser must never be able to write `role`, `status` or
  `team_id`. Anything that needs to write to `profiles` goes through a
  `SECURITY DEFINER` function scoped to one column on the caller's own row.
  V7.74's migration asserts this is still true; keep that assertion.

## Verifying a visual change

Screenshot every affected view and **look at it**. Scanning the DOM for
"no white backgrounds" is not the same as checking the page is readable —
V7.68 shipped broken that way and had to be rolled back.

The scratchpad is wiped between sessions, so the harness scripts
(`shots.mjs`, `mshots.mjs`, `parse.sh`, `gate.mjs`) have to be rebuilt.
A `grep` over a script that no longer exists reports success. Check the file
is there before trusting a clean sweep.

Run `parse.sh` after every edit to `index.html`.

## Shape of the app

- One file, `index.html`, ~6k lines. No framework, no build.
- The whole app is painted out of one set of CSS custom properties. To
  restyle every page, restate the tokens on `.scr` — do not chase classes.
  Only rules that name a colour outright need saying twice.
- Breakpoints inside the case cannot read the viewport: the content column is
  far narrower than the window. Use `@container` on `.scr-in`.
- `tasks`, `categories`, `projects`, `kolItems`, `prItems`, `npdProducts`
  mean **the signed-in person's own**. What the other person owns lives in
  `teamTasks`, `teamProjects`, `teamKol`, `teamPr`, `teamProducts`, and is
  read in exactly one place on purpose: the Team page.
- Class names are shared across old and new code. Check a name is free before
  using it — `.dash-main` was already taken and the collision silently
  emptied every task row.

## Constraints that do not change

- The backup format string `GUY_WORK_OS_BACKUP` must not be renamed.
- The repo is public.
- `vercel.app`, Google Fonts, jsDelivr and open-meteo are blocked by the
  egress proxy, so anything that depends on them can only be verified by the
  user. Say so plainly rather than implying it was tested.

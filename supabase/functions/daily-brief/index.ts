// GUY WORK OS V7.2/V7.3 - Daily Task Reminder
// Scheduled Edge Function: sends one daily notification per user summarizing
// today's tasks (and overdue count). Prefers LINE (if the user linked their
// account) and falls back to Web Push otherwise, so nobody gets both.
//
// Required secrets (set with `supabase secrets set`):
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT (mailto:you@example.com)
// Optional secret (only needed once LINE is set up):
//   LINE_CHANNEL_ACCESS_TOKEN
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.
// Optional secret: APP_TIMEZONE (IANA name, default "Asia/Bangkok") controls
// what counts as "today" when comparing against each task's due date.

import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const VAPID_PUBLIC_KEY = Deno.env.get("VAPID_PUBLIC_KEY")!;
const VAPID_PRIVATE_KEY = Deno.env.get("VAPID_PRIVATE_KEY")!;
const VAPID_SUBJECT = Deno.env.get("VAPID_SUBJECT") || "mailto:admin@example.com";
const APP_TIMEZONE = Deno.env.get("APP_TIMEZONE") || "Asia/Bangkok";
const LINE_CHANNEL_ACCESS_TOKEN = Deno.env.get("LINE_CHANNEL_ACCESS_TOKEN") || "";

webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);

function todayInTimezone(tz: string): string {
  // en-CA gives YYYY-MM-DD, matching the app's `due` date format.
  return new Intl.DateTimeFormat("en-CA", { timeZone: tz }).format(new Date());
}

async function sendLine(lineUserId: string, text: string): Promise<boolean> {
  const res = await fetch("https://api.line.me/v2/bot/message/push", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${LINE_CHANNEL_ACCESS_TOKEN}`,
    },
    body: JSON.stringify({ to: lineUserId, messages: [{ type: "text", text }] }),
  });
  if (!res.ok) console.error("LINE push failed", res.status, await res.text());
  return res.ok;
}

Deno.serve(async (req) => {
  if (req.method !== "POST" && req.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }

  const sb = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const today = todayInTimezone(APP_TIMEZONE);

  const [
    { data: tasks, error: taskErr },
    { data: subs, error: subErr },
    { data: profiles, error: profErr },
    { data: lineSubs, error: lineErr },
  ] = await Promise.all([
    sb.from("tasks").select("user_id,task,due,status,priority").neq("status", "Done"),
    sb.from("push_subscriptions").select("id,user_id,endpoint,p256dh,auth"),
    sb.from("profiles").select("user_id,full_name,email"),
    sb.from("line_subscriptions").select("user_id,line_user_id"),
  ]);

  if (taskErr || subErr || profErr || lineErr) {
    return new Response(
      JSON.stringify({ error: (taskErr || subErr || profErr || lineErr)?.message }),
      { status: 500, headers: { "content-type": "application/json" } },
    );
  }

  const subsByUser = new Map<string, typeof subs>();
  for (const s of subs || []) {
    if (!subsByUser.has(s.user_id)) subsByUser.set(s.user_id, []);
    subsByUser.get(s.user_id)!.push(s);
  }

  const lineByUser = new Map<string, string>();
  for (const l of lineSubs || []) lineByUser.set(l.user_id, l.line_user_id);

  const nameByUser = new Map<string, string>();
  for (const p of profiles || []) nameByUser.set(p.user_id, p.full_name || p.email || "there");

  const userIds = new Set<string>([...subsByUser.keys(), ...lineByUser.keys()]);

  let sent = 0, expired = 0, failed = 0, usersNotified = 0;

  for (const userId of userIds) {
    const mine = (tasks || []).filter((t) => t.user_id === userId);
    const dueToday = mine.filter((t) => t.due === today);
    const overdue = mine.filter((t) => t.due && t.due < today);
    if (!dueToday.length && !overdue.length) continue; // nothing to nag about today

    const first = dueToday.slice(0, 3).map((t) => t.task);
    const extra = dueToday.length - first.length;
    const parts: string[] = [];
    if (dueToday.length) {
      parts.push(`${first.join(", ")}${extra > 0 ? ` +${extra} more` : ""}`);
    }
    if (overdue.length) parts.push(`${overdue.length} overdue`);

    const title = dueToday.length
      ? `${dueToday.length} task${dueToday.length === 1 ? "" : "s"} today`
      : `${overdue.length} overdue task${overdue.length === 1 ? "" : "s"}`;
    const body = parts.join(" · ") || "Open GUY WORK OS to see what's up.";
    const name = nameByUser.get(userId) || "GUY WORK OS";

    usersNotified++;
    const lineUserId = lineByUser.get(userId);

    if (lineUserId && LINE_CHANNEL_ACCESS_TOKEN) {
      // Prefer LINE when linked, so the user doesn't get double notifications.
      const ok = await sendLine(lineUserId, `${title} — ${name}\n${body}`);
      if (ok) sent++; else failed++;
      continue;
    }

    const payload = JSON.stringify({ title: `${title} — ${name}`, body, url: "./" });
    for (const s of subsByUser.get(userId) || []) {
      try {
        await webpush.sendNotification(
          { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
          payload,
        );
        sent++;
      } catch (err) {
        const status = (err as { statusCode?: number })?.statusCode;
        if (status === 404 || status === 410) {
          await sb.from("push_subscriptions").delete().eq("id", s.id);
          expired++;
        } else {
          failed++;
          console.error("push send failed", userId, status, err);
        }
      }
    }
  }

  return new Response(
    JSON.stringify({ today, usersNotified, sent, expired, failed }),
    { headers: { "content-type": "application/json" } },
  );
});

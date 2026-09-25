// PORKCHOP G - Daily Task Reminder
// Scheduled Edge Function: sends one daily notification per user summarizing
// today's tasks (and overdue count). Each person gets it once, on the first
// channel they have linked: Telegram, then LINE, then Web Push.
//
// Every channel is optional; set the secrets for the ones in use:
//   TELEGRAM_BOT_TOKEN                                  (V7.79)
//   LINE_CHANNEL_ACCESS_TOKEN
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT (mailto:you@example.com)
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.
// Optional secret: APP_TIMEZONE (IANA name, default "Asia/Bangkok") controls
// what counts as "today" when comparing against each task's due date.

import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const VAPID_PUBLIC_KEY = Deno.env.get("VAPID_PUBLIC_KEY") || "";
const VAPID_PRIVATE_KEY = Deno.env.get("VAPID_PRIVATE_KEY") || "";
const VAPID_SUBJECT = Deno.env.get("VAPID_SUBJECT") || "mailto:admin@example.com";
const APP_TIMEZONE = Deno.env.get("APP_TIMEZONE") || "Asia/Bangkok";
const LINE_CHANNEL_ACCESS_TOKEN = Deno.env.get("LINE_CHANNEL_ACCESS_TOKEN") || "";
const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN") || "";

const APP_URL = Deno.env.get("APP_URL") || "https://guy-work-os.vercel.app";

// Web Push and LINE are two separate ways out, and either may be the only one
// set up. This used to configure Web Push unconditionally at load: with no
// VAPID keys that threw before a single request was served, so a project set
// up for LINE alone never sent anything. Push is now only armed when its keys
// are actually there.
const PUSH_ON = !!(VAPID_PUBLIC_KEY && VAPID_PRIVATE_KEY);
if (PUSH_ON) webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);

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

// Returns "gone" when the person blocked the bot, so the link can be dropped
// instead of failing again every morning.
async function sendTelegram(chatId: number, text: string): Promise<"ok" | "gone" | "fail"> {
  const res = await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ chat_id: chatId, text, disable_web_page_preview: true }),
  });
  if (res.ok) return "ok";
  const detail = await res.text();
  console.error("Telegram send failed", res.status, detail);
  return res.status === 403 || (res.status === 400 && /chat not found/i.test(detail)) ? "gone" : "fail";
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
    { data: tgSubs, error: tgErr },
  ] = await Promise.all([
    sb.from("tasks").select("user_id,task,due,status,priority").neq("status", "Done"),
    sb.from("push_subscriptions").select("id,user_id,endpoint,p256dh,auth"),
    sb.from("profiles").select("user_id,full_name,email"),
    sb.from("line_subscriptions").select("user_id,line_user_id"),
    sb.from("tg_subscriptions").select("user_id,chat_id"),
  ]);

  // A table that was never created means nobody uses that channel, not that
  // the whole brief should fail -- any setup that skips a channel has its
  // table missing.
  const missing = (e: { code?: string; message?: string } | null) =>
    !!e && (e.code === "42P01" || e.code === "PGRST205" || /does not exist|Could not find the table/i.test(e.message || ""));
  if ((taskErr || profErr) || (subErr && !missing(subErr)) || (lineErr && !missing(lineErr)) || (tgErr && !missing(tgErr))) {
    return new Response(
      JSON.stringify({ error: (taskErr || subErr || profErr || lineErr || tgErr)?.message }),
      { status: 500, headers: { "content-type": "application/json" } },
    );
  }

  const subsByUser = new Map<string, typeof subs>();
  for (const s of (PUSH_ON && !subErr ? subs : []) || []) {
    if (!subsByUser.has(s.user_id)) subsByUser.set(s.user_id, []);
    subsByUser.get(s.user_id)!.push(s);
  }

  const lineByUser = new Map<string, string>();
  for (const l of (lineErr ? [] : lineSubs) || []) lineByUser.set(l.user_id, l.line_user_id);

  const tgByUser = new Map<string, number>();
  for (const t of (tgErr || !TELEGRAM_BOT_TOKEN ? [] : tgSubs) || []) tgByUser.set(t.user_id, t.chat_id);

  const nameByUser = new Map<string, string>();
  for (const p of profiles || []) nameByUser.set(p.user_id, p.full_name || p.email || "there");

  const userIds = new Set<string>([...subsByUser.keys(), ...lineByUser.keys(), ...tgByUser.keys()]);

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
    const body = parts.join(" · ") || "Open PORKCHOP G to see what's up.";
    const name = nameByUser.get(userId) || "PORKCHOP G";

    usersNotified++;

    const chatId = tgByUser.get(userId);
    if (chatId) {
      // A chat has room for the whole day, not just the first three.
      const lines = [`☀️ ${title} — ${name}`, ""];
      for (const t of dueToday.slice(0, 10)) lines.push(`• ${t.task}`);
      if (dueToday.length > 10) lines.push(`… +${dueToday.length - 10} more`);
      if (overdue.length) {
        if (dueToday.length) lines.push("");
        lines.push(`⚠️ ${overdue.length} overdue`);
        for (const t of overdue.slice(0, 5)) lines.push(`• ${t.task} (${t.due})`);
        if (overdue.length > 5) lines.push(`… +${overdue.length - 5} more`);
      }
      lines.push("", APP_URL);
      const r = await sendTelegram(chatId, lines.join("\n"));
      if (r === "ok") { sent++; continue; }
      if (r === "gone") {
        await sb.from("tg_subscriptions").delete().eq("user_id", userId);
        expired++;
      } else failed++;
      // Fall through: LINE or push may still reach them today.
    }

    const lineUserId = lineByUser.get(userId);

    if (lineUserId && LINE_CHANNEL_ACCESS_TOKEN) {
      // Prefer LINE when linked, so the user doesn't get double notifications.
      const ok = await sendLine(lineUserId, `${title} — ${name}\n${body}\n\n${APP_URL}`);
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

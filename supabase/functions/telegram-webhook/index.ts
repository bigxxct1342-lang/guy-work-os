// PORKCHOP G V7.79 - Telegram linking webhook
// Receives updates from the team's Telegram bot and links a Telegram chat to
// a PORKCHOP G account.
//
// Flow: Settings -> Telegram -> "เชื่อม Telegram" writes a one-time code to
// public.tg_links and opens t.me/<bot>?start=<code>. Pressing Start sends
// "/start <code>" here; the code is consumed and the chat id is stored in
// public.tg_subscriptions, which daily-brief reads.
//
// Required secret:
//   TELEGRAM_BOT_TOKEN - the token @BotFather gives when the bot is created
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.
//
// Must be deployed with JWT verification OFF: Telegram calls it directly.
// Requests are authenticated instead by the secret token Telegram echoes in
// X-Telegram-Bot-Api-Secret-Token, which is derived from the bot token, so
// there is no second secret to create.
//
// GET  ?setup=1  points the bot's webhook at this function (run once after
//                deploying, and again if the bot token ever changes)
// GET            returns {"bot":"<username>"} so the app can build the link
//
// V7.80: the "📋 งานค้าง" button (or /today) answers with the same report the
// app opens with after sign-in -- date, weather, the priority matrix, what is
// urgent, and the ads running today -- read live at the moment it is asked.

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN") || "";

const APP_URL = Deno.env.get("APP_URL") || "https://guy-work-os.vercel.app";
const APP_TIMEZONE = Deno.env.get("APP_TIMEZONE") || "Asia/Bangkok";
const WEATHER_LAT = Deno.env.get("WEATHER_LAT") || "13.7563";
const WEATHER_LON = Deno.env.get("WEATHER_LON") || "100.5018";

const SELF_URL = `${SUPABASE_URL}/functions/v1/telegram-webhook`;
const sb = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "content-type": "application/json" },
  });
}

async function tg(method: string, payload: Record<string, unknown> = {}) {
  const res = await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/${method}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  const out = await res.json().catch(() => ({ ok: false, description: `HTTP ${res.status}` }));
  if (!out.ok) console.error(`telegram ${method} failed`, out.description);
  return out;
}

// A button that stays under the message box, so asking never means typing.
const ASK = "📋 งานค้าง";
const KEYBOARD = { keyboard: [[{ text: ASK }]], resize_keyboard: true, is_persistent: true };

function say(chatId: number, text: string, extra: Record<string, unknown> = {}) {
  return tg("sendMessage", { chat_id: chatId, text, disable_web_page_preview: true, ...extra });
}

// ---- The report -----------------------------------------------------------
// Mirrors bootReport() in index.html: the same matrix rule (High = important,
// due within PM_URGENT_DAYS or overdue = urgent), the same quadrant names,
// the same "ads running" rule (approved creative whose boost covers today).

const PM_URGENT_DAYS = 2;
const Q_NAME = ["", "Q1 · ทำวันนี้", "Q2 · ต้องวางแผน", "Q3 · รีบแต่ไม่สำคัญ", "Q4 · ไว้ก่อน"];
const WMO: Record<number, string> = {0:"ฟ้าโปร่ง",1:"แดดจัด",2:"มีเมฆบางส่วน",3:"เมฆมาก",45:"หมอกลง",48:"หมอกลง",
  51:"ฝนปรอย",53:"ฝนปรอย",55:"ฝนปรอย",61:"ฝนตกเล็กน้อย",63:"ฝนตก",65:"ฝนตกหนัก",
  71:"หิมะ",73:"หิมะ",75:"หิมะ",80:"ฝนซู่",81:"ฝนซู่",82:"ฝนซู่หนัก",
  95:"ฝนฟ้าคะนอง",96:"ฝนฟ้าคะนอง",99:"ฝนฟ้าคะนอง"};

type Task = {
  task: string; due: string | null; priority: string | null; category?: string | null;
  cv_on?: boolean; cv_status?: string | null;
  post_boost?: boolean; post_boost_from?: string | null; post_boost_to?: string | null;
};

const h = (s: unknown) => String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const dayMs = 864e5;
const daysBetween = (a: string, b: string) =>
  Math.round((Date.parse(b + "T00:00:00Z") - Date.parse(a + "T00:00:00Z")) / dayMs);
const fmtD = (d: string) =>
  new Date(d + "T00:00:00Z").toLocaleDateString("en-GB", { day: "numeric", month: "short", timeZone: "UTC" });

function dueLabel(d: number | null) {
  if (d == null) return "ไม่มีกำหนด";
  if (d < 0) return `เลยมา ${-d} วัน`;
  if (d === 0) return "วันนี้";
  if (d === 1) return "พรุ่งนี้";
  return `อีก ${d} วัน`;
}

async function weather(): Promise<string> {
  const u = `https://api.open-meteo.com/v1/forecast?latitude=${WEATHER_LAT}&longitude=${WEATHER_LON}` +
    `&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max` +
    `&timezone=${encodeURIComponent(APP_TIMEZONE)}&forecast_days=1`;
  try {
    const r = await fetch(u, { signal: AbortSignal.timeout(4000) });
    if (!r.ok) return "";
    const j = await r.json();
    const t = Math.round(j.current?.temperature_2m);
    if (!isFinite(t)) return "";
    const w = WMO[j.current?.weather_code] || "";
    const hi = Math.round(j.daily?.temperature_2m_max?.[0]), lo = Math.round(j.daily?.temperature_2m_min?.[0]);
    const rain = j.daily?.precipitation_probability_max?.[0];
    return `${t}°${w ? " · " + w : ""}${isFinite(hi) && isFinite(lo) ? ` · ${lo}–${hi}°` : ""}` +
      `${isFinite(rain) ? ` · โอกาสฝน ${rain}%` : ""}`;
  } catch {
    return "";
  }
}

async function openTasks(userId: string): Promise<Task[]> {
  const full = "task,due,priority,category,cv_on,cv_status,post_boost,post_boost_from,post_boost_to";
  const read = (cols: string) => sb.from("tasks").select(cols).eq("user_id", userId).neq("status", "Done");
  let r = await read(full);
  // Before the V7.32 creative columns exist, the matrix still works.
  if (r.error) r = await read("task,due,priority,category");
  if (r.error) throw r.error;
  return (r.data || []) as unknown as Task[];
}

async function report(userId: string): Promise<string> {
  const [tasks, wx] = await Promise.all([openTasks(userId), weather()]);
  const now = new Date();
  const today = new Intl.DateTimeFormat("en-CA", { timeZone: APP_TIMEZONE }).format(now);

  const rows = tasks.map((t) => {
    const d = t.due ? daysBetween(today, t.due) : null;
    const urgent = d != null && d <= PM_URGENT_DAYS;
    const q = t.priority === "High" ? (urgent ? 1 : 2) : (urgent ? 3 : 4);
    return { t, d, q };
  });
  const count = [0, 0, 0, 0, 0];
  rows.forEach((r) => count[r.q]++);

  const L: string[] = [];
  L.push("<b>PORKCHOP G :: DAILY REPORT</b>");
  L.push(
    now.toLocaleDateString("th-TH-u-ca-gregory", { weekday: "long", day: "numeric", month: "long", year: "numeric", timeZone: APP_TIMEZONE }) +
      " · " + now.toLocaleTimeString("th-TH", { hour: "2-digit", minute: "2-digit", timeZone: APP_TIMEZONE }) + " น.",
  );
  L.push(`สภาพอากาศ: ${h(wx || "ดูไม่ได้ตอนนี้")}`);

  L.push("", "<b>PRIORITY MATRIX</b>");
  for (let q = 1; q <= 4; q++) L.push(`${q === 1 ? "🔥" : "▫️"} ${Q_NAME[q]} — <b>${count[q]}</b>`);

  // The two urgent quadrants are the ones worth naming; the rest is a count.
  for (const q of [1, 3]) {
    const list = rows.filter((r) => r.q === q).sort((a, b) => (a.d ?? 1e9) - (b.d ?? 1e9));
    if (!list.length) continue;
    L.push("", `<b>${q === 1 ? "🔥 " : ""}${Q_NAME[q]}</b>`);
    for (const r of list.slice(0, 8)) {
      L.push(`• ${h(r.t.task)} — ${r.d != null && r.d < 0 ? "⚠️ " : ""}${dueLabel(r.d)}`);
    }
    if (list.length > 8) L.push(`… อีก ${list.length - 8} งาน`);
  }
  if (!tasks.length) L.push("", "ไม่มีงานค้างเลย 🎉");

  L.push("", "<b>กิจกรรม · ADS ที่กำลังรัน</b>");
  const ads = tasks
    .filter((t) => t.cv_on && t.cv_status === "done" && t.post_boost && t.post_boost_from && t.post_boost_to &&
      today >= t.post_boost_from && today <= t.post_boost_to)
    .sort((a, b) => String(a.post_boost_to).localeCompare(String(b.post_boost_to)));
  if (!ads.length) L.push("ตอนนี้ไม่มีตัวไหนรันแอดอยู่");
  for (const t of ads) {
    const span = Math.max(1, daysBetween(t.post_boost_from!, t.post_boost_to!) + 1);
    const gone = daysBetween(t.post_boost_from!, today) + 1;
    const pct = Math.max(0, Math.min(100, Math.round((gone / span) * 100)));
    const left = Math.max(0, daysBetween(today, t.post_boost_to!));
    const bar = "▓".repeat(Math.round(pct / 10)) + "░".repeat(10 - Math.round(pct / 10));
    L.push(`• ${h(t.task)}`, `  บูท ${fmtD(t.post_boost_from!)} – ${fmtD(t.post_boost_to!)} · ${left ? `เหลืออีก ${left} วัน` : "วันสุดท้าย"}`, `  ${bar} ${pct}%`);
  }

  L.push("", APP_URL);
  return L.join("\n");
}

async function sendReport(chatId: number) {
  const { data: sub } = await sb.from("tg_subscriptions").select("user_id").eq("chat_id", chatId).maybeSingle();
  if (!sub) {
    await say(chatId, "แชทนี้ยังไม่ได้เชื่อมกับบัญชี PORKCHOP G\n\n" + HELP);
    return;
  }
  try {
    await say(chatId, await report(sub.user_id), { parse_mode: "HTML", reply_markup: KEYBOARD });
  } catch (err) {
    console.error("report failed", err);
    await say(chatId, "ดึงรายงานไม่สำเร็จ ลองใหม่อีกครั้ง", { reply_markup: KEYBOARD });
  }
}

// Telegram allows A-Z a-z 0-9 _ - in a webhook secret. A hash of the bot token
// fits, changes when the token is revoked, and never has to be typed anywhere.
async function webhookSecret(): Promise<string> {
  const d = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(`porkchop-g:${TELEGRAM_BOT_TOKEN}`));
  return Array.from(new Uint8Array(d), (b) => b.toString(16).padStart(2, "0")).join("");
}

let botName = "";
async function getBotName(): Promise<string> {
  if (!botName) {
    const me = await tg("getMe");
    botName = me.ok ? me.result.username : "";
  }
  return botName;
}

const HELP =
  "บอทนี้ส่งสรุปงานประจำวันของ PORKCHOP G\n\n" +
  "เชื่อมบัญชี: เปิดแอป → Settings → Telegram → กด \"เชื่อม Telegram\" แล้วกด Start ที่นี่\n" +
  `ดูงานค้างตอนนี้: กดปุ่ม "${ASK}" หรือพิมพ์ /today\n` +
  "เลิกรับ: พิมพ์ /stop";

async function link(chatId: number, rawCode: string, tgName: string) {
  const code = rawCode.trim().toUpperCase();
  // One statement: a code can only ever be consumed once, even if Start is
  // pressed twice in quick succession.
  const { data: row } = await sb
    .from("tg_links")
    .update({ consumed_at: new Date().toISOString() })
    .eq("code", code)
    .is("consumed_at", null)
    .gt("expires_at", new Date().toISOString())
    .select("user_id")
    .maybeSingle();

  if (!row) {
    await say(chatId, "โค้ดนี้ใช้ไม่ได้หรือหมดอายุแล้ว (15 นาที)\nกลับไปที่แอป → Settings → Telegram แล้วกด \"เชื่อม Telegram\" ใหม่อีกครั้ง");
    return;
  }

  // A chat belongs to one account at a time.
  await sb.from("tg_subscriptions").delete().eq("chat_id", chatId);
  const { error } = await sb.from("tg_subscriptions").upsert(
    { user_id: row.user_id, chat_id: chatId, tg_name: tgName || null, linked_at: new Date().toISOString() },
    { onConflict: "user_id" },
  );
  if (error) {
    console.error("tg_subscriptions upsert failed", error);
    await say(chatId, "เชื่อมไม่สำเร็จ ลองใหม่อีกครั้ง");
    return;
  }

  const { data: p } = await sb.from("profiles").select("full_name,email").eq("user_id", row.user_id).maybeSingle();
  const who = p?.full_name || p?.email || "";
  await say(
    chatId,
    `เชื่อม PORKCHOP G สำเร็จ ✓${who ? `\nบัญชี: ${who}` : ""}\n\nทุกเช้าจะส่งสรุปงานวันนี้มาที่แชทนี้\n` +
      `อยากดูงานค้างตอนไหนก็กดปุ่ม "${ASK}" ด้านล่าง\nเลิกรับเมื่อไหร่ก็พิมพ์ /stop`,
    { reply_markup: KEYBOARD },
  );
}

async function unlink(chatId: number) {
  const { data } = await sb.from("tg_subscriptions").delete().eq("chat_id", chatId).select("user_id");
  await say(chatId, data?.length ? "ยกเลิกแล้ว จะไม่ส่งสรุปงานมาที่นี่อีก" : "แชทนี้ยังไม่ได้เชื่อมกับบัญชีไหน",
    { reply_markup: { remove_keyboard: true } });
}

// deno-lint-ignore no-explicit-any
async function handle(update: any) {
  // Blocking the bot is the same as /stop.
  const mcm = update.my_chat_member;
  if (mcm && mcm.chat?.type === "private" && mcm.new_chat_member?.status === "kicked") {
    await sb.from("tg_subscriptions").delete().eq("chat_id", mcm.chat.id);
    return;
  }

  const msg = update.message;
  if (!msg || msg.chat?.type !== "private" || typeof msg.text !== "string") return;
  const chatId: number = msg.chat.id;
  const text = msg.text.trim();
  const tgName = [msg.from?.first_name, msg.from?.last_name].filter(Boolean).join(" ") ||
    (msg.from?.username ? `@${msg.from.username}` : "");

  const start = text.match(/^\/start(?:@\w+)?(?:\s+(\S+))?$/i);
  if (start) {
    if (start[1]) await link(chatId, start[1], tgName);
    else await say(chatId, HELP, { reply_markup: KEYBOARD });
    return;
  }
  if (text === ASK || /^\/(today|report)(?:@\w+)?$/i.test(text) || /^(งานค้าง|งาน|report)$/i.test(text)) {
    await sendReport(chatId);
    return;
  }
  if (/^\/stop(?:@\w+)?$/i.test(text)) {
    await unlink(chatId);
    return;
  }
  // The code typed by hand works too, in case the Start link was lost.
  if (/^[A-Za-z0-9]{8,12}$/.test(text)) {
    await link(chatId, text, tgName);
    return;
  }
  await say(chatId, HELP, { reply_markup: KEYBOARD });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS });

  if (!TELEGRAM_BOT_TOKEN) {
    return json({ error: "TELEGRAM_BOT_TOKEN is not set (Edge Functions → Secrets)" }, 500);
  }

  if (req.method === "GET") {
    const url = new URL(req.url);
    if (url.searchParams.has("setup")) {
      const set = await tg("setWebhook", {
        url: SELF_URL,
        secret_token: await webhookSecret(),
        allowed_updates: ["message", "my_chat_member"],
        drop_pending_updates: true,
      });
      await tg("setMyCommands", {
        commands: [
          { command: "today", description: "ดูงานค้างตอนนี้" },
          { command: "start", description: "วิธีเชื่อมกับ PORKCHOP G" },
          { command: "stop", description: "เลิกรับสรุปงานประจำวัน" },
        ],
      });
      const bot = await getBotName();
      return json({
        ok: !!set.ok && !!bot,
        bot: bot ? `@${bot}` : null,
        webhook: set.ok ? SELF_URL : null,
        error: set.ok ? (bot ? null : "getMe failed — check TELEGRAM_BOT_TOKEN") : set.description,
      }, set.ok && bot ? 200 : 500);
    }
    const bot = await getBotName();
    return bot ? json({ bot }) : json({ error: "getMe failed — check TELEGRAM_BOT_TOKEN" }, 500);
  }

  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  if (req.headers.get("x-telegram-bot-api-secret-token") !== (await webhookSecret())) {
    return new Response("Forbidden", { status: 403 });
  }

  try {
    await handle(await req.json());
  } catch (err) {
    // Always 200: a non-2xx makes Telegram redeliver the same update forever.
    console.error("telegram-webhook update failed", err);
  }
  return new Response("OK");
});

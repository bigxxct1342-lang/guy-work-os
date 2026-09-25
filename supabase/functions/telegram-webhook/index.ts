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

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN") || "";

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

function say(chatId: number, text: string) {
  return tg("sendMessage", { chat_id: chatId, text, disable_web_page_preview: true });
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
  await say(chatId, `เชื่อม PORKCHOP G สำเร็จ ✓${who ? `\nบัญชี: ${who}` : ""}\n\nทุกเช้าจะส่งสรุปงานวันนี้มาที่แชทนี้\nเลิกรับเมื่อไหร่ก็พิมพ์ /stop`);
}

async function unlink(chatId: number) {
  const { data } = await sb.from("tg_subscriptions").delete().eq("chat_id", chatId).select("user_id");
  await say(chatId, data?.length ? "ยกเลิกแล้ว จะไม่ส่งสรุปงานมาที่นี่อีก" : "แชทนี้ยังไม่ได้เชื่อมกับบัญชีไหน");
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
    else await say(chatId, HELP);
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
  await say(chatId, HELP);
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

// GUY WORK OS V7.3 - LINE linking webhook
// Receives events from a LINE Official Account (Messaging API webhook).
// Flow: user opens the app -> Settings -> LINE Notifications -> "Generate
// Code" (writes a row to public.line_links). The user then sends that code
// as a chat message to the LINE Official Account. LINE calls this webhook,
// we match the code, and store the mapping in public.line_subscriptions.
//
// Required secrets:
//   LINE_CHANNEL_SECRET       - Messaging API channel secret (for signature check)
//   LINE_CHANNEL_ACCESS_TOKEN - Messaging API long-lived channel access token
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const LINE_CHANNEL_SECRET = Deno.env.get("LINE_CHANNEL_SECRET")!;
const LINE_CHANNEL_ACCESS_TOKEN = Deno.env.get("LINE_CHANNEL_ACCESS_TOKEN")!;

const sb = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

async function verifySignature(rawBody: string, signature: string | null): Promise<boolean> {
  if (!signature) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(LINE_CHANNEL_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(rawBody));
  const expected = btoa(String.fromCharCode(...new Uint8Array(mac)));
  return expected === signature;
}

async function lineReply(replyToken: string, text: string) {
  await fetch("https://api.line.me/v2/bot/message/reply", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${LINE_CHANNEL_ACCESS_TOKEN}`,
    },
    body: JSON.stringify({ replyToken, messages: [{ type: "text", text }] }),
  });
}

async function handleLinkCode(lineUserId: string, rawCode: string, replyToken: string) {
  const code = rawCode.trim().toUpperCase();
  const { data: link } = await sb
    .from("line_links")
    .select("id,user_id,expires_at,consumed_at")
    .eq("code", code)
    .maybeSingle();

  if (!link || link.consumed_at || new Date(link.expires_at) < new Date()) {
    await lineReply(replyToken, "โค้ดไม่ถูกต้องหรือหมดอายุแล้ว ลองกดสร้างโค้ดใหม่ในแอป (Settings > LINE Notifications) แล้วส่งมาใหม่อีกครั้งครับ");
    return;
  }

  // A LINE account can only be linked to one GUY WORK OS account at a time.
  await sb.from("line_subscriptions").delete().eq("line_user_id", lineUserId);
  await sb.from("line_subscriptions").upsert(
    { user_id: link.user_id, line_user_id: lineUserId },
    { onConflict: "user_id" },
  );
  await sb.from("line_links").update({ consumed_at: new Date().toISOString() }).eq("id", link.id);

  await lineReply(replyToken, "เชื่อมต่อ GUY WORK OS สำเร็จ! 🎉 คุณจะได้รับแจ้งเตือนงานประจำวันทาง LINE จากนี้ไป");
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const rawBody = await req.text();
  const signature = req.headers.get("x-line-signature");
  if (!(await verifySignature(rawBody, signature))) {
    return new Response("Invalid signature", { status: 401 });
  }

  const body = JSON.parse(rawBody);
  const events = Array.isArray(body.events) ? body.events : [];

  for (const event of events) {
    try {
      if (event.type === "follow" && event.replyToken) {
        await lineReply(
          event.replyToken,
          "ยินดีต้อนรับสู่ GUY WORK OS! เปิดแอป ไปที่ Settings > LINE Notifications เพื่อขอโค้ดเชื่อมต่อ แล้วส่งโค้ดนั้นมาที่แชทนี้ได้เลยครับ",
        );
      } else if (event.type === "message" && event.message?.type === "text" && event.replyToken && event.source?.userId) {
        await handleLinkCode(event.source.userId, event.message.text, event.replyToken);
      }
    } catch (err) {
      console.error("line-webhook event failed", err);
    }
  }

  return new Response("OK", { status: 200 });
});

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.1/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Payload = {
  recipient_id: string;
  event_table: string;
  event_id: string;
  payload: { kind: string; title: string; body: string; url: string };
};

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

function pemToBytes(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer;
}

async function getAccessToken(raw: string): Promise<string | null> {
  const sa = JSON.parse(raw);
  const now = getNumericDate(0);
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: sa.client_email,
      scope: FCM_SCOPE,
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: getNumericDate(60 * 60),
    },
    key
  );
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const json = await res.json();
  return json.access_token ?? null;
}

serve(async (req) => {
  if (req.method !== "POST") return new Response("only POST", { status: 405 });

  let body: Payload;
  try {
    body = await req.json();
  } catch {
    return new Response("invalid json", { status: 400 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "http://kong:8000",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    { auth: { persistSession: false } }
  );

  const sa = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");

  if (!sa) {
    // Stub mode — mark delivered=true
    await supabase
      .from("push_log")
      .update({ delivered: true })
      .eq("event_table", body.event_table)
      .eq("event_id", body.event_id)
      .eq("recipient_id", body.recipient_id);
    return new Response("ok (stub)", { status: 200 });
  }

  // Look up device tokens for the recipient
  const { data: tokens, error: tokensError } = await supabase
    .from("device_tokens")
    .select("token, platform")
    .eq("user_id", body.recipient_id);

  if (tokensError) {
    await supabase
      .from("push_log")
      .update({ error: tokensError.message })
      .eq("event_table", body.event_table)
      .eq("event_id", body.event_id)
      .eq("recipient_id", body.recipient_id);
    return new Response("err", { status: 500 });
  }

  if (!tokens || tokens.length === 0) {
    await supabase
      .from("push_log")
      .update({ delivered: true, error: "no tokens" })
      .eq("event_table", body.event_table)
      .eq("event_id", body.event_id)
      .eq("recipient_id", body.recipient_id);
    return new Response("ok (no tokens)", { status: 200 });
  }

  const accessToken = await getAccessToken(sa);
  const projectId = JSON.parse(sa).project_id;
  let allOk = true;
  const errors: string[] = [];

  for (const t of tokens) {
    if (t.platform === "web") continue;
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: t.token,
            notification: { title: body.payload.title, body: body.payload.body },
            data: { url: body.payload.url, kind: body.payload.kind },
            android: { priority: "HIGH" },
          },
        }),
      }
    );
    if (!res.ok) {
      allOk = false;
      errors.push(await res.text());
    }
  }

  await supabase
    .from("push_log")
    .update({
      delivered: allOk,
      error: errors.length ? errors.join("; ") : null,
    })
    .eq("event_table", body.event_table)
    .eq("event_id", body.event_id)
    .eq("recipient_id", body.recipient_id);

  return new Response(allOk ? "ok" : "partial", { status: 200 });
});

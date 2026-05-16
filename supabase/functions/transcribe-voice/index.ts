import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  if (req.method !== "POST") return new Response("only POST", { status: 405 });

  let body: { message_id?: string };
  try {
    body = await req.json();
  } catch {
    return new Response("invalid json", { status: 400 });
  }
  if (!body.message_id) return new Response("message_id required", { status: 400 });

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "http://kong:8000";
  const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const whisperKey = Deno.env.get("WHISPER_API_KEY");

  const admin = createClient(supabaseUrl, serviceRole, { auth: { persistSession: false } });

  // Stub mode: no real ASR key set
  if (!whisperKey) {
    await admin
      .from("messages")
      .update({
        transcript:
          "[Transcript unavailable in dev — set WHISPER_API_KEY to enable Whisper ASR]",
        transcript_status: "unsupported",
      })
      .eq("id", body.message_id);
    return new Response("ok (stub)", { status: 200 });
  }

  // Real mode: download audio + call Whisper
  const { data: msg } = await admin
    .from("messages")
    .select("media_path, conversation_id")
    .eq("id", body.message_id)
    .single();

  if (!msg?.media_path) {
    return new Response("no media path", { status: 404 });
  }

  // Signed URL good for 60s
  const { data: signed } = await admin.storage
    .from("chat-media")
    .createSignedUrl(msg.media_path, 60);
  if (!signed?.signedUrl) return new Response("signed url failed", { status: 500 });

  const audioRes = await fetch(signed.signedUrl);
  const audioBlob = await audioRes.blob();

  const form = new FormData();
  form.append("file", audioBlob, "voice.m4a");
  form.append("model", "whisper-1");

  const whisper = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: { Authorization: `Bearer ${whisperKey}` },
    body: form,
  });

  if (!whisper.ok) {
    await admin
      .from("messages")
      .update({
        transcript: `[Whisper error ${whisper.status}]`,
        transcript_status: "failed",
      })
      .eq("id", body.message_id);
    return new Response("whisper failed", { status: 500 });
  }

  const result = await whisper.json();
  await admin
    .from("messages")
    .update({
      transcript: result.text ?? null,
      transcript_status: "ready",
    })
    .eq("id", body.message_id);

  return new Response("ok", { status: 200 });
});

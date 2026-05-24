import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { handlePreflight, jsonResponse } from "../_shared/cors.ts";
import { optionalEnv, requireEnv, verifyWebhookSecret } from "../_shared/env.ts";

const SUPABASE_URL = requireEnv("SUPABASE_URL");
const SERVICE_ROLE = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
const WEBHOOK_SECRET = requireEnv("WEBHOOK_SHARED_SECRET");
const WHISPER_KEY = optionalEnv("WHISPER_API_KEY") ??
  optionalEnv("OPENAI_API_KEY");

const MAX_AUDIO_BYTES = 25 * 1024 * 1024; // Whisper hard limit is 25 MiB.
const SIGNED_URL_TTL_SECONDS = 60;
const FETCH_TIMEOUT_MS = 30_000;
// Guard against a malformed env value (NaN setTimeout fires immediately and
// would abort every Whisper call before it could complete). Fall back to 30s.
const _whisperTimeoutRaw = Number(optionalEnv("WHISPER_TIMEOUT_MS") ?? 30_000);
const WHISPER_TIMEOUT_MS = Number.isFinite(_whisperTimeoutRaw) && _whisperTimeoutRaw > 0
  ? _whisperTimeoutRaw
  : 30_000;

// Whisper sniffs the input format from the multipart filename's extension.
// Android can record `.aac`, `.opus`, or other containers; only this set is
// accepted by Whisper. Anything not on the list falls back to `m4a` since
// that's the iOS default and what the legacy code used to hard-code.
const WHISPER_ALLOWED_EXTS = new Set([
  "m4a",
  "mp3",
  "mp4",
  "mpeg",
  "mpga",
  "wav",
  "webm",
  "aac",
  "ogg",
  "opus",
  "flac",
]);

// Extracts the lowercased extension from a storage path. Returns the fallback
// when no recognisable trailing `.<alnum+>` is present, or when the extension
// is not in the Whisper allow-list.
function extractAudioExtension(mediaPath: string, fallback = "m4a"): string {
  const m = mediaPath.match(/\.([a-z0-9]+)$/i);
  if (!m) return fallback;
  const ext = m[1].toLowerCase();
  return WHISPER_ALLOWED_EXTS.has(ext) ? ext : fallback;
}

const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
  auth: { persistSession: false },
});

// Transient failure — revert from 'processing' back to 'pending' so a
// subsequent webhook fire (manual retry, cron, etc.) can re-claim the row.
// Used for sign / download / Whisper errors where the next attempt has a
// real chance of succeeding.
async function revertToPending(messageId: string): Promise<void> {
  const { error } = await admin
    .from("messages")
    .update({ transcript: null, transcript_status: "pending" })
    .eq("id", messageId)
    .eq("kind", "voice");
  if (error) {
    console.error({
      fn: "transcribe-voice",
      stage: "revert-to-pending",
      err: String(error.message ?? error),
    });
  }
}

// Terminal failure — mark the row as permanently un-transcribable so we
// don't loop on it. Reserved for cases where retry CANNOT succeed (oversized
// audio, etc.). Scoped to voice messages and nulls the transcript so an
// earlier attempt's stub string doesn't linger.
async function setFailed(messageId: string): Promise<void> {
  const { error } = await admin
    .from("messages")
    .update({ transcript: null, transcript_status: "failed" })
    .eq("id", messageId)
    .eq("kind", "voice");
  if (error) {
    console.error({
      fn: "transcribe-voice",
      stage: "set-failed",
      err: String(error.message ?? error),
    });
  }
}

// Exported for unit tests (see index.test.ts).
export async function handler(req: Request): Promise<Response> {
  const pre = handlePreflight(req);
  if (pre) return pre;

  if (req.method !== "POST") {
    return jsonResponse({ error: "only POST" }, 405);
  }

  if (!verifyWebhookSecret(req, WEBHOOK_SECRET)) {
    console.error({ fn: "transcribe-voice", stage: "auth", err: "bad secret" });
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  let body: { message_id?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "invalid json" }, 400);
  }
  const messageId = body.message_id;
  if (!messageId) {
    return jsonResponse({ error: "message_id required" }, 400);
  }

  // Atomic claim: flip 'pending' → 'processing' for this voice message in a
  // single UPDATE. This dedups concurrent webhook fires (only one wins the
  // row and proceeds to Whisper) and supersedes the previous read-then-act
  // status check. The filter on kind='voice' AND transcript_status='pending'
  // collapses every non-actionable case (already ready, already unsupported,
  // already processing, already failed, wrong kind, missing row) into a
  // single "0 rows affected" → return 200 skipped.
  //
  // 'pending' is set by the dispatch_transcription SQL trigger before pg_net
  // fires this webhook, so a legitimate fresh dispatch always matches.
  // Stub mode (no Whisper key) takes the same claim before writing
  // 'unsupported' as a terminal state.
  const { data: claimed, error: claimErr } = await admin
    .from("messages")
    .update({ transcript_status: "processing" })
    .eq("id", messageId)
    .eq("kind", "voice")
    .eq("transcript_status", "pending")
    .select("media_path")
    .maybeSingle();

  if (claimErr) {
    console.error({
      fn: "transcribe-voice",
      stage: "claim",
      err: String(claimErr.message ?? claimErr),
    });
    return jsonResponse({ error: "claim failed" }, 500);
  }
  if (!claimed) {
    // Already processed (ready/unsupported/failed), already in-flight
    // (processing), wrong kind, or row missing. All non-actionable.
    return jsonResponse({ ok: true, skipped: true }, 200);
  }
  if (!claimed.media_path) {
    // Voice row claimed but no media_path — terminal, can't transcribe.
    await setFailed(messageId);
    return jsonResponse({ error: "voice message missing media_path" }, 404);
  }

  // Stub mode: no Whisper key set. We already claimed the row, so just
  // flip it to the terminal 'unsupported' state with the stub transcript.
  if (!WHISPER_KEY) {
    const { error } = await admin
      .from("messages")
      .update({
        transcript:
          "[Transcript unavailable in dev — set OPENAI_API_KEY to enable Whisper ASR]",
        transcript_status: "unsupported",
      })
      .eq("id", messageId)
      .eq("kind", "voice");
    if (error) {
      console.error({
        fn: "transcribe-voice",
        stage: "stub-update",
        err: String(error.message ?? error),
      });
      // Revert so something else can pick it up — the stub flip is the
      // only "work" this branch does, so a failure here is recoverable.
      await revertToPending(messageId);
      return jsonResponse({ error: "stub update failed" }, 500);
    }
    return jsonResponse({ ok: true, stub: true }, 200);
  }

  const { data: signed, error: signedErr } = await admin.storage
    .from("chat-media")
    .createSignedUrl(claimed.media_path, SIGNED_URL_TTL_SECONDS);
  if (signedErr || !signed?.signedUrl) {
    console.error({
      fn: "transcribe-voice",
      stage: "sign",
      err: String(signedErr?.message ?? "no url"),
    });
    await revertToPending(messageId);
    return jsonResponse({ error: "signed url failed" }, 500);
  }

  // Download with a 30s ceiling.
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);

  let audioBlob: Blob;
  try {
    const audioRes = await fetch(signed.signedUrl, { signal: controller.signal });
    if (!audioRes.ok) {
      console.error({
        fn: "transcribe-voice",
        stage: "download",
        err: `status ${audioRes.status}`,
      });
      // Transient: storage hiccup, signed URL race, etc. Allow retry.
      await revertToPending(messageId);
      return jsonResponse({ error: "download failed" }, 502);
    }
    audioBlob = await audioRes.blob();
  } catch (err) {
    console.error({
      fn: "transcribe-voice",
      stage: "download",
      err: String(err),
    });
    await revertToPending(messageId);
    return jsonResponse({ error: "download failed" }, 504);
  } finally {
    clearTimeout(timer);
  }

  if (audioBlob.size > MAX_AUDIO_BYTES) {
    console.error({
      fn: "transcribe-voice",
      stage: "size-check",
      err: `audio ${audioBlob.size}B exceeds ${MAX_AUDIO_BYTES}B`,
    });
    // Permanent: the file is bigger than the Whisper hard limit. A retry
    // can never succeed for this row, so mark it 'failed' to break the loop.
    await setFailed(messageId);
    return jsonResponse({ error: "audio too large" }, 413);
  }

  // Whisper sniffs container/codec from the multipart filename extension.
  // Android records `.aac`/`.opus`; iOS records `.m4a`. Derive from the stored
  // path so the sniff matches the actual bytes — fall back to m4a otherwise.
  const audioExt = extractAudioExtension(claimed.media_path);
  const form = new FormData();
  form.append("file", audioBlob, `voice.${audioExt}`);
  form.append("model", "whisper-1");

  // Mirror the storage-download pattern: bound the Whisper call with an
  // AbortController so a hung connection doesn't pin the function for the
  // platform-default 150s. Timeout is configurable via WHISPER_TIMEOUT_MS.
  const whisperController = new AbortController();
  const whisperTimer = setTimeout(
    () => whisperController.abort(),
    WHISPER_TIMEOUT_MS,
  );

  let whisperJson: { text?: string };
  try {
    const whisper = await fetch(
      "https://api.openai.com/v1/audio/transcriptions",
      {
        method: "POST",
        headers: { Authorization: `Bearer ${WHISPER_KEY}` },
        body: form,
        signal: whisperController.signal,
      },
    );
    if (!whisper.ok) {
      console.error({
        fn: "transcribe-voice",
        stage: "whisper",
        err: `status ${whisper.status}`,
      });
      // IMPORTANT: do not write the error string into messages.transcript.
      // Transient: rate-limit, 5xx, timeout — revert to 'pending' so retry works.
      await revertToPending(messageId);
      return jsonResponse({ error: "whisper failed" }, 502);
    }
    whisperJson = await whisper.json();
  } catch (err) {
    console.error({
      fn: "transcribe-voice",
      stage: "whisper",
      err: String(err),
    });
    await revertToPending(messageId);
    return jsonResponse({ error: "whisper failed" }, 502);
  } finally {
    clearTimeout(whisperTimer);
  }

  const text = whisperJson.text ?? null;
  const { error: updErr } = await admin
    .from("messages")
    .update({ transcript: text, transcript_status: "ready" })
    .eq("id", messageId)
    .eq("kind", "voice");
  if (updErr) {
    console.error({
      fn: "transcribe-voice",
      stage: "update",
      err: String(updErr.message ?? updErr),
    });
    // Whisper already charged us but the DB write to mark 'ready' failed.
    // Revert to 'pending' so a retry can re-attempt — re-charging Whisper
    // once is better than leaving the row stuck in 'processing' forever.
    await revertToPending(messageId);
    return jsonResponse({ error: "update failed" }, 500);
  }

  return jsonResponse({ ok: true }, 200);
}

serve(handler);

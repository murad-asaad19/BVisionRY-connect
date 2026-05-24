// Generates an AI "meeting playbook" — a per-(meeting, viewer) briefing card
// shown in the mobile MeetingCard when a confirmed meeting is < 24h away.
//
// Why this is server-side:
//   * The Anthropic API key never touches the mobile client.
//   * Per-viewer cache rows in `meeting_playbooks` are written using the
//     service-role key so a misbehaving client can't poison another viewer's
//     row. The mobile client reads via the `get_meeting_playbook` RPC.
//
// Caching strategy (mirrors the README on the migration):
//   * `generation_input_hash` is sha256 of the JSON-serialized
//     `{viewer_profile, target_profile, meeting_topic}` (sorted keys). Any
//     drift in a profile field we include in the prompt invalidates the
//     cache and forces a regen.
//   * Soft 7-day TTL on `generated_at` even when the hash matches, so prompt
//     / model changes also propagate.
//   * `force: true` from the client (the "Regenerate" button) bypasses both.
//
// Privacy: ONLY the public-display profile fields ever go to Claude — id,
// email, and any sensitive auth-table data are filtered out at the source.
//
// JWT verification is ON (see supabase/config.toml). Even so we explicitly
// resolve the user from the bearer token to make the auth boundary obvious
// at the function level (and so tests can stub it).

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { handlePreflight, jsonResponse } from "../_shared/cors.ts";
import { optionalEnv, requireEnv } from "../_shared/env.ts";

const SUPABASE_URL = requireEnv("SUPABASE_URL");
const ANON_KEY = requireEnv("SUPABASE_ANON_KEY");
const SERVICE_ROLE = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
// Optional at module load so missing-key produces a 500 at request time
// rather than crashing the worker at boot. Tests rely on this too.
const ANTHROPIC_API_KEY = optionalEnv("ANTHROPIC_API_KEY");

const ANTHROPIC_MODEL = "claude-sonnet-4-6";
const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";

// Soft TTL on cached rows — past this we regenerate even if the hash matches.
const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000;

// System prompt is deterministic across calls — cached server-side by
// Anthropic when `cache_control: {type: "ephemeral"}` is set on the block.
const SYSTEM_PROMPT =
  `You are a meeting prep assistant for a professional networking app. Given two professional profiles and a meeting topic, generate a brief "playbook" that helps the FIRST PROFILE prepare to meet the SECOND PROFILE.

Respond with ONLY a JSON object with the following keys:
- "summary" (string, 2 sentences max): an at-a-glance who-they-are addressed to the viewer.
- "shared_interests" (string[], 3-5 items): concrete intersections of background/goal/role.
- "conversation_starters" (string[], 3 items): specific open-ended questions the viewer can ask.
- "do_notes" (string[], 2-3 items): brief actionable do-this-during-the-meeting tips.
- "dont_notes" (string[], 1-2 items): brief avoid-this tips.

No prose outside the JSON. No markdown fences. Plain JSON only.`;

// Public-display profile fields. These are the only fields we ever read or
// send to the LLM. id / email / suspended_at / private_mode / etc. are
// deliberately excluded.
type DisplayProfile = {
  name: string | null;
  headline: string | null;
  bio: string | null;
  roles: string[] | null;
  primary_role: string | null;
  goal_type: string | null;
  goal_text: string | null;
  city: string | null;
  country: string | null;
};

type Playbook = {
  summary: string;
  shared_interests: string[];
  conversation_starters: string[];
  do_notes: string[];
  dont_notes: string[];
};

type PlaybookBody = {
  meeting_id?: unknown;
  force?: unknown;
};

type ClaudeContentBlock = { type: string; text?: string };
type ClaudeResponse = { content?: ClaudeContentBlock[] };

const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
  auth: { persistSession: false },
});

// ----- Helpers -------------------------------------------------------------

/** Serialize an object with deterministic key ordering — for hashing only. */
function stableStringify(value: unknown): string {
  if (value === null || typeof value !== "object") return JSON.stringify(value);
  if (Array.isArray(value)) {
    return "[" + value.map((v) => stableStringify(v)).join(",") + "]";
  }
  const obj = value as Record<string, unknown>;
  const keys = Object.keys(obj).sort();
  return "{" +
    keys.map((k) => JSON.stringify(k) + ":" + stableStringify(obj[k])).join(
      ",",
    ) +
    "}";
}

async function sha256Hex(input: string): Promise<string> {
  const buf = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(input),
  );
  const bytes = new Uint8Array(buf);
  let out = "";
  for (let i = 0; i < bytes.length; i++) {
    out += bytes[i].toString(16).padStart(2, "0");
  }
  return out;
}

function pickDisplayProfile(row: Record<string, unknown>): DisplayProfile {
  return {
    name: (row.name as string | null) ?? null,
    headline: (row.headline as string | null) ?? null,
    bio: (row.bio as string | null) ?? null,
    roles: Array.isArray(row.roles)
      ? (row.roles as string[]).filter((r) => typeof r === "string")
      : null,
    primary_role: (row.primary_role as string | null) ?? null,
    goal_type: (row.goal_type as string | null) ?? null,
    goal_text: (row.goal_text as string | null) ?? null,
    city: (row.city as string | null) ?? null,
    country: (row.country as string | null) ?? null,
  };
}

function isValidPlaybook(x: unknown): x is Playbook {
  if (!x || typeof x !== "object") return false;
  const o = x as Record<string, unknown>;
  if (typeof o.summary !== "string" || o.summary.length === 0) return false;
  for (
    const key of [
      "shared_interests",
      "conversation_starters",
      "do_notes",
      "dont_notes",
    ] as const
  ) {
    const v = o[key];
    if (!Array.isArray(v)) return false;
    if (!v.every((it) => typeof it === "string" && it.length > 0)) {
      return false;
    }
  }
  return true;
}

/**
 * Pull the JSON payload out of a Claude text reply. Tolerates the model
 * wrapping the JSON in stray prose or markdown fences (system prompt asks
 * for plain JSON, but defense-in-depth).
 */
function extractJson(text: string): unknown | null {
  const trimmed = text.trim();
  // Strip leading/trailing markdown fences if present.
  const fenceMatch = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/);
  const candidate = fenceMatch ? fenceMatch[1] : trimmed;
  try {
    return JSON.parse(candidate);
  } catch {
    // Fall back: find the first `{` and last `}` and try the substring.
    const first = candidate.indexOf("{");
    const last = candidate.lastIndexOf("}");
    if (first >= 0 && last > first) {
      try {
        return JSON.parse(candidate.slice(first, last + 1));
      } catch {
        return null;
      }
    }
    return null;
  }
}

async function callClaude(
  apiKey: string,
  viewer: DisplayProfile,
  target: DisplayProfile,
  topic: string | null,
): Promise<Playbook | null> {
  const userPayload = {
    viewer_profile: viewer,
    target_profile: target,
    meeting_topic: topic,
  };

  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "x-api-key": apiKey,
      "anthropic-version": ANTHROPIC_VERSION,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: ANTHROPIC_MODEL,
      max_tokens: 800,
      temperature: 0.4,
      system: [
        {
          type: "text",
          text: SYSTEM_PROMPT,
          // Cache the static system prompt — every call has the same one,
          // so we only pay the input-token cost on cache miss.
          cache_control: { type: "ephemeral" },
        },
      ],
      messages: [
        {
          role: "user",
          content: JSON.stringify(userPayload),
        },
      ],
    }),
  });

  if (!res.ok) {
    const errBody = await res.text().catch(() => "");
    console.error({
      fn: "meeting-playbook",
      stage: "claude",
      status: res.status,
      body: errBody.slice(0, 200),
    });
    return null;
  }

  const json = (await res.json()) as ClaudeResponse;
  const block = json.content?.find((b) => b.type === "text");
  const text = block?.text;
  if (!text) return null;

  const parsed = extractJson(text);
  if (!isValidPlaybook(parsed)) return null;
  return parsed;
}

// ----- Handler -------------------------------------------------------------

// Exported for unit tests (see index.test.ts). The default `serve(handler)`
// boot path below is the only thing that runs in production.
export async function handler(req: Request): Promise<Response> {
  const t0 = Date.now();
  const pre = handlePreflight(req);
  if (pre) return pre;

  if (req.method !== "POST") {
    return jsonResponse({ error: "only POST" }, 405);
  }

  // --- JWT --------------------------------------------------------------
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }
  const jwt = authHeader.replace(/^Bearer\s+/i, "");
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser(jwt);
  if (userErr || !userData?.user?.id) {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }
  const callerId = userData.user.id;

  // --- Body parsing -----------------------------------------------------
  let body: PlaybookBody;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "invalid_body" }, 400);
  }

  const meetingId = typeof body.meeting_id === "string" ? body.meeting_id : "";
  if (!UUID_REGEX.test(meetingId)) {
    return jsonResponse({ error: "invalid_body" }, 400);
  }
  const force = body.force === true;

  // --- Load meeting + verify participation ------------------------------
  // Service-role lookup. We've already authenticated the caller via JWT —
  // the admin client is just so the data fetch isn't subject to RLS that
  // would require us to spin up a per-request user client.
  const { data: meeting, error: meetingErr } = await admin
    .from("meeting_proposals")
    .select("id, conversation_id, state, confirmed_slot")
    .eq("id", meetingId)
    .maybeSingle();

  if (meetingErr) {
    console.error({
      fn: "meeting-playbook",
      stage: "meeting-lookup",
      err: String(meetingErr.message ?? meetingErr),
    });
    return jsonResponse({ error: "server_error" }, 500);
  }
  if (!meeting) {
    // Don't leak existence vs non-existence — treat unknown meeting like
    // not-a-participant.
    return jsonResponse({ error: "forbidden" }, 403);
  }

  // Resolve participants via the conversation row.
  const { data: convo, error: convoErr } = await admin
    .from("conversations")
    .select("participant_a_id, participant_b_id")
    .eq("id", meeting.conversation_id)
    .maybeSingle();
  if (convoErr || !convo) {
    console.error({
      fn: "meeting-playbook",
      stage: "convo-lookup",
      err: convoErr ? String(convoErr.message ?? convoErr) : "missing",
    });
    return jsonResponse({ error: "forbidden" }, 403);
  }

  const participantA = convo.participant_a_id as string;
  const participantB = convo.participant_b_id as string;
  if (callerId !== participantA && callerId !== participantB) {
    return jsonResponse({ error: "forbidden" }, 403);
  }
  const targetId = callerId === participantA ? participantB : participantA;

  // --- Load both profiles (display fields only) -------------------------
  const { data: profiles, error: profilesErr } = await admin
    .from("profiles")
    .select(
      "id, name, headline, bio, roles, primary_role, goal_type, goal_text, city, country",
    )
    .in("id", [callerId, targetId]);

  if (profilesErr || !profiles || profiles.length < 2) {
    console.error({
      fn: "meeting-playbook",
      stage: "profile-lookup",
      err: profilesErr ? String(profilesErr.message ?? profilesErr) : "missing",
    });
    return jsonResponse({ error: "server_error" }, 500);
  }

  const viewerRow = profiles.find((p) => p.id === callerId);
  const targetRow = profiles.find((p) => p.id === targetId);
  if (!viewerRow || !targetRow) {
    return jsonResponse({ error: "server_error" }, 500);
  }
  const viewerProfile = pickDisplayProfile(viewerRow);
  const targetProfile = pickDisplayProfile(targetRow);

  // --- Topic resolution -------------------------------------------------
  // For office-hours-spawned meetings the topic lives on
  // office_hours_slots.topic. For regular proposals there is no topic — we
  // treat that as `null` (the LLM is told it's optional context).
  let topic: string | null = null;
  const { data: slot } = await admin
    .from("office_hours_slots")
    .select("topic")
    .eq("meeting_proposal_id", meetingId)
    .maybeSingle();
  if (slot && typeof (slot as { topic?: unknown }).topic === "string") {
    topic = (slot as { topic: string }).topic;
  }

  // --- Cache lookup -----------------------------------------------------
  const inputHash = await sha256Hex(stableStringify({
    viewer_profile: viewerProfile,
    target_profile: targetProfile,
    meeting_topic: topic,
  }));

  const { data: existing } = await admin
    .from("meeting_playbooks")
    .select(
      "summary, shared_interests, conversation_starters, do_notes, dont_notes, generated_at, generation_input_hash",
    )
    .eq("meeting_id", meetingId)
    .eq("viewer_id", callerId)
    .maybeSingle();

  if (
    !force && existing &&
    existing.generation_input_hash === inputHash &&
    Date.now() - new Date(existing.generated_at as string).getTime() <
      CACHE_TTL_MS
  ) {
    console.log({
      fn: "meeting-playbook",
      meeting_id: meetingId,
      viewer_id: callerId,
      cache_hit: true,
      ms: Date.now() - t0,
    });
    return jsonResponse({
      summary: existing.summary,
      shared_interests: existing.shared_interests,
      conversation_starters: existing.conversation_starters,
      do_notes: existing.do_notes,
      dont_notes: existing.dont_notes,
      generated_at: existing.generated_at,
    }, 200);
  }

  // --- Generate ---------------------------------------------------------
  if (!ANTHROPIC_API_KEY) {
    console.error({
      fn: "meeting-playbook",
      stage: "boot",
      err: "ANTHROPIC_API_KEY missing",
    });
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  const playbook = await callClaude(
    ANTHROPIC_API_KEY,
    viewerProfile,
    targetProfile,
    topic,
  );

  if (!playbook) {
    // Generation failed (network / model returned garbage). Do NOT write a
    // bad row to the cache table — leave any prior row alone so the next
    // attempt can either reuse it or try again.
    console.error({
      fn: "meeting-playbook",
      meeting_id: meetingId,
      viewer_id: callerId,
      stage: "generation",
      err: "invalid_or_missing",
      ms: Date.now() - t0,
    });
    return jsonResponse({ error: "generation_failed" }, 502);
  }

  const nowIso = new Date().toISOString();
  const { error: upsertErr } = await admin
    .from("meeting_playbooks")
    .upsert({
      meeting_id: meetingId,
      viewer_id: callerId,
      target_id: targetId,
      summary: playbook.summary,
      shared_interests: playbook.shared_interests,
      conversation_starters: playbook.conversation_starters,
      do_notes: playbook.do_notes,
      dont_notes: playbook.dont_notes,
      generated_at: nowIso,
      generation_input_hash: inputHash,
    }, { onConflict: "meeting_id,viewer_id" });

  if (upsertErr) {
    console.error({
      fn: "meeting-playbook",
      stage: "upsert",
      err: String(upsertErr.message ?? upsertErr),
    });
    return jsonResponse({ error: "server_error" }, 500);
  }

  console.log({
    fn: "meeting-playbook",
    meeting_id: meetingId,
    viewer_id: callerId,
    cache_hit: false,
    ms: Date.now() - t0,
  });

  return jsonResponse({
    summary: playbook.summary,
    shared_interests: playbook.shared_interests,
    conversation_starters: playbook.conversation_starters,
    do_notes: playbook.do_notes,
    dont_notes: playbook.dont_notes,
    generated_at: nowIso,
  }, 200);
}

serve(handler);

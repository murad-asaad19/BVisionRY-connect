// Infers a `goal_type` enum value from the user's free-form goal description.
//
// Called from GoalStep.tsx as the user types (debounced 800ms, ≥20 chars).
// Replaces the keyword-heuristic that used to live in the mobile app — the
// LLM handles negation ("looking to invest" vs "raising investment"),
// multi-lingual phrasing, and synonyms without us maintaining a regex zoo.
//
// JWT verification is ON (see supabase/config.toml). The function never sees
// the user's text in logs — only `{ inferred, ms }`.

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { handlePreflight, jsonResponse } from "../_shared/cors.ts";
import { optionalEnv, requireEnv } from "../_shared/env.ts";

const SUPABASE_URL = requireEnv("SUPABASE_URL");
const ANON_KEY = requireEnv("SUPABASE_ANON_KEY");
// Optional at module load so missing-key produces a 500 at request time rather
// than crashing the worker at boot. Tests rely on this being optional too.
const ANTHROPIC_API_KEY = optionalEnv("ANTHROPIC_API_KEY");

// Mirror of the goal_type enum (see slice2 migration). Keep in sync.
const GOAL_TYPES = [
  "hire",
  "be_hired",
  "co_found",
  "invest",
  "take_investment",
  "advise",
  "find_advisor",
  "peer_connect",
] as const;
type GoalType = typeof GOAL_TYPES[number];
const GOAL_TYPE_SET = new Set<string>(GOAL_TYPES);

const MIN_LEN = 20;
const MAX_LEN = 280;

const ANTHROPIC_MODEL = "claude-sonnet-4-6";
const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";

// System prompt is deterministic across calls — cached server-side by
// Anthropic when `cache_control: {type: "ephemeral"}` is set on the block.
// Keeps cost ~flat regardless of how many keystrokes the user makes.
const SYSTEM_PROMPT =
  `You classify a single user-supplied "goal description" into exactly one of these networking goal types:

- hire: speaker wants to hire someone (employer side)
- be_hired: speaker is looking for work / a job / a role
- co_found: speaker wants to find a co-founder for a venture
- invest: speaker invests money in other people's ventures
- take_investment: speaker is raising money for their own venture
- advise: speaker wants to advise / mentor others
- find_advisor: speaker is looking for an advisor / mentor for themselves
- peer_connect: speaker wants peer connections without any of the above intents

Rules:
- Output exactly ONE token: the enum value (lowercase, snake_case), or the literal "none" if no category fits with reasonable confidence.
- No explanation, no punctuation, no quotes, no markdown.
- Speaker perspective matters: "looking to invest in startups raising pre-seed" is invest (not take_investment).
- "find an advisor who can advise me" is find_advisor (not advise).
- If the speaker mentions multiple intents, pick the dominant one. If genuinely ambiguous, output none.`;

type InferBody = {
  text?: unknown;
  primary_role?: unknown;
  roles?: unknown;
};

type ClaudeContentBlock = { type: string; text?: string };
type ClaudeResponse = { content?: ClaudeContentBlock[] };

function buildUserMessage(
  text: string,
  primaryRole: string | null,
  roles: string[],
): string {
  const ctx: string[] = [];
  if (primaryRole) ctx.push(`Primary role: ${primaryRole}`);
  if (roles.length > 0) ctx.push(`All roles: ${roles.join(", ")}`);
  const contextLine = ctx.length > 0 ? `${ctx.join(". ")}.\n\n` : "";
  return `${contextLine}Goal description:\n"""\n${text}\n"""\n\nClassify:`;
}

async function callClaude(
  apiKey: string,
  text: string,
  primaryRole: string | null,
  roles: string[],
): Promise<string | null> {
  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "x-api-key": apiKey,
      "anthropic-version": ANTHROPIC_VERSION,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: ANTHROPIC_MODEL,
      max_tokens: 16,
      temperature: 0,
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
          content: buildUserMessage(text, primaryRole, roles),
        },
      ],
    }),
  });

  if (!res.ok) {
    // Body may be useful for debugging but never log the user's text.
    const errBody = await res.text().catch(() => "");
    console.error({
      fn: "infer-goal-type",
      stage: "claude",
      status: res.status,
      body: errBody.slice(0, 200),
    });
    return null;
  }

  const json = (await res.json()) as ClaudeResponse;
  const block = json.content?.find((b) => b.type === "text");
  return block?.text ?? null;
}

function normalizeRoles(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw.filter((r): r is string => typeof r === "string" && r.length > 0);
}

// Exported for unit tests (see index.test.ts). The default `serve(handler)`
// boot path below is the only thing that runs in production.
export async function handler(req: Request): Promise<Response> {
  const t0 = Date.now();
  const pre = handlePreflight(req);
  if (pre) return pre;

  if (req.method !== "POST") {
    return jsonResponse({ error: "only POST" }, 405);
  }

  // JWT verification — even though Supabase Gateway already enforces
  // verify_jwt=true, we resolve the user too to confirm the token is valid
  // and to make the auth boundary explicit at the function level.
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

  let body: InferBody;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "invalid_body" }, 400);
  }

  const text = typeof body.text === "string" ? body.text.trim() : "";
  if (text.length < MIN_LEN || text.length > MAX_LEN) {
    return jsonResponse({ error: "invalid_body" }, 400);
  }
  const primaryRole = typeof body.primary_role === "string"
    ? body.primary_role
    : null;
  const roles = normalizeRoles(body.roles);

  if (!ANTHROPIC_API_KEY) {
    console.error({
      fn: "infer-goal-type",
      stage: "boot",
      err: "ANTHROPIC_API_KEY missing",
    });
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  const raw = await callClaude(ANTHROPIC_API_KEY, text, primaryRole, roles);
  const normalized = (raw ?? "").trim().toLowerCase();

  let goalType: GoalType | null = null;
  let confidence: "high" | "low" = "low";
  if (GOAL_TYPE_SET.has(normalized)) {
    goalType = normalized as GoalType;
    confidence = "high";
  }
  // Everything else — "none", garbage, network failure — collapses to
  // { goal_type: null, confidence: "low" }. The client surfaces a quiet
  // caption and the user picks manually.

  console.log({
    fn: "infer-goal-type",
    inferred: goalType,
    ms: Date.now() - t0,
  });

  return jsonResponse({ goal_type: goalType, confidence }, 200);
}

serve(handler);

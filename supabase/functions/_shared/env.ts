// Env-var helpers shared across edge functions.

export function requireEnv(name: string): string {
  const v = Deno.env.get(name);
  if (!v || v.length === 0) {
    throw new Error(`${name} required`);
  }
  return v;
}

export function optionalEnv(name: string): string | undefined {
  const v = Deno.env.get(name);
  return v && v.length > 0 ? v : undefined;
}

// Constant-time string compare to discourage timing attacks on the shared secret.
export function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return mismatch === 0;
}

export function verifyWebhookSecret(req: Request, expected: string): boolean {
  const got = req.headers.get("X-Supabase-Webhook-Secret");
  if (!got) return false;
  return safeEqual(got, expected);
}

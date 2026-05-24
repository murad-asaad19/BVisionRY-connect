// CORS helpers shared across edge functions.

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-supabase-webhook-secret",
  "Access-Control-Max-Age": "3600",
};

export function handlePreflight(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  return null;
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function textResponse(body: string, status = 200): Response {
  return new Response(body, { status, headers: corsHeaders });
}

// -----------------------------------------------------------------------------
// Restricted CORS — for credentialed endpoints (e.g. delete-account) where a
// wildcard origin is unsafe. Echoes back the request's Origin when it is on the
// allow-list; otherwise omits Allow-Origin entirely (browsers will then refuse
// the response, which is the desired behaviour for a disallowed origin).
//
// Pass the full list of allowed origins (exact match, scheme included). Custom
// app schemes such as `connect-mobile://` are accepted as-is — the Origin
// header on requests from a custom-scheme WebView/Expo runtime is typically
// `null` or the scheme itself, so callers should include both forms as needed.
// -----------------------------------------------------------------------------

export function restrictedCorsHeaders(
  req: Request,
  allowedOrigins: readonly string[],
): Record<string, string> {
  const origin = req.headers.get("Origin");
  const headers: Record<string, string> = {
    "Vary": "Origin",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type, x-supabase-webhook-secret",
    "Access-Control-Allow-Credentials": "true",
    "Access-Control-Max-Age": "3600",
  };
  if (origin && allowedOrigins.includes(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
  }
  return headers;
}

export function handlePreflightRestricted(
  req: Request,
  allowedOrigins: readonly string[],
): Response | null {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: restrictedCorsHeaders(req, allowedOrigins),
    });
  }
  return null;
}

export function jsonResponseRestricted(
  req: Request,
  allowedOrigins: readonly string[],
  body: unknown,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...restrictedCorsHeaders(req, allowedOrigins),
      "Content-Type": "application/json",
    },
  });
}

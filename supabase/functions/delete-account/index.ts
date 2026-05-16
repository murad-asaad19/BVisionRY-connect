import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  if (req.method !== "POST") return new Response("only POST", { status: 405 });

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return new Response("unauthorized", { status: 401 });
  const jwt = authHeader.replace(/^Bearer\s+/i, "");

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "http://kong:8000";
  const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  const anon = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userErr } = await anon.auth.getUser(jwt);
  if (userErr || !userData?.user?.id) return new Response("unauthorized", { status: 401 });

  const admin = createClient(supabaseUrl, serviceRole, {
    auth: { persistSession: false },
  });

  // Delete auth.users (this cascades to profiles via the FK on profiles.id)
  const { error: delErr } = await admin.auth.admin.deleteUser(userData.user.id);
  if (delErr) {
    return new Response(JSON.stringify({ error: delErr.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response("ok", { status: 200 });
});

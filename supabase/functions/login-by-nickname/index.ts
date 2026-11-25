import { createClient } from "npm:@supabase/supabase-js@2.118.0";
import { admin, digest, json, limited, preflight } from "../_shared/backend.ts";

Deno.serve(async (req) => {
  const early = preflight(req);
  if (early) return early;
  try {
    const body = await req.json();
    const nickname = String(body.login_identifier ?? "").trim().toLowerCase();
    const password = String(body.password ?? "");
    if (!/^[a-z0-9_]{3,20}$/.test(nickname) || !password || password.length > 256) {
      return json({ error: "Invalid login credentials" }, 401);
    }
    const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
    const allowed = await limited(`login-ip:${await digest(ip)}`, 20, 300);
    const accountAllowed = await limited(`login-name:${await digest(nickname)}`, 10, 300);
    if (!allowed || !accountAllowed) return json({ error: "Too many requests" }, 429);
    const { data: profile } = await admin.from("profiles").select("id").eq("username", nickname).maybeSingle();
    const user = profile ? (await admin.auth.admin.getUserById(profile.id)).data.user : null;
    // Email is resolved only inside the server; there is no public email lookup.
    if (!user?.email) return json({ error: "Invalid login credentials" }, 401);
    const client = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await client.auth.signInWithPassword({ email: user.email, password });
    if (error || !data.session) return json({ error: "Invalid login credentials" }, 401);
    return json({ session: { refresh_token: data.session.refresh_token } });
  } catch {
    return json({ error: "Invalid request" }, 400);
  }
});

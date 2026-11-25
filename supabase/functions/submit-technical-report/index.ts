import { admin, authenticated, json, limited, preflight } from "../_shared/backend.ts";

// Reports are stored in DashCore. No external email service is required.
Deno.serve(async (req) => {
  const early = preflight(req);
  if (early) return early;
  const user = await authenticated(req);
  if (!user) return json({ error: "Unauthorized" }, 401);
  if (!await limited(`report:${user.id}`, 5, 3600)) return json({ error: "Too many requests" }, 429);
  try {
    const payload = await req.json();
    const subject = String(payload.subject ?? "").trim();
    const message = String(payload.message ?? "").trim();
    if (!subject || subject.length > 200 || !message || message.length > 10000) {
      return json({ error: "Invalid report" }, 400);
    }
    const { data, error } = await admin.from("technical_reports").insert({
      user_id: user.id,
      reporter_name: String(payload.reporter_name ?? payload.reporterName ?? "").slice(0, 120),
      reporter_email: user.email,
      subject, message, email_status: "disabled",
    }).select("id").single();
    if (error) return json({ error: "Could not save report" }, 500);
    return json({ ok: true, report_id: data.id, email_status: "disabled" });
  } catch {
    return json({ error: "Invalid request" }, 400);
  }
});

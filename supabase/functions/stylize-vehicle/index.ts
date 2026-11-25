import { admin, authenticated, json, limited, preflight } from "../_shared/backend.ts";

// Open-source image service owned by DashCore. No paid image API or embedded key.
Deno.serve(async (req) => {
  const early = preflight(req);
  if (early) return early;
  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }
  const endpoint = Deno.env.get("VEHICLE_AI_URL");
  const token = Deno.env.get("VEHICLE_AI_TOKEN");
  if (body.action === "status") return json({ available: Boolean(endpoint && token), mode: "local-angle-cutout" });
  const user = await authenticated(req);
  if (!user) return json({ error: "Unauthorized" }, 401);
  if (!endpoint || !token) return json({ error: "El servicio de IA libre aún no está conectado." }, 503);
  const url = new URL(endpoint);
  if (url.protocol !== "https:") return json({ error: "Invalid server configuration" }, 503);
  try {
    const id = body.vehicle_id;
    if (body.consent !== true || typeof id !== "string" || !/^custom_[a-zA-Z0-9_]{1,64}$/.test(id)) return json({ error: "Invalid request" }, 400);
    const { data: vehicle } = await admin.from("user_vehicles").select("id,photo_path").eq("user_id", user.id).eq("id", id).maybeSingle();
    const sourcePath = `${user.id}/${id}/source.png`;
    if (!vehicle || vehicle.photo_path !== sourcePath) return json({ error: "Vehicle photo not found" }, 404);
    if (!await limited(`vehicle-art:${user.id}`, 5, 3600)) return json({ error: "Inténtalo más tarde." }, 429);
    const { data: photo, error } = await admin.storage.from("user-vehicles").download(sourcePath);
    if (error || !photo || photo.size > 10 * 1024 * 1024) return json({ error: "Invalid photo" }, 400);
    // The destination is owner-configured, never supplied by the client.
    const response = await fetch(url, { method: "POST", redirect: "error",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "image/png" },
      body: photo, signal: AbortSignal.timeout(115000),
    });
    if (!response.ok || !response.headers.get("content-type")?.startsWith("image/png")) return json({ error: "La IA no está disponible. Tu foto local sigue guardada." }, 502);
    const reader = response.body!.getReader();
    const chunks: Uint8Array[] = [];
    let length = 0;
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.length;
      if (length > 10 * 1024 * 1024) { await reader.cancel(); return json({ error: "Image too large" }, 502); }
      chunks.push(value);
    }
    const bytes = new Uint8Array(length);
    let offset = 0;
    for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
    if (bytes[0] !== 137 || bytes[1] !== 80 || bytes[2] !== 78 || bytes[3] !== 71) return json({ error: "Invalid image" }, 502);
    const artworkPath = `${user.id}/${id}/artwork.png`;
    const uploaded = await admin.storage.from("user-vehicles").upload(artworkPath, bytes, { upsert: true, contentType: "image/png" });
    if (uploaded.error) return json({ error: "Could not save artwork" }, 500);
    const updated = await admin.from("user_vehicles").update({ artwork_path: artworkPath, updated_at: new Date().toISOString() }).eq("user_id", user.id).eq("id", id);
    if (updated.error) return json({ error: "Could not update vehicle" }, 500);
    return json({ ok: true, artwork_path: artworkPath });
  } catch { return json({ error: "La IA no terminó. Tu foto local sigue disponible." }, 502); }
});

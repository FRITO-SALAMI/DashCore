import { admin, authenticated, json, preflight } from "../_shared/backend.ts";

Deno.serve(async (req) => {
  const early = preflight(req);
  if (early) return early;
  const user = await authenticated(req);
  if (!user) return json({ error: "Unauthorized" }, 401);
  // Only these private user prefixes are eligible. Shared buckets are excluded.
  async function removeOwnedPrefix(bucket: string, prefix: string, depth = 0): Promise<boolean> {
    if (!prefix.startsWith(`${user!.id}/`) && prefix !== user!.id) return false;
    if (depth > 5) return false;
    for (let page = 0; page < 100; page++) {
      const { data: objects, error } = await admin.storage.from(bucket).list(prefix, { limit: 100 });
      if (error) return false;
      if (!objects?.length) return true;
      const files: string[] = [];
      for (const object of objects) {
        if (!object.id) {
          if (!await removeOwnedPrefix(bucket, `${prefix}/${object.name}`, depth + 1)) return false;
        } else files.push(`${prefix}/${object.name}`);
      }
      if (files.length && (await admin.storage.from(bucket).remove(files)).error) return false;
    }
    return false;
  }
  for (const bucket of ["avatars", "user-vehicles"]) {
    if (!await removeOwnedPrefix(bucket, user.id)) return json({ error: "Could not remove owned files" }, 500);
  }
  const token = req.headers.get("authorization")!.replace(/^Bearer /i, "");
  const { error: signOutError } = await admin.auth.admin.signOut(token, "global");
  if (signOutError) return json({ error: "Could not revoke sessions" }, 500);
  const { error } = await admin.auth.admin.deleteUser(user.id);
  if (error) return json({ error: "Could not delete account" }, 500);
  return json({ ok: true });
});

// delete-account
// GDPR / App Store Guideline 5.1.1(v) — authenticated member deletes their account.
// Purges DMs they participate in, then deletes auth.users (profiles cascade).
//
// Deploy: supabase functions deploy delete-account
// Env: SUPABASE_URL, SUPABASE_ANON_KEY|SUPABASE_PUBLISHABLE_KEY,
//      SUPABASE_SERVICE_ROLE_KEY|SUPABASE_SECRET_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    if (!authHeader.startsWith("Bearer ")) {
      return json({ error: "unauthorized" }, 401);
    }

    const url = Deno.env.get("SUPABASE_URL")!;
    const anon =
      Deno.env.get("SUPABASE_ANON_KEY") ??
      Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
      "";
    const service =
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
      Deno.env.get("SUPABASE_SECRET_KEY") ??
      "";

    if (!url || !anon || !service) {
      return json({ error: "server misconfigured" }, 500);
    }

    const userClient = createClient(url, anon, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userError } = await userClient.auth.getUser();
    const userId = userData.user?.id;
    if (userError || !userId) {
      return json({ error: "unauthorized" }, 401);
    }

    const admin = createClient(url, service);

    // Explicit DM purge (both directions) before auth delete — belt + suspenders
    // even when ON DELETE CASCADE covers profiles → messages.
    await admin
      .from("messages")
      .delete()
      .or(`sender_id.eq.${userId},recipient_id.eq.${userId}`);

    // Blocks / reports as actor (owned rows cascade with profile, but clear promptly)
    await admin.from("blocks").delete().eq("blocker_id", userId);
    await admin.from("reports").delete().eq("reporter_id", userId);

    const { error } = await admin.auth.admin.deleteUser(userId);
    if (error) throw error;

    return json({ deleted: true, userId });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

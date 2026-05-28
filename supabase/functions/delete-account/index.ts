// GDPR right-to-erasure (Art. 17). The client can delete its own table rows but
// cannot remove the auth.users record — that needs the service role. This function
// authenticates the caller by their JWT, then service-role deletes ALL their data
// including the auth.users row. Deploy WITH jwt verification (the caller is the
// signed-in user, including anonymous/guest sessions).
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  if (!token) return new Response("Unauthorized", { status: 401 });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );

  // Identify the caller from their access token.
  const { data: { user }, error: authError } = await admin.auth.getUser(token);
  if (authError || !user) return new Response("Unauthorized", { status: 401 });
  const uid = user.id;

  // Delete the user's data (service role bypasses RLS), children before parents.
  for (const table of ["notifications", "email_parse_queue", "cancellation_attempts", "user_subscriptions"]) {
    const { error } = await admin.from(table).delete().eq("user_id", uid);
    if (error) {
      return new Response(JSON.stringify({ error: `Failed clearing ${table}: ${error.message}` }), {
        status: 500, headers: { "content-type": "application/json" },
      });
    }
  }
  const { error: profileError } = await admin.from("profiles").delete().eq("id", uid);
  if (profileError) {
    return new Response(JSON.stringify({ error: `Failed clearing profiles: ${profileError.message}` }), {
      status: 500, headers: { "content-type": "application/json" },
    });
  }

  // Hard-delete the auth.users record — completes GDPR erasure.
  const { error: deleteError } = await admin.auth.admin.deleteUser(uid);
  if (deleteError) {
    return new Response(JSON.stringify({ error: deleteError.message }), {
      status: 500, headers: { "content-type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ deleted: true }), {
    headers: { "content-type": "application/json" },
  });
});

// send-push — deliver an APNs push to all of a user's registered devices.
//
// Intended to be called SERVER-SIDE only (from pg_cron, the parse-email function,
// or the Supabase dashboard) — never directly by the app. Authenticate the call
// with the internal shared secret in the `x-push-secret` header.
//
// Deploy WITHOUT jwt verification (it's an internal service):
//   supabase functions deploy send-push --no-verify-jwt
//
// Required secrets (supabase secrets set ...):
//   PUSH_INTERNAL_SECRET   — shared secret the caller must present
//   APNS_KEY_ID            — 10-char Key ID of the APNs auth key (.p8)
//   APNS_TEAM_ID           — 10-char Apple Team ID (52N9GMM7Q6)
//   APNS_PRIVATE_KEY       — contents of the .p8 (PEM, incl. BEGIN/END lines)
//   APNS_TOPIC             — app bundle id (com.vincli.easycancel)
//   APNS_HOST              — api.push.apple.com (prod) | api.sandbox.push.apple.com (dev)
// Plus the auto-injected SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY.
//
// ⚠️ UNTESTED in this repo: there's no APNs key available here and `deno` isn't
// installed locally. The APNs token-auth flow below follows Apple's spec but
// must be verified against a real key before relying on it in production.
import { createClient } from "jsr:@supabase/supabase-js@2";

interface PushPayload {
  user_id: string;
  title: string;
  body: string;
  // Optional custom data merged into the APNs payload.
  data?: Record<string, unknown>;
}

// --- APNs auth-token (ES256 JWT) -------------------------------------------

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN [^-]+-----/g, "")
    .replace(/-----END [^-]+-----/g, "")
    .replace(/\s+/g, "");
  const raw = atob(b64);
  const buf = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) buf[i] = raw.charCodeAt(i);
  return buf.buffer;
}

function base64url(bytes: Uint8Array): string {
  let str = btoa(String.fromCharCode(...bytes));
  return str.replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function base64urlJSON(obj: unknown): string {
  return base64url(new TextEncoder().encode(JSON.stringify(obj)));
}

let cachedToken: { jwt: string; issuedAt: number } | null = null;

async function apnsAuthToken(): Promise<string> {
  // APNs accepts a provider token for up to 60 min; refresh every ~50 min.
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && now - cachedToken.issuedAt < 3000) return cachedToken.jwt;

  const keyId = Deno.env.get("APNS_KEY_ID")!;
  const teamId = Deno.env.get("APNS_TEAM_ID")!;
  const pem = Deno.env.get("APNS_PRIVATE_KEY")!;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(pem),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );

  const header = { alg: "ES256", kid: keyId };
  const claims = { iss: teamId, iat: now };
  const signingInput = `${base64urlJSON(header)}.${base64urlJSON(claims)}`;

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput),
  );
  const jwt = `${signingInput}.${base64url(new Uint8Array(signature))}`;
  cachedToken = { jwt, issuedAt: now };
  return jwt;
}

// --- handler ----------------------------------------------------------------

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  // Internal auth: caller must present the shared secret.
  const secret = Deno.env.get("PUSH_INTERNAL_SECRET");
  if (!secret || req.headers.get("x-push-secret") !== secret) {
    return new Response("Unauthorized", { status: 401 });
  }

  let payload: PushPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response("Bad request", { status: 400 });
  }
  if (!payload.user_id || !payload.title || !payload.body) {
    return new Response("Missing user_id/title/body", { status: 400 });
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );

  const { data: rows, error } = await admin
    .from("device_tokens")
    .select("token")
    .eq("user_id", payload.user_id)
    .eq("platform", "ios");
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { "content-type": "application/json" },
    });
  }
  const tokens: string[] = (rows ?? []).map((r: { token: string }) => r.token);
  if (tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0, reason: "no tokens" }), {
      headers: { "content-type": "application/json" },
    });
  }

  const authToken = await apnsAuthToken();
  const host = Deno.env.get("APNS_HOST") ?? "api.push.apple.com";
  const topic = Deno.env.get("APNS_TOPIC")!;
  const apsBody = JSON.stringify({
    aps: { alert: { title: payload.title, body: payload.body }, sound: "default" },
    ...(payload.data ?? {}),
  });

  const results = await Promise.all(tokens.map(async (token) => {
    const res = await fetch(`https://${host}/3/device/${token}`, {
      method: "POST",
      headers: {
        "authorization": `bearer ${authToken}`,
        "apns-topic": topic,
        "apns-push-type": "alert",
        "content-type": "application/json",
      },
      body: apsBody,
    });
    // 410 = token no longer valid → prune it.
    if (res.status === 410) {
      await admin.from("device_tokens").delete().eq("token", token);
    }
    return { token: token.slice(0, 8), status: res.status };
  }));

  const sent = results.filter((r) => r.status === 200).length;
  return new Response(JSON.stringify({ sent, results }), {
    headers: { "content-type": "application/json" },
  });
});

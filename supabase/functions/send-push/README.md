# send-push edge function

Delivers an APNs push to all of a user's registered devices. **Internal use
only** — called by `pg_cron`, the `parse-email` function, or the dashboard,
never by the app directly.

> ⚠️ **Not yet deployed and not testable in this repo.** There's no APNs key
> here and `deno` isn't installed locally. The token-auth flow follows Apple's
> spec but verify it against a real key before relying on it.

## One-time setup (you, in the Apple Developer portal + Supabase)

1. **App ID → Push Notifications:** enable the *Push Notifications* capability
   for `com.vincli.easycancel`.
2. **APNs auth key:** Certificates, IDs & Profiles → Keys → create a key with
   *Apple Push Notifications service (APNs)* enabled. Download the `.p8`
   (one-time download) and note the **Key ID**.
3. **Apply migration `0004_device_tokens.sql`** to the live project (creates the
   `device_tokens` table the app writes to and this function reads).
4. **Set the secrets:**
   ```bash
   supabase secrets set \
     PUSH_INTERNAL_SECRET="$(openssl rand -hex 32)" \
     APNS_KEY_ID=XXXXXXXXXX \
     APNS_TEAM_ID=52N9GMM7Q6 \
     APNS_TOPIC=com.vincli.easycancel \
     APNS_HOST=api.push.apple.com \
     APNS_PRIVATE_KEY="$(cat AuthKey_XXXXXXXXXX.p8)"
   ```
   Use `api.sandbox.push.apple.com` for development/TestFlight-debug builds.
5. **Deploy:**
   ```bash
   supabase functions deploy send-push --no-verify-jwt
   ```

## Invoke (server-side)

```bash
curl -X POST "$SUPABASE_URL/functions/v1/send-push" \
  -H "x-push-secret: $PUSH_INTERNAL_SECRET" \
  -H "content-type: application/json" \
  -d '{"user_id":"<uuid>","title":"Cancel window closing","body":"Netflix ends in 2 days."}'
```

The client side (`PushService` + `PushAppDelegate`) already registers the device
and upserts its token into `device_tokens`, so once the steps above are done,
this function has tokens to send to.

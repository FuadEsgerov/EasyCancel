# parse-email

Inbound email → subscription. Receives a forwarded confirmation email via Resend
inbound, parses merchant/amount/currency/frequency/dates (heuristics + Mistral
fallback), and inserts a row into `user_subscriptions` (`source = 'email_forward'`).

The Swift `EmailParser` (`Sources/Services/EmailParser.swift`) mirrors these
heuristics for the in-app paste-to-autofill path; keep the two in sync.

## What I (Claude) can't do for you

Everything below needs your dashboard / CLI access and live secrets, so it's on you:

### 1. Set secrets

```bash
supabase secrets set \
  SUPABASE_URL="https://jinzwwsbuwvemwmcqfqw.supabase.co" \
  SUPABASE_SERVICE_ROLE_KEY="<service-role-key>" \
  MISTRAL_API_KEY="<mistral-key>" \
  RESEND_WEBHOOK_SECRET="<svix-signing-secret-from-resend>"
```

- `SUPABASE_SERVICE_ROLE_KEY` — Project Settings → API. **Server-only.** Never ship it in the app.
- `MISTRAL_API_KEY` — optional; without it, low-confidence emails are queued as `failed` instead of LLM-parsed.
- `RESEND_WEBHOOK_SECRET` — optional but recommended; without it signature checks are skipped (dev only).

### 2. Deploy

```bash
supabase functions deploy parse-email --no-verify-jwt
```

`--no-verify-jwt`: the caller is Resend's webhook, not a logged-in user — auth is
the Svix signature instead.

### 3. Wire up Resend inbound

1. Add and verify the domain `inbox.easycancel.app` for **inbound** in Resend (MX records).
2. Add an inbound webhook → the function URL:
   `https://jinzwwsbuwvemwmcqfqw.supabase.co/functions/v1/parse-email`
3. Copy Resend's signing secret into `RESEND_WEBHOOK_SECRET` (step 1).

## How users address it

Each profile has `forwarding_address_local` (set by the `handle_new_user` trigger).
The full address is `{forwarding_address_local}@inbox.easycancel.app`, shown in the
app's "Forward an email" screen.

## Local check

```bash
deno check index.ts
supabase functions serve parse-email --no-verify-jwt   # then POST a sample payload
```

Sample payload (Resend inbound shape):

```json
{ "type": "inbound.email.received",
  "data": { "from": "Netflix <info@netflix.com>", "to": ["jane-1a2b@inbox.easycancel.app"],
            "subject": "Your Netflix membership", "text": "Your plan is €15,99/month starting 2026-05-20." } }
```

## Notes

- Raw email isn't persisted yet (`raw_email_path = "inline"`). Spec F3.6 wants raw
  storage with a 7-day TTL — add Storage upload + the existing `cleanup_old_emails`
  cron when you enable that.
- Insert threshold 0.5, review threshold 0.7 — matches `ParsedSubscription.reviewThreshold`.

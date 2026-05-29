// parse-email — inbound subscription-confirmation email parser (spec §10.1).
//
// Trigger: webhook from Resend inbound on `inbox.vincli.com`.
// Flow: verify signature → find user by forwarding handle → heuristic parse →
// Mistral fallback (confidence < 0.7) → insert subscription → log queue row.
//
// Deploy:  supabase functions deploy parse-email --no-verify-jwt
// Secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, MISTRAL_API_KEY,
//          RESEND_WEBHOOK_SECRET   (see README.md)

import { createClient } from "npm:@supabase/supabase-js@2";
import { Webhook } from "npm:svix@1";

// Must match `AuthStore.forwardingDomain` in the iOS app.
const FORWARDING_DOMAIN = "inbox.vincli.com";
const REVIEW_THRESHOLD = 0.7;
const INSERT_THRESHOLD = 0.5;

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const raw = await req.text();
  if (!verifySignature(req, raw)) return new Response("Invalid signature", { status: 401 });

  let payload: InboundEmail;
  try {
    payload = extractEmail(JSON.parse(raw));
  } catch {
    return new Response("Bad payload", { status: 400 });
  }

  const handle = recipientHandle(payload.to);
  if (!handle) return ok("no matching recipient");

  const { data: profile } = await supabase
    .from("profiles")
    .select("id")
    .eq("forwarding_address_local", handle)
    .maybeSingle();
  if (!profile) return ok("unknown forwarding handle");

  // Log the attempt up front so we always have a queue record.
  const { data: queued } = await supabase
    .from("email_parse_queue")
    .insert({ user_id: profile.id, raw_email_path: "inline", status: "processing" })
    .select("id")
    .single();
  const queueId = queued?.id as string | undefined;

  // 1) Heuristics, 2) Mistral fallback when unsure.
  let parsed = parseEmail(payload.subject, payload.text, payload.from);
  if (parsed.confidence < REVIEW_THRESHOLD && Deno.env.get("MISTRAL_API_KEY")) {
    const llm = await mistralParse(payload.subject, payload.text);
    if (llm) parsed = mergeParse(parsed, llm);
  }

  if (parsed.confidence < INSERT_THRESHOLD) {
    await finishQueue(queueId, "failed", parsed.confidence, null, "confidence too low");
    return ok("parsed but below insert threshold");
  }

  const { data: sub, error } = await supabase
    .from("user_subscriptions")
    .insert({
      user_id: profile.id,
      custom_merchant_name: parsed.merchantName ?? "Unknown",
      amount_cents: parsed.amountCents ?? 0,
      currency: parsed.currency ?? "EUR",
      billing_frequency: parsed.billingFrequency ?? "monthly",
      signup_date: parsed.signupDate ?? todayUTC(),
      status: "active",
      source: "email_forward",
    })
    .select("id")
    .single();

  if (error) {
    await finishQueue(queueId, "failed", parsed.confidence, null, error.message);
    return ok("insert failed: " + error.message);
  }

  await finishQueue(queueId, "parsed", parsed.confidence, sub!.id as string, null);
  return ok("parsed", { subscription_id: sub!.id, confidence: parsed.confidence });
});

// ── Signature verification ────────────────────────────────────────────────

function verifySignature(req: Request, body: string): boolean {
  const secret = Deno.env.get("RESEND_WEBHOOK_SECRET");
  if (!secret) {
    // Fail closed in production: an unsigned request must never be trusted, or
    // anyone could POST forged emails for a known handle. Set
    // ALLOW_UNSIGNED_WEBHOOKS=true ONLY for local development.
    return Deno.env.get("ALLOW_UNSIGNED_WEBHOOKS") === "true";
  }
  try {
    new Webhook(secret).verify(body, {
      "svix-id": req.headers.get("svix-id") ?? "",
      "svix-timestamp": req.headers.get("svix-timestamp") ?? "",
      "svix-signature": req.headers.get("svix-signature") ?? "",
    });
    return true;
  } catch {
    return false;
  }
}

// ── Payload extraction (Resend inbound shape, defensive) ──────────────────

interface InboundEmail { from: string; to: string[]; subject: string; text: string }

function extractEmail(json: Record<string, unknown>): InboundEmail {
  const data = (json.data ?? json) as Record<string, unknown>;
  const toRaw = data.to ?? data.recipient ?? [];
  const to = Array.isArray(toRaw) ? toRaw.map(String) : [String(toRaw)];
  return {
    from: String(data.from ?? ""),
    to,
    subject: String(data.subject ?? ""),
    text: String(data.text ?? data.plain ?? stripHtml(String(data.html ?? ""))),
  };
}

function stripHtml(html: string): string {
  return html.replace(/<[^>]+>/g, " ").replace(/&nbsp;/g, " ").replace(/\s+/g, " ").trim();
}

function recipientHandle(addresses: string[]): string | null {
  const domain = FORWARDING_DOMAIN.replace(/\./g, "\\.");
  const re = new RegExp(`([a-z0-9._-]+)@${domain}`);
  for (const a of addresses) {
    const m = a.toLowerCase().match(re);
    if (m) return m[1];
  }
  return null;
}

// ── Heuristic parser (port of Sources/Services/EmailParser.swift) ─────────

interface Parsed {
  merchantName: string | null;
  amountCents: number | null;
  currency: string | null;
  billingFrequency: string | null;
  signupDate: string | null; // yyyy-MM-dd
  confidence: number;
}

const KNOWN: [string, string][] = [
  ["netflix", "Netflix"], ["spotify", "Spotify"], ["disney", "Disney+"],
  ["audible", "Audible"], ["youtube", "YouTube Premium"], ["amazon", "Amazon"],
  ["nytimes", "NYT"], ["new york times", "NYT"],
  ["fitnessfirst", "FitnessFirst"], ["fitness first", "FitnessFirst"],
  ["mcfit", "McFit"], ["dazn", "DAZN"], ["adobe", "Adobe"], ["dropbox", "Dropbox"],
  ["notion", "Notion"], ["linkedin", "LinkedIn"], ["duolingo", "Duolingo"],
  ["hellofresh", "HelloFresh"], ["patreon", "Patreon"], ["apple", "Apple"],
  ["google", "Google"], ["microsoft", "Microsoft"],
];

const CURRENCY: Record<string, string> = {
  "€": "EUR", eur: "EUR", "£": "GBP", gbp: "GBP",
  "$": "USD", usd: "USD", "zł": "PLN", zl: "PLN", pln: "PLN",
};

const PRICE_KEYWORDS = ["total", "amount", "charged", "billed", "price", "betrag", "montant", "importe", "kwota", "due", "pay"];

function parseEmail(subject: string, body: string, from: string): Parsed {
  const haystack = `${subject}\n${body}`.toLowerCase();
  const merchant = detectMerchant(from, subject, body);
  const money = detectAmount(`${subject}\n${body}`);
  const frequency = detectFrequency(haystack);
  const signupDate = detectDate(`${subject}\n${body}`);

  let confidence = 0;
  if (merchant?.source === "known") confidence += 0.30;
  else if (merchant?.source === "derived") confidence += 0.15;
  if (money) confidence += 0.40;
  if (frequency) confidence += 0.20;
  if (signupDate) confidence += 0.10;

  return {
    merchantName: merchant?.name ?? null,
    amountCents: money?.cents ?? null,
    currency: money?.currency ?? null,
    billingFrequency: frequency,
    signupDate,
    confidence: Math.min(confidence, 1),
  };
}

function detectMerchant(from: string, subject: string, body: string): { name: string; source: "known" | "derived" } | null {
  const domain = senderDomain(from);
  const scopes = [domain, senderDisplayName(from), subject.toLowerCase(), body.toLowerCase()];
  for (const scope of scopes) {
    if (!scope) continue;
    for (const [kw, name] of KNOWN) if (scope.includes(kw)) return { name, source: "known" };
  }
  const label = registrableLabel(domain);
  return label ? { name: capitalize(label), source: "derived" } : null;
}

function senderDomain(from: string): string {
  const at = from.indexOf("@");
  if (at < 0) return "";
  return (from.slice(at + 1).match(/^[a-z0-9.-]+/i)?.[0] ?? "").toLowerCase();
}

function senderDisplayName(from: string): string {
  const lt = from.indexOf("<");
  if (lt >= 0) return from.slice(0, lt).trim().toLowerCase();
  return from.includes("@") ? "" : from.toLowerCase();
}

function registrableLabel(domain: string): string | null {
  if (!domain) return null;
  let labels = domain.split(".");
  const secondLevel = new Set(["co", "com", "org", "net", "gov", "ac"]);
  if (labels.length >= 2 && secondLevel.has(labels[labels.length - 2])) labels = labels.slice(0, -1);
  const noise = new Set(["mail", "email", "e", "news", "no-reply", "noreply", "account", "billing", "info", "smtp"]);
  labels = labels.filter((l) => !noise.has(l));
  return labels.length >= 2 ? labels[labels.length - 2] : null;
}

function detectAmount(text: string): { cents: number; currency: string } | null {
  const before = /(€|£|\$|zł|EUR|GBP|USD|PLN)\s*(\d[\d.,]*\d|\d)/gi;
  const after = /(\d[\d.,]*\d|\d)\s*(€|£|zł|EUR|GBP|USD|PLN)/gi;
  const candidates: { cents: number; currency: string; near: boolean }[] = [];

  for (const re of [before, after]) {
    let m: RegExpExecArray | null;
    while ((m = re.exec(text)) !== null) {
      const a = m[1], b = m[2];
      const token = (CURRENCY[a.toLowerCase()] ? a : b).toLowerCase();
      const numberStr = CURRENCY[a.toLowerCase()] ? b : a;
      const currency = CURRENCY[token];
      const cents = centsFromAmount(numberStr);
      if (!currency || cents === null) continue;
      const window = text.slice(Math.max(0, m.index - 24), m.index + 24).toLowerCase();
      candidates.push({ cents, currency, near: PRICE_KEYWORDS.some((k) => window.includes(k)) });
    }
  }
  if (candidates.length === 0) return null;
  const keyed = candidates.filter((c) => c.near).sort((x, y) => y.cents - x.cents);
  const pick = keyed[0] ?? candidates.sort((x, y) => y.cents - x.cents)[0];
  return { cents: pick.cents, currency: pick.currency };
}

function centsFromAmount(raw: string): number | null {
  const s = raw.replace(/[^\d.,]/g, "");
  if (!s) return null;
  const lastDot = s.lastIndexOf("."), lastComma = s.lastIndexOf(",");
  const lastSep = Math.max(lastDot, lastComma);
  let integerPart = s, fraction = "00";
  if (lastSep >= 0) {
    const after = s.slice(lastSep + 1);
    if (after.length === 2 && /^\d{2}$/.test(after)) { integerPart = s.slice(0, lastSep); fraction = after; }
  }
  const digits = integerPart.replace(/\D/g, "");
  if (!digits) return null;
  const cents = parseInt(digits, 10) * 100 + parseInt(fraction, 10);
  return cents > 0 ? cents : null;
}

function detectFrequency(h: string): string | null {
  const has = (xs: string[]) => xs.some((x) => h.includes(x));
  if (has(["year", "annual", "jährlich", "pro jahr", "par an", "/an", "anual", "annuel", "annuale", "rocznie"])) return "yearly";
  if (has(["quarter", "vierteljähr", "trimestr"])) return "quarterly";
  if (has(["week", "wöchentlich", "par semaine", "semanal", "settimanal", "tygodnio"])) return "weekly";
  if (has(["month", "/mo", "monatlich", "im monat", "par mois", "/mois", "al mese", "mensual", "mensile", "miesięcz"])) return "monthly";
  return null;
}

// Conservative date match: ISO, dd.MM.yyyy, dd/MM/yyyy. Returns yyyy-MM-dd.
function detectDate(text: string): string | null {
  let m = text.match(/(\d{4})-(\d{2})-(\d{2})/);
  if (m) return `${m[1]}-${m[2]}-${m[3]}`;
  m = text.match(/(\d{1,2})[.\/](\d{1,2})[.\/](\d{4})/);
  if (m) {
    const d = m[1].padStart(2, "0"), mo = m[2].padStart(2, "0");
    return `${m[3]}-${mo}-${d}`;
  }
  return null;
}

// ── Mistral fallback (spec §10.1 step 6) ──────────────────────────────────

async function mistralParse(subject: string, body: string): Promise<Partial<Parsed> | null> {
  const key = Deno.env.get("MISTRAL_API_KEY");
  if (!key) return null;
  const prompt =
    `Extract from this email and return JSON only with keys ` +
    `merchantName (string), amount (number, major units), currency (ISO code), ` +
    `billingFrequency (one of weekly|monthly|quarterly|yearly|one_time), ` +
    `startDate (yyyy-MM-dd).\n\nSubject: ${subject}\n\n${body.slice(0, 4000)}`;
  try {
    const res = await fetch("https://api.mistral.ai/v1/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
      body: JSON.stringify({
        model: "mistral-large-latest",
        messages: [{ role: "user", content: prompt }],
        response_format: { type: "json_object" },
        temperature: 0,
      }),
    });
    if (!res.ok) return null;
    const json = await res.json();
    const content = json.choices?.[0]?.message?.content;
    if (!content) return null;
    const obj = JSON.parse(content);
    return {
      merchantName: obj.merchantName ?? null,
      amountCents: typeof obj.amount === "number" ? Math.round(obj.amount * 100) : null,
      currency: obj.currency ?? null,
      billingFrequency: obj.billingFrequency ?? null,
      signupDate: obj.startDate ?? null,
      confidence: 0.8,
    };
  } catch {
    return null;
  }
}

function mergeParse(base: Parsed, llm: Partial<Parsed>): Parsed {
  return {
    merchantName: base.merchantName ?? llm.merchantName ?? null,
    amountCents: base.amountCents ?? llm.amountCents ?? null,
    currency: base.currency ?? llm.currency ?? null,
    billingFrequency: base.billingFrequency ?? llm.billingFrequency ?? null,
    signupDate: base.signupDate ?? llm.signupDate ?? null,
    confidence: Math.max(base.confidence, llm.confidence ?? 0),
  };
}

// ── Helpers ───────────────────────────────────────────────────────────────

async function finishQueue(
  id: string | undefined, status: string, confidence: number,
  subscriptionId: string | null, error: string | null,
) {
  if (!id) return;
  await supabase.from("email_parse_queue").update({
    status,
    parse_confidence: confidence,
    parsed_subscription_id: subscriptionId,
    error_message: error,
    processed_at: new Date().toISOString(),
  }).eq("id", id);
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function todayUTC(): string {
  return new Date().toISOString().slice(0, 10);
}

function ok(message: string, extra: Record<string, unknown> = {}): Response {
  return new Response(JSON.stringify({ ok: true, message, ...extra }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

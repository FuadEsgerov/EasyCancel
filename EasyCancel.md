# EasyCancel — Full Product & Build Specification

> **Version:** 1.0
> **Last updated:** May 2026
> **Owner:** [Your name]
> **Target launch:** May–June 2026 (aligned with EU Directive 2023/2673 enforcement deadline of 19 June 2026)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [The Legal Opportunity](#2-the-legal-opportunity)
3. [Product Vision & Positioning](#3-product-vision--positioning)
4. [Target Users & Personas](#4-target-users--personas)
5. [Competitive Landscape](#5-competitive-landscape)
6. [Feature Specification](#6-feature-specification)
7. [User Flows](#7-user-flows)
8. [Technical Architecture](#8-technical-architecture)
9. [Supabase Schema & RLS](#9-supabase-schema--rls)
10. [Edge Functions & Background Jobs](#10-edge-functions--background-jobs)
11. [Third-Party Services](#11-third-party-services)
12. [Legal & Compliance](#12-legal--compliance)
13. [Localization Strategy](#13-localization-strategy)
14. [Design System & UX Principles](#14-design-system--ux-principles)
15. [Monetization & Pricing](#15-monetization--pricing)
16. [Go-to-Market Plan](#16-go-to-market-plan)
17. [Roadmap & Milestones](#17-roadmap--milestones)
18. [KPIs & Success Metrics](#18-kpis--success-metrics)
19. [Risks & Mitigations](#19-risks--mitigations)
20. [Estimated Costs](#20-estimated-costs)
21. [Appendix: Letter Templates](#21-appendix-letter-templates)

---

## 1. Executive Summary

**EasyCancel** is a consumer-rights iOS app that helps EU and UK users exercise their legal right to cancel subscriptions and withdraw from online purchases. The app forwards confirmation emails to a unique address, auto-extracts merchant details, tracks the 14-day cooling-off window, and either triggers the legally-mandated cancellation button or generates a GDPR-compliant withdrawal letter sent via durable medium.

**Key differentiators:**
- **First-mover on EU Directive 2023/2673** (mandatory withdrawal button by 19 June 2026)
- **Legal proof of delivery** — every cancellation is timestamped and stored as evidence
- **Multilingual letter generator** (EN, DE, FR, ES, IT, NL, PL)
- **EU data residency** (Supabase Frankfurt) and GDPR-native architecture

**Business model:** Freemium subscription
- Free: 5 tracked subscriptions, 2 cancellations/month
- Pro: €2.99/month or €19.99/year — unlimited
- Family: €4.99/month — 4 users

**Target Year-1 metrics:**
- 100,000 downloads
- 8,000 paying users
- €15,000 MRR
- 4.5+ App Store rating in 5 markets

---

## 2. The Legal Opportunity

### 2.1 Why this app exists now

Three converging legal frameworks make 2026 the year to launch this product.

#### EU Directive 2023/2673 — The Withdrawal Button

- **Effective date:** Member states must transpose by **19 June 2026**
- **Requirement:** Every trader selling distance contracts via an online interface (website, app) to EU consumers must provide a clearly visible "withdraw from contract here" function
- **Label requirement:** Must use the exact wording "withdraw from contract here" or unambiguous equivalent in local language
- **Confirmation requirement:** Trader must immediately confirm withdrawal receipt on a "durable medium"
- **Source:** Directive (EU) 2023/2673, amending Consumer Rights Directive 2011/83/EU

#### EU Consumer Rights Directive — 14-Day Cooling-Off

- **Effective:** Already in force since 2014, applies to all EU member states
- **Coverage:** Most distance and off-premises contracts (online purchases, doorstep sales)
- **User right:** Cancel for any reason within 14 days of receiving goods or concluding service contracts
- **Refund obligation:** Trader must refund within 14 days of withdrawal notification

#### Germany's Kündigungsbutton (Cancellation Button)

- **Effective:** July 2022 (§ 312k BGB)
- **Status:** Proven product-market fit — Germany shows how this works at scale
- **Requirement:** Two-click cancellation flow with mandatory button labeled "Verträge hier kündigen"
- **Penalty for non-compliance:** Customers can cancel anytime without notice if button is missing

#### UK Consumer Contracts Regulations 2013

- **Effective:** 2014, retained post-Brexit
- **Coverage:** Mirrors EU 14-day cooling-off rights
- **No equivalent withdrawal button mandate yet** — but ASA/CMA are pressuring on dark patterns

### 2.2 Market size

- **EU consumer subscription market:** €350+ billion (2025)
- **UK alone:** Citizens Advice reports 2 million people struggle to cancel continuous payments yearly
- **UK estimate:** £25 billion wasted annually on unmonitored subscriptions
- **Germany:** €0.5 billion lost to unintentional auto-renewals (2022 study)
- **EAA Eurobarometer 2024:** Only 42% of EU consumers feel "well informed" about their consumer rights

### 2.3 Regulatory tailwinds for 2026

- **Digital Fairness Act (DFA)** — expected Q3 2026, will target dark patterns
- **EU 2030 Consumer Agenda** — adopted Nov 2025, makes consumer empowerment a 5-year priority
- **PSD2 → PSD3 transition** — strengthens consumer payment rights, expected 2026–2027

---

## 3. Product Vision & Positioning

### 3.1 Vision statement

> "Every European has the legal right to cancel anything online. EasyCancel makes exercising that right take 10 seconds instead of 2 hours."

### 3.2 Mission

Reduce the friction between EU consumer rights and consumer action to near-zero, while creating an auditable legal trail.

### 3.3 Positioning

**Category:** Consumer rights / Personal finance utility

**One-line pitch:**
> "Cancel any EU subscription with one tap. We handle the legal paperwork."

**Comparison frame:**
- *Snoop, Emma, Plum*: Show you subscriptions. EasyCancel cancels them.
- *Rocket Money* (US only): Bank-linked, US-focused, expensive. EasyCancel is EU-first and privacy-first.
- *Cancel-my-subscription services*: Manual, slow, English-only. EasyCancel is automated, multilingual, legally grounded.

### 3.4 Brand principles

- **Legally precise** — every claim, every letter, every deadline is correct
- **Calm under pressure** — users come to us frustrated; we radiate competence
- **Privacy-native** — we read what we must, store what's necessary, delete the rest
- **Transparent** — clear about what we do and don't do
- **Quietly powerful** — no aggressive marketing, no dark patterns (we'd be hypocrites)

---

## 4. Target Users & Personas

### 4.1 Primary persona — "Frustrated Frieda" (Germany)

- **Age:** 34
- **Job:** Marketing manager, Berlin
- **Income:** €55k
- **Subscriptions:** 14 active (streaming, news, fitness app, dating app, two software tools, a meal kit she forgot about)
- **Pain:** Tried to cancel a fitness app — was forced to call a hotline during business hours, then sent a letter, then they "lost" it. Wasted 3 hours over 2 months.
- **Tech:** iPhone 14, uses Apple Pay, mid-tech-literacy
- **Languages:** German native, English fluent
- **Trigger for adoption:** Saw EasyCancel on Stiftung Warentest comparison

### 4.2 Secondary persona — "Skeptical Simon" (UK)

- **Age:** 47
- **Job:** Self-employed accountant, Manchester
- **Income:** £70k
- **Subscriptions:** 22 active (mix of personal + business)
- **Pain:** Discovered he'd been paying for a SaaS tool for 18 months after a free trial. Cost him £540.
- **Tech:** iPhone 15 Pro, power user
- **Languages:** English
- **Trigger for adoption:** Reddit r/UKPersonalFinance recommendation

### 4.3 Tertiary persona — "Overwhelmed Ola" (Poland)

- **Age:** 26
- **Job:** Junior software developer, Warsaw
- **Income:** PLN 8,500/month
- **Subscriptions:** 11 active, mostly digital media
- **Pain:** Subscriptions are billed in EUR/USD, hard to track in złoty; cancellation flows are in English she doesn't fully trust
- **Tech:** iPhone 13, high tech-literacy
- **Languages:** Polish native, English working
- **Trigger:** TikTok ad in Polish

### 4.4 Anti-personas (NOT our users)

- **Bank-account-deep users** wanting full PFM (use Snoop, Emma, Plum)
- **US users** (regulatory framework doesn't apply)
- **Teenagers under 18** (cannot legally enter contracts in most jurisdictions)
- **Business users with corporate subscriptions** (different legal regime; future expansion)

---

## 5. Competitive Landscape

### 5.1 Direct competitors

| App | Strength | Weakness | Threat Level |
|-----|----------|----------|--------------|
| **Snoop** (UK) | Open Banking integration, free | Tracks only — doesn't cancel under law | 🟡 Medium |
| **Emma** (UK/EU) | Multi-bank aggregation | Premium tier expensive, no legal cancellation flow | 🟡 Medium |
| **Plum** (UK/EU) | Savings + tracking | Subscription tracker is a side feature | 🟢 Low |
| **Money Dashboard** (UK) | Long-established | Subscription tracker is basic | 🟢 Low |
| **Little Birdie** (UK) | Cancel-within-app feature | UK-only, limited merchant coverage | 🟠 High |
| **Bobby** (iOS global) | Beautiful, 4.7 rating | Manual entry only, no legal layer | 🟡 Medium |

### 5.2 Indirect competitors

- **Rocket Money** (US only) — different regulatory regime, can't operate in EU same way
- **Consumer rights lawyers / agencies** — slow, expensive
- **National consumer protection orgs** (vzbv, Which?, UFC-Que Choisir) — provide info, not action

### 5.3 Competitive moat

1. **Regulatory expertise barrier** — encoding consumer law across 8 jurisdictions is hard
2. **First-mover on Directive 2023/2673** — own the "withdrawal button" category
3. **Letter quality** — legal templates reviewed by consumer rights lawyers
4. **Trust signal** — partnerships with consumer orgs are hard to copy
5. **Language depth** — 7 native localizations, not Google-translated

---

## 6. Feature Specification

### 6.1 MVP (V1.0) — Launch features

#### F1. Onboarding (3 screens max)

- **F1.1** Welcome screen with value prop in 3 bullets
- **F1.2** Country selection (drives legal framework + language)
- **F1.3** Sign in with Apple (default) or email magic link

**Acceptance criteria:**
- 90% of users complete onboarding without back-tapping
- Country detection auto-suggested via device locale

#### F2. Subscription tracking — Manual

- **F2.1** Add subscription manually: name, amount, currency, billing frequency, next renewal date, signup date
- **F2.2** Browse from merchant database (200+ common EU/UK merchants pre-loaded with icons)
- **F2.3** Subscription list view sorted by next renewal
- **F2.4** Edit / delete subscriptions
- **F2.5** Mark as "cancelled" with proof attachment

**Acceptance criteria:**
- Adding a subscription takes ≤ 15 seconds
- Merchant database supports 500+ entries by launch

#### F3. Subscription tracking — Email forwarding

- **F3.1** Each user gets a unique forwarding address: `[user-uuid]@inbox.easycancel.app`
- **F3.2** User forwards subscription confirmation emails to this address
- **F3.3** Server-side parser extracts: merchant, amount, currency, frequency, dates
- **F3.4** New subscription appears in app within 30 seconds
- **F3.5** User confirms or edits extracted data
- **F3.6** Raw email deleted within 7 days of processing

**Parser tech stack:**
- Regex for known merchants
- LLM (Mistral Large via API) fallback for unknown formats
- Confidence score < 0.7 → flag for user review

#### F4. The Cancel Engine

- **F4.1** **Smart cancel** — for merchants with known German-style Kündigungsbutton or EU withdrawal button: app opens deep-linked URL with pre-filled user data
- **F4.2** **Letter generator** — for merchants without button: generates legally compliant withdrawal letter
- **F4.3** Letter sent via email (Resend API) with read receipt + DKIM signature
- **F4.4** Optional: send via certified email service (D-Trust, eIDAS-compliant) for €1.99 add-on
- **F4.5** PDF copy saved to user's vault

**Acceptance criteria:**
- Cancel flow completes in ≤ 30 seconds
- Letter contains: user identity, contract reference, withdrawal clause citation (correct article per country), date, durable-medium request

#### F5. Cooling-off deadline tracker

- **F5.1** Auto-calculate 14-day window from subscription start date
- **F5.2** Push notification at: 7 days remaining, 3 days remaining, 1 day remaining
- **F5.3** Visual urgency indicator (color-coded badge)
- **F5.4** Country-specific rules (some EU countries extend rights)

#### F6. Proof & evidence vault

- **F6.1** Every sent letter saved as PDF
- **F6.2** Email send confirmations with timestamps
- **F6.3** Merchant responses logged (when received)
- **F6.4** Export ZIP of evidence for disputes
- **F6.5** "Durable medium" compliance — files stored in user's iCloud or downloadable

#### F7. Settings

- **F7.1** Account: email, country, language, delete account (GDPR right)
- **F7.2** Privacy: data export (GDPR Art. 20), delete all data
- **F7.3** Notifications: granular controls
- **F7.4** Subscription management (in-app purchase status)
- **F7.5** Help & support

### 6.2 V1.1 (Months 2–3 post-launch)

- **F8** Apple Mail / Gmail OAuth integration (auto-scan inbox, opt-in)
- **F9** Open Banking connection (TrueLayer for UK, Tink for EU)
- **F10** Subscription discovery from bank transactions
- **F11** Merchant difficulty rating (community-sourced)
- **F12** Bulk cancel flow

### 6.3 V1.2 (Months 4–6)

- **F13** Dispute escalation — auto-file with national consumer authority if merchant ignores
- **F14** Spending insights dashboard
- **F15** Family plan with shared subscription pool
- **F16** Refund recovery — for charges within 14-day window already paid

### 6.4 V2.0 (Year 2)

- **F17** Android app
- **F18** B2B tier for SMEs managing employee subscriptions
- **F19** Browser extension (Safari iOS extension + Mac)
- **F20** AI agent that negotiates retention offers on user's behalf

---

## 7. User Flows

### 7.1 First-time user flow

```
Open app
  → Welcome screen (3-bullet value prop)
  → Country selection (default: device locale)
  → Sign in with Apple
  → Permission request: notifications
  → Empty state: "Add your first subscription"
  → Choose: Manual entry / Forward email
  → Subscription added → Confirmation screen
  → If within 14-day cooling-off: prompt "Cancel within deadline?"
  → If outside: prompt "Set renewal reminder"
```

### 7.2 Forward-email flow

```
User taps "Forward email"
  → Modal shows unique forwarding address with copy button
  → "Open Mail" deep link
  → User forwards confirmation email
  → Push notification: "Subscription detected: Netflix €15.99/mo"
  → Tap notification → Review extracted data
  → Confirm or edit
  → Subscription added
```

### 7.3 Cancel flow (button-eligible merchant)

```
User taps subscription
  → Detail screen shows: amount, next renewal, days into cooling-off
  → CTA: "Cancel now"
  → Confirm screen with consequences ("You'll lose access on [date]")
  → "Cancel" button tapped
  → If merchant has Kündigungsbutton/withdrawal button:
      → Open in-app browser to deep-linked URL
      → User completes cancel (often 2 clicks)
      → Return to app, mark as "cancelled - confirmation pending"
  → Push notification when merchant confirms (24–72h)
  → Status: "Successfully cancelled" with proof PDF
```

### 7.4 Cancel flow (letter-required merchant)

```
User taps "Cancel"
  → App detects no withdrawal button → switches to letter flow
  → Preview letter in user's language (editable)
  → Optional: add custom reason
  → "Send" button
  → Letter sent via Resend with read-receipt
  → Status: "Letter sent - awaiting response"
  → 14-day countdown begins for merchant response
  → If no response: prompt "Escalate to consumer authority?"
```

### 7.5 Subscription paywall flow

```
User hits free-tier limit (5 subscriptions or 2 cancellations)
  → Bottom sheet appears (not full screen — respectful)
  → Show: "Pro €2.99/mo or €19.99/yr"
  → 3 bullet benefits
  → "Start free trial" (7-day trial)
  → Apple in-app purchase sheet
  → On success: dismiss, unlock feature
  → On cancel: dismissable, can continue with free tier
```

---

## 8. Technical Architecture

### 8.1 Stack overview

```
┌─────────────────────────────────────────────────────┐
│                    iOS App                          │
│              SwiftUI + Swift 5.10                   │
│                  iOS 17+ target                     │
└────────────────────┬────────────────────────────────┘
                     │
                     │ HTTPS / WebSocket (Realtime)
                     │
┌────────────────────▼────────────────────────────────┐
│                  Supabase                           │
│              (eu-central-1, Frankfurt)              │
│  ┌─────────────┐  ┌──────────┐  ┌──────────────┐    │
│  │ Postgres 15 │  │   Auth   │  │   Storage    │    │
│  └─────────────┘  └──────────┘  └──────────────┘    │
│  ┌────────────────────────────────────────────────┐ │
│  │           Edge Functions (Deno)                │ │
│  │  - parse-email                                 │ │
│  │  - generate-letter                             │ │
│  │  - send-cancellation                           │ │
│  │  - process-bank-webhook                        │ │
│  └────────────────────────────────────────────────┘ │
└─────┬───────────────┬─────────────────────┬─────────┘
      │               │                     │
      ▼               ▼                     ▼
  ┌───────┐       ┌───────┐            ┌──────────┐
  │Resend │       │Mistral│            │RevenueCat│
  │ Email │       │  AI   │            │   IAP    │
  └───────┘       └───────┘            └──────────┘
      │
      ▼
  ┌──────────────┐
  │ Inbound email│
  │ webhook to   │
  │ Edge Function│
  └──────────────┘
```

### 8.2 iOS app architecture

- **Pattern:** MVVM with Combine
- **Navigation:** SwiftUI `NavigationStack` + deep-link router
- **State:** `@Observable` (iOS 17 macro)
- **Persistence:** SwiftData for offline-first cache; Supabase as source of truth
- **Networking:** `URLSession` + custom Supabase Swift SDK wrapper
- **Auth:** Apple Sign In + Supabase Auth
- **Analytics:** PostHog (EU-hosted, GDPR-friendly)
- **Crash reporting:** Sentry
- **Push notifications:** APNs direct (no third party needed)

### 8.3 Backend architecture

- **Database:** Supabase Postgres 15 in `eu-central-1`
- **Auth:** Supabase Auth (Apple OAuth + magic link email)
- **Storage:** Supabase Storage (encrypted at rest, signed URLs)
- **Realtime:** Supabase Realtime for live subscription updates after email parse
- **Edge Functions:** Deno-based, deployed to EU edge
- **Background jobs:** pg_cron for scheduled tasks (deadline reminders, cleanup)

### 8.4 Key technical decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Database region | EU only (Frankfurt) | GDPR data residency |
| Auth method | Apple Sign In primary | iOS requirement; lowest friction |
| Email parsing | Edge Function + Mistral | Stay in EU; Mistral is EU company |
| Letter generation | Edge Function + Resend | Both have EU hosting + GDPR DPAs |
| Payments | Apple IAP via RevenueCat | Required by App Store; RevenueCat simplifies |
| Encryption | TLS 1.3 + AES-256 at rest | Standard; Supabase handles |
| Offline support | SwiftData cache | Letters viewable offline |

---

## 9. Supabase Schema & RLS

### 9.1 Tables

```sql
-- Users (extends Supabase auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  country_code TEXT NOT NULL CHECK (country_code IN ('DE','UK','FR','ES','IT','NL','PL','AT','BE','IE','PT')),
  preferred_language TEXT NOT NULL DEFAULT 'en',
  forwarding_address_local TEXT UNIQUE NOT NULL, -- e.g. "frieda-7af9"
  subscription_tier TEXT NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free','pro','family')),
  trial_ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ -- soft delete for GDPR
);

-- Merchant catalog
CREATE TABLE public.merchants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  domain TEXT,
  icon_url TEXT,
  category TEXT, -- streaming, software, fitness, news, etc.
  country_of_registration TEXT,
  has_withdrawal_button BOOLEAN DEFAULT FALSE,
  withdrawal_button_url TEXT,
  has_kuendigungsbutton BOOLEAN DEFAULT FALSE,
  kuendigungsbutton_url TEXT,
  legal_email TEXT, -- where to send withdrawal letters
  difficulty_score INTEGER CHECK (difficulty_score BETWEEN 1 AND 5),
  notes TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User subscriptions (the things they want to cancel)
CREATE TABLE public.user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  merchant_id UUID REFERENCES public.merchants(id),
  custom_merchant_name TEXT, -- for unknown merchants
  amount_cents INTEGER NOT NULL,
  currency TEXT NOT NULL DEFAULT 'EUR',
  billing_frequency TEXT NOT NULL CHECK (billing_frequency IN ('weekly','monthly','quarterly','yearly','one_time')),
  signup_date DATE NOT NULL,
  next_renewal_date DATE,
  cooling_off_deadline DATE GENERATED ALWAYS AS (signup_date + INTERVAL '14 days') STORED,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','cancelled','disputed','expired')),
  cancelled_at TIMESTAMPTZ,
  source TEXT CHECK (source IN ('manual','email_forward','bank_sync','gmail_scan')),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Cancellation attempts (audit log)
CREATE TABLE public.cancellation_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES public.user_subscriptions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  method TEXT NOT NULL CHECK (method IN ('button','letter_email','letter_certified')),
  letter_pdf_path TEXT, -- Supabase Storage path
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  delivery_confirmed_at TIMESTAMPTZ,
  read_receipt_at TIMESTAMPTZ,
  merchant_response_at TIMESTAMPTZ,
  merchant_response_text TEXT,
  outcome TEXT CHECK (outcome IN ('success','rejected','no_response','disputed')),
  resend_message_id TEXT, -- for tracking via Resend API
  legal_clause_cited TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Email parsing queue
CREATE TABLE public.email_parse_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  raw_email_path TEXT NOT NULL, -- Supabase Storage path
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','parsed','failed','deleted')),
  parsed_subscription_id UUID REFERENCES public.user_subscriptions(id),
  parse_confidence DECIMAL(3,2),
  error_message TEXT,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  delete_after TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days')
);

-- Notifications log
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('cooling_off_reminder','renewal_reminder','cancellation_confirmed','letter_response')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  related_subscription_id UUID REFERENCES public.user_subscriptions(id),
  sent_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 9.2 Row-Level Security policies

**Always enable RLS — default deny.**

```sql
-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cancellation_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_parse_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
-- merchants table is public read-only

-- Profiles: users see only themselves
CREATE POLICY "Users view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Subscriptions: users see only their own
CREATE POLICY "Users view own subscriptions"
  ON public.user_subscriptions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users insert own subscriptions"
  ON public.user_subscriptions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own subscriptions"
  ON public.user_subscriptions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users delete own subscriptions"
  ON public.user_subscriptions FOR DELETE
  USING (auth.uid() = user_id);

-- Cancellation attempts: read-only for users (write via Edge Function only)
CREATE POLICY "Users view own attempts"
  ON public.cancellation_attempts FOR SELECT
  USING (auth.uid() = user_id);

-- Merchants: public read
ALTER TABLE public.merchants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads merchants"
  ON public.merchants FOR SELECT
  USING (true);
```

### 9.3 Indexes

```sql
CREATE INDEX idx_subs_user_status ON public.user_subscriptions(user_id, status);
CREATE INDEX idx_subs_renewal ON public.user_subscriptions(next_renewal_date) WHERE status = 'active';
CREATE INDEX idx_subs_cooling_off ON public.user_subscriptions(cooling_off_deadline) WHERE status = 'active';
CREATE INDEX idx_attempts_sub ON public.cancellation_attempts(subscription_id);
CREATE INDEX idx_parse_queue_status ON public.email_parse_queue(status, received_at);
CREATE INDEX idx_notifications_user_unread ON public.notifications(user_id, read_at) WHERE read_at IS NULL;
```

### 9.4 Triggers

```sql
-- Auto-create profile on signup
CREATE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, forwarding_address_local, country_code)
  VALUES (
    NEW.id,
    NEW.email,
    LOWER(SPLIT_PART(NEW.email, '@', 1)) || '-' || SUBSTRING(NEW.id::TEXT, 1, 4),
    COALESCE(NEW.raw_user_meta_data->>'country_code', 'UK')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Soft delete cleanup (run nightly via pg_cron)
CREATE FUNCTION public.cleanup_old_emails()
RETURNS void AS $$
BEGIN
  DELETE FROM public.email_parse_queue
  WHERE delete_after < NOW();
END;
$$ LANGUAGE plpgsql;

SELECT cron.schedule('cleanup-emails', '0 3 * * *', 'SELECT public.cleanup_old_emails();');
```

---

## 10. Edge Functions & Background Jobs

### 10.1 Edge Function: `parse-email`

**Trigger:** Webhook from inbound email provider (Resend or Cloudflare Email Routing)

**Flow:**
1. Receive raw email payload
2. Extract recipient (`frieda-7af9@inbox.easycancel.app`)
3. Look up user by `forwarding_address_local`
4. Store raw email in Storage with 7-day TTL
5. Run regex against known merchant patterns
6. If no match, call Mistral API with prompt:
   ```
   Extract from this email:
   - Merchant name
   - Subscription amount (number)
   - Currency
   - Billing frequency
   - Start date
   Return JSON only.
   ```
7. Insert into `user_subscriptions` table
8. Send push notification
9. Return 200 OK

### 10.2 Edge Function: `generate-letter`

**Trigger:** App calls when user taps "Cancel"

**Input:**
```json
{
  "subscription_id": "uuid",
  "language": "de",
  "custom_reason": "optional string"
}
```

**Flow:**
1. Verify auth (user owns subscription)
2. Fetch subscription + merchant data
3. Load language-specific letter template
4. Populate template with user data + legal citation
5. Generate PDF (using `pdf-lib` or `puppeteer`)
6. Upload PDF to Storage at `letters/{user_id}/{attempt_id}.pdf`
7. Insert `cancellation_attempts` row
8. Trigger `send-cancellation` function
9. Return signed URL of PDF for preview

### 10.3 Edge Function: `send-cancellation`

**Flow:**
1. Fetch letter PDF from Storage
2. Compose email via Resend:
   - From: `cancel@easycancel.app` (DKIM-signed)
   - To: merchant legal email
   - CC: user's email (for their records)
   - Subject: localized "Withdrawal from contract — [user name]"
   - Body: localized cover note
   - Attachment: letter PDF
   - Headers: `Disposition-Notification-To` for read receipt
3. Store Resend `message_id`
4. Update `cancellation_attempts.sent_at`
5. Schedule 14-day reminder via pg_cron if no response

### 10.4 Edge Function: `process-bank-webhook` (V1.1)

For Open Banking subscription detection — receives webhook from TrueLayer/Tink when new recurring transaction detected.

### 10.5 Scheduled jobs (pg_cron)

```sql
-- Cooling-off deadline reminders (daily 9am UTC)
SELECT cron.schedule('cooling-off-reminders', '0 9 * * *', $$
  INSERT INTO notifications (user_id, type, title, body, related_subscription_id)
  SELECT
    user_id,
    'cooling_off_reminder',
    'Cooling-off ends soon',
    'You have ' || (cooling_off_deadline - CURRENT_DATE) || ' days to cancel ' || COALESCE(custom_merchant_name, (SELECT name FROM merchants WHERE id = merchant_id)),
    id
  FROM user_subscriptions
  WHERE status = 'active'
    AND cooling_off_deadline IN (CURRENT_DATE + 7, CURRENT_DATE + 3, CURRENT_DATE + 1);
$$);

-- Email cleanup (3am UTC)
SELECT cron.schedule('cleanup-emails', '0 3 * * *', 'SELECT public.cleanup_old_emails();');

-- Soft-delete account cleanup (4am UTC, 30 days after deletion request)
SELECT cron.schedule('purge-deleted-accounts', '0 4 * * *', $$
  DELETE FROM profiles WHERE deleted_at < NOW() - INTERVAL '30 days';
$$);
```

---

## 11. Third-Party Services

| Service | Purpose | EU-hosted | Pricing (launch) |
|---------|---------|-----------|------------------|
| **Supabase** | Backend (auth, DB, storage, edge functions) | ✅ Frankfurt | $25/mo Pro |
| **Resend** | Transactional email + inbound parsing | ✅ EU region | $20/mo (50k emails) |
| **Mistral AI** | Email parsing fallback | ✅ Paris-based | ~$0.002/parse, ~$20/mo at launch |
| **RevenueCat** | iOS in-app purchase mgmt | ❌ US (uses Apple servers) | Free under $2.5k MTR |
| **Apple Push Notifications** | Push delivery | n/a | Free |
| **PostHog** | Product analytics | ✅ EU Cloud | Free tier |
| **Sentry** | Crash reporting | ✅ EU region | Free tier |
| **Cloudflare** | CDN + DDoS + DNS | ✅ EU edge | Free tier |
| **Apple Developer** | App distribution | n/a | $99/year |

**Total monthly infrastructure cost at launch:** ~€50–80

---

## 12. Legal & Compliance

### 12.1 GDPR compliance checklist

- [ ] **Lawful basis for processing** documented (contract + legitimate interest)
- [ ] **Privacy policy** in all 7 supported languages
- [ ] **Terms of service** in all 7 supported languages
- [ ] **Cookie/tracking consent** (not strictly cookies on iOS but for any web property)
- [ ] **Data Processing Agreement** signed with Supabase
- [ ] **Data Processing Agreement** signed with Resend
- [ ] **Data Processing Agreement** signed with Mistral
- [ ] **Subprocessor list** published and updated
- [ ] **GDPR Article 30 records** maintained
- [ ] **Data Protection Officer** appointed (recommended even if not strictly required at <250 employees)
- [ ] **Right to access** (Art. 15) — export endpoint
- [ ] **Right to rectification** (Art. 16) — edit profile
- [ ] **Right to erasure** (Art. 17) — delete account flow
- [ ] **Right to portability** (Art. 20) — ZIP export
- [ ] **Right to object** (Art. 21) — opt out of marketing
- [ ] **Data breach response plan** — 72-hour notification process
- [ ] **DPIA** (Data Protection Impact Assessment) for email scanning

### 12.2 App Store compliance

- [ ] Apple Sign In offered (required when other social logins exist)
- [ ] In-app purchase used for subscriptions (Apple's cut: 15% for small biz program)
- [ ] App Privacy details accurate in App Store Connect
- [ ] No selling user data
- [ ] Subscription terms clearly disclosed in paywall
- [ ] Cancel-subscription instructions in app (Apple requires this)

### 12.3 EU app compliance (DMA)

- Optional: distribute via alternative app stores in EU (Setapp Mobile, AltStore PAL)
- Lower commission (typically 17% vs Apple's 30%)
- Decide post-launch based on App Store traction

### 12.4 Legal entity setup

**Recommended structure for solo founder:**
- **UK Ltd** (e.g. EasyCancel Ltd) if UK-based — simple, ~£12 to incorporate
- **Estonia e-Residency + OÜ** if EU-based without local country preference — 20% corporate tax only on dividends
- **German UG (haftungsbeschränkt)** if Germany-based — €1 minimum capital, easier with local market

**VAT:**
- Register for VAT once revenue > local threshold
- Use **VAT OSS** (One Stop Shop) for cross-EU sales
- Or use **Paddle** / **Lemon Squeezy** as Merchant of Record — they handle VAT entirely for ~5% extra fee

### 12.5 Insurance

- **Professional indemnity insurance** — €1M cover, ~€600/year (essential — you're giving quasi-legal advice)
- **Cyber insurance** — €1M cover, ~€800/year
- **D&O insurance** — only when raising funding

### 12.6 Letter legal review

Before launch, have all 7 language letter templates reviewed by a consumer rights lawyer in each jurisdiction:
- Estimated cost: €500–1,500 per language
- Total: €4–10k one-time
- Worth every euro — these are the core product

---

## 13. Localization Strategy

### 13.1 Launch languages (V1.0)

| Language | Country priority | Letter template needed | UI strings |
|----------|------------------|------------------------|------------|
| English | UK, IE | ✅ (UK + IE variants) | ✅ |
| German | DE, AT | ✅ | ✅ |
| French | FR, BE | ✅ | ✅ |
| Spanish | ES | ✅ | ✅ |
| Italian | IT | ✅ | ✅ |
| Dutch | NL, BE | ✅ | ✅ |
| Polish | PL | ✅ | ✅ |

### 13.2 V1.1 languages

- Portuguese (PT)
- Czech (CZ)
- Swedish (SE)
- Danish (DK)
- Finnish (FI)

### 13.3 Translation workflow

1. Source content in English, written carefully (short, plain, no idioms)
2. Use **Lokalise** or **Crowdin** for translation management
3. **Native legal translator** for letter templates (NOT generic translation services)
4. **Native UX translator** for app strings (literary quality matters less)
5. In-context QA on real devices for each language

### 13.4 Country-specific behaviors

```javascript
// Pseudo-code for country-specific logic
const countryRules = {
  DE: {
    coolingOffDays: 14,
    coolingOffStartsAt: "contract_conclusion", // not delivery
    requiresKuendigungsbutton: true, // for ongoing contracts
    legalCitation: "§ 355 BGB"
  },
  UK: {
    coolingOffDays: 14,
    coolingOffStartsAt: "delivery",
    requiresKuendigungsbutton: false,
    legalCitation: "Consumer Contracts Regulations 2013, Regulation 29"
  },
  FR: {
    coolingOffDays: 14,
    coolingOffStartsAt: "delivery",
    legalCitation: "Article L221-18 du Code de la consommation"
  },
  // ...
};
```

---

## 14. Design System & UX Principles

### 14.1 Design principles

1. **Calm by default** — avoid red/orange except for genuine urgency
2. **Confident, not preachy** — present facts, not warnings
3. **Numbers over adjectives** — "€340 in active subscriptions" beats "lots of subscriptions"
4. **Honest empty states** — never fake-populate with demo data
5. **Respectful upsell** — bottom sheet, not full takeover

### 14.2 Visual identity

- **Primary color:** Deep navy `#1A2C42` (trust, legal authority)
- **Accent color:** Warm green `#3FB680` (cancellation success)
- **Warning color:** Amber `#D89B3F` (cooling-off urgency)
- **Critical color:** Coral `#E66B5C` (use sparingly)
- **Typography:** SF Pro (iOS system) for UI; serif for legal docs (e.g. *Charter*)
- **Iconography:** SF Symbols + custom merchant icons
- **Tone:** Quiet competence — think IRS but human

### 14.3 Key screens (low-fidelity description)

#### Home screen
- Top: total monthly outflow in user's currency
- Below: list of subscriptions sorted by next renewal
- Each row: merchant icon, name, amount, "X days to cooling-off" or "renews in X days"
- Sticky FAB: "+ Add subscription"
- Bottom tab: Home / Vault / Settings

#### Subscription detail screen
- Hero: merchant icon, name, amount/period
- Cooling-off countdown if active
- Big primary button: "Cancel now"
- Secondary: "Edit details"
- History: cancellation attempts, responses

#### Cancel confirmation screen
- Heading: "Cancel [Merchant Name]?"
- Impact summary: "You'll lose access on [date]"
- Refund estimate: "You may be entitled to €X refund"
- Letter preview (if applicable)
- Primary: "Send cancellation"
- Secondary: "Not yet"

#### Vault screen
- List of all sent letters with status indicators
- Search + filter
- Export-all button

### 14.4 Accessibility

- **WCAG 2.2 AA** compliance minimum
- Dynamic Type support (test up to 200%)
- VoiceOver labels on every interactive element
- Sufficient color contrast on all status indicators
- Reduce motion respected
- Haptic feedback for confirmations

---

## 15. Monetization & Pricing

### 15.1 Pricing tiers

| Tier | Price | Limits | Target |
|------|-------|--------|--------|
| **Free** | €0 | 5 active subscriptions, 2 cancellations/month, basic letters | Acquisition, virality |
| **Pro** | €2.99/mo or €19.99/yr | Unlimited, all languages, certified mail option | Activated users |
| **Family** | €4.99/mo or €34.99/yr | 4 users, shared vault | Households |

**Pricing rationale:**
- Pro annual saves ~45% — pushes toward annual commitment
- Family at <2x Pro — clear value
- Certified mail add-on (€1.99/letter) — high-margin premium for serious disputes

### 15.2 Free trial

- 7-day free trial of Pro on signup
- No credit card required for trial
- Soft conversion: notification on day 6 with "What you'd lose"

### 15.3 Conversion funnel target

| Stage | % | Notes |
|-------|---|-------|
| Download → Onboard | 80% | Strong onboarding |
| Onboard → First subscription added | 70% | |
| First sub → First cancellation | 35% | Key activation |
| Active free → Hit limit | 25% | Within 60 days |
| Hit limit → Trial start | 60% | |
| Trial → Paid | 35% | Industry average ~30% |
| Paid → Retained Y1 | 70% | Annual plan helps |

### 15.4 Expected unit economics

- **Average revenue per paying user (ARPU):** €18/year
- **Customer acquisition cost (CAC) target:** < €6 (organic-heavy)
- **LTV target:** €40
- **LTV/CAC:** > 6x

---

## 16. Go-to-Market Plan

### 16.1 Pre-launch (March–May 2026)

- [ ] Landing page with email waitlist (in 7 languages)
- [ ] Build pre-launch buzz: 5,000 waitlist signups goal
- [ ] Soft outreach to consumer rights orgs:
  - **Germany:** Stiftung Warentest, vzbv (Verbraucherzentrale Bundesverband)
  - **UK:** Which?, Citizens Advice, Money Saving Expert
  - **France:** UFC-Que Choisir, 60 Millions de Consommateurs
  - **Italy:** Altroconsumo
  - **Spain:** OCU (Organización de Consumidores)
  - **EU-wide:** BEUC (umbrella org)
- [ ] Apply for App Store featuring ("Apps We Love" team)
- [ ] Build relationships with 3–5 tech journalists per market

### 16.2 Launch week (around 19 June 2026)

- [ ] Press release: "EU's new consumer law is live — here's the app that uses it for you"
- [ ] ProductHunt launch
- [ ] Reddit AMAs: r/eupersonalfinance, r/germany, r/AskUK, r/france, r/italy
- [ ] TikTok creator partnerships (€500/creator × 5 creators × 3 markets)
- [ ] YouTube: 3 sponsored videos with finance creators
- [ ] X/Twitter: thread on EU consumer rights misinformation

### 16.3 Post-launch growth (Months 1–6)

**Channels (in expected ROI order):**

1. **Organic search (SEO)** — Build content hub answering "how to cancel [merchant] in [country]"
2. **Reddit** — Genuine help in personal finance subs
3. **Consumer org partnerships** — Newsletter mentions, "recommended apps"
4. **TikTok organic** — "Things you didn't know about EU consumer rights"
5. **Press** — Quarterly "State of EU subscriptions" report
6. **Referral program** — 1 month Pro for referrer + referee
7. **App Store Search Ads** — Targeted at competitor keywords ("Snoop alternative")
8. **Paid social** — Last priority, only after organic proves model

### 16.4 Content marketing pillars

1. **Cancellation guides** — "How to cancel [merchant]" for top 100 EU merchants
2. **Consumer rights explainers** — One per directive, per language
3. **State of subscriptions reports** — Quarterly data drops (PR catnip)
4. **Dark pattern wall of shame** — Highlight merchants making cancellation hard

---

## 17. Roadmap & Milestones

### Phase 1: Foundation (March 2026)

- [ ] Incorporate company, sign DPAs
- [ ] Supabase project setup with EU region + RLS
- [ ] iOS project setup, design system
- [ ] First 3 letter templates legal-reviewed (EN, DE, FR)
- [ ] Landing page live with waitlist

### Phase 2: MVP build (April–May 2026)

- [ ] Onboarding + auth complete
- [ ] Manual subscription tracking
- [ ] Email forwarding + parsing
- [ ] Letter generation (3 languages)
- [ ] Send + receipt tracking
- [ ] Cooling-off reminders
- [ ] In-app purchase setup
- [ ] TestFlight beta with 200 users from waitlist

### Phase 3: Launch (June 2026)

- [ ] All 7 languages live
- [ ] All letter templates legal-reviewed
- [ ] Press kit + media outreach
- [ ] App Store submission
- [ ] Public launch on/around 19 June

### Phase 4: Iteration (July–Sept 2026)

- [ ] V1.1: Gmail integration + Open Banking
- [ ] Merchant catalog expansion (200 → 1,000)
- [ ] Localization for PT, CZ, SE, DK, FI

### Phase 5: Scale (Oct–Dec 2026)

- [ ] V1.2: Dispute escalation
- [ ] Family plan
- [ ] First consumer org partnership signed
- [ ] €10k MRR target

### Year 2: Expansion

- [ ] Android app
- [ ] B2B tier
- [ ] EU-wide press launch with quarterly report
- [ ] Series A consideration if metrics justify (only if >€50k MRR)

---

## 18. KPIs & Success Metrics

### 18.1 North Star metric

**Active cancellations completed per week** — captures activation + retention + product value in one number.

### 18.2 Tier 1 KPIs (weekly review)

- New downloads
- New paying subscribers
- MRR
- Active cancellations (button + letter)
- Free → Pro conversion rate
- Churn rate (monthly)
- App Store rating

### 18.3 Tier 2 KPIs (monthly review)

- LTV / CAC
- Average subscriptions tracked per user
- Letter response rate (merchant compliance)
- Average days from signup to first cancel
- Localization performance (per language)
- Support ticket volume

### 18.4 Year-1 targets

| Metric | Target |
|--------|--------|
| Downloads | 100,000 |
| Paying users | 8,000 |
| MRR (end of Y1) | €15,000 |
| App Store rating | ≥ 4.5 |
| Avg subscriptions/user | 8 |
| Cancellation success rate | > 80% |
| Free → Pro conversion | > 8% |

---

## 19. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Merchants block our email domain | Medium | High | Multiple sending domains; certified mail option; manual fallback |
| Legal letters challenged in court | Low | High | Pre-launch legal review per jurisdiction; insurance |
| Apple rejects app | Low | High | Pre-submission consultation; clear privacy disclosures |
| Email parsing inaccuracy | Medium | Medium | User confirmation step; LLM fallback; growing pattern library |
| GDPR complaint | Low | High | DPO, DPIA, strong consent flows, EU-only data |
| Big competitor (Rocket Money) launches in EU | Medium | High | Move fast, build moat via consumer org partnerships |
| Directive 2023/2673 transposition delays | Medium | Low | Most member states have signaled compliance; UK/legacy works regardless |
| Mistral AI parsing costs spike | Low | Medium | Cache aggressive, build regex coverage for top 200 merchants |
| Founder burnout | Medium | High | Don't go alone past month 4; hire contractor or co-founder |

---

## 20. Estimated Costs

### 20.1 One-time costs (pre-launch)

| Item | Cost |
|------|------|
| Company incorporation | €100–500 |
| Legal: ToS + Privacy Policy (7 languages) | €2,000 |
| Legal: Letter templates legal-reviewed (7 jurisdictions) | €5,000 |
| DPIA + DPO setup | €1,500 |
| Brand + logo design | €1,000 |
| App icon + key art | €500 |
| **Total one-time** | **~€10,000** |

### 20.2 Monthly recurring (at launch)

| Item | Cost/month |
|------|-----------|
| Supabase Pro | €25 |
| Resend (50k emails) | €20 |
| Mistral API | €20 |
| Cloudflare | €0 |
| Domain + email forwarding | €10 |
| Translation management (Lokalise) | €30 |
| Apple Developer (annualized) | €8 |
| Professional indemnity insurance | €50 |
| **Total monthly** | **~€165** |

### 20.3 Build cost scenarios

**Scenario A: Solo founder + AI-assisted (recommended)**
- Time: 4–6 months full-time
- Cash out: €15–20k (legal + services + initial marketing)
- Opportunity cost: foregone salary

**Scenario B: Founder + 1 contractor designer/iOS dev**
- Time: 3 months
- Cash out: €40–60k
- Faster to market, less burnout risk

**Scenario C: Founder + 2 co-founders (technical + commercial)**
- Time: 3 months
- Equity-funded, ~€20k cash needed
- Highest ceiling, most complex

### 20.4 First-year P&L projection

| Quarter | Revenue | Costs | Net |
|---------|---------|-------|-----|
| Q3 2026 (launch) | €1,500 | €5,000 | -€3,500 |
| Q4 2026 | €8,000 | €8,000 | €0 |
| Q1 2027 | €25,000 | €15,000 | +€10,000 |
| Q2 2027 | €50,000 | €25,000 | +€25,000 |
| **Year 1 total** | **~€85,000** | **~€53,000** | **+€32,000** |

---

## 21. Appendix: Letter Templates

### 21.1 English (UK) — Withdrawal under Consumer Contracts Regulations 2013

```
[Date]
[Merchant legal name]
[Merchant address]

Re: Notice of withdrawal — Contract reference [REF]

Dear Sir/Madam,

I am writing to inform you that I hereby withdraw from my contract for
the supply of the following service:

  Service: [Service name]
  Order reference: [Reference number]
  Date of contract: [Signup date]
  My name: [Full name]
  My address: [Postal address]
  My email: [Email]

This notice is given pursuant to Regulation 29 of the Consumer Contracts
(Information, Cancellation and Additional Charges) Regulations 2013,
within the 14-day cooling-off period.

I request a full refund of [amount] to my original payment method within
14 days, in accordance with Regulation 34.

Please confirm receipt of this notice on a durable medium, as required
by law.

Yours faithfully,
[Full name]

---
Sent via EasyCancel on behalf of [user]. This message constitutes a
durable medium under UK consumer law. A read receipt has been requested
to confirm delivery.
```

### 21.2 German — Widerruf nach BGB § 355

```
[Datum]
[Firmenname]
[Firmenanschrift]

Betreff: Widerruf des Vertrags — Vertragsnummer [REF]

Sehr geehrte Damen und Herren,

hiermit widerrufe ich den von mir abgeschlossenen Vertrag über
die folgende Leistung:

  Leistung: [Leistungsname]
  Vertragsnummer: [Referenznummer]
  Vertragsdatum: [Datum]
  Mein Name: [Vollständiger Name]
  Meine Anschrift: [Postanschrift]
  Meine E-Mail: [E-Mail]

Dieser Widerruf erfolgt gemäß § 355 BGB innerhalb der 14-tägigen
Widerrufsfrist.

Ich fordere die vollständige Rückerstattung in Höhe von [Betrag] auf
die ursprüngliche Zahlungsmethode innerhalb von 14 Tagen, gemäß § 357 BGB.

Bitte bestätigen Sie den Eingang dieses Widerrufs auf einem
dauerhaften Datenträger, wie gesetzlich vorgeschrieben.

Mit freundlichen Grüßen,
[Vollständiger Name]

---
Gesendet über EasyCancel im Auftrag von [Nutzer]. Diese Nachricht
stellt einen dauerhaften Datenträger im Sinne des deutschen
Verbraucherrechts dar. Eine Lesebestätigung wurde angefordert.
```

### 21.3 French — Rétractation sous Code de la consommation L221-18

```
[Date]
[Nom de l'entreprise]
[Adresse de l'entreprise]

Objet : Notification de rétractation — Référence contrat [REF]

Madame, Monsieur,

Par la présente, je vous notifie ma rétractation du contrat conclu
pour la prestation suivante :

  Service : [Nom du service]
  Référence : [Numéro de commande]
  Date du contrat : [Date]
  Mon nom : [Nom complet]
  Mon adresse : [Adresse postale]
  Mon email : [Email]

Cette notification est faite en application de l'article L221-18
du Code de la consommation, dans le délai légal de rétractation
de 14 jours.

Je demande le remboursement intégral de [montant] sur mon moyen
de paiement initial dans un délai de 14 jours, conformément à
l'article L221-24.

Je vous prie de bien vouloir accuser réception de cette notification
sur un support durable, comme l'exige la loi.

Cordialement,
[Nom complet]

---
Envoyé via EasyCancel pour le compte de [utilisateur]. Ce message
constitue un support durable au sens du droit français de la
consommation. Un accusé de lecture a été demandé.
```

### 21.4 Spanish, Italian, Dutch, Polish — same structure, native legal citations

(To be drafted and legal-reviewed before launch — see § 12.6)

---

## End of specification

> Built with care for European consumers.
> Last reviewed: May 2026.
> Next review: Quarterly or upon major regulatory change.

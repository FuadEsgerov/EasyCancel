# EasyCancel — App Store Connect Submission Reference

_Generated 2026-05-23. Copy-paste the fields below into App Store Connect.
Bundle ID: `com.vincli.easycancel` · Team: VINCLI LTD (52N9GMM7Q6) · Primary language: English (U.K.)_

> Accuracy note: copy below describes what ships in v1.0 (manual add, paste-to-autofill,
> cooling-off tracking, withdrawal-letter generation, multi-country). It deliberately does
> **not** promise the forward-to-inbox auto-detection, because the `parse-email` edge
> function is not deployed yet. Don't add that claim to the listing until it's live
> (App Store Guideline 2.3 — accurate metadata).

---

## 1. App Information (General → App Information)

| Field | Value |
|-------|-------|
| Name (≤30) | `EasyCancel` |
| Subtitle (≤30) | `Cancel subscriptions in time` |
| Primary category | Finance |
| Secondary category | Productivity |
| Age rating | 4+ (no objectionable content) |

---

## 2. Version metadata (Distribution → 1.0)

### Promotional Text (≤170, editable anytime without review)
```
Never miss a cancellation deadline. EasyCancel tracks your subscriptions, watches the EU/UK 14-day cooling-off window, and helps you cancel before you're charged again.
```

### Description (≤4000)
```
Tired of paying for subscriptions you meant to cancel? EasyCancel helps you take back control — track every subscription, see what you really spend each month, and cancel on time using your legal rights.

WHY EASYCANCEL

Under EU and UK law you have a 14-day "cooling-off" right to withdraw from most online subscriptions. Miss the window and you're locked in. EasyCancel watches that deadline for you and helps you act before the next charge.

ADD A SUBSCRIPTION IN SECONDS
• Paste a confirmation email and EasyCancel fills in the merchant, amount and renewal dates for you
• Or add anything manually in a few taps
• See your total monthly spend at a glance

NEVER MISS THE DEADLINE
• Every subscription shows how many days are left in its cooling-off window
• Clear badges tell you what needs action now

CANCEL THE RIGHT WAY
• Generate a clean, GDPR-compliant withdrawal letter for any subscription
• Keep a record of every cancellation request in your Vault as evidence

BUILT FOR EUROPE
• Localised for English, German, French, Spanish, Italian, Dutch and Polish
• Country-aware guidance for Germany, the UK, France, Spain, Italy, the Netherlands and Poland

PRIVACY FIRST
• Your data is stored on EU-hosted infrastructure
• No ad tracking, ever
• Export or delete all your data at any time

EASYCANCEL PRO
Upgrade for unlimited subscription tracking and Family Sharing.
• Monthly or yearly plans
• 7-day free trial
Payment is charged to your Apple ID at confirmation of purchase. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in your App Store account settings.

Terms: https://vincli.com/docs/easyterms.pdf
Privacy Policy: https://vincli.com/docs/easyprivacy.pdf
```

### Keywords (≤100, comma-separated, no spaces — name & subtitle words are already indexed, so they're omitted)
```
unsubscribe,manage,tracker,money,save,budget,reminder,cooling off,refund,GDPR,bills,renewal,trial
```

### Support URL
```
https://vincli.com/docs/easysupport.pdf
```

### Marketing URL (optional)
```
https://vincli.com
```

### What's New in This Version (1.0)
```
First release of EasyCancel. Track your subscriptions, watch the EU/UK 14-day cooling-off window, and cancel on time with GDPR-ready withdrawal letters.
```

---

## 3. App Privacy (App Privacy → questionnaire)

_Based on the current build (Supabase auth + your own subscription records; no analytics/ads SDK
integrated). Must stay consistent with `Sources/Resources/PrivacyInfo.xcprivacy`._

**Do you or your third-party partners collect data? → Yes**

**Data Used to Track You: NONE** (NSPrivacyTracking=false; no ATT prompt needed)

**Data Linked to the user — purpose: App Functionality only:**
| Category | Type | Why |
|----------|------|-----|
| Contact Info | Email Address | Account sign-in / magic link |
| User Content | Other User Content | The subscription records the user enters |
| Identifiers | User ID | Supabase account identifier |

**Data Not Linked to the user:** none.

> If you later wire in PostHog/Sentry (in the spec, not in the build yet), add
> Usage Data (Analytics) and Diagnostics (App Functionality) and update PrivacyInfo.xcprivacy.

---

## 4. In-App Purchases (Monetization → Subscriptions)

These MUST be **auto-renewable subscriptions** under Monetization → **Subscriptions**
(NOT regular In-App Purchases — a regular IAP won't show in the paywall and can't carry the trial).
Create a **subscription group**, then two auto-renewable subscriptions.
⚠️ Product IDs must match the app **exactly**. NOTE: IDs are `.pro.month` / `.pro.year`
(NOT `.monthly`/`.yearly` — `app.easycancel.pro.monthly` was burned by a mistaken IAP that was deleted, and Apple won't reuse it):

**Subscription Group**
- Reference Name: `EasyCancel Pro`
- (Group display name shown to users: `EasyCancel Pro`)

**Subscription 1 — Monthly**
| Field | Value |
|-------|-------|
| Reference Name | Pro Monthly |
| Product ID | `app.easycancel.pro.month` |
| Duration | 1 Month |
| Price | €2.99 (pick the matching tier) |
| Introductory Offer | Free, 1 week (7-day free trial) |
| Family Sharing | ON |
| Display Name | EasyCancel Pro (Monthly) |

**Subscription 2 — Yearly**
| Field | Value |
|-------|-------|
| Reference Name | Pro Yearly |
| Product ID | `app.easycancel.pro.year` |
| Duration | 1 Year |
| Price | €19.99 (pick the matching tier) |
| Family Sharing | ON |
| Display Name | EasyCancel Pro (Yearly) |

> Both products need a localised display name + description and a review screenshot of the
> paywall before they can be submitted. They are submitted **together with** the app's first version.

---

## 5. App Review Information (Distribution → App Review)

- **Sign-in required?** No dedicated demo account needed.
- **Notes for reviewer:**
```
No login is required to evaluate the app — tap "Continue as guest" on the sign-in screen to access all features.

How cancellation works: EasyCancel tracks each subscription's cooling-off deadline and generates a withdrawal-letter template. The user shares/sends the letter themselves (tap a subscription → Cancel now → Send cancellation letter). The app does NOT contact merchants or send any email automatically.

To test the paywall: Settings → Upgrade to Pro. Use a Sandbox Apple ID; the monthly plan has a 7-day free trial.

Note: email-forward auto-detection is planned for a future update and is not part of this version.
```

> Don't put "coming in v2" in the **public Description** — Apple Guideline 2.3.1 forbids referencing unreleased features there. The reviewer note above is the right place; use your own marketing/changelog for the v2 teaser.

---

## 6. Pricing and Availability
- App price: **Free** (monetised via the Pro subscription above).
- Availability: launch markets — Germany, United Kingdom, France, Spain, Italy, Netherlands, Poland (expand as you like; the app is localised for these).

---

## 7. Screenshots (required) — GENERATED ✅
App is iPhone-only (`TARGETED_DEVICE_FAMILY=1`). Same four shots captured for both buckets:
1. `01-home.png` — monthly spend + subscription list + cooling-off badges
2. `02-detail.png` — subscription detail with the cooling-off countdown card
3. `03-letter.png` — GDPR withdrawal-letter preview (differentiator)
4. `04-settings.png` — account, privacy controls (export/delete), upgrade

- **`Screenshots/AppStore-6.5/`** — **1242 × 2688** → upload these to the **iPhone 6.5" Display** slot (this is what your ASC app currently requires).
- **`Screenshots/AppStore-6.9/`** — 1320 × 2868 (iPhone 6.9", in case ASC asks for that bucket).

Regenerate the 6.5" set from scratch:
```bash
UDID=$(xcrun simctl create EC-6.5in com.apple.CoreSimulator.SimDeviceType.iPhone-11-Pro-Max com.apple.CoreSimulator.SimRuntime.iOS-18-5)
xcrun simctl boot "$UDID"; sleep 6
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4
xcodebuild test -project EasyCancel.xcodeproj -scheme EasyCancel -destination "id=$UDID" \
  -only-testing:EasyCancelUITests/ScreenshotTests -resultBundlePath build/Screenshots65.xcresult
xcrun xcresulttool export attachments --path build/Screenshots65.xcresult --output-path build/screenshots65
# (6.9" set: same, but -destination 'id=1DB984E0-73C1-499C-9F04-EFF88A3CC7C1')
```

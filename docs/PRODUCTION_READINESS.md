# EasyCancel — Production Readiness

_Last updated: 2026-05-23_

**Verdict: not production-ready yet.** The codebase is feature-complete and
well-tested in automation, the live Supabase backend is verified, but several
launch prerequisites (App Store Connect, edge-function deploy, legal review,
real-device QA) are still outstanding. Target launch is **19 Jun 2026** (EU
Directive 2023/2673 deadline).

**Recently completed (2026-05-23):** App Icon added · GDPR Export/Delete wired
(was no-ops) · Sign-in Terms/Privacy now tappable · CI workflow added · 36 tests
green · Release build verified.

---

## 1. What's done & verified ✅

| Area | Status |
|------|--------|
| App build (Swift 6, iOS 17+) | ✅ clean |
| Automated tests | ✅ **36 passing** — 33 unit/integration + 3 XCUITest UI smoke |
| Onboarding + auth (guest/Apple/magic-link send) | ✅ built; guest+magic-link verified live |
| Email parsing (in-app paste) | ✅ unit-tested |
| Cooling-off tracking, Vault, Detail, Cancel letter preview | ✅ built |
| StoreKit 2 paywall + free-tier gate | ✅ built; products load (SKTestSession) |
| Supabase schema + RLS | ✅ verified live (insert/read own, isolation, negative) |
| `handle_new_user` trigger | ✅ verified live (email + guest) |
| Localization (7 languages) | ✅ 130 keys, German verified on device sim |
| Accessibility (Dynamic Type, VoiceOver labels, reflow) | ✅ done |
| Privacy manifest (`PrivacyInfo.xcprivacy`) | ✅ added |
| Security advisors | ✅ 0 lints |
| Git | ✅ initialized + committed |

---

## 2. Test coverage status

**Automated (run in CI/locally):**
- Unit: models, email parser, free-tier gate, auth store, country detection.
- Integration: StoreKit `SKTestSession` (products + trial), live RLS (via REST/SQL).
- UI (XCUITest, mock backend): onboarding → guest → add subscription → list; Settings → paywall.

**NOT covered by automation (manual / future):**
- ❌ Real IAP **purchase** end-to-end (tap-buy → transaction → entitlement → unlock). Only product loading is tested.
- ❌ **Apple Sign-In** (system UI; needs device + Apple Team).
- ❌ **Magic-link deep-link return** into the app (`app.easycancel://login-callback`).
- ❌ **Email-forward pipeline** (the `parse-email` edge function is not deployed/tested live).
- ❌ Cancel/withdrawal-letter send flow against live backend.
- ❌ Push notifications (table exists; not implemented in-app).

---

## 3. Launch blockers (must do before submission) 🚫

### App Store Connect
- [ ] Create the app record (bundle id `app.easycancel`).
- [ ] Create **in-app subscription products**: `app.easycancel.pro.monthly` (€2.99, 7-day free trial) and `app.easycancel.pro.yearly` (€19.99) in subscription group "EasyCancel Pro". _(`Configuration.storekit` is local-test only — real purchases fail without these.)_
- [ ] Fill the **privacy nutrition labels** (must match `PrivacyInfo.xcprivacy` + actual data: email, subscription data).
- [ ] Provide **demo guest** note in App Review Information (guest sign-in needs no creds — state that).

### Apple / Xcode
- [ ] Set a real **Apple Developer Team** for signing (`DEVELOPMENT_TEAM` in `project.yml` is unset; Sign in with Apple needs it).
- [ ] Configure **Sign in with Apple** capability in the Apple Developer portal for the app id.
- [x] App Icon added (green checkmark, `Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png`) — replace with final brand art if desired.
- [ ] Archive a **Release** build and upload via TestFlight.

### Supabase (dashboard / deploy)
- [x] Anonymous sign-ins enabled.
- [ ] Confirm **redirect URL** `app.easycancel://login-callback` is in Auth → URL Configuration (send works; deep-link return unverified).
- [ ] Deploy the **`parse-email` edge function** (`supabase functions deploy parse-email --no-verify-jwt`) and set its secrets (`SUPABASE_SERVICE_ROLE_KEY`, `MISTRAL_API_KEY`, `RESEND_WEBHOOK_SECRET`).
- [ ] Configure **Resend** inbound domain `inbox.easycancel.app` (MX + webhook → the edge function).
- [ ] Set up **email templates** + a verified sending domain for magic-link emails (currently using Supabase default).

### Legal / Web (compliance-critical for this app)
- [ ] **Withdrawal-letter templates**: legally reviewed + professionally translated per market (currently English-only by design — see `CancelConfirmationView.letterPreview`).
- [ ] Publish real **Terms** + **Privacy Policy** at `https://easycancel.app/terms` and `/privacy` (paywall + sign-in reference them).
- [x] GDPR **Export my data** (JSON share sheet) + **Delete account** wired (Settings). Delete purges the user's own rows (RLS delete-own policies added) + soft-deletes the profile (`deleted_at`) + signs out. ⚠️ Still TODO: a **service-role edge function / cron purge** to hard-delete the `auth.users` record (client can't). Delete is build-verified + RLS-verified, but not tap-tested against live.

---

## 4. Should do before launch ⚠️

- [ ] **Device QA**: run all auth paths (guest, Apple, magic-link tap) + a real sandbox purchase on a physical device.
- [x] Sign-in "Terms and Privacy Policy" are now **tappable links** (point at the placeholder URLs — publish the pages).
- [x] **Export my data** / **Delete account** wired (see §3 Legal/Web for the remaining hard-delete edge function).
- [x] **CI workflow** added (`.github/workflows/ci.yml`) — runs xcodegen + build + 36 tests (writes a placeholder `SupabaseConfig.swift` since the real one is gitignored).
- [ ] Decide & implement **push notifications** (cooling-off / renewal reminders — `notifications` table + pg_cron jobs exist).

---

## 5. Nice to have / post-launch

- [ ] Performance advisors: wrap RLS `auth.uid()` as `(select auth.uid())` (scale optimization).
- [ ] More XCUITest coverage (cancel flow, paywall purchase via StoreKit testing, localization snapshot tests).
- [ ] Widen mock `forwardingAddressLocal` parity (cosmetic; live trigger already widened to 8 chars).

---

## 6. Known issues & pending decisions

- **`SupabaseConfig.swift` is gitignored** → a fresh clone won't compile until it's recreated (holds the client-safe publishable key). Decide whether to commit it.
- **No git remote** configured.
- **Free-tier cap = 3** active subscriptions (`FreeTier.maxActiveSubscriptions`) — confirm the number.
- **Paywall benefit** changed from "All 7 languages" (untrue — localization is free) to **"Family Sharing"** — confirm.
- Paywall **Terms/Privacy URLs** are placeholders pointing at non-existent pages.

---

## 7. How to run the tests

```bash
cd EasyCancel
xcodegen generate
xcodebuild test -project EasyCancel.xcodeproj -scheme EasyCancel \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```
UI tests force the offline mock via the `-uiTest` launch argument, so they never
touch the live Supabase backend.

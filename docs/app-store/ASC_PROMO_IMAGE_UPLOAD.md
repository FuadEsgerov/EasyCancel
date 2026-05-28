# App Store Connect — Promoted IAP Image Upload Guide

**Purpose:** Replace the two duplicate Promoted In-App Purchase images for `app.easycancel.pro.month` and `app.easycancel.pro.year` to resolve App Store Review rejection **Guideline 2.3.2 — Accurate Metadata** (duplicate promotional artwork).

**Prerequisites — must be done before starting:**

1. The two new unique PNGs exist at:
   - `/Users/fuadasgarov/Documents/AllProjects/EasyCancel/MarketingAssets/PromotedIAP/pro-monthly.png`
   - `/Users/fuadasgarov/Documents/AllProjects/EasyCancel/MarketingAssets/PromotedIAP/pro-yearly.png`
2. Each PNG is **1024 × 1024 px**, sRGB, no alpha, < 5 MB.
3. The two images are **visually distinct** (different colour, hero copy, badge — not just a "Monthly" vs "Yearly" word swap on the same artwork).
4. You are signed in to <https://appstoreconnect.apple.com> with the EasyCancel Apple ID (Account Holder or Admin role).

---

## Path A — Replace the promotional images (recommended)

Choose this path if you **do** want Pro Monthly and Pro Yearly to appear in the App Store "Promoted In-App Purchases" browse area / in-app store widget.

### Step 1 — Open the Subscriptions section

EasyCancel's Pro plans are **auto-renewable subscriptions**, so they live under **Subscriptions**, not the legacy "In-App Purchases" list.

1. Sign in → <https://appstoreconnect.apple.com>.
2. Click **My Apps**.
3. Click the **EasyCancel** tile.
4. In the left sidebar, click **Monetization → Subscriptions**.
5. You should see your Subscription Group (e.g. "EasyCancel Pro") containing both products.

### Step 2 — Replace the image for `app.easycancel.pro.month`

1. Click the subscription group name to expand it.
2. Click **Pro Monthly** (Product ID: `app.easycancel.pro.month`).
3. Scroll down to the **Promoted In-App Purchase** section (it sits below "App Store Localization" and above "Review Information").
4. Confirm the toggle **"Display In-App Purchase on App Store"** is **ON** (blue).
5. Under the existing 1024×1024 promotional image, click the image itself (or the **Edit** / pencil icon).
6. In the popover, click **Delete** (or **Remove**) to clear the current image.
7. Click **Choose File** / drag-and-drop **`pro-monthly.png`** from `MarketingAssets/PromotedIAP/`.
8. Wait for the upload to finish (a green checkmark appears).
9. Click **Save** at the top-right of the page.
10. Verify the new thumbnail is now shown and the status reads **"Ready to Submit"** or **"In Review"** (not "Missing Metadata").

### Step 3 — Repeat for `app.easycancel.pro.year`

1. Use the breadcrumb to go back to the Subscription Group.
2. Click **Pro Yearly** (Product ID: `app.easycancel.pro.year`).
3. Repeat steps 3 – 10 from Step 2, uploading **`pro-yearly.png`** instead.

### Step 4 — Sanity check

Before contacting the reviewer, open both products one more time and confirm:

- The two thumbnails are visibly different from each other.
- Neither thumbnail matches any of your App Store **screenshots**.
- "Display In-App Purchase on App Store" is ON for both.
- Status for both reads **Ready to Submit** (or stays **In Review** if the parent app submission is still pending — that is fine).

---

## Path B — Remove the promotion entirely (alternative)

Choose this path if you do **not** actually need Pro Monthly / Pro Yearly to surface in the App Store browse pages — many apps only sell IAPs in-app and skip Promoted IAPs altogether. This also fully resolves 2.3.2 because the duplicate artwork is no longer published.

For **each** of the two products (`.month` and `.year`):

1. **My Apps → EasyCancel → Monetization → Subscriptions → [product name]**.
2. Scroll to **Promoted In-App Purchase**.
3. Click the existing image → **Delete** (do **not** upload a replacement).
4. **Untick / toggle off** "Display In-App Purchase on App Store".
5. Click **Save**.

After both products are toggled off, the "Promoted In-App Purchase" section becomes empty/disabled — the reviewer can no longer see duplicate art because there is no art to compare.

> Recommendation: **Use Path A.** Promoted IAPs are free marketing surface on the App Store. Only fall back to Path B if you genuinely don't want this app surfaced via in-store promotion.

---

## Step 5 — Reply in Resolution Center

1. Top nav → **App Store Connect** logo → **My Apps** → **EasyCancel**.
2. Click the yellow / red **"App Review"** banner at the top of the app page, **or** open the left sidebar **App Review → Resolution Center**.
3. Open the latest message thread from App Review (subject mentions Guideline 2.3.2).
4. Click **Reply**.
5. Paste the contents of:
   ```
   /Users/fuadasgarov/Documents/AllProjects/EasyCancel/docs/app-store/RESUBMISSION_REPLY_2.3.2.md
   ```
   (Open the .md file → copy the body — do not paste the markdown front-matter / heading prefix if any.)
6. Click **Send**.

---

## Step 6 — Resubmit (metadata-only vs new build)

**Short answer:** For a 2.3.2 rejection caused by **metadata only** (Promoted IAP artwork is metadata, not code), you do **not** need to upload a new build. Apple lets you fix the metadata in place and the same submission record continues through review.

### Decision tree

- **You only changed the two Promoted IAP images?** → **Metadata-only resubmit.**
  1. Go to **App Store → iOS App → 1.0 (Prepare for Submission / In Review)**.
  2. If the submission was **rejected** and is no longer in review, scroll to the bottom and click **Submit for Review** again. Apple picks up the new images automatically.
  3. If the submission is **still in review**, the Resolution Center reply alone usually suffices — the reviewer fetches the latest metadata when they revisit.
  4. No need to bump build number. Stay on **v1.0 build 4**.

- **You also changed Swift code, Info.plist, entitlements, or assets shipped inside the .ipa?** → **New build required.**
  1. In Xcode: bump build number to **5** (Project → Target → General → Build).
  2. Archive (Product → Archive) → **Distribute App → App Store Connect → Upload**.
  3. Wait for processing email (~15 min).
  4. Back in App Store Connect → **App Store → 1.0** → under **Build**, click the **+** / pencil → select **1.0 (5)** → **Save**.
  5. Click **Submit for Review** again.

For this rejection (duplicate Promoted IAP image only), **Path = metadata-only, stay on build 4**.

---

## Step 7 — Monitor

After resubmission:

- Status under **App Store → 1.0** should change from **Developer Rejected / Metadata Rejected** to **Waiting for Review** within minutes.
- Median re-review for metadata-only fixes is **< 24 h**.
- Apple emails you on status changes; also watch the **Resolution Center** thread for follow-up questions.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Upload button is greyed out | The product status is **Removed from Sale** or **Developer Action Needed** — fix the higher-level issue first (pricing, tax, agreements). |
| "Image dimensions are invalid" | PNG is not exactly **1024 × 1024**. Re-export at that exact size, sRGB, no alpha. |
| "Image must not contain transparency" | Flatten alpha in Preview: File → Export → uncheck Alpha, save as PNG. |
| New image still shows old thumbnail | Hard refresh the browser (Cmd-Shift-R). ASC caches thumbnails for ~60 s. |
| Resolution Center reply box is missing | The case is closed — open a new one via **Contact Us → App Review → Resubmit Issue**. |
| Submit for Review button is disabled | Some other section (e.g. Age Rating, Privacy) now shows red — fix it, then resubmit. |

---

## Reference

- Apple — Promoting Your In-App Purchases: <https://developer.apple.com/app-store/promoting-in-app-purchases/>
- App Store Review Guideline 2.3.2: <https://developer.apple.com/app-store/review/guidelines/#accurate-metadata>
- Promoted IAP image spec (1024×1024, PNG/JPEG, sRGB, no alpha, < 5 MB).

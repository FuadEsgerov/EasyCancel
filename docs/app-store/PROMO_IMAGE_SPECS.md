# Promoted In-App Purchase Promotional Image — Apple Spec Sheet

Authoritative requirements for the promotional images attached to each promoted
IAP on the App Store. Aligns EasyCancel with **App Review Guideline 2.3.2**
(Accurate Metadata) and Apple's "Promoting your in-app purchases" guidance.

Audience: `monthly-design`, `yearly-design` (and any future IAP designers).
Scope: rules only — no creative direction.

---

## 1. Dimensions

| Property | Required Value |
|---|---|
| Width  | **1024 px** |
| Height | **1024 px** |
| Aspect ratio | **1 : 1 (square)** |
| Pixel density | 1x (no @2x / @3x variants — single master file) |

Image is rendered at small sizes in product pages, Today/Apps/Games tabs, and
search results, so the design must remain legible when scaled down.

## 2. Format & Color

| Property | Required Value |
|---|---|
| File format | **PNG** (preferred) or high-quality **JPEG** |
| Color space | **sRGB** (Display P3 acceptable; do not use CMYK or untagged) |
| Bit depth | 8-bit per channel |
| Transparency / alpha | **None.** Background must be fully opaque |
| Layers | Flattened — single composite image |
| Compression | Lossless PNG, or JPEG at maximum quality |

## 3. Content Rules — what the image MUST NOT contain

These are the rules whose violation triggers Guideline 2.3.2 rejections.

- **Must not be identical or confusingly similar to the app icon.** This was
  EasyCancel's rejection trigger — the promo image and the app icon were the
  same artwork.
- **Must not be duplicated across promoted products.** Monthly and Yearly
  must each have a **distinct, unique** image. Reusing the same artwork for
  multiple IAPs (or win-back / introductory offers) is a 2.3.2 violation.
- **Must not be a screenshot of the app, the App Store, or any device chrome.**
- **No App Store badges** ("Download on the App Store", star ratings, "Editor's
  Choice", etc.).
- **No Apple logos**, Apple product imagery, or Apple trademarks.
- **No currency prices** in the artwork (e.g. "£4.99/month"). Prices are
  region-dependent and shown by the system separately.
- **No platform references** ("Also on Android", "Web version available").
- **No misleading content** — must accurately represent the specific IAP it
  promotes (Monthly vs Yearly must be visually distinguishable and each must
  represent its own product).
- **4+ age-rating safe content** even though EasyCancel will be rated higher
  if needed — Apple requires promo art to meet a 4+ bar regardless.
- **No overlaid marketing text** is recommended by Apple ("you don't overlay
  text on the image"). Short product wordmarks are tolerated in practice, but
  long taglines / feature lists should be avoided.

## 4. Content Rules — what the image SHOULD do

- **Represent the specific IAP**, not the app as a whole. The image is the
  visual identity of that one product.
- **Differentiate Monthly vs Yearly** unambiguously through colour, shape,
  iconography, or layout — never rely on text alone since the system overlays
  the localised display name separately.
- **Be recognisable at thumbnail size** (think ~80–120 px on a phone).

## 5. Safe Area & Cropping

Apple applies its own framing/mask system around the uploaded image to match
App Store visual style. To survive that:

- Keep all critical content (logo, focal subject, key shapes) within the
  **centre 80 %** of the canvas — roughly a 100 px inset on every edge.
- **Avoid the lower-left corner** in particular — Apple has historically
  placed framing UI there.
- Don't push text or important detail to the bleed edges.
- Don't rely on the corners being square — Apple may round / mask them.

## 6. Localisation

- One image per locale is supported, but **not required**.
- For v1 launch (English-only metadata): **a single English image per IAP is
  acceptable**. EasyCancel's IAP display names are not heavily text-based, so
  one master image per product covers all locales we ship at launch.
- If localised art is added later, each locale must still follow every rule
  above independently.

## 7. Deliverable Checklist (for designers)

Before handing back to the dev team, each image must pass:

- [ ] 1024 × 1024 px, exactly square
- [ ] PNG (or max-quality JPEG), sRGB, no alpha / transparency
- [ ] Visually distinct from the EasyCancel app icon (different composition,
      not just a recolour)
- [ ] Monthly image and Yearly image are visually distinct from each other
- [ ] No App Store badges, no Apple logos, no currency prices, no platform
      mentions, no screenshots
- [ ] No overlaid marketing copy (short wordmark only, if any)
- [ ] Critical content within centre 80 %; lower-left corner kept clean
- [ ] Reads clearly at ~120 px thumbnail size
- [ ] Content is 4+ age-rating safe

## 8. Sources

- Apple — *Promoting your in-app purchases*:
  https://developer.apple.com/app-store/promoting-in-app-purchases/
- Apple — *App Review Guidelines* (3.1.1 + 2.3.2):
  https://developer.apple.com/app-store/review/guidelines/
- App Store Connect Help — *Promote In-App Purchases*:
  https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/promote-in-app-purchases/
- App Store Connect Help — *View and edit In-App Purchase information*:
  https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/view-and-edit-in-app-purchase-information/

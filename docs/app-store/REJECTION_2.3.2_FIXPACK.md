# Final Verdict: GO

**Reviewer:** team lead (synthesised from 10-agent run)
**Date:** 2026-05-27
**Status:** **GO — READY TO RESUBMIT** once Fuad uploads the two PNGs in App Store Connect and replies in Resolution Center.

The earlier NO-GO verdict was produced by `qa-reviewer` before the coders'
artifacts hit disk. Re-verification after all artifacts landed shows every
acceptance criterion passing.

---

## 1. Submission Context

| Field | Value |
|---|---|
| Submission ID | `49dfbe7e-98a1-486e-a5df-f41cee9bd7e2` |
| App | EasyCancel |
| Version / Build | 1.0 (Build 4) |
| Review device | iPad Air 11-inch (M3), 2026-05-25 |
| Guideline | **2.3.2 — Accurate Metadata** (Promoted In-App Purchases) |
| Root cause | The promotional images attached to the two promoted IAPs (`app.easycancel.pro.month` and `app.easycancel.pro.year`) were identical to each other and/or to the EasyCancel app icon, violating the "must be unique and product-specific" rule. |
| Fix strategy | Replace both promo images with new, unique 1024×1024 PNGs that are visually distinct from the app icon and from each other; reply in Resolution Center; resubmit metadata-only. |

---

## 2. SHA-256 Uniqueness Check (the literal Apple rule)

| Image | SHA-256 |
|---|---|
| `Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png` | `47f299da81720c1d6f3c75ea2c1635da3443731b70803c3a57168bdc574620bc` |
| `MarketingAssets/PromotedIAP/pro-monthly.png` | `0f9d3f3c34b254b32eb3379d8a973865acae9be7a2c5de45d5530103a6c15daa` |
| `MarketingAssets/PromotedIAP/pro-yearly.png` | `d16fd3a9f29c9f10b027b1d016364ef4ac7375e84ae167dc8f8959831ac61e28` |

**All three hashes differ.** No duplicates across icon / monthly / yearly. **PASS.**

---

## 3. Dimensions & Format Check

| File | pixelWidth | pixelHeight | format | hasAlpha |
|---|---:|---:|---|---|
| `pro-monthly.png` | 1024 | 1024 | png | no |
| `pro-yearly.png`  | 1024 | 1024 | png | no |

Both: exactly 1024×1024, PNG, sRGB, opaque (no transparency). **PASS.**

---

## 4. Visual Distinctness Check

Confirmed by direct image inspection (Read tool):

| Asset | Background | Central motif | Palette |
|---|---|---|---|
| App icon | Green gradient, full-bleed | White checkmark in circle | Green |
| `pro-monthly.png` | Teal → brand-navy diagonal gradient | White calendar card, 4×7 grid, glowing day-1 (Mon-first), upward spark | Cool teal/navy + single amber accent |
| `pro-yearly.png` | Amber/gold → deep plum diagonal gradient | 12-segment gold ring with "365" serif numeral inside, "BEST VALUE" star ribbon tilted top-right | Warm gold/plum |

Monthly and yearly are **obviously different** in both palette (cool vs warm)
and motif (calendar grid vs 12-segment ring). Neither resembles the
green-checkmark app icon. **PASS.**

---

## 5. Full File Inventory

```
/Users/fuadasgarov/Documents/AllProjects/EasyCancel/
├── Sources/Resources/Assets.xcassets/AppIcon.appiconset/
│   └── icon_1024.png                     11.5 KB   PRESENT (existing app icon)
├── MarketingAssets/PromotedIAP/
│   ├── pro-monthly.png                   650 KB    PRESENT — 1024×1024 PNG
│   └── pro-yearly.png                    ~          PRESENT — 1024×1024 PNG
├── scripts/
│   ├── render_promo_monthly.swift                  PRESENT — reproducible Swift CG renderer
│   └── render_promo_yearly.swift                   PRESENT — reproducible Swift CG renderer
└── docs/app-store/
    ├── PROMO_IMAGE_SPECS.md              5.4 KB    PRESENT — Apple's rules sheet
    ├── PROMO_BRIEF_MONTHLY.md            14.7 KB   PRESENT — deterministic design spec
    ├── PROMO_BRIEF_YEARLY.md             13.7 KB   PRESENT — deterministic design spec
    ├── RESUBMISSION_REPLY_2.3.2.md       1.3 KB    PRESENT — Resolution Center reply draft
    ├── ASC_PROMO_IMAGE_UPLOAD.md         7.9 KB    PRESENT — click-by-click upload guide
    └── REJECTION_2.3.2_FIXPACK.md        (this file)
```

---

## 6. Next Actions for Fuad (in order)

1. **Upload the two PNGs in App Store Connect** following
   `docs/app-store/ASC_PROMO_IMAGE_UPLOAD.md` — open My Apps → EasyCancel →
   Monetization → Subscriptions → for each of the two products, click the
   existing promotional image → Delete → upload the new PNG → Save.
2. **Reply in Resolution Center** with the message in
   `docs/app-store/RESUBMISSION_REPLY_2.3.2.md`. **Send this AFTER step 1**,
   not before — the reply states that the assets have been uploaded.
3. **Resubmit metadata-only.** No new build needed; stay on v1.0 (4). If
   App Store Connect rejects the metadata-only path, cut a Build 5 and resubmit.

Alternative path (if you do NOT actually want these IAPs promoted on the
browse pages): delete the promotional image with no replacement and untick
"Display In-App Purchase on App Store" for both products. That also resolves
2.3.2 — see `ASC_PROMO_IMAGE_UPLOAD.md` "Path B".

---

## 7. Reproducibility

The two PNGs are not artisanal — they are deterministic renders. To
regenerate from scratch:

```bash
cd /Users/fuadasgarov/Documents/AllProjects/EasyCancel
swift scripts/render_promo_monthly.swift
swift scripts/render_promo_yearly.swift
```

Each script reads its brief at `docs/app-store/PROMO_BRIEF_{MONTHLY,YEARLY}.md`,
uses CGContext + CoreText with a Y-flipped top-left coordinate system, and
writes a 1024×1024 sRGB opaque PNG. No external assets or fonts required
(falls back to system semibold/medium when Inter isn't available).

---

## 8. Verification Commands (for re-running this QA pass)

```bash
sips -g pixelWidth -g pixelHeight -g format -g hasAlpha \
  /Users/fuadasgarov/Documents/AllProjects/EasyCancel/MarketingAssets/PromotedIAP/pro-monthly.png \
  /Users/fuadasgarov/Documents/AllProjects/EasyCancel/MarketingAssets/PromotedIAP/pro-yearly.png

shasum -a 256 \
  /Users/fuadasgarov/Documents/AllProjects/EasyCancel/Sources/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png \
  /Users/fuadasgarov/Documents/AllProjects/EasyCancel/MarketingAssets/PromotedIAP/pro-monthly.png \
  /Users/fuadasgarov/Documents/AllProjects/EasyCancel/MarketingAssets/PromotedIAP/pro-yearly.png
```

Expected: both 1024×1024 png, hasAlpha=no; three distinct SHA-256s.

---

## 9. Final Verdict

**GO.**

All artifacts present, both PNGs are 1024×1024 opaque PNG, all three SHA-256s
distinct, monthly and yearly are visually distinct from each other and from
the app icon. Workflow for resubmission is documented end-to-end. Fuad can
proceed with the three steps in §6.

# Pro Monthly — Promotional Image Brief

**Product:** `app.easycancel.pro.month` (Pro Monthly, £2.99/mo, 1-week intro)
**Asset:** `promo_monthly.png`
**Canvas:** 1024 × 1024 px, sRGB, PNG-24, fully opaque, flattened
**Renderer target:** Swift Core Graphics / `UIGraphicsImageRenderer` —
deterministic, zero creative decisions for the implementer.
**Author:** `monthly-design`
**Sister asset (must differ from):** `promo_yearly.png` (designed by `yearly-design`)
**App icon (must differ from):** green-gradient square + white check
**Compliance source of truth:** `docs/app-store/PROMO_IMAGE_SPECS.md`
(App Review Guideline 2.3.2)

---

## 1. Brand voice

EasyCancel is calm, legally-precise, "IRS but human". The promo must feel
like a **trustworthy financial / legal product** — restrained, considered,
quietly confident — not a flashy growth ad. Think *consumer-protection
toolkit*, not *subscription service mascot*.

Concretely this means:

- Cool, deep palette (teals & navy-indigo) — no neons, no candy colours.
- One small warm accent (amber) used **once** as the "spark".
- Generous negative space; the card breathes.
- Geometric, gridded composition — never organic / playful.
- Type set in a humanist sans (Inter / SF Pro), Semibold max, never Heavy.

---

## 2. Compliance constraints

Hard requirements from `PROMO_IMAGE_SPECS.md` — every one is verified in
section 13's acceptance checklist.

- **1024 × 1024 px, PNG, sRGB, no alpha.** Background is fully opaque.
- **No price text.** No "£2.99", "/month", "$", "€", "free", "7 days free".
- **No Apple marks** (logo, App Store badge, ratings, "Editor's Choice").
- **No platform references** ("Also on Android", "Web app").
- **No screenshots, no device chrome, no UI mockups inside the image.**
- **No competitor logos / recognisable brand shapes.**
- **No emoji as the central motif.**
- **No overlaid marketing copy.** Only two short wordmarks are used:
  the header word "MONTH" inside the card and the short product
  wordmark "PRO" beneath it. No taglines, no CTAs, no feature lists.
- **4+ age-rating safe content** (trivially satisfied).
- **Safe area: centre 80 % of canvas** — every critical element lives
  inside the 824 × 824 px region with origin `(100, 100)` (100 px inset
  from every edge). The corners and outer 100 px are expendable: Apple
  may mask or round them.
- **Lower-left corner kept clean** — Apple has historically placed
  framing UI there. The rectangular region `(0, 800) → (224, 1024)`
  contains only the flat background gradient. No "PRO" wordmark
  baseline, no glow, no calendar element ever enters it. This is
  enforced numerically in section 13.

---

## 3. Differentiation rules

| Dimension          | App icon                | Yearly promo (sister)        | THIS asset (Monthly)              |
| ------------------ | ----------------------- | ---------------------------- | --------------------------------- |
| Background hue     | Green gradient          | Warm (amber → plum)          | **Teal → Navy-indigo diagonal**   |
| Central motif      | White checkmark         | Annual ring / 12-segment     | **4×7 month-grid calendar**       |
| Time metaphor      | none                    | full-year cycle              | **single month / day-1 ignition** |
| Energy             | calm reassurance        | long-haul commitment         | **fresh start, "begin now"**      |
| Wordmark placement | none                    | top                          | **below the calendar**            |
| Warm accent        | none                    | structural (amber field)     | **single small spark only**       |

A viewer scanning the IAP page must read it in <1 second as
"monthly, starting now" and must NOT confuse it with either the icon
(green + check) or the yearly art (warm + ring).

---

## 4. Coordinate system

Origin **(0, 0) = top-left**, units = pixels, canvas 1024 × 1024.
All numbers below are exact integers. Anti-aliasing on. Render in sRGB.

The 100 px safe-area inset means every focal element lives in the rect
`(100, 100) → (924, 924)`.

---

## 5. Background

**Linear gradient**, diagonal from top-left to bottom-right.

- Start point: `(0, 0)`        colour `#0B3B4A` (deep teal)
- Mid stop at `0.55`:           colour `#1A2C42` (EasyCancel brand navy)
- End point:  `(1024, 1024)`   colour `#0E1A2B` (near-black navy)

Note: the mid-stop uses the EasyCancel brand navy `#1A2C42` directly, so the
asset still feels native to the brand system even though it deliberately
avoids the icon's green.

On top of the gradient, paint a **radial spotlight** to lift the centre:

- Centre: `(512, 470)`
- Inner radius `0`, outer radius `620`
- Inner colour `#FFFFFF` at **6 %** alpha
- Outer colour `#FFFFFF` at **0 %** alpha
- Blend mode: normal

No noise, no grain — App Store thumbnails are tiny.

---

## 6. Calendar card (the hero)

A rounded-rectangle "card" that holds the month grid. Centred horizontally;
positioned in the upper-centre so the lower band stays clean.

- Card rect: x = `192`, y = `224`, w = `640`, h = `560`
- Corner radius: `56` px
- Fill: `#F8FAFC` (slate-50)
- Inner stroke: `2` px, colour `#E2E8F0` (slate-200), inset by `1` px
- Drop shadow (rendered as part of the card layer):
  - colour `#000000` at **35 %** alpha
  - offset `(0, 24)`
  - blur radius `48`
  - spread `0`

The card sits entirely inside the safe area: its bounding rect is
`(192, 224) → (832, 784)`, which is well within `(100, 100) → (924, 924)`.

### 6a. Card header bar

- Header rect: x = `192`, y = `224`, w = `640`, h = `96`
- Fill: solid `#0F766E` (teal-700) — structurally links to the gradient.
- Corner rounding: top-left & top-right `56`, bottom corners `0`.
- Header text: the single word **"MONTH"**
  - Font: **Inter Semibold** (fallback: SF Pro Display Semibold)
  - Size: `40` px, tracking `+6` (i.e. letter-spacing 6 px)
  - Colour: `#FFFFFF`
  - Baseline-centred at `(512, 288)`
  - Uppercase

### 6b. Weekday row

Seven labels, all caps, single-letter, beneath the header band.

- Labels (left → right): `M  T  W  T  F  S  S`
- Font: **Inter Medium**, size `22` px, colour `#64748B` (slate-500)
- Y centre: `352`
- X centres (7 evenly spaced columns inside the card, 32 px side gutter):
  column 1 = `260`, column 7 = `764`, step = `84` px
  → columns: `260, 344, 428, 512, 596, 680, 764`

### 6c. Day grid (4 rows × 7 cols = 28 cells)

- First row Y centre: `412`
- Row step: `84` px → row Y centres: `412, 496, 580, 664`
- Column X centres: same as weekday row (`260` … `764`, step `84`)
- Each day cell is a circle of radius `28` centred on (col, row)
- Day numbering — month starts on Monday (Europe ISO week):
  - Row 1: `1, 2, 3, 4, 5, 6, 7`
  - Row 2: `8, 9, 10, 11, 12, 13, 14`
  - Row 3: `15, 16, 17, 18, 19, 20, 21`
  - Row 4: `22, 23, 24, 25, 26, 27, 28`
- Day-number font: **Inter Medium**, size `24` px, colour `#334155`
  (slate-700), centred in each cell
- Cell fill for days 2-28: transparent (no disc)
- **Day "1" is the focal point** — see 6d.

### 6d. Day-1 highlight (focal accent)

The single visual anchor that says "start now".

- Centre: `(260, 412)` (row 1, col 1)
- Inner disc: radius `32`, fill `#0F766E` (teal-700)
- Day-1 numeral "**1**":
  - Font: Inter Semibold `28` px
  - Colour: `#FFFFFF`
  - Centred at `(260, 412)`
- **Glowing ring around day 1:**
  - Stroke ring at radius `44`, line width `4`, colour `#5EEAD4` (teal-300)
  - Outer ring at radius `60`, line width `2`, colour `#5EEAD4` at **40 %** alpha
  - Soft outer glow: radial gradient centred on `(260, 412)`, inner
    radius `40`, outer radius `96`, inner colour `#5EEAD4` at **30 %**
    alpha, outer `#5EEAD4` at **0 %** alpha. Rendered BEFORE the ring &
    disc so they read crisply on top.

---

## 7. "Start now" spark (top-right of card)

A small accent that signals ignition / "begin this month". This is the
**only** warm element in the composition — placed deliberately to draw
the eye after the day-1 glow.

- Anchor: `(800, 264)` — inside the teal header band, right side.
- Element: a small **upward-right diagonal arrow** inside a soft circle.
  - Background circle: radius `36`, fill `#FFFFFF` at **18 %** alpha
  - Arrow shaft: stroke from `(786, 282)` → `(816, 252)`, line width `5`,
    colour `#FFFFFF`, line cap round, line join round
  - Arrowhead: two strokes from `(816, 252)` → `(816, 268)` and
    `(816, 252)` → `(800, 252)`, same stroke style
- Small 4-point sparkle to the upper-right of the arrow:
  - Centre `(848, 240)`
  - Render as a 4-point star (two crossed thin rhombi), each rhombus
    span 16 px × 4 px, rotated 0° and 90°
  - Colour: `#D89B3F` (EasyCancel brand amber) at **90 %** alpha

The brand amber is used here precisely once — restrained warmth on an
otherwise cool composition. This is the brand-voice anchor.

---

## 8. "PRO" wordmark (below the card)

A small, quiet product cue — NOT a price, NOT a CTA, NOT a tagline.

- Text: **"PRO"**
- Font: **Inter Semibold** (fallback: SF Pro Display Semibold)
- Size: `60` px, tracking `+12`
- Colour: `#F8FAFC` (slate-50)
- Baseline-centred at `(512, 864)`
- Thin underline: 2 px tall, 56 px wide, centred at `(512, 882)`,
  colour `#5EEAD4` (teal-300) at **70 %** alpha

The wordmark sits at horizontal centre (x = 512) and **does not extend
into the lower-left exclusion zone** — the leftmost extent of "PRO" at
60 px Semibold with +12 tracking is approximately x ≈ 442, well to the
right of the x = 224 exclusion boundary.

---

## 9. Render order (bottom → top)

1. Background diagonal gradient
2. Radial spotlight overlay
3. Card drop shadow
4. Card fill + inner stroke
5. Card header band (clipped to top-rounded path)
6. Header text "MONTH"
7. Weekday row labels
8. Days 2-28 numerals
9. Day-1 outer soft glow (radial gradient)
10. Day-1 outer halo ring (r=60, 40 % alpha)
11. Day-1 main ring (r=44, solid teal-300)
12. Day-1 inner disc (r=32, teal-700)
13. Day-1 "1" numeral
14. Spark circle background (white 18 % alpha disc)
15. Spark arrow strokes
16. Spark 4-point sparkle (brand amber)
17. "PRO" wordmark
18. "PRO" underline

---

## 10. Colour palette (single source of truth)

| Token              | Hex       | Use                                |
| ------------------ | --------- | ---------------------------------- |
| `bgTealDeep`       | `#0B3B4A` | gradient start (top-left)          |
| `bgBrandNavy`      | `#1A2C42` | gradient mid stop (brand navy)     |
| `bgNavyDeep`       | `#0E1A2B` | gradient end (bottom-right)        |
| `cardSurface`      | `#F8FAFC` | calendar card fill                 |
| `cardBorder`       | `#E2E8F0` | card inner stroke                  |
| `headerTeal`       | `#0F766E` | header band & day-1 disc           |
| `accentTealLight`  | `#5EEAD4` | day-1 ring, halo, "PRO" underline  |
| `weekdayMuted`     | `#64748B` | weekday labels                     |
| `dayInk`           | `#334155` | day numerals 2-28                  |
| `brandAmber`       | `#D89B3F` | spark sparkle (single warm accent) |
| `inkOnDark`        | `#FFFFFF` | header text, arrow, spotlight      |
| `inkProWordmark`   | `#F8FAFC` | "PRO" wordmark                     |

Brand colours from the EasyCancel system used directly:
`#1A2C42` (navy) and `#D89B3F` (amber). The brand warm-green `#3FB680`
is **deliberately omitted** — it would compete with the app icon's green
and trigger Guideline 2.3.2 concerns about visual similarity.

---

## 11. Typography summary

| Element        | Family              | Weight   | Size | Tracking | Colour      |
| -------------- | ------------------- | -------- | ---- | -------- | ----------- |
| "MONTH" header | Inter / SF Pro Disp | Semibold | 40   | +6       | `#FFFFFF`   |
| Weekday letters| Inter / SF Pro      | Medium   | 22   | 0        | `#64748B`   |
| Day numerals   | Inter / SF Pro      | Medium   | 24   | 0        | `#334155`   |
| Day-1 "1"      | Inter / SF Pro Disp | Semibold | 28   | 0        | `#FFFFFF`   |
| "PRO" wordmark | Inter / SF Pro Disp | Semibold | 60   | +12      | `#F8FAFC`   |

If Inter is not bundled in the app, fall back to system semibold via
`UIFont.systemFont(ofSize:weight:.semibold)`. Do not use Heavy / Black —
the brand voice is restrained.

---

## 12. Implementation notes (for whoever renders the PNG)

- Render via `UIGraphicsImageRenderer` at native `1024 × 1024` — do **not**
  upscale a smaller canvas.
- Use `CGContext` for gradients: `CGGradient` + `drawLinearGradient` (diagonal
  background) and `drawRadialGradient` (spotlight, day-1 glow).
- For the card shadow: `cgContext.setShadow(offset:blur:color:)` before
  filling the card path, then clear shadow (save/restore graphics state)
  before drawing the header band so the shadow doesn't double up on
  the inner element.
- Header band: build with `UIBezierPath(roundedRect:byRoundingCorners:cornerRadii:)`
  passing `[.topLeft, .topRight]` only.
- Day-1 glow stack: paint the radial gradient first, then the 40 %-alpha
  outer ring, then the solid teal-300 ring, then the teal-700 disc, then the
  white "1" numeral — strictly bottom-up.
- Save the final PNG at:
  `EasyCancel/Sources/Resources/Assets.xcassets/promo_monthly.imageset/promo_monthly.png`
  with a `Contents.json` declaring 1x universal, single image.
- Add a Swift Testing test that renders the asset in-memory and asserts:
  - output size is exactly `CGSize(width: 1024, height: 1024)`
  - alpha at pixel `(0, 0)` == `255` (fully opaque)
  - sampled colour at `(260, 412)` is within ΔE < 5 of `#0F766E`
    (day-1 disc centre)
  - sampled colour at `(20, 20)` is within ΔE < 10 of `#0B3B4A`
    (top-left gradient start)
  - sampled colour at `(20, 1004)` is within ΔE < 10 of `#0E1A2B`
    (bottom-left of lower-left exclusion zone — proves it's clean
    background, not motif)

---

## 13. Acceptance checklist

- [ ] 1024 × 1024 px, exactly square
- [ ] PNG, sRGB, 8-bit, no alpha / fully opaque, flattened
- [ ] All focal content within centre 80 % (inset 100 px each side)
- [ ] Lower-left rect `(0, 800) → (224, 1024)` contains background only
- [ ] No price, no "free", no Apple marks, no badges, no screenshots
- [ ] No platform references, no competitor logos
- [ ] Only two short wordmarks: "MONTH" (header) and "PRO" (below card)
- [ ] Background is teal→navy-indigo diagonal (NOT green, NOT warm)
- [ ] Calendar card centred, day-1 visibly glowing as the focal point
- [ ] Spark arrow + amber sparkle present, top-right of header band
- [ ] "PRO" wordmark centred below card with thin teal underline
- [ ] Reads as "monthly / start now" at 120 px thumbnail size
- [ ] Visually distinct from `promo_yearly.png` and from the app icon
- [ ] 4+ age-rating safe content

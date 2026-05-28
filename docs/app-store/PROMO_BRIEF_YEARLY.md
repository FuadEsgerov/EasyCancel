# Promotional Image Brief — Pro Yearly

**Product:** `app.easycancel.pro.year` ("Pro Yearly", £19.99/year, ~44% saving vs monthly)
**Output:** Single PNG, **1024 x 1024 px**, sRGB, opaque (no alpha), file name
`promo_pro_yearly.png`.
**Renderer:** Swift / Core Graphics (deterministic). Coordinates use the
**top-left origin** of a 1024 x 1024 canvas. All numbers below are exact pixel
values unless flagged otherwise.

> Author: `yearly-design` (agent 5/10)
> Authoritative spec: `PROMO_IMAGE_SPECS.md` (apple-rules). This brief is
> compliant with sections 1–7 of that document; see §0 below for the audit.
> Sibling brief: `PROMO_BRIEF_MONTHLY.md` (cool teal/indigo palette, different motif)
> App icon to differentiate from: solid green gradient + white checkmark.
> Brand palette context: navy `#1A2C42`, warm green `#3FB680`, amber `#D89B3F`.
> This brief deliberately uses the amber/plum family to contrast the icon's green.

---

## 0. Compliance Audit vs `PROMO_IMAGE_SPECS.md`

| Spec rule | This brief |
| --- | --- |
| 1024 × 1024 PNG, sRGB, 8-bit, opaque | §2 |
| Distinct from app icon | §1 + §3 (no green, no checkmark, no rounded-square framing) |
| Distinct from Monthly | §1 (warm vs cool palette; ring vs 30-dot calendar motif) |
| No App Store badges / Apple marks | None used (only SF Symbol `star.fill`, redrawn if licensing concerns) |
| No currency prices, no platform refs | None present |
| No overlaid marketing copy | Only short descriptive wordmark "BEST VALUE" (≤24 pt) — see §6 |
| Centre-80 % safe area | §2.1 (all hero elements within (102, 102)–(922, 922)) |
| Lower-left corner clean | §2.1 (no content placed in lower-left 200×200 region) |
| 4+ age-rating safe | Abstract geometry + numeral, no people/text concerns |
| Thumbnail legibility (~120 px) | Ring + "365" remain readable; ribbon and dots are accents |

---

## 1. Differentiation Constraints (must-haves)

This image is App Store promotional artwork — **not** an app icon and **not** a
"price/discount" ad badge. It must:

1. **Not be mistaken for the app icon.**
   - No green. No solid checkmark glyph. No square-with-rounded-corners framing.
   - No single full-bleed solid color background.
2. **Not be mistaken for the monthly promo image.**
   - Monthly uses cool teal/cyan + a 30-dot calendar motif.
   - Yearly uses **warm amber/gold → deep plum** + a **12-segment ring** motif.
3. **Communicate "best value, full year"** through motif + a small descriptive
   ribbon label "BEST VALUE" — descriptive, not a price/% discount badge
   (App Store Review Guideline 2.3.10 / 3.1.1 compliant: the label describes
   the tier name, no price/percentage in the artwork itself).

---

## 2. Canvas & Coordinate System

| Field | Value |
| --- | --- |
| Width | 1024 px |
| Height | 1024 px |
| Origin | Top-left (Core Graphics `CGContext` default after a Y-flip, or use `UIGraphicsImageRenderer` which is top-left) |
| Color space | sRGB |
| Background | Diagonal gradient (see §3) |
| Bit depth | 8-bit per channel |
| Alpha | Opaque (no transparency, alpha = 1.0 everywhere) |

**Center point:** `C = (512, 512)`.

### 2.1 Safe Area & Forbidden Zones

Apple may apply framing/masking around the uploaded image. To survive that:

- **Safe area:** all hero/critical content (ring, "365", ribbon) lives inside
  the rectangle `(102, 102) → (922, 922)` — a 100 px inset on every edge
  (centre 80 % of the canvas).
- **Forbidden zone — lower-left:** keep the 200 × 200 region from `(0, 824)`
  to `(200, 1024)` visually quiet (background gradient only, no glyphs/text/
  motif elements). Apple has historically placed framing UI here.
- **Edge bleed:** the diagonal gradient and 12 outer dots are allowed to sit
  outside the safe area because they are decorative and survive masking.
- **Corners:** do not assume the four corners will remain square; the
  background is a smooth gradient so any rounding/masking is invisible.

---

## 3. Background — Diagonal Gradient

Linear gradient from **top-left** to **bottom-right**, i.e. start `(0, 0)`,
end `(1024, 1024)`. Five color stops:

| Stop | Position | Hex | RGB (0–255) |
| --- | --- | --- | --- |
| 0 | 0.00 | `#FFD27A` | 255, 210, 122 (warm amber highlight) |
| 1 | 0.25 | `#F2A23A` | 242, 162, 58 (gold) |
| 2 | 0.55 | `#B85C2A` | 184, 92, 42 (burnt amber transition) |
| 3 | 0.80 | `#6B2A4E` | 107, 42, 78 (plum) |
| 4 | 1.00 | `#3A123A` | 58, 18, 58 (deep plum shadow) |

After drawing the gradient, overlay a **radial highlight** to lift the center:

- Radial gradient centered at `(380, 380)`, radius `0 → 700`.
- Colors: `rgba(255, 240, 200, 0.18)` at 0.0 → `rgba(255, 240, 200, 0.0)` at 1.0.
- Blend mode: normal (it's already pre-faded by alpha).

**Subtle film grain (optional, low priority):** 2 % opacity monochrome noise
across the whole canvas. Skip if it complicates the render.

---

## 4. Central Motif — 12-Segment Illuminated Ring

A circular ring divided into 12 equal segments (one per month), all illuminated.

### 4.1 Ring geometry

| Field | Value |
| --- | --- |
| Center | `(512, 512)` |
| Outer radius `Ro` | 300 px |
| Inner radius `Ri` | 240 px (ring thickness = 60 px) |
| Segment count | 12 |
| Segment arc | 30° each |
| Gap between segments | 2° (1° padding on each side) → drawn arc = 28° per segment |
| Start angle | −90° (12 o'clock), going clockwise |

Render each segment as an annular wedge (filled path: outer arc + line in +
inner arc reversed + line back).

### 4.2 Segment fill — per-segment gradient

Each of the 12 segments is filled with a **radial gradient** centered at `C`,
going from `Ri` to `Ro`:

- Inner edge (`Ri`): `#FFE9A8` (pale gold, opacity 1.0)
- Outer edge (`Ro`): `#F2A23A` (gold, opacity 1.0)

Then add a **per-segment angular tint** by multiplying the alpha of an overlay:
segments at 12/3/6/9 o'clock are slightly brighter, segments between are slightly
warmer. Implementation-friendly simplification: same gradient for all 12; no
per-segment variance required if it's costly. Default to **identical fill for
all segments** for determinism.

### 4.3 Segment stroke

- 1 px stroke on each segment, color `rgba(58, 18, 58, 0.35)` (deep-plum hairline).
- Round line joins.

### 4.4 Outer glow

Draw a soft glow OUTSIDE the ring:

- Stroke a circle at `Ro + 6` (radius 306), stroke width 18 px, color
  `rgba(255, 210, 122, 0.35)`.
- Apply Gaussian blur radius 12 (Core Graphics: use a shadow with
  `setShadow(offset: .zero, blur: 14, color: UIColor(red: 1, green: 0.82, blue: 0.48, alpha: 0.55).cgColor)`
  drawn under the stroke, then clear the shadow).

### 4.5 Inner disk (behind "365")

Fill a solid disk at center `C`, radius `Ri − 6 = 234`:

- Radial gradient from center `(512, 512)`, radius `0 → 234`.
- Stops: `#2A0A2A` at 0.0 → `#4A1A4A` at 1.0 (deep plum well, makes the gold "365" pop).

Add a 1 px hairline stroke at radius 234, color `rgba(255, 233, 168, 0.20)`.

---

## 5. Center Numeral — "365"

A subtle, premium serif numeral set inside the ring.

| Field | Value |
| --- | --- |
| Text | `365` |
| Font family | **New York** (system serif on iOS — `UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle).withDesign(.serif)!, size: 0)`) |
| Weight | Light (`UIFont.Weight.light`) |
| Size | 220 pt |
| Tracking | −4 (tight) |
| Fill | Linear gradient inside the glyphs, top-left `#FFE9A8` → bottom-right `#F2A23A` |
| Opacity | 0.92 |
| Baseline | Visually centered at `C` (use the typographic bounding box; vertical center adjustment ≈ `+8 px` from geometric center to compensate for serif optical balance) |
| Horizontal centering | Centered on `x = 512` |

Render with `kCGTextFill`. Single line. No drop shadow on the numeral itself
(the inner disk provides contrast).

**Fallback fonts** (in order if New York-serif is unavailable in the render
context): `Georgia-Light`, `TimesNewRomanPS-LightMT`, system default with
`.serif` design.

---

## 6. "BEST VALUE" Ribbon — Top-Right

A small descriptive label, NOT a price/discount badge. Style: pill ribbon
with a small star.

### 6.1 Ribbon geometry

| Field | Value |
| --- | --- |
| Anchor (top-right of pill) | `(990, 90)` |
| Pill width | 260 px |
| Pill height | 56 px |
| Corner radius | 28 px (full pill) |
| Top-left corner of pill | `(730, 62)` |
| Bottom-right corner of pill | `(990, 118)` |

Rotate the entire ribbon group **−8°** (counter-clockwise) around its center
`(860, 90)`. This gives a slight playful tilt while staying readable.

### 6.2 Ribbon fill & stroke

- Fill: linear gradient, top → bottom inside the pill bounds.
  - `#FFF1C8` at 0.0 → `#FFD27A` at 1.0.
- Stroke: 1.5 px, color `#6B2A4E` (plum), full opacity.
- Drop shadow: `offset (0, 4)`, blur 8, color `rgba(58, 18, 58, 0.35)`.

### 6.3 Star glyph (left side of pill)

- SF Symbol `star.fill` (or hand-drawn 5-point star if symbol rendering is
  not available in the image renderer).
- Color: `#6B2A4E` (plum).
- Size: 22 pt (height ~22 px).
- Center: `(770, 90)` (within the ribbon pre-rotation coords).

### 6.4 Label text

| Field | Value |
| --- | --- |
| Text | `BEST VALUE` (exact, all caps) |
| Font | SF Pro Display, Semibold (`UIFont.systemFont(ofSize: 20, weight: .semibold)`) |
| Size | **20 pt** (≤ 24 pt cap satisfied) |
| Letter-spacing (tracking) | +2 (small-caps feel) |
| Color | `#3A123A` (deep plum) |
| Alignment | Left-aligned starting at `x = 792` (post-star), vertically centered at `y = 90` |

The whole ribbon (pill + star + text) is the rotated group from §6.1.

---

## 7. Twelve "Month Dots" — Tiny Accents Around the Ring

Twelve small dots, one per segment, placed just outside the ring to reinforce
the "12 months" reading. These are intentionally subtle so the ring stays hero.

| Field | Value |
| --- | --- |
| Count | 12 |
| Radius from center | 326 px |
| Angles | −90° + i × 30° for `i = 0..11` (matches segment center lines) |
| Dot radius | 4 px |
| Fill | `#FFE9A8` at opacity 0.55 |
| Stroke | none |

---

## 8. Bottom Caption — DELIBERATELY OMITTED

Per `PROMO_IMAGE_SPECS.md` §3 ("no overlaid marketing text" preferred) and §4
(localised display name is rendered separately by the App Store system),
**no bottom caption is drawn.** The "Pro Yearly" display name will appear
alongside the image courtesy of App Store Connect metadata, not baked into
the PNG. This also keeps the lower-left forbidden zone (§2.1) clean.

The single short wordmark in the artwork is the descriptive "BEST VALUE"
label inside the ribbon (§6) — that is the only typographic element on the
canvas besides the abstract "365" numeral.

---

## 9. Z-Order (back → front)

1. Background diagonal gradient (§3).
2. Background radial highlight (§3).
3. Twelve month dots (§7).
4. Outer ring glow (§4.4).
5. Twelve ring segments with stroke (§4.1–4.3).
6. Inner disk + hairline (§4.5).
7. "365" numeral (§5).
8. Ribbon shadow (§6.2).
9. Ribbon pill + star + "BEST VALUE" text, as the rotated group (§6).

---

## 10. Implementation Notes (for `yearly-coder`)

- Recommended renderer: `UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 1024))` — top-left origin, sRGB, retina-safe.
- Use `CGContext.saveGState()` / `restoreGState()` around the ribbon rotation.
- For text gradients on "365", draw the text as a clipping mask (`context.clip(to: path)` after converting the glyph to a `CGPath` via Core Text), then draw the linear gradient inside the clip.
- For the segments, build each annular wedge with:
  ```
  let path = UIBezierPath()
  path.addArc(withCenter: c, radius: Ro, startAngle: a0, endAngle: a1, clockwise: true)
  path.addArc(withCenter: c, radius: Ri, startAngle: a1, endAngle: a0, clockwise: false)
  path.close()
  ```
  Angles in radians; remember 28° drawn arc with 1° gap on each side.
- All hex values are sRGB; use `UIColor(red:green:blue:alpha:)` with normalized 0–1 floats.
- Determinism: do NOT use any random/noise unless you seed it. Skip film grain (§3) if not seedable.
- Output: write PNG via `renderer.pngData()` and save to
  `EasyCancel/Sources/Resources/Assets.xcassets/PromoYearly.imageset/promo_pro_yearly.png`
  (or wherever the asset pipeline expects — `yearly-coder` decides the final path).

---

## 11. Acceptance Criteria

A render is acceptable iff **all** of the following hold:

- [ ] Image is exactly 1024 × 1024 px PNG, opaque, sRGB (no alpha channel).
- [ ] Diagonal warm-to-plum gradient is the dominant background (no green, no teal, no solid single-color fill).
- [ ] 12 illuminated ring segments are visible, evenly spaced, with visible 2° gaps.
- [ ] "365" is centered inside the ring in a light serif face, gold-gradient filled.
- [ ] "BEST VALUE" ribbon is in the top-right, tilted ~−8°, ≤ 24 pt, contains a small star glyph.
- [ ] Twelve subtle outer dots are present.
- [ ] No price, no percentage, no "subscribe"/"buy"/"save" CTAs in the artwork.
- [ ] No bottom caption / display-name baked into the PNG (system renders it separately).
- [ ] No App Store badges, no Apple logos, no platform references.
- [ ] No checkmark glyph anywhere.
- [ ] All hero content (ring, "365", ribbon) is inside the centre-80 % safe area `(102, 102) → (922, 922)`.
- [ ] Lower-left forbidden zone `(0, 824) → (200, 1024)` contains only background gradient.
- [ ] Side-by-side with the monthly promo image, the two are obviously different in palette (warm vs cool) and motif (ring vs 30-dot calendar).
- [ ] Side-by-side with the app icon, no risk of confusion (different shape framing, no green).
- [ ] Reads clearly when scaled to ~120 px thumbnail (ring + "365" stay legible).
- [ ] Content is 4+ age-rating safe.

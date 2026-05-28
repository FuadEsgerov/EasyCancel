# EasyCancel — Marketing Video Brief (Sora 2 + real screen capture)

Paste-ready prompts and a shot list for a launch promo. Read this first:

> **Sora cannot render your real app UI.** Apple's App Store **App Preview** must
> show the actual app (Guideline 2.3.3 — no mockups/simulations). So use Sora 2
> for **lifestyle / atmospheric b-roll** and intercut it with **real screen
> recordings** (capture commands at the bottom). The Sora-only cut is for
> **social** (Instagram Reels / TikTok / YouTube Shorts), not the App Store.

Brand: green `#2F9E6B → #1C7A52`, clean, calm, modern. Tone: relief, control,
trust. No hype, no fake numbers.

---

## A. 20-second social promo — storyboard

| t (s) | Visual | On-screen text | VO (optional) |
|------|--------|----------------|---------------|
| 0–3  | Sora b-roll: phone face-down on a kitchen table at dawn, soft light, calm | "Still paying for things you forgot?" | "We all have them." |
| 3–7  | **Real capture:** Home screen — monthly spend ticks up, list of subs | "See what you really spend" | "Every subscription, in one place." |
| 7–11 | **Real capture:** subscription detail — cooling-off countdown card | "14 days to cancel — don't miss it" | "Know exactly how long you've got." |
| 11–15| **Real capture:** tap → withdrawal letter generates | "One tap. Done right." | "A GDPR-ready letter, instantly." |
| 15–18| Sora b-roll: person exhales, closes laptop, relaxed, EU city window light | "Take back control" | — |
| 18–20| Logo lockup on brand gradient + "EasyCancel" + App Store badge | "EasyCancel" | — |

Music: warm, minimal, optimistic (90–110 BPM). Captions burned in (most social plays muted).

---

## B. Sora 2 prompts (b-roll only — copy one per clip)

Use **9:16, 1080×1920**, ~3–4 s each, photorealistic, shallow depth of field.

**Clip 1 — "the forgotten subscriptions" (0–3s)**
```
Cinematic close-up, 9:16 vertical. A smartphone lying face-down on a light oak
kitchen table at soft morning light, a half-finished coffee beside it. Slow
push-in, shallow depth of field, gentle dust motes in a warm sunbeam. Calm,
quiet, slightly melancholic mood. Natural color, no text, no logos, no UI on
screen. 4 seconds.
```

**Clip 2 — "relief / control" (15–18s)**
```
Cinematic, 9:16 vertical. A person in their late 20s sits by a large window in a
bright European apartment, gently closes a laptop and exhales with a small
relieved smile, soft natural daylight, green plants in soft focus background.
Warm, reassuring, calm mood. Realistic, handheld-stable, shallow depth of field.
No text, no logos, no phone screen visible. 3 seconds.
```

**Clip 3 — logo bed (18–20s, optional abstract)**
```
Abstract, 9:16 vertical. Smooth flowing gradient of emerald green to deep
teal (#2F9E6B to #1C7A52), soft volumetric light, gentle slow motion liquid
ripples, premium and minimal, like a fintech brand background. No text, no
logos. 3 seconds.
```

> Tips: keep people's hands away from fake phone screens (Sora invents UI). If a
> clip shows a screen, regenerate or crop it out — only the **real captures**
> may show the app.

---

## C. Alternate: 15-second App Store App Preview (real UI only)

For the App Store slot, **no Sora**. Sequence the real captures below with a
0.5s brand intro/outro card (made from `Screenshots/Marketing-6.9/`):
1. Home (spend + list) — 4s
2. Detail (cooling-off countdown) — 4s
3. Generate withdrawal letter — 4s
4. Outro card: logo + "Cancel in time." — 3s

App Preview specs: H.264/HEVC, 1080×1920 (portrait), 15–30s, ≤500 MB.

---

## D. Capture the real UI (simulator screen recording)

The app has a seeded, offline `-screenshots` demo mode — perfect for clean
recordings (status bar pinned to 9:41, mock data, no network).

```bash
cd EasyCancel
# Boot a 6.9" sim and pin a clean status bar
UDID=$(xcrun simctl create EC-rec com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max com.apple.CoreSimulator.SimRuntime.iOS-18-5)
xcrun simctl boot "$UDID"; sleep 6
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4

# Build & install, then launch in demo mode
xcodebuild build -project EasyCancel.xcodeproj -scheme EasyCancel -destination "id=$UDID"
xcrun simctl launch "$UDID" com.vincli.easycancel -screenshots

# Record (Ctrl-C to stop) — then perform the taps you want on screen
xcrun simctl io "$UDID" recordVideo --codec h264 build/promo-raw.mov
```

Trim/assemble in iMovie, CapCut, or DaVinci Resolve (free). Drop the Sora b-roll
on the timeline around the real captures per the storyboard in section A.

---

## E. Assets already generated for you
- `Screenshots/Marketing-6.9/` & `Marketing-6.5/` — captioned slides (great for intro/outro frames and thumbnails)
- `web/assets/icon.png` — logo for the lockup
- Captions/copy — reuse the headlines from the marketing screenshots

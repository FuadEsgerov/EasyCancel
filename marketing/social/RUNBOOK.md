# EasyCancel — Social Launch RUNBOOK ("Everything You Need To Do")

> Do these in order. Tick the boxes as you go. Goal of all of it: **waitlist sign-ups** at
> https://easycancel.vincli.com. PRE-LAUNCH — we are selling the waitlist, not a download.
> Companion docs: `PROFILES.md` (copy-paste handles/bios) and `CONTENT_CALENDAR.md` (what to post when).

---

## 1. Create the accounts (Instagram + TikTok)

- [ ] **Check handle availability** on BOTH platforms first. Try `@easycancel`; if taken
      on either, use the first fallback that's free on **both** (see `PROFILES.md` → Handles).
- [ ] **Instagram:** sign up with a brand email (e.g. social@vincli.com, not personal).
      Create the account → in **Settings → Account type and tools → Switch to professional
      account → Business** (gets analytics + a clickable website link + scheduling).
- [ ] **TikTok:** sign up → **Profile → ⚙ Settings → Manage account → Switch to Business
      Account** (unlocks the bio website link, analytics, and the post scheduler).
- [ ] Use the **same email + a saved password** in your password manager for both.
- [ ] Enable **2FA** on both accounts.

---

## 2. Set the profile picture

- [ ] File: **`marketing/social/profile/profile-picture.png`**.
- [ ] Upload the **same image** on Instagram and TikTok (consistency = recognisable brand).
- [ ] IG: **Edit profile → Change profile photo**. TikTok: **Edit profile → tap the photo**.
- [ ] Both crop to a circle — make sure the logo/key element is centered.

---

## 3. Paste the bios

- [ ] **Instagram bio:** copy the chosen bio from `PROFILES.md` → **Edit profile → Bio**.
- [ ] **Instagram display name:** `EasyCancel — Track & cancel subscriptions`
      (the Name field is searchable — keywords help discovery).
- [ ] **TikTok bio (≤80 chars):** copy from `PROFILES.md` → **Edit profile → Bio**.
- [ ] **TikTok display name:** `EasyCancel`.
- [ ] Keep emoji sparing and on-brand (📉 💸 🇪🇺 🇬🇧 👇).

---

## 4. Set the link-in-bio → waitlist

The clickable link must point to **https://easycancel.vincli.com**.

- [ ] **Instagram:** **Edit profile → Links → Add external link** → paste
      `https://easycancel.vincli.com` → Title: "Join the waitlist".
- [ ] **TikTok:** **Edit profile → Website** → paste `https://easycancel.vincli.com`
      (Business account required — done in §1).
- [ ] **(Optional) Use a Linktree** if you want more than one link (waitlist + privacy +
      "what is it"): create a free Linktree, put the **waitlist link first/at the top**, and
      use the Linktree URL as the bio link. Keep the waitlist as the obvious primary button.
- [ ] **Tip — track attribution:** add a query param so you can see social sign-ups in
      Supabase, e.g. `https://easycancel.vincli.com?src=ig` and `?src=tiktok`. (Even if the
      landing form currently logs `source: "landing"`, the URL param lets you confirm which
      channel sent the visit; optionally update the landing JS later to read `?src=`.)

---

## 5. Where every asset lives

| Asset | Folder | Files |
|-------|--------|-------|
| IG feed posts (square) | `marketing/social/instagram/posts/` | `P01.png` … `P10.png` |
| Vertical (Reels/TikTok/Stories) | `marketing/social/vertical/` | `V1.png` … `V6.png` |
| Profile pic + highlight covers | `marketing/social/profile/` | `profile-picture.png` + covers |
| IG captions + hashtags | `marketing/social/instagram/captions.md` | (+ `captions-de.md`, `captions-fr.md`) |
| TikTok captions | `marketing/social/tiktok/captions.md` | |
| TikTok scripts | `marketing/social/tiktok/scripts.md` | |

> The **calendar maps each day's slot to a theme code** (P01–P10, V1–V6) — open
> `CONTENT_CALENDAR.md`, find the code, grab that file + its caption.

---

## 6. How to post (quick refs)

### Instagram carousel (square, P-series)
- [ ] Tap **+ → Post** → select the P0x.png slides **in order** (long-press to set order).
- [ ] Aspect: square (1:1) — the P assets are already square.
- [ ] Paste the caption + hashtags from `instagram/captions.md` (find the matching P code).
- [ ] Add **alt text** (Advanced settings → Accessibility) for reach + a11y.
- [ ] Post → then **pin a CTA comment** ("👉 Join the waitlist, link in bio").

### Instagram Reel (vertical, V-series video)
- [ ] Tap **+ → Reel** → upload the finished 9:16 video → trim → add cover/first frame.
- [ ] Add the caption from `instagram/captions.md` (or repurpose the TikTok caption).
- [ ] Make sure "**Also share to Feed**" is ON (more reach).
- [ ] Avoid TikTok watermarks (see §9) — IG suppresses watermarked re-uploads.

### Instagram Story
- [ ] Tap your profile pic / **+ → Story** → pick a V or P asset (or a video clip).
- [ ] Add a **Link sticker** → `https://easycancel.vincli.com` → label it "Join 👇".
- [ ] Optional: **Poll / Quiz / Question** sticker to drive replies.
- [ ] After 24h, save the best ones to a **Highlight** (see `PROFILES.md` highlight plan).

### TikTok video
- [ ] Tap **+** → upload the 9:16 video (or film in-app) → next.
- [ ] Add **trending audio** (see §9), text hook on the first frame, and 3–5 hashtags.
- [ ] Paste the caption from `tiktok/captions.md`.
- [ ] Post → **pin a CTA comment** with the waitlist nudge.

---

## 7. Captions & hashtags

- [ ] Captions live in `marketing/social/instagram/captions.md` and
      `marketing/social/tiktok/captions.md`, keyed by theme code (P01.., V1..).
- [ ] For DE/FR audiences, use `captions-de.md` / `captions-fr.md` for those posts.
- [ ] **Every caption ends with the waitlist CTA** ("Join the waitlist — link in bio 👇").
- [ ] On any **rights claim** (P01, P05, V2), include: *"Rights vary by country — not legal/
      financial advice."*
- [ ] Hashtag mix per post (5–10): a few broad (#subscriptions #savemoney #personalfinance),
      a few niche (#cancelsubscriptions #cooloffperiod #GDPR), 1–2 regional (#UKdeals #EUlife).

---

## 8. Free scheduling (optional but recommended for a solo founder)

- [ ] **Instagram → Meta Business Suite** (free): business.facebook.com → connect the IG
      account → **Planner / Create post** → schedule feed posts, carousels, and Reels by
      date/time. (Stories generally can't be scheduled here — post those manually.)
- [ ] **TikTok → native scheduler:** post from **tiktok.com on desktop** → upload video →
      toggle **Schedule** → set date/time (up to 10 days ahead).
- [ ] **Batch on Sunday:** queue the week's feed/Reel/TikTok slots from `CONTENT_CALENDAR.md`
      in one sitting. Leave Stories + comment replies as the daily 10-minute manual task.

---

## 9. Turning the TikTok scripts into videos

You have two equally-fine options — pick per video:

**A) Film with your phone (best for hooks V1, V6, talking-to-camera):**
- [ ] Open `marketing/social/tiktok/scripts.md` → read the script for that V-code.
- [ ] Film **vertical (9:16)**, good light, 7–20s, hook in the **first 1.5 seconds**.
- [ ] Edit in **CapCut** (free): add captions/subtitles (auto-caption), text hook, B-roll.

**B) Assemble the vertical frames into a slideshow Reel (fastest, no filming):**
- [ ] Open CapCut (or TikTok's photo/slideshow mode) → import the **V1–V6 .png** frames
      relevant to the script.
- [ ] Set each frame to ~1.5–2.5s, add simple transitions + the script text as on-screen captions.
- [ ] Add a **trending audio** track: in TikTok, tap **Add sound** → "**Trending**" tab, or
      look for a ↗ rising-arrow on sounds. Use sounds with **< ~50k videos** (still rising)
      and on-brand vibe. (For IG, swap to a track flagged "Trending" with the ↗ arrow.)
- [ ] Export **9:16, 1080×1920**, no watermark.
- [ ] **De-watermark for IG re-use:** save your own video from your TikTok **drafts/profile
      before** adding TikTok-branded stickers, OR keep the clean CapCut export to re-upload
      to IG Reels. Never re-post a watermarked TikTok to IG.

> The V-series PNGs are designed to read as standalone Story/feed cards **and** to chain
> into a slideshow Reel — so you can ship a video even on a no-filming day.

---

## 10. Where sign-ups land + eyeballing growth

- The landing page (`web/index.html`) **POSTs each waitlist email to a Supabase REST
  endpoint** → it lands in the **`waitlist` table** with `{ email, locale, source }`.
  (`source` is `"landing"` from the site; use the `?src=ig` / `?src=tiktok` URL param from
  §4 to attribute social traffic.)
- [ ] **Check growth in Supabase:** open the project → **Table Editor → `waitlist`** to see
      rows, or **SQL Editor** and run:
      ```sql
      -- total + new today
      select count(*) as total,
             count(*) filter (where created_at::date = current_date) as today
      from public.waitlist;

      -- sign-ups by day (spot which posts moved the needle)
      select created_at::date as day, count(*)
      from public.waitlist
      group by 1 order by 1 desc limit 30;

      -- by locale (which EU/UK markets are biting)
      select locale, count(*) from public.waitlist group by 1 order by 2 desc;
      ```
- [ ] **Correlate** the daily sign-up counts against `CONTENT_CALENDAR.md` — note which
      theme/format/time caused spikes, then **post more of that**.
- [ ] **Platform analytics** for reach/engagement: IG **Insights** (Professional account)
      and TikTok **Analytics** (Business account) → watch saves, shares, and **link/profile
      taps** (taps → site → waitlist is the funnel that matters, not raw views).

---

## Daily quick-checklist (the 10-minute habit)

- [ ] Post today's scheduled slot(s) per `CONTENT_CALENDAR.md` (or confirm the scheduler fired).
- [ ] Drop 1–3 **Story** frames with a **Link sticker** to the waitlist.
- [ ] **Reply to every comment + DM** from the last 24h (within the first hour if you can).
- [ ] **Pin the CTA comment** on any new post.
- [ ] Glance at the `waitlist` count vs. yesterday.

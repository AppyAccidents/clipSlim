# Launch Execution Plan - ClipSlim

**Launch Window:** March 7-8, 2026
**Primary Channel:** Direct distribution (notarized DMG via website)
**Secondary Channel:** Mac App Store (may launch March 10-12 pending review)

---

## Immediate Actions (Today, March 5, 2026)

### Action 1: Privacy Policy (30 minutes)

Create and publish a privacy policy. For a local-only app with zero data collection, this can be concise.

**Content to include:**
- ClipSlim does not collect, store, or transmit any user data
- All image processing happens locally on the user's device
- No analytics, crash reporting, or third-party SDKs
- No network connections made by the app
- No cookies, no tracking, no advertising
- Contact email for privacy questions

**Where to host:**
- Option A: GitHub Pages (free, fast to set up)
- Option B: A page on the AppyAccidents website (when live)
- Option C: A GitHub Gist with a raw URL (quickest)

**Validation:** Open the URL in a private browser window and confirm it loads.

---

### Action 2: App Store Connect Record (45 minutes)

1. Log in to https://appstoreconnect.apple.com
2. My Apps > + > New App
3. Fill in:
   - Platform: macOS
   - Name: ClipSlim
   - Primary Language: English (U.S.)
   - Bundle ID: (select from dropdown, must match Xcode)
   - SKU: clipslim-v1
4. Save and proceed to the app record

---

### Action 3: Metadata Entry (1 hour)

All metadata has been pre-written and validated. Copy-paste from the metadata files:

**Source file:** `/outputs/clipSlim/02-metadata/apple-metadata.md`

**Title (25/30 chars):**
`clipSlim - Image Optimizer`

**Subtitle (30/30 chars):**
`Clipboard & Folder Compression`

**Promotional Text (148/170 chars):**
`NEW: Folder Watcher now monitors entire directories! Drop images in, get slim files out. 100% local - zero uploads, zero tracking. Try free today.`

**Keywords (91/100 chars):**
`compress,png,jpeg,resize,batch,shrink,menubar,photo,converter,heic,screenshot,bulk,filesize`

IMPORTANT: Do NOT include "image", "optimizer", or "clipboard" in the keyword field -- they are already in the title and subtitle, and Apple would ignore duplicates.

**Description:** Copy the full description from apple-metadata.md (2,847/4,000 chars). It includes all keyword density targets and natural language integration.

**What's New:** Copy the What's New text from apple-metadata.md (840/4,000 chars).

Refer to the full Implementation Instructions in apple-metadata.md for step-by-step App Store Connect entry.

---

### Action 4: Build and Notarize DMG (1.5 hours)

Follow the commands in submission-guide.md Part 1. The pipeline is already established per the README:

1. `xcodebuild test` (run tests)
2. `xcodebuild -configuration Release build` (build release)
3. Code sign with Developer ID
4. Create DMG via script
5. Sign DMG
6. Notarize via `xcrun notarytool submit`
7. Staple
8. Verify with `spctl`

---

### Action 5: Sandbox Evaluation (1 hour)

Test whether ClipSlim functions correctly under App Sandbox:

1. Temporarily add sandbox entitlement
2. Build and run
3. Test clipboard polling -- does it still detect clipboard changes?
4. Test folder watcher -- does it work with user-selected folders?
5. Test global hotkeys -- do they still register?
6. Document results
7. If everything works: proceed with MAS submission
8. If issues found: defer MAS to v1.1, launch DMG-only

---

## March 6 Actions

### Action 6: Create Screenshots (2 hours)

Capture 3-5 screenshots showing ClipSlim in action:

**Screenshot 1 (Hero):** The menubar popover open, showing a fresh optimization result with compression stats (before/after size, percentage saved). Clean desktop background.

**Screenshot 2 (Presets):** Settings panel with the four presets visible and one selected. Shows the intensity level selector.

**Screenshot 3 (Folder Watcher):** The folder watcher view with a batch of optimized files listed, showing individual file stats.

**Screenshot 4 (Resize):** The overlay resize controls with width/height fields and quick square presets visible.

**Screenshot 5 (Privacy):** A simple graphic or screenshot emphasizing "100% Local" -- possibly the settings or about view with no network indicators.

**Technical requirements:**
- Mac App Store: 2880x1800 (16-inch Retina) or 2560x1600 (13-inch Retina)
- Capture using Cmd+Shift+5 (screen recording) or Cmd+Shift+4 (area)
- Add text overlays using Figma, Sketch, or even Preview/Keynote

---

### Action 7: Create Landing Page (1.5 hours)

Minimum viable landing page needs:
- App name and icon
- One-line description
- 3-5 bullet points of key features
- Download button (link to DMG)
- System requirements
- Privacy policy link
- Support email or link
- At least one screenshot

---

### Action 8: Draft Launch Announcements (1 hour)

**Twitter/X:**
"Introducing ClipSlim -- a macOS menubar utility that automatically optimizes images on your clipboard. Copy an image, it shrinks. That simple. 100% local, zero data leaves your Mac. Free download: [URL]"

**Reddit r/macapps:**
Title: "I made ClipSlim -- a menubar app that auto-optimizes clipboard images (macOS, 100% local)"
Body: Brief description, key features, download link, what makes it different from ImageOptim/Clop, request for feedback.

**Hacker News:**
Title: "Show HN: ClipSlim -- Auto-optimize clipboard images on macOS (local-only)"
Link to website or GitHub.

---

## March 7 Actions (Launch Day)

### Action 9: Execute Launch (2 hours morning)

**9:00 AM:**
- Final check: website up, DMG downloadable, links working
- Post Twitter/X announcement
- Post Reddit r/macapps

**10:00 AM:**
- Post Hacker News (Show HN)
- Share in relevant Discord/Slack communities

**11:00 AM:**
- Monitor all channels for comments
- Respond to questions within 30 minutes

### Action 10: Monitor and Respond (ongoing)

- Check all channels every 30-60 minutes through the day
- Priority: respond to bug reports immediately
- Document all feedback in a single file or note
- If critical bug found: fix, rebuild, re-notarize, update website (30-min pipeline)

---

## Success Metrics for Launch Weekend

| Metric | Target | How to Measure |
|--------|--------|----------------|
| DMG downloads | 50+ | Website analytics / server logs |
| Reddit upvotes | 20+ | r/macapps post |
| HN points | 10+ | Show HN post |
| Critical bugs reported | 0 | All channels |
| Support emails | < 5 | Inbox |
| MAS submitted | Yes/No | App Store Connect status |

---

## Post-Launch Week 1 Actions

### Action 11: Daily Monitoring (15 min/day, March 8-14)
- Check App Store Connect status (if submitted)
- Respond to any reviews or feedback
- Track cumulative downloads
- Monitor for bug reports

### Action 12: Product Hunt Launch (March 10-11)
- Create Product Hunt listing
- Upload screenshots and description
- Launch on a Tuesday or Wednesday (highest traffic)
- Engage with comments throughout the day

### Action 13: Week 1 Retrospective (March 14)
- Total downloads (DMG + MAS)
- Total social reach
- User feedback themes
- Bug count and status
- v1.1 scope decision

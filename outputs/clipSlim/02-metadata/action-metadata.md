# Metadata Implementation Checklist - clipSlim

**Last Updated:** 2026-03-05
**Launch Target:** March 7-8, 2026
**Developer:** AppyAccidents

---

## PRE-SUBMISSION TASKS

### 1. App Store Connect Setup
- [ ] Log in to https://appstoreconnect.apple.com
- [ ] Confirm clipSlim app record exists (or create new macOS app)
- [ ] Confirm Bundle ID matches Xcode project: verify in App Information
- [ ] Confirm Primary Language is set to English (U.S.)
- [ ] Confirm app category is set to Utilities
- [ ] Set age rating (clipSlim: 4+ - no content issues)

### 2. Pricing Configuration
Decide between two models before submitting. The description copy and promotional text differ.

**Option A: Fully Free**
- Set price to Free in Pricing and Availability
- No in-app purchases required
- Use the current description as-is

**Option B: Freemium (Free core + paid unlock)**
- Set base price to Free
- Create an in-app purchase for Pro features (e.g., Folder Watcher, unlimited compression)
- Update the Description to include a pricing section:
  ```
  FREE INCLUDES
  - Clipboard optimization
  - 3 presets
  - Light and Moderate intensity

  CLIPSLIM PRO - $X.99/year or $X.99 one-time
  - Folder Watcher
  - Aggressive intensity
  - Custom preset
  - Debug log
  ```
- Update Promotional Text to mention free tier and Pro unlock

### 3. Paste Metadata into App Store Connect

All copy is in `/outputs/clipSlim/02-metadata/apple-metadata.md`. Use the PRIMARY METADATA section for launch.

| Field | Source | Location in App Store Connect |
|-------|--------|------------------------------|
| App Name | Primary > App Name | App Information > Name |
| Subtitle | Primary > Subtitle | App Information > Subtitle |
| Description | Primary > Description | Version Information > Description |
| What's New | Primary > What's New | Version Information > What's New |
| Keywords | Primary > Keywords Field | Version Information > Keywords |
| Promotional Text | Primary > Promotional Text | Version Information > Promotional Text |

**Step-by-step paste order:**
1. App Information tab: paste Name, paste Subtitle, Save
2. Version Information: paste Description
3. Version Information: paste What's New
4. Version Information: paste Keywords (verify no spaces after commas)
5. Version Information: paste Promotional Text
6. Save all changes

### 4. Visual Assets Upload
- [ ] Upload app icon (1024x1024 PNG, no alpha) - see visual-assets-spec.md
- [ ] Upload minimum 3 screenshots at 2560x1600 - see visual-assets-spec.md
- [ ] Confirm screenshot order: hero first, folder watcher second, presets third
- [ ] (Optional) Upload app preview video

### 5. App Review Information
- [ ] Add demo account credentials if app requires login (clipSlim does not)
- [ ] Add review notes explaining how to test clipboard compression:
  ```
  Review Notes:
  1. Launch clipSlim from the menubar
  2. Copy any image file (PNG, JPEG, or HEIC) to the clipboard
  3. The app will automatically compress the image and notify you
  4. Use Option+1 to paste the optimized version
  5. Use Option+2 to paste the original version
  The Folder Watcher tab allows monitoring a directory for automatic compression.
  All processing is local - no network required.
  ```

### 6. Privacy Details
- [ ] Set Data Collection to None (clipSlim collects no data)
- [ ] Confirm Privacy Policy URL is set: https://appyaccidents.com/privacy
- [ ] Confirm Support URL is set: https://appyaccidents.com or support email

---

## POST-LAUNCH METADATA TASKS (Week 1)

### Day 1-3 After Approval
- [ ] Confirm app is live on Mac App Store search
- [ ] Search "image optimizer mac" - check if clipSlim appears
- [ ] Search "clipboard compression" - check if clipSlim appears
- [ ] Search "menubar image" - check if clipSlim appears
- [ ] Take a screenshot of any search placements for baseline tracking

### Day 3-7 After Launch
- [ ] Check first user reviews in App Store Connect
- [ ] Note any feature requests or complaints that could inform metadata changes
- [ ] If reviews are strong (4+ stars), plan to add a testimonial quote to the Description in the next update

---

## POST-LAUNCH METADATA TASKS (Month 1)

### Week 2
- [ ] Update Promotional Text with any new content (no submission required):
  - Example: "NOW WITH FOCUS MODE: Skip optimization in specific apps. clipSlim 1.0 - 100% local image compression from your menubar. Free to download."
- [ ] Start A/B test on App Name using Product Page Optimization (see ab-test-setup.md)

### Week 3-4
- [ ] Review keyword performance using third-party ASO tool (AppFollow, Sensor Tower, or MobileAction)
- [ ] Identify which keywords are driving impressions but not installs
- [ ] Swap low-performing keywords in the Keywords field for alternatives:
  - Candidate replacements: `filesize,lossless,workflow,screenshot,editor,bulk`

### End of Month 1
- [ ] Review conversion rate: impressions to downloads ratio
- [ ] If conversion rate is below 10%, prioritize Screenshot 1 A/B test (highest impact change)
- [ ] Evaluate whether to add a second language localization (consider: German, Japanese - both strong markets for Mac utilities)

---

## ONGOING MAINTENANCE SCHEDULE

| Task | Frequency | Effort |
|------|-----------|--------|
| Update Promotional Text | Monthly | 10 minutes |
| Refresh What's New for each release | Per release | 20 minutes |
| Check and rotate Keywords field | Quarterly | 30 minutes |
| Refresh Description with new features | Per major release | 1 hour |
| Add testimonial quotes to Description | After collecting 10+ reviews | 20 minutes |
| Run screenshot A/B test | Quarterly | 2 hours |
| Localize for top non-English markets | When download volume justifies it | 1-2 days |

---

## METADATA CHANGE APPROVAL REQUIREMENTS

Understanding which changes require an App Review submission saves time:

| Change | Requires Submission |
|--------|-------------------|
| App Name | YES |
| Subtitle | YES |
| Description | YES |
| What's New | YES |
| Keywords | YES |
| Promotional Text | NO - update anytime |
| Screenshots | NO - update anytime (for existing version) |
| App Preview Video | NO - update anytime (for existing version) |
| Pricing | NO - change anytime in Pricing and Availability |

**Practical implication:** Keep Promotional Text fresh. It's your only real-time marketing lever without going through App Review.

---

## METADATA FILE REFERENCE

| File | Purpose |
|------|---------|
| `02-metadata/apple-metadata.md` | All App Store copy, primary + 3 variants |
| `02-metadata/visual-assets-spec.md` | Icon and screenshot requirements |
| `02-metadata/action-metadata.md` | This file - implementation tasks |
| `03-testing/ab-test-setup.md` | A/B test configuration guide |
| `03-testing/action-testing.md` | Testing and monitoring tasks |

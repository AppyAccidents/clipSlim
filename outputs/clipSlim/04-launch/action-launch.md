# Launch Execution Plan - ClipSlim (Resubmission)

**Submission Date:** March 16, 2026 (today)
**Context:** Resubmission after Guideline 3.1.1 rejection (BMC replaced with StoreKit 2)
**Platform:** Mac App Store
**App Store ID:** 6759780567
**Expected Approval:** March 17-19, 2026

---

## Today's Actions (March 16, 2026)

### Action 1: Final 3.1.1 Compliance Verification (15 minutes)

Run the verification grep one final time:

```bash
cd /Users/berkerceylan/Documents/GitHub/clipSlim
grep -ri "buymeacoffee\|buy.me.a.coffee\|bmc" --include="*.swift" --include="*.plist" .
```

Expected: zero matches.

Then manually:
1. Launch the app
2. Open Settings > Support tab
3. Confirm only three native tip buttons are visible
4. Confirm no external links, no "Donate" buttons, no BMC branding
5. Tap each tip button -- confirm native StoreKit purchase sheet appears (in sandbox)

---

### Action 2: Build, Upload, Configure IAPs (2 hours)

Follow submission-guide.md steps 2 through 7:

1. Run tests
2. Increment build number
3. Archive in Xcode
4. Upload to App Store Connect
5. Wait for processing
6. Configure three consumable IAPs (if not already done)
7. Verify all IAPs show "Ready to Submit"

---

### Action 3: Update App Review Notes and Submit (30 minutes)

1. In App Store Connect, select the app version
2. Select the new build
3. Replace App Review notes with the resubmission text from prelaunch-checklist.md Phase 5
4. Verify all metadata is clean (no BMC references)
5. Verify IAPs are included in submission summary
6. Submit for review

---

### Action 4: Prepare Post-Approval Announcements (30 minutes)

Draft these now so they are ready to post the moment approval comes through.

**Twitter/X:**
```
ClipSlim is live on the Mac App Store!

Automatic clipboard image optimization for macOS:
- Copy an image, it shrinks instantly
- Folder watcher for batch processing
- PDF compression
- 100% local, zero data collection

Free with optional tip jar.

[Mac App Store link]
```

**Reddit r/macapps:**
```
Title: ClipSlim -- menubar app that auto-optimizes clipboard images (macOS, 100% local, free)

Body:
Hey r/macapps -- ClipSlim is now available on the Mac App Store.

It sits in your menubar and automatically compresses images the moment you copy them.
No drag-and-drop, no upload tools, no manual steps.

Features:
- Automatic clipboard image optimization
- Folder watcher (point it at a directory, images get compressed automatically)
- PDF compression
- Drop zone for drag-and-drop batches
- Format override (JPEG/PNG), resize, crop
- Global hotkeys (Option+1 for optimized, Option+2 for original)
- Focus mode (skip optimization in specific apps)
- 100% local -- nothing leaves your Mac

Free with an optional tip jar if you want to support development.

Mac App Store: [link]
Direct download (DMG): [link]

Happy to answer any questions or take feedback.
```

**Hacker News:**
```
Title: Show HN: ClipSlim -- Auto-optimize clipboard images on macOS (local-only, free)
URL: [website or MAS link]
```

---

## Post-Approval Actions

### Approval Day (execute within 2 hours of approval)

**Verification (15 minutes):**
- [ ] Search Mac App Store for "ClipSlim" -- confirm listing is live
- [ ] Download from MAS on a test machine or clean user account
- [ ] Launch and verify core functionality works
- [ ] Open Settings > Support -- verify tip jar loads real products (not sandbox)
- [ ] Purchase one small tip to confirm real transaction completes

**Announcements (30 minutes):**
- [ ] Post Twitter/X announcement (drafted above)
- [ ] Post Reddit r/macapps (drafted above)
- [ ] Post Hacker News Show HN (drafted above)
- [ ] Update website/landing page with Mac App Store badge and link
- [ ] Email announcement to any existing user list or contacts

**App Store Connect (10 minutes):**
- [ ] Update promotional text to highlight availability:
  ```
  Now on the Mac App Store! Automatic clipboard image optimization, folder watcher, PDF compression. 100% local processing, zero data collection. Free with optional tip jar.
  ```
  (Promotional text can be changed without a new submission)

### Days 1-3 Post-Approval

- [ ] Monitor MAS reviews daily (respond within 24 hours using review-responses.md)
- [ ] Monitor crash reports in App Store Connect
- [ ] Track daily download numbers in App Store Connect > Trends
- [ ] Monitor social media mentions and respond to questions
- [ ] Watch for StoreKit-related issues (tip jar not loading, purchase failures)
- [ ] Document any bug reports for v1.1

### Days 4-7 Post-Approval

- [ ] Week 1 metrics report:
  - Total MAS downloads
  - Total DMG downloads (if tracking)
  - Number of reviews received
  - Average rating
  - Number of tip purchases (Revenue > Proceeds in App Store Connect)
  - Social media reach (impressions, engagement)
- [ ] Check keyword rankings (manual App Store search for primary terms)
- [ ] Review conversion rate in App Store Connect Analytics
- [ ] Plan v1.1 scope based on user feedback
- [ ] Submit to Product Hunt (Tuesday or Wednesday)

---

## Week 2 Post-Approval Actions

### Monday
- [ ] Full keyword ranking check
- [ ] Conversion rate analysis (impressions > page views > installs)
- [ ] Respond to all outstanding reviews
- [ ] Competitor check (any new apps in the space?)

### Wednesday
- [ ] Update promotional text if messaging needs refinement
- [ ] Evaluate screenshot effectiveness (is first screenshot compelling?)
- [ ] Begin v1.1 development if bugs identified

### Friday
- [ ] Week 2 metrics comparison vs. Week 1
- [ ] Plan any metadata adjustments based on data

---

## Success Metrics

### Submission Day (March 16)
| Metric | Target | Status |
|--------|--------|--------|
| Build uploaded | Yes | |
| IAPs configured | 3/3 Ready to Submit | |
| Review notes updated | Yes | |
| Submitted for review | Yes | |

### Approval Week
| Metric | Target | How to Measure |
|--------|--------|----------------|
| Approved without second rejection | Yes | App Store Connect status |
| App live on MAS | Yes | Search Mac App Store |
| Tip jar functional in production | Yes | Manual test purchase |

### First Week Post-Approval
| Metric | Target | How to Measure |
|--------|--------|----------------|
| MAS downloads | 50+ | App Store Connect Trends |
| App Store rating | 4.0+ | App Store Connect |
| Reviews received | 3+ | App Store Connect |
| Critical bugs reported | 0 | All channels |
| Tip purchases | Any (validation) | App Store Connect Revenue |

### First Month Post-Approval
| Metric | Target | How to Measure |
|--------|--------|----------------|
| MAS downloads | 200+ | App Store Connect |
| Average rating | 4.3+ | App Store Connect |
| Reviews | 10+ | App Store Connect |
| Keywords in top 50 | 3+ | Manual search |
| v1.1 submitted | Yes | App Store Connect |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Second rejection (3.1.1) | Low | Medium | Code fully verified, grep confirms zero BMC references |
| Second rejection (different guideline) | Low | Medium | Comprehensive review notes, full smoke test |
| IAPs not loading for reviewer | Medium | High | Configure IAPs before submitting, verify "Ready to Submit" status |
| Long review time (5+ days) | Low | Low | Contact App Review via Resolution Center |
| Low initial downloads | Medium | Low | Social media announcements drafted and ready |
| Negative reviews about tip jar | Low | Low | Response templates prepared in review-responses.md |

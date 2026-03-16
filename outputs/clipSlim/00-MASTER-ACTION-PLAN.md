# ClipSlim - Master ASO Action Plan

**Updated:** March 16, 2026
**Platform:** Mac App Store (macOS)
**App Store ID:** 6759780567
**Current Status:** Version 1.0.0 (Build 7) -- WAITING FOR REVIEW

---

## CURRENT STATE

The app has been submitted to App Review after resolving a Guideline 3.1.1 rejection (external Buy Me a Coffee link replaced with native StoreKit 2 tip jar). All code changes, IAP configuration, and binary upload are complete.

**What is done:**
- StoreKit 2 tip jar implemented (TipStore.swift)
- 3 consumable IAPs created in App Store Connect ($2.99 / $4.99 / $9.99) with localizations, pricing, review screenshots
- Build 7 uploaded, processed, and validated (encryption exempt)
- All BMC references removed from codebase (verified with grep)
- ITSAppUsesNonExemptEncryption = NO in Info.plist
- App submitted -- status is WAITING_FOR_REVIEW

---

## CHECKLIST

### Phase 1: Awaiting Review (Now -- March 17-19)

- [x] Final BMC grep verification -- zero matches
- [x] StoreKit 2 tip jar implemented with 3 consumable IAPs
- [x] IAPs created in App Store Connect with localizations and review screenshots
- [x] Build 7 uploaded and processed (VALID)
- [x] Encryption exemption declared (ITSAppUsesNonExemptEncryption = NO)
- [x] App submitted for review -- WAITING_FOR_REVIEW
- [ ] Monitor App Store Connect status twice daily (morning + evening)
- [ ] Be available for App Review questions via Resolution Center
- [ ] Prepare post-approval announcements while waiting (see 04-launch/action-launch.md for drafts)

### Phase 2: Approval Day (Expected March 17-19)

- [ ] Verify app is live -- search Mac App Store for "ClipSlim"
- [ ] Download from MAS and test fresh install
- [ ] Verify tip jar loads real products (not sandbox)
- [ ] Test one tip purchase to confirm real transaction flow
- [ ] Update promotional text in App Store Connect (no review needed):
  ```
  Now with a native tip jar - support ClipSlim directly in-app. 100% local image & PDF compression from your menubar. Free to download, no account needed.
  ```
- [ ] Post Twitter/X announcement (draft in 04-launch/action-launch.md)
- [ ] Post Reddit r/macapps announcement (draft in 04-launch/action-launch.md)
- [ ] Post Hacker News Show HN (draft in 04-launch/action-launch.md)
- [ ] Update website/landing page with Mac App Store badge and link

### Phase 3: Week 1 Post-Approval (Days 1-7)

- [ ] Respond to all MAS reviews within 24 hours (templates in 05-optimization/review-responses.md)
- [ ] Monitor crash reports daily in App Store Connect
- [ ] Track daily download numbers in App Store Connect > Trends
- [ ] Watch for StoreKit-related issues (tip jar not loading, purchase failures)
- [ ] Document bug reports for v1.1 planning
- [ ] Submit to Product Hunt (Tuesday or Wednesday for best visibility)
- [ ] Record Day 7 baseline metrics:
  - Impressions, Product Page Views, Installs, Conversion Rate
  - Top search terms driving traffic

### Phase 4: Week 2 Post-Approval (Days 8-14)

- [ ] Full keyword ranking check -- search MAS for each primary keyword and record position:
  - "image compressor", "clipboard optimizer", "pdf compressor", "compress png", "menubar utility"
- [ ] Conversion rate analysis (impressions > page views > installs)
- [ ] Update promotional text with fresh copy (rotate to privacy or feature angle)
- [ ] Record Day 14 baseline metrics
- [ ] Competitor check: any updates from Clop, Zipic, Squash, Resize it?

### Phase 5: Month 1 Post-Approval (Weeks 3-4)

- [ ] First keyword adjustment based on 2 weeks of impression data
- [ ] Evaluate A/B test readiness (need 1,000+ impressions for significance)
- [ ] Begin v1.1 development:
  - Add SKStoreReviewController (trigger after 5th successful optimization)
  - Fix any reported bugs
  - Polish based on user feedback
- [ ] Submit v1.1 update
- [ ] Month 1 ASO health report:
  - Total downloads, average rating, review count
  - Top keywords and positions
  - Conversion rate
  - Tip jar revenue

### Phase 6: A/B Testing (After Day 14 Baseline)

- [ ] Test 1 (highest priority): App Icon -- design 2 alternative concepts (see 03-testing/ab-test-setup.md)
- [ ] Test 2: Screenshot 1 hero image -- output-lead vs privacy-lead (run after Test 1 concludes)
- [ ] Test 3: App Name -- sequential submission test (run after 4 weeks of baseline)
- [ ] Log all test results in test log (03-testing/ab-test-setup.md)

### Phase 7: Ongoing Optimization (Monthly)

- [ ] Update promotional text every 4-6 weeks (no review needed)
- [ ] Refresh keywords quarterly based on App Store Connect search data
- [ ] Respond to all reviews within 24 hours
- [ ] Monthly competitor deep dive (Clop, Zipic, Squash, Optimage, Compresto)
- [ ] Quarterly full keyword research refresh
- [ ] Evaluate localization ROI after Month 3 (Japanese, German, French are top Mac utility markets)

---

## METADATA QUICK REFERENCE

| Field | Content | Chars |
|-------|---------|-------|
| **App Name** | `ClipSlim - Clipboard Optimizer` | 30/30 |
| **Subtitle** | `Image & PDF Compressor for Mac` | 30/30 |
| **Keywords** | `compress,png,jpeg,resize,batch,shrink,menubar,photo,converter,heic,screenshot,bulk,pdf,filesize` | 95/100 |
| **Promo Text** | See promotional text above (update freely, no review needed) | 152/170 |

Full description, What's New, and 3 A/B variants: `02-metadata/apple-metadata.md`

---

## TOP KEYWORD OPPORTUNITIES

| Keyword | MAS Competition | Action |
|---------|----------------|--------|
| clipboard image optimization | ZERO | Own this -- core differentiator |
| automatic clipboard compression | ZERO | Feature headline in description |
| folder watcher image | ZERO | Description feature section |
| menubar image compressor | VERY LOW | Keyword field + description |
| pdf compressor | LOW-MEDIUM | Subtitle captures this |

Full 35-keyword list: `01-research/keyword-list.md`

---

## SUCCESS TARGETS

| Timeframe | Downloads | Rating | Reviews | Keywords Top 10 |
|-----------|-----------|--------|---------|-----------------|
| Week 1 | 50+ | 4.0+ | 3+ | 0-1 |
| Month 1 | 200+ | 4.3+ | 10+ | 2-3 |
| Month 3 | 500+ | 4.5+ | 25+ | 5+ |
| Year 1 | 5,000+ | 4.5+ | 100+ | 10+ |

---

## IF REJECTED AGAIN

1. Read rejection message in Resolution Center carefully
2. Most likely causes: IAP metadata incomplete, residual BMC reference, or different guideline
3. Fix immediately, increment build number, rebuild, resubmit same day
4. Use appeal template in 05-optimization/review-responses.md (Template AR1)
5. Resubmissions after rejection are typically reviewed faster (often same/next day)

---

## FILE INDEX

| File | Purpose |
|------|---------|
| `01-research/keyword-list.md` | 35 prioritized keywords with placement guide |
| `01-research/competitor-gaps.md` | 10 competitors analyzed, 5 zero-competition gaps |
| `01-research/action-research.md` | Research phase checklist |
| `02-metadata/apple-metadata.md` | Copy-paste ready metadata + 3 A/B variants |
| `02-metadata/visual-assets-spec.md` | Icon and screenshot specifications |
| `02-metadata/action-metadata.md` | Metadata implementation checklist |
| `03-testing/ab-test-setup.md` | A/B test configuration and test log |
| `04-launch/prelaunch-checklist.md` | Pre-submission validation (72 items) |
| `04-launch/timeline.md` | Day-by-day schedule from submission through Month 1 |
| `04-launch/submission-guide.md` | Step-by-step submission instructions |
| `04-launch/action-launch.md` | Launch execution plan + drafted social posts |
| `05-optimization/review-responses.md` | 18 review response templates |
| `05-optimization/ongoing-tasks.md` | Daily/weekly/monthly optimization schedule |
| `05-optimization/action-optimization.md` | Ongoing optimization strategy |

# Launch Execution Plan - ClipSlim v1.1

**Created:** 2026-04-06
**Context:** Feature update (v1.0 -> v1.1). App already live on MAS.
**Platform:** Mac App Store

---

## Submission Day Checklist

### Morning (2-3 hours total)

**Final Code Verification (30 min)**
- [ ] Run test suite
- [ ] Manual smoke test: clipboard, folder watcher, drop zone, Finder Quick Action, Shortcuts
- [ ] Verify AVIF encoding produces valid output
- [ ] Verify SKStoreReviewController triggers correctly

**Build and Upload (45 min)**
- [ ] Build Release archive
- [ ] Upload to App Store Connect
- [ ] Wait for processing
- [ ] Verify: "Ready to Submit"

**Metadata Entry (30 min)**
- [ ] Create version 1.1.0 in App Store Connect
- [ ] Paste What's New from apple-metadata.md
- [ ] Replace Description from apple-metadata.md
- [ ] Update Keywords field from apple-metadata.md
- [ ] Upload new screenshots from visual-assets-spec.md
- [ ] Update Promotional Text from apple-metadata.md

**Submit (15 min)**
- [ ] Select build
- [ ] Export Compliance: No encryption
- [ ] Privacy: No data collection
- [ ] Add Review Notes: "v1.1 feature update adding AVIF, Shortcuts, Finder Quick Action, comparison slider, metadata control, clipboard history."
- [ ] Submit for Review
- [ ] Confirm: "Waiting for Review"

---

## Approval Day Checklist

- [ ] Verify v1.1 live on Mac App Store
- [ ] Download and test from MAS
- [ ] Verify tip jar works in production
- [ ] Test one tip purchase (optional -- confirm real transaction)

### Announcements
- [ ] Twitter/X: "ClipSlim v1.1 is live! Native AVIF encoding, Shortcuts automation, Finder Quick Action, and more. Still 100% free. [MAS link]"
- [ ] Reddit r/macapps: "ClipSlim v1.1 -- now with AVIF, Shortcuts, and Finder Quick Action"
- [ ] Reddit r/webdev: "Free Mac menubar tool for AVIF/WebP image optimization -- ClipSlim v1.1"
- [ ] Product Hunt: Consider relaunch post
- [ ] Hacker News: Consider Show HN post

### Metrics Setup
- [ ] Begin tracking daily downloads
- [ ] Begin tracking search terms (App Store Connect > Analytics > Search)
- [ ] Set calendar reminder: Day 7 baseline check
- [ ] Set calendar reminder: Day 14 baseline check

---

## Week 1 Routine (15-20 min/day)

**Every morning:**
- [ ] Check App Store Connect for new reviews
- [ ] Check crash reports
- [ ] Check download numbers
- [ ] Respond to any reviews (within 24 hours)

**End of Week 1:**
- [ ] Record Day 7 metrics (impressions, page views, installs, CVR)
- [ ] Note top search terms driving traffic
- [ ] Evaluate if SKStoreReviewController is generating prompts
- [ ] Check if any v1.1 bugs reported

---

## Rating Collection Strategy

This is the #1 priority for v1.1. ClipSlim has 0 ratings after 16 days of v1.0.

- [ ] SKStoreReviewController triggers after 3rd successful optimization
- [ ] Soft CTA in What's New: "Enjoying ClipSlim? A review helps others find us."
- [ ] Social media posts include: "If you find it useful, a review on the App Store really helps!"
- [ ] Do NOT include in-app review nagging beyond SKStoreReviewController
- [ ] Target: 10 ratings within first month, 50 within 3 months

---

## Validation Criteria

v1.1 launch is successful when:
- [ ] App live on MAS with v1.1 metadata
- [ ] All v1.1 features working in production
- [ ] No critical crash reports in first 48 hours
- [ ] At least one announcement posted
- [ ] Baseline tracking started
- [ ] Day 14 metrics recorded
- [ ] First A/B test ready to launch on Day 15

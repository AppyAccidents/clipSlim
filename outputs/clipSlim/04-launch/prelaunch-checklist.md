# Pre-Launch Checklist - ClipSlim v1.1

**Target Submission Date:** When v1.1 build is ready
**Platform:** Mac App Store (macOS only)
**App Store ID:** 6759780567
**Context:** Feature update (v1.0 -> v1.1). App is already live.

---

## Phase 1: Code Readiness

- [ ] All v1.1 features implemented and tested:
  - [ ] AVIF encoding works correctly
  - [ ] Before/after comparison slider functional
  - [ ] Selective metadata control (keep copyright, strip GPS)
  - [ ] Clipboard history with thumbnails
  - [ ] Shortcuts.app OptimizeImageIntent works
  - [ ] Finder Quick Action registered and functional
  - [ ] Smart format detection (screenshot vs photo)
  - [ ] Context-aware app-to-preset mapping
  - [ ] SSIM quality guard
  - [ ] WebP format support
- [ ] SKStoreReviewController implemented (triggers after 3rd successful optimization)
- [ ] No regressions in existing features (clipboard, folder watcher, drop zone, PDF, hotkeys)
- [ ] Run test suite: `xcodebuild -project ClipSlim.xcodeproj -scheme ClipSlim -destination 'platform=macOS' test`
- [ ] Manual smoke test of all input modes (clipboard copy, folder drop, drop zone, Finder Quick Action)
- [ ] Verify tip jar still works (StoreKit 2 IAPs)

---

## Phase 2: Build and Upload

- [ ] Increment version to 1.1.0 in Xcode project settings
- [ ] Increment build number
- [ ] Build Release archive: Product > Archive in Xcode
- [ ] Upload to App Store Connect via Xcode Organizer
- [ ] Wait for build processing (15-30 minutes)
- [ ] Verify build status: "Ready to Submit"

---

## Phase 3: Screenshots

- [ ] Capture new screenshots showing v1.1 features (see visual-assets-spec.md)
- [ ] Required new screenshots:
  - [ ] AVIF format output (Screenshot 2)
  - [ ] Before/after comparison slider (Screenshot 3)
  - [ ] Shortcuts.app integration (Screenshot 4)
  - [ ] Finder Quick Action context menu (Screenshot 5)
  - [ ] Selective metadata control (Screenshot 7)
  - [ ] App-to-preset mapping (Screenshot 8)
- [ ] All screenshots at 2560x1600 resolution
- [ ] Captions added per visual-assets-spec.md guidelines
- [ ] Verify screenshots look good at thumbnail size (search result preview)

---

## Phase 4: Metadata

- [ ] Open apple-metadata.md and have it ready
- [ ] In App Store Connect, create new version 1.1.0:
  - [ ] Paste What's New (497 chars)
  - [ ] Replace Description with v1.1 version (3,847 chars)
  - [ ] Update Keywords field (99 chars, no spaces after commas)
  - [ ] Upload new screenshots
  - [ ] Update Promotional Text (159 chars)
- [ ] Verify no changes to App Name or Subtitle (keep as-is)
- [ ] Run character count validation on all fields

---

## Phase 5: Submission

- [ ] Complete Export Compliance (no encryption - select No)
- [ ] Confirm Privacy Details (Data Collection: None)
- [ ] Verify IAPs are still linked (3 tip jar products)
- [ ] Review submission summary
- [ ] Submit for Review
- [ ] Record submission date: _______________
- [ ] Expected approval: 1-3 business days

---

## Phase 6: Post-Approval (Approval Day)

- [ ] Verify v1.1 is live on Mac App Store
- [ ] Download and test from MAS (fresh update)
- [ ] Verify all v1.1 features work in production
- [ ] Verify tip jar still processes real transactions
- [ ] Post v1.1 announcements:
  - [ ] Twitter/X: highlight AVIF, Shortcuts, Finder Quick Action
  - [ ] Reddit r/macapps: update thread or new post
  - [ ] Reddit r/webdev: AVIF angle for web developers
  - [ ] Product Hunt: consider a "relaunch" post
- [ ] Update Promotional Text if rotating copy
- [ ] Begin 14-day baseline period for A/B testing

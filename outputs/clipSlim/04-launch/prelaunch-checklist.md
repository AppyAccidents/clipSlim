# Pre-Launch Checklist - ClipSlim

**Target Launch Date:** March 7-8, 2026 (this weekend)
**Platform:** Mac App Store + Direct distribution (notarized DMG)
**Status:** In Progress
**Today:** March 5, 2026 -- 2 days to launch

---

## PRIORITY TIERS

Given the 2-day window, items are ranked by priority:
- **P0 (BLOCKER):** Must be done before submission. Launch cannot happen without these.
- **P1 (CRITICAL):** Should be done before launch day. Missing these hurts first impressions.
- **P2 (IMPORTANT):** Do within first week post-launch if time runs out.
- **P3 (NICE TO HAVE):** Can wait until first update cycle.

---

## Phase 1: App Store Connect Setup (P0 -- Do March 5)

### Account and App Record
- [ ] Apple Developer Program membership active and in good standing
- [ ] New App record created in App Store Connect
- [ ] Bundle ID registered: matches `$(PRODUCT_BUNDLE_IDENTIFIER)` in Xcode project
- [ ] App name "ClipSlim" reserved in App Store Connect
- [ ] Primary category set: Utilities
- [ ] Secondary category set: Productivity (optional but recommended)
- [ ] SKU assigned (e.g., `clipslim-v1`)

### Pricing and Availability
- [ ] Pricing tier selected (Free / Paid -- decide now)
- [ ] Availability territories selected (worldwide or specific)
- [ ] Pre-order disabled (launching immediately)

---

## Phase 2: Mac App Store Metadata (P0 -- Do March 5)

### Text Metadata (PRE-WRITTEN -- see outputs/clipSlim/02-metadata/apple-metadata.md)
- [ ] App Name: `clipSlim - Image Optimizer` (25/30 chars) -- READY
- [ ] Subtitle: `Clipboard & Folder Compression` (30/30 chars) -- READY
- [ ] Promotional Text (148/170 chars) -- READY
- [ ] Keywords: `compress,png,jpeg,resize,batch,shrink,menubar,photo,converter,heic,screenshot,bulk,filesize` (91/100 chars) -- READY
- [ ] Description (2,847/4,000 chars) -- READY
- [ ] "What's New" text (840/4,000 chars) -- READY
- [ ] Support URL provided and accessible -- NEEDS SETUP
- [ ] Marketing URL provided (website, even if placeholder) -- NEEDS SETUP
- [ ] Privacy Policy URL published and accessible -- NEEDS SETUP
- [ ] All character limits validated -- DONE (ASO score: 91/100)

### Content Rating
- [ ] Age rating questionnaire completed (should be 4+ for a utility)

### App Review Information
- [ ] Review notes written explaining the app is a menubar utility
  - Note: Explain that the app runs in the menubar (no main window) and how to test it
  - Include: "Copy any image to clipboard. ClipSlim automatically optimizes it. Check menubar icon for status."
- [ ] Demo instructions clear (no login required -- good)
- [ ] Contact information for reviewer provided

---

## Phase 3: Visual Assets (P1 -- Do March 5-6)

### App Icon
- [ ] App icon designed and included in Assets.xcassets (1024x1024 master)
- [ ] Icon renders well at small sizes (16x16, 32x32, 128x128)
- [ ] Icon follows macOS design guidelines (rounded rectangle applied by system)
- [ ] Icon uploaded to App Store Connect (1024x1024 PNG, no transparency, no rounded corners)

### Mac App Store Screenshots
- [ ] Screenshots created for Mac display sizes
  - Required: At least one screenshot
  - Recommended: 3-5 screenshots showing key workflows
  - Resolution: 2880x1800 (Retina) or 1440x900 (non-Retina)
- [ ] Screenshot 1: Menubar popover showing optimization results (hero shot)
- [ ] Screenshot 2: Folder watcher in action with batch results
- [ ] Screenshot 3: Settings panel showing presets and intensity levels
- [ ] Screenshot 4: Overlay resize controls
- [ ] Screenshot 5: Debug log / event history view
- [ ] Text overlays added explaining each feature (readable at thumbnail size)
- [ ] Screenshots uploaded to App Store Connect

### App Preview Video (P3 -- Optional for v1)
- [ ] 15-30 second screen recording showing clipboard optimization flow
- [ ] Uploaded to App Store Connect

---

## Phase 4: Technical Build (P0 -- Do March 5-6)

### Mac App Store Build
- [ ] App builds successfully in Release configuration
- [ ] All tests pass: `xcodebuild test`
- [ ] App sandbox entitlements configured for Mac App Store (if submitting to MAS)
  - IMPORTANT: Current entitlements are empty. Mac App Store requires sandbox.
  - Required entitlements for MAS: `com.apple.security.app-sandbox = true`
  - Plus: file access entitlements for folder watcher
  - Plus: clipboard access (automatic within sandbox on macOS)
- [ ] OR: Decision made to skip Mac App Store and go DMG-only for v1
- [ ] Binary uploaded to App Store Connect via Xcode or `xcrun altool`
- [ ] Build processed without errors in App Store Connect
- [ ] Build selected for submission

### Direct Distribution (DMG) Build
- [ ] Release build compiled: `xcodebuild -configuration Release build`
- [ ] App signed with Developer ID Application certificate
- [ ] DMG created using `scripts/create_stylized_dmg.sh`
- [ ] DMG signed with Developer ID Application certificate
- [ ] Notarization submitted and approved (keychain profile `clipslim-notary` ready)
- [ ] DMG stapled: `xcrun stapler staple`
- [ ] Gatekeeper verified: `spctl --assess --type execute -vv`
- [ ] DMG tested: download from web, open, drag to Applications, launch
- [ ] Version string confirmed: 1.0.0 (build 1)

---

## Phase 5: Legal and Compliance (P0 -- Do March 5)

### Privacy Policy
- [ ] Privacy policy written (can be simple for a local-only app)
  - Key points: No data collection, no network requests, all processing local
  - No analytics, no crash reporting (unless added), no third-party SDKs
- [ ] Privacy policy hosted at a public URL
  - Options: GitHub Pages, app website, or a simple hosted page
- [ ] URL added to App Store Connect

### App Privacy Details (App Store Connect)
- [ ] Data collection declaration completed
  - For ClipSlim: "Data Not Collected" (select this option)
  - No analytics, no tracking, no data linked to user
- [ ] Privacy nutrition label shows clean (no data types collected)

### Terms of Service (P2)
- [ ] Terms of service written (optional but recommended)
- [ ] Hosted at public URL

---

## Phase 6: Distribution Infrastructure (P1 -- Do March 6)

### Website / Landing Page
- [ ] Landing page live (even minimal: app name, description, download link)
- [ ] DMG download link functional
- [ ] System requirements listed (macOS 14.0+ Sonoma)
- [ ] Screenshots or GIF demo on page
- [ ] Privacy policy linked from page
- [ ] Support contact listed

### Support Channel
- [ ] Support email configured (e.g., support@appyaccidents.com or GitHub Issues)
- [ ] Support URL submitted to App Store Connect
- [ ] GitHub Issues enabled as backup support channel

### Analytics (P2)
- [ ] Download tracking for DMG (e.g., simple server-side counter or GitHub release download count)
- [ ] App Store Connect analytics will auto-track MAS downloads

---

## Phase 7: Marketing Preparation (P1 -- Do March 6-7)

### Social Media
- [ ] Launch announcement drafted for Twitter/X
- [ ] Launch announcement drafted for Mastodon (if applicable)
- [ ] Reddit post drafted for r/macapps (high-value community)
- [ ] Reddit post drafted for r/apple or r/mac
- [ ] Hacker News "Show HN" post drafted
- [ ] Product Hunt launch prepared (P2 -- can do week after)

### Content
- [ ] One-paragraph press blurb written
- [ ] 3 key differentiators documented for sharing:
  1. 100% local, zero data collection
  2. Automatic clipboard optimization (set and forget)
  3. Folder watcher for batch processing
- [ ] App icon and screenshots exported for social sharing

---

## Phase 8: ASO Foundation (P1)

### Keywords Strategy
- [ ] Primary keywords identified and placed in title/subtitle
- [ ] Full keyword field populated (100 chars)
- [ ] Competitor keywords analyzed (Clop, ImageOptim, Squash, TinyPNG)
- [ ] Keyword tracking set up (manual spreadsheet or tool)

### Conversion Optimization
- [ ] First screenshot is the strongest selling point
- [ ] Description front-loads key benefits
- [ ] Promotional text highlights unique value (local-only, automatic)

---

## CRITICAL DECISION: Mac App Store Sandboxing

**Issue:** ClipSlim currently has empty entitlements and uses hardened runtime without sandbox. The Mac App Store REQUIRES app sandbox (`com.apple.security.app-sandbox`).

**Options:**
1. **Add sandbox entitlements** -- Requires testing clipboard access and folder watcher under sandbox. May need `com.apple.security.temporary-exception.apple-events` or file access entitlements. Risk of breaking functionality.
2. **Launch DMG-only first** -- Skip Mac App Store for v1.0. Launch direct distribution immediately. Submit to MAS in v1.1 after sandbox testing.
3. **Submit to MAS and DMG simultaneously** -- If sandbox entitlements are straightforward to add.

**Recommendation:** Option 2 (DMG-only for this weekend, MAS submission next week after sandbox testing). This avoids rushing sandbox work and risking App Review rejection.

---

## Summary

| Phase | Items | Priority | Target |
|-------|-------|----------|--------|
| App Store Connect Setup | 7 | P0 | March 5 |
| Metadata | 13 | P0 | March 5 |
| Visual Assets | 9 | P1 | March 5-6 |
| Technical Build | 13 | P0 | March 5-6 |
| Legal/Compliance | 7 | P0 | March 5 |
| Distribution | 7 | P1 | March 6 |
| Marketing | 8 | P1 | March 6-7 |
| ASO Foundation | 5 | P1 | March 6 |

**Total Items:** 69
**P0 (Blockers):** 40
**P1 (Critical):** 22
**P2/P3 (Deferrable):** 7

**Estimated Work:**
- March 5: 6-8 hours (metadata, legal, App Store Connect, build)
- March 6: 4-6 hours (screenshots, website, marketing prep, final build)
- March 7: 2-3 hours (launch execution, announcements)

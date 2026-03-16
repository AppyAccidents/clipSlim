# Pre-Launch Checklist - ClipSlim (Resubmission)

**Target Submission Date:** March 16, 2026 (today)
**Platform:** Mac App Store (macOS only)
**App Store ID:** 6759780567
**Status:** Resubmission after Guideline 3.1.1 rejection
**Rejection Reason:** External donation link (Buy Me a Coffee) violates Guideline 3.1.1
**Fix Applied:** Replaced all BMC references with native StoreKit 2 consumable tip jar

---

## PRIORITY TIERS

- **P0 (BLOCKER):** Must pass before clicking "Submit for Review." Failure means another rejection.
- **P1 (CRITICAL):** Should be done to maximize approval odds and launch quality.
- **P2 (IMPORTANT):** Do within first week post-approval if time runs out today.

---

## Phase 1: Guideline 3.1.1 Compliance Verification (P0)

This is the reason for rejection. Every item here must be verified before resubmission.

### Code Audit -- No External Payment References
- [x] All Buy Me a Coffee code removed from codebase
- [x] No BMC URLs in any Swift files (verified via grep: zero matches)
- [x] No BMC URLs in Info.plist or entitlements
- [x] No BMC references in storyboards, XIBs, or asset catalogs
- [x] No BMC SDK or framework linked
- [x] No external donation links in any UI (buttons, labels, text views)
- [x] No external payment URLs opened via NSWorkspace or similar

### StoreKit 2 Implementation Verified
- [x] TipStore.swift uses native StoreKit 2 `Product.products()` API
- [x] Three consumable IAPs defined:
  - `com.appyaccidents.clipslim.tip.small` ($2.99)
  - `com.appyaccidents.clipslim.tip.medium` ($4.99)
  - `com.appyaccidents.clipslim.tip.large` ($9.99)
- [x] ClipSlim.storekit configuration file matches product IDs
- [x] SupportTab.swift uses native VibeButton for tip purchases (no external links)
- [x] Transaction.finish() called on successful purchase
- [x] Error handling for failed/cancelled/pending states
- [x] No "donate" language that implies money bypasses Apple's system

### App Store Connect IAP Configuration
- [ ] All three consumable IAPs created in App Store Connect
- [ ] IAP status: "Ready to Submit" for all three (not "Missing Metadata" or "Developer Action Needed")
- [ ] IAP pricing set correctly for all territories ($2.99 / $4.99 / $9.99 USD)
- [ ] IAP display names match StoreKit config (Small Tip / Medium Tip / Large Tip)
- [ ] IAP descriptions filled in for all three products
- [ ] IAP review screenshot uploaded for each (screenshot of SupportTab showing tip buttons)
- [ ] IAP review notes added: "These are optional consumable tips. The app is fully functional without purchase."

### Metadata Audit for Payment Language
- [ ] App description does NOT mention Buy Me a Coffee, donations, or external payment
- [ ] App description does NOT contain any external payment URLs
- [ ] Promotional text does NOT reference external funding or donation
- [ ] Screenshots do NOT show any BMC buttons, links, or branding
- [ ] If SupportTab appears in any screenshot, it shows only native tip jar buttons

---

## Phase 2: Technical Build Verification (P0)

### Build and Test
- [ ] App builds successfully in Release configuration:
  ```
  xcodebuild -project ClipSlim.xcodeproj -scheme ClipSlim -configuration Release build
  ```
- [ ] All tests pass:
  ```
  xcodebuild -project ClipSlim.xcodeproj -scheme ClipSlim -destination 'platform=macOS' test
  ```
- [ ] App sandbox entitlements correctly configured for MAS
- [ ] StoreKit 2 tip jar loads products in sandbox testing environment
- [ ] Tip purchase flow completes in sandbox (buy, verify, finish transaction)
- [ ] Tip purchase error states handled gracefully (cancel, fail, network error)
- [ ] No crashes during tip jar interaction
- [ ] "Tips unavailable" message displays gracefully when products fail to load

### Binary Upload
- [ ] Archive created via Xcode (Product > Archive)
- [ ] Build uploaded to App Store Connect via Xcode Organizer
- [ ] Build processed without errors in App Store Connect
- [ ] Build status shows "Ready to Submit" (not "Processing" or "Invalid Binary")
- [ ] Build version number incremented from the rejected build

### Core Functionality Smoke Test
- [ ] App launches and appears in menubar
- [ ] Clipboard optimization works (copy image, verify auto-compression)
- [ ] Folder watcher works (enable, drop image in watched folder)
- [ ] PDF compression works (copy PDF to clipboard)
- [ ] Drop zone works (drag and drop images)
- [ ] Global hotkeys work (Option+1 optimized, Option+2 original)
- [ ] Settings persist across quit/relaunch
- [ ] Support tab shows tip jar with three native buttons (no external links)

---

## Phase 3: App Store Connect Metadata (P1)

### Text Metadata
- [ ] App Name verified: `clipSlim - Image Optimizer` (25/30 chars) -- unchanged
- [ ] Subtitle verified: `Clipboard & Folder Compression` (30/30 chars) -- unchanged
- [ ] Keywords verified: 91/100 chars, no external payment terms
- [ ] Description verified: no BMC or external donation references
- [ ] Promotional text reviewed (update if desired)
- [ ] What's New updated for this version (mention tip jar if appropriate)
- [ ] Support URL accessible and loading
- [ ] Privacy Policy URL accessible and loading
- [ ] Marketing URL accessible (if set)

### Visual Assets
- [ ] Screenshots still accurate (no BMC buttons visible)
- [ ] App icon uploaded and displays correctly

### Content and Privacy
- [ ] Age rating questionnaire completed (4+)
- [ ] App Privacy details: "Data Not Collected" still accurate
- [ ] StoreKit transactions are handled by Apple -- no new privacy data to declare

---

## Phase 4: In-App Purchase Setup in App Store Connect (P0)

### Small Tip ($2.99)
- [ ] Type: Consumable
- [ ] Reference Name: Small Tip
- [ ] Product ID: `com.appyaccidents.clipslim.tip.small`
- [ ] Price: Tier 3 ($2.99 USD)
- [ ] Display Name (localization): Small Tip
- [ ] Description (localization): A small tip to support ClipSlim development
- [ ] Review screenshot uploaded (SupportTab showing tip buttons)
- [ ] Status: Ready to Submit

### Medium Tip ($4.99)
- [ ] Type: Consumable
- [ ] Reference Name: Medium Tip
- [ ] Product ID: `com.appyaccidents.clipslim.tip.medium`
- [ ] Price: Tier 5 ($4.99 USD)
- [ ] Display Name (localization): Medium Tip
- [ ] Description (localization): A medium tip to support ClipSlim development
- [ ] Review screenshot uploaded
- [ ] Status: Ready to Submit

### Large Tip ($9.99)
- [ ] Type: Consumable
- [ ] Reference Name: Large Tip
- [ ] Product ID: `com.appyaccidents.clipslim.tip.large`
- [ ] Price: Tier 10 ($9.99 USD)
- [ ] Display Name (localization): Large Tip
- [ ] Description (localization): A large tip to support ClipSlim development
- [ ] Review screenshot uploaded
- [ ] Status: Ready to Submit

### IAP Validation
- [ ] All three IAPs show "Ready to Submit" status in App Store Connect
- [ ] IAPs are included with the app version submission (visible in submission summary)
- [ ] Pricing is correct across all configured territories

---

## Phase 5: App Review Notes -- Resubmission (P0)

This is critical. The reviewer will specifically check for 3.1.1 compliance.

- [ ] App Review notes updated with the resubmission context (copy-paste ready text below)
- [ ] Demo account field: "No demo account required"
- [ ] Contact information filled in (name, email, phone)

**Copy-paste for App Review Notes:**

```
RESUBMISSION NOTE (Guideline 3.1.1 Resolution):

The previous submission was rejected for using an external donation link
(Buy Me a Coffee). This has been fully resolved:

1. ALL Buy Me a Coffee references have been removed from the app
2. The donation/tip functionality now uses native StoreKit 2 consumable
   in-app purchases exclusively
3. Three tip options are available: Small Tip ($2.99), Medium Tip ($4.99),
   Large Tip ($9.99)
4. Tips are entirely optional -- the app is fully functional without purchase
5. The tip jar is located in Settings > Support tab

HOW TO TEST THE TIP JAR:
1. Launch ClipSlim (menubar icon appears in top-right area)
2. Click the menubar icon > gear icon to open Settings
3. Navigate to the "Support" tab
4. Three tip buttons are displayed, all using native StoreKit 2

HOW TO TEST CORE FUNCTIONALITY:
1. Launch ClipSlim. The app icon appears in the macOS menubar.
2. Copy any image to your clipboard (e.g., take a screenshot with Cmd+Shift+4)
3. ClipSlim automatically detects and optimizes the clipboard image.
4. Check the menubar popover for optimization results (file size reduction).
5. Additional: Enable Folder Watcher in Settings to monitor a directory.

NO LOGIN REQUIRED. No account needed. No network access required for core
functionality. All image/PDF processing is local via Apple's ImageIO framework.

Contact: support@appyaccidents.com
```

---

## Phase 6: Final Validation Before Submit (P0)

### Pre-Submit Checklist
- [ ] Grep entire project one final time for: buymeacoffee, buy me a coffee, bmc, donation link
- [ ] Run the app and navigate to every screen -- confirm zero external payment UI
- [ ] Verify StoreKit products load in sandbox environment
- [ ] All three IAPs show "Ready to Submit" in App Store Connect
- [ ] Build is selected and shows "Ready to Submit"
- [ ] App Review notes explicitly address the 3.1.1 fix (see Phase 5)
- [ ] All URLs work in a browser (privacy policy, support, marketing)
- [ ] Re-read Guideline 3.1.1 one final time to confirm full compliance

### Submit
- [ ] Click "Submit to App Review"
- [ ] Confirm submission status shows "Waiting for Review"
- [ ] Note submission timestamp: _______ (for tracking)

---

## Summary

| Phase | Items | Priority |
|-------|-------|----------|
| 3.1.1 Compliance Verification | 18 | P0 |
| Technical Build Verification | 17 | P0 |
| App Store Connect Metadata | 11 | P1 |
| IAP Setup in App Store Connect | 13 | P0 |
| App Review Notes (Resubmission) | 3 | P0 |
| Final Validation | 10 | P0 |

**Total Items:** 72
**P0 (Blockers):** 61
**P1 (Critical):** 11

**Estimated Work:** 2-3 hours (code changes already done; this is validation, IAP configuration, and App Store Connect setup)

**Key Risk:** IAPs not configured in App Store Connect. If IAPs are not created and showing "Ready to Submit," the submission will either fail or the tip jar will not work for the reviewer, potentially causing another rejection.

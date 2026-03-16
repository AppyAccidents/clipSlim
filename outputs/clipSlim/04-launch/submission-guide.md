# Submission Guide - ClipSlim (Resubmission)

**Version:** Current (incremented from rejected build)
**Platform:** macOS 14.0+ (Sonoma)
**Distribution:** Mac App Store
**Context:** Resubmission after Guideline 3.1.1 rejection
**App Store ID:** 6759780567

---

## Overview

This is a resubmission, not a first-time submission. The app record already exists in App Store Connect. The primary task is uploading a new build with the StoreKit 2 tip jar, configuring IAPs, and providing clear review notes explaining the 3.1.1 fix.

---

## Step 1: Verify the Fix is Complete

Before building, confirm zero external payment references remain.

```bash
cd /Users/berkerceylan/Documents/GitHub/clipSlim

# Search for any remaining BMC references
grep -ri "buymeacoffee\|buy.me.a.coffee\|bmc\|buymeacoffee" --include="*.swift" --include="*.plist" --include="*.storyboard" .

# Expected output: no matches
```

Verify the StoreKit implementation:
- Open `ClipSlim/Services/TipStore.swift` -- confirm it uses `Product.products()` and `product.purchase()`
- Open `ClipSlim/Views/Settings/SupportTab.swift` -- confirm tip buttons use `VibeButton` with `store.purchase()`, no external URLs
- Open `ClipSlim.storekit` -- confirm three consumable products with correct IDs

---

## Step 2: Run Tests

```bash
xcodebuild -project ClipSlim.xcodeproj \
  -scheme ClipSlim \
  -destination 'platform=macOS' \
  test
```

All tests must pass. If any fail, fix before proceeding.

---

## Step 3: Increment Build Number

The rejected build's version/build number cannot be reused. In Xcode:

1. Select the ClipSlim target
2. Go to General > Identity
3. Increment the Build number (e.g., if rejected build was 5, set to 6)
4. Version number can stay the same unless you want to increment it

Alternatively, edit directly:
```bash
# Check current build number
grep -A1 "CURRENT_PROJECT_VERSION" ClipSlim.xcodeproj/project.pbxproj | head -5

# Or check Info.plist if build number is set there
```

---

## Step 4: Build Release Archive

**Option A: Via Xcode (Recommended)**

1. In Xcode, select the ClipSlim scheme
2. Set destination to "Any Mac (Apple Silicon, Intel)"
3. Product > Archive
4. Wait for archive to complete (progress in the Activity area)
5. Organizer window opens automatically when done

**Option B: Via Command Line**

```bash
xcodebuild -project ClipSlim.xcodeproj \
  -scheme ClipSlim \
  -configuration Release \
  -archivePath /tmp/ClipSlim.xcarchive \
  archive
```

---

## Step 5: Upload to App Store Connect

**Via Xcode Organizer (Recommended):**

1. In the Organizer window, select the new archive
2. Click "Distribute App"
3. Select "App Store Connect"
4. Select "Upload"
5. Follow prompts:
   - Signing: Automatic (or select Apple Distribution certificate)
   - Review entitlements: confirm sandbox is enabled
   - Review content: confirm no issues flagged
6. Click "Upload"
7. Wait for upload to complete (usually 2-5 minutes)

**Via Command Line:**

```bash
xcodebuild -exportArchive \
  -archivePath /tmp/ClipSlim.xcarchive \
  -exportPath /tmp/ClipSlimExport \
  -exportOptionsPlist ExportOptions.plist
```

ExportOptions.plist (if needed):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

---

## Step 6: Wait for Build Processing

After upload:
- App Store Connect will process the build (typically 15-30 minutes)
- You will receive an email when processing is complete
- Check App Store Connect > Your App > TestFlight or Activity tab for status
- Status should change from "Processing" to a version number

If processing fails:
- Check email for error details
- Common issues: missing entitlements, invalid signing, missing icon sizes
- Fix and re-upload

---

## Step 7: Configure In-App Purchases

Navigate to App Store Connect > Your App > In-App Purchases (left sidebar under Features or Monetization).

### Create Each IAP

For each of the three tips, click the "+" button:

**IAP 1: Small Tip**
- Type: Consumable
- Reference Name: Small Tip
- Product ID: `com.appyaccidents.clipslim.tip.small`
- Availability: Available in all territories
- Price Schedule: $2.99 USD (Tier 3) -- Apple auto-calculates other currencies
- Localizations > English (U.S.):
  - Display Name: Small Tip
  - Description: A small tip to support ClipSlim development
- Review Information:
  - Screenshot: Upload a screenshot of the Support tab showing the three tip buttons
  - Review Notes: "This is an optional consumable tip. The app is fully functional without purchase. Users can tip from Settings > Support."
- Save

**IAP 2: Medium Tip**
- Same as above but:
  - Reference Name: Medium Tip
  - Product ID: `com.appyaccidents.clipslim.tip.medium`
  - Price: $4.99 USD (Tier 5)
  - Display Name: Medium Tip
  - Description: A medium tip to support ClipSlim development

**IAP 3: Large Tip**
- Same as above but:
  - Reference Name: Large Tip
  - Product ID: `com.appyaccidents.clipslim.tip.large`
  - Price: $9.99 USD (Tier 10)
  - Display Name: Large Tip
  - Description: A large tip to support ClipSlim development

### Verify IAP Status

After creating all three:
- Each should show status "Ready to Submit"
- If any shows "Missing Metadata" or "Developer Action Needed," click into it and fill in the missing fields
- All three must be "Ready to Submit" before you submit the app for review

---

## Step 8: Configure App Version for Submission

In App Store Connect, navigate to your app > macOS > the version being submitted.

### Select Build
1. Under "Build," click the "+" button
2. Select the newly uploaded build
3. Verify version and build number are correct

### Update What's New (Optional)

If this is a version update, consider updating the What's New text:
```
- Added native Tip Jar (Settings > Support) -- optional tips to support development
- Improved PDF compression workflow
- Bug fixes and performance improvements
```

### Update App Review Information

This is the most important step for a resubmission.

1. Scroll to "App Review Information"
2. Replace the existing review notes with the full resubmission text from prelaunch-checklist.md Phase 5
3. Verify contact information is correct
4. Demo Account: "No demo account required"

### Verify Metadata

Scroll through all metadata fields and confirm:
- No references to Buy Me a Coffee anywhere
- Description is clean
- Promotional text is clean
- All URLs are working

---

## Step 9: Submit for Review

1. At the top of the version page, click "Add for Review" (or "Submit to App Review")
2. A submission summary page will appear showing:
   - The app version
   - The build
   - In-App Purchases (all three should be listed)
   - Export compliance information
3. Review the summary carefully
4. Confirm that all three IAPs are included
5. Click "Submit to App Review"
6. Status should change to "Waiting for Review"

---

## Step 10: Post-Submission Monitoring

### Status Tracking

Check App Store Connect at least twice daily:

| Status | Meaning | Action |
|--------|---------|--------|
| Waiting for Review | In the queue | Wait. Do not submit another build. |
| In Review | Reviewer is looking at it now | Be available for questions. |
| Approved | Passed review | App will go live shortly. Celebrate. |
| Rejected | Failed review again | Read reason carefully. Fix and resubmit. |

### If Approved

1. Verify app is live: search Mac App Store for "ClipSlim"
2. Download and test (fresh install from MAS)
3. Verify tip jar loads real products (not sandbox)
4. Post launch announcements
5. Begin monitoring reviews and downloads

### If Rejected Again

1. Read the rejection message in Resolution Center
2. Identify the specific issue cited
3. Common second-rejection reasons:
   - **IAP metadata incomplete:** Fix in App Store Connect, no code change needed. Resubmit.
   - **Residual external payment reference found:** The reviewer found something the grep missed. Search harder, fix, rebuild, resubmit.
   - **Different guideline entirely:** Address the new issue separately.
4. Reply in Resolution Center acknowledging the issue and stating your fix
5. Fix, rebuild (increment build number again), upload, resubmit
6. Resubmissions after a rejection are typically reviewed faster (often same day or next day)

---

## Quick Reference: Resubmission Pipeline

```
1. Verify code (grep for BMC)
2. Run tests
3. Increment build number
4. Archive (Product > Archive)
5. Upload (Distribute App > App Store Connect > Upload)
6. Wait for processing (15-30 min)
7. Configure IAPs in App Store Connect (if not done)
8. Select build in version page
9. Update App Review notes (resubmission explanation)
10. Submit for Review
11. Monitor status (1-3 business days)
```

---

## Common Pitfalls for 3.1.1 Resubmissions

1. **Forgetting to configure IAPs in App Store Connect.** The code can be perfect, but if IAPs are not set up server-side, the reviewer's device will not load products, and the tip jar will show "Tips unavailable."

2. **Not incrementing the build number.** App Store Connect rejects uploads with the same build number as a previously submitted (even rejected) build.

3. **Leaving BMC references in metadata.** Even if the code is clean, if the App Store description or screenshots mention external payment, Apple will flag it.

4. **Not explaining the fix in review notes.** Reviewers appreciate clear resubmission context. It speeds up review because they know exactly what changed and what to look for.

5. **Submitting a new build while one is in review.** This can cause the current review to be cancelled and restart the queue. Wait for the current review to resolve before uploading again.

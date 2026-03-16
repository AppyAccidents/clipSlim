# Metadata Implementation Checklist - ClipSlim

**Last Updated:** 2026-03-16
**Developer:** AppyAccidents
**Update:** StoreKit 2 Tip Jar (replaces Buy Me a Coffee link + donation reminder notifications)

---

## THIS UPDATE - WHAT CHANGED

The following changes require a new app binary submission:

| Change | Type | Action Required |
|--------|------|----------------|
| StoreKit 2 tip jar (3 consumable IAPs) | Feature addition | New binary |
| Removed donation reminder notifications | Behavior change | New binary |
| Updated Support tab with tip jar UI | UI change | New binary |
| "Leave a Tip" added to menubar menu | UI change | New binary |
| What's New copy | Metadata | Paste from apple-metadata.md |
| Promotional Text (tip jar callout) | Metadata | Paste from apple-metadata.md |

The following do NOT require a new submission and can be updated immediately:

| Change | Type | Action Required |
|--------|------|----------------|
| Promotional Text update | Metadata | Update in App Store Connect anytime |

---

## PRE-SUBMISSION TASKS

### 1. In-App Purchase Configuration (Tip Jar)

Before submitting the binary, confirm all three IAP products are configured in App Store Connect:

- [ ] Navigate to My Apps > ClipSlim > In-App Purchases
- [ ] Confirm product 1 exists: Reference Name "Tip - Small", Type "Consumable", Price $2.99
- [ ] Confirm product 2 exists: Reference Name "Tip - Medium", Type "Consumable", Price $4.99
- [ ] Confirm product 3 exists: Reference Name "Tip - Large", Type "Consumable", Price $9.99
- [ ] Each IAP product has a Display Name (e.g., "Small Tip") and Description filled in for App Review
- [ ] IAP products are set to "Ready to Submit" status before submitting the parent app

**IAP Display Name and Description suggestions for App Review:**

| Product | Display Name | Description |
|---------|-------------|-------------|
| Tip - Small | Small Tip | A small thank-you tip to support ClipSlim development. |
| Tip - Medium | Medium Tip | A medium thank-you tip to support ClipSlim development. |
| Tip - Large | Large Tip | A generous thank-you tip to support ClipSlim development. |

### 2. App Store Connect - New Version

- [ ] Log in to https://appstoreconnect.apple.com
- [ ] Navigate to My Apps > ClipSlim
- [ ] Click the "+" next to the existing version number in the left sidebar
- [ ] Enter the new version number (e.g., 1.1.0 or 1.2.0 - follow your existing versioning scheme)
- [ ] Confirm the version is in "Prepare for Submission" state

### 3. Paste Metadata - Step by Step

All copy is in `/outputs/clipSlim/02-metadata/apple-metadata.md`. Use the PRIMARY METADATA section.

**Paste order:**

| Step | Field | Source | Location in App Store Connect |
|------|-------|--------|------------------------------|
| 1 | App Name | Primary > App Name | App Information > Name |
| 2 | Subtitle | Primary > Subtitle | App Information > Subtitle |
| 3 | Save App Information | - | Click Save in top right |
| 4 | Description | Primary > Description | Version Information > Description |
| 5 | What's New | Primary > What's New | Version Information > What's New |
| 6 | Keywords | Primary > Keywords Field | Version Information > Keywords |
| 7 | Promotional Text | Primary > Promotional Text | Version Information > Promotional Text |
| 8 | Save Version Information | - | Click Save in top right |

- [ ] App Name pasted and saved
- [ ] Subtitle pasted and saved
- [ ] Description pasted
- [ ] What's New pasted
- [ ] Keywords pasted - confirmed no spaces after commas
- [ ] Promotional Text pasted

### 4. Visual Assets

- [ ] Screenshots are current and reflect the new Support tab with tip jar UI
- [ ] If screenshots do not show tip jar UI, either update screenshot 5 (recommended) or keep current screenshots (acceptable for this update)
- [ ] App icon unchanged - no action required
- [ ] See visual-assets-spec.md for any new screenshot requirements

### 5. App Review Information

- [ ] Navigate to Version Information > App Review Information
- [ ] Confirm no login credentials are required (ClipSlim has no accounts)
- [ ] Add or update review notes:

```
Review Notes for App Review Team:

ClipSlim is a macOS menubar utility that automatically compresses images and PDFs on the clipboard.

To test the core feature:
1. Launch ClipSlim from the menubar (the app icon appears in the top menubar after launch)
2. Copy any image file to the clipboard (PNG, JPEG, HEIC, or TIFF)
3. The app compresses the image automatically and shows a notification overlay
4. Use Option+1 to paste the optimized version, Option+2 to paste the original

To test the tip jar (new in this version):
1. Open ClipSlim and click the menubar icon
2. Either navigate to the Support tab, or click "Leave a Tip" in the menubar dropdown
3. Three tip amounts are available: $2.99, $4.99, $9.99
4. These are consumable in-app purchases with no functionality unlock - they are voluntary tips

The Folder Watcher tab allows monitoring a directory for automatic compression of new files.
All processing is 100% local - no network access is required for any feature.
```

### 6. Privacy Details

- [ ] Navigate to App Privacy in the left sidebar
- [ ] Confirm Data Collection is set to "We do not collect data from this app"
- [ ] Confirm Privacy Policy URL is set: https://appyaccidents.com/privacy
- [ ] Confirm Support URL is set

### 7. Pricing

- [ ] Base app price: Free
- [ ] Tip jar IAPs are priced separately as consumables (configured in step 1)
- [ ] No subscription products required

---

## SUBMISSION

- [ ] Attach the new binary build (via Xcode Organizer or Transporter)
- [ ] Complete Export Compliance: ClipSlim uses no encryption - select "No" when asked
- [ ] Review all metadata fields one final time using the App Store preview tool
- [ ] Click "Submit for Review"
- [ ] Note submission date for tracking

**Expected review time:** 24-48 hours for Utilities category updates. Tip jar IAPs may add a day if this is the first time App Review evaluates the consumable products.

---

## POST-APPROVAL TASKS (Day 1)

- [ ] Confirm app is live and searchable on the Mac App Store
- [ ] Search "ClipSlim" and confirm the app appears with updated subtitle and promotional text
- [ ] Search "clipboard optimizer" and "image compressor mac" and note placement
- [ ] Test the tip jar purchase flow on a device using a sandbox or production account
- [ ] Take a screenshot of search placement for baseline tracking
- [ ] Update Promotional Text if the current copy needs refreshing (no submission needed)

---

## POST-LAUNCH METADATA TASKS (Week 1-2)

- [ ] Monitor App Store Connect Analytics daily: impressions, product page views, installs, conversion rate
- [ ] Check for any App Review rejection notes in Resolution Center
- [ ] If early reviews mention the tip jar positively, note the language for future description updates
- [ ] Baseline conversion rate: record Day 7 numbers before starting any A/B test

---

## POST-LAUNCH METADATA TASKS (Month 1)

### Week 2
- [ ] Update Promotional Text with fresh copy (no submission required). Options:
  - Rotate to privacy angle: "100% local image and PDF compression. No cloud, no accounts. ClipSlim runs silently in your Mac menubar. Free."
  - Rotate to feature angle: "Folder Watcher. Drop Zone. PDF compression. ClipSlim handles images and PDFs automatically from your Mac menubar. Free to download."

### Week 3-4
- [ ] Start App Name A/B test using Product Page Optimization (see ab-test-setup.md)
- [ ] Review keyword performance: which search terms are driving impressions but not installs?
- [ ] Candidate keyword field replacements if needed: `lossless,workflow,editor,transparency,export`

### End of Month 1
- [ ] Review conversion rate: impressions to installs ratio
- [ ] If conversion rate is below 20%, prioritize Screenshot 1 A/B test (see ab-test-setup.md)
- [ ] If conversion rate is above 35%, maintain current metadata and focus on driving more top-of-funnel impressions

---

## ONGOING MAINTENANCE SCHEDULE

| Task | Frequency | Effort | Notes |
|------|-----------|--------|-------|
| Update Promotional Text | Every 4-6 weeks | 10 min | No submission needed |
| Refresh What's New | Per release | 20 min | Template in apple-metadata.md |
| Review and rotate Keywords field | Quarterly | 30 min | Check App Store Connect search term data first |
| Refresh Description with new features | Per major release | 1 hour | Add tip jar stats or testimonials when available |
| Add review quotes to Description | After 20+ reviews collected | 20 min | Add before the REQUIREMENTS section |
| Run screenshot A/B test | Quarterly | 2 hours | Use Product Page Optimization |
| Consider localization | When volume justifies | 1-2 days | German and Japanese are strong Mac utility markets |

---

## METADATA CHANGE APPROVAL REQUIREMENTS

| Change | Requires App Submission |
|--------|------------------------|
| App Name | YES |
| Subtitle | YES |
| Description | YES |
| What's New | YES |
| Keywords | YES |
| Promotional Text | NO - update anytime in App Store Connect |
| Screenshots | NO - update anytime for the current live version |
| App Preview Video | NO - update anytime for the current live version |
| IAP pricing | NO - change anytime in Pricing and Availability |
| Base app pricing | NO - change anytime |

**Key implication:** Promotional Text is the only real-time metadata lever. Keep it current. Every time you ship a meaningful update, update the Promotional Text the same day to call it out - without waiting for App Review.

---

## METADATA FILE REFERENCE

| File | Purpose |
|------|---------|
| `02-metadata/apple-metadata.md` | All App Store copy: primary metadata, 3 variants, implementation guide |
| `02-metadata/visual-assets-spec.md` | Icon and screenshot requirements, design guidance |
| `02-metadata/action-metadata.md` | This file - implementation checklist per update |
| `03-testing/ab-test-setup.md` | A/B test configuration and test log |

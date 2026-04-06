# Submission Guide - ClipSlim v1.1

**Version:** 1.1.0
**Platform:** macOS 14.0+ (Sonoma)
**Distribution:** Mac App Store
**Last Updated:** 2026-04-06

---

## Pre-Submission Verification

### Code
- [ ] Version set to 1.1.0 in Xcode project
- [ ] Build number incremented from v1.0 build
- [ ] All v1.1 features tested and working
- [ ] SKStoreReviewController implemented
- [ ] No debug/development flags left enabled
- [ ] Hardened Runtime enabled
- [ ] App Sandbox enabled
- [ ] Signing with App Store distribution certificate

### App Store Connect
- [ ] Navigate to: appstoreconnect.apple.com > My Apps > ClipSlim
- [ ] Create new version: 1.1.0

---

## Metadata Submission (Copy from apple-metadata.md)

### Fields That Change in v1.1

| Field | Action | Source |
|-------|--------|--------|
| Description | Replace entirely | apple-metadata.md "Description" section |
| What's New | New text | apple-metadata.md "What's New" section |
| Keywords | Update | `compress,png,jpeg,resize,batch,shrink,menubar,photo,avif,heic,webp,shortcuts,metadata,quick,action` |
| Promotional Text | Update | apple-metadata.md "Promotional Text" section |
| Screenshots | Add new, reorder | visual-assets-spec.md |

### Fields That Do NOT Change

| Field | Current Value | Action |
|-------|---------------|--------|
| App Name | ClipSlim - Clipboard Optimizer | Keep |
| Subtitle | Image & PDF Compressor for Mac | Keep |
| Category | Utilities (primary) | Keep |
| Secondary Category | Developer Tools | Keep |
| Price | Free | Keep |
| Privacy Details | Data Collection: None | Keep |

---

## Build Upload Steps

1. In Xcode: Product > Archive
2. In Xcode Organizer: Select archive > Distribute App > App Store Connect
3. Wait for processing (15-30 minutes)
4. In App Store Connect: verify build appears under the v1.1.0 version
5. Select the build

---

## Submission Steps

1. [ ] Select v1.1.0 build in App Store Connect
2. [ ] Verify all metadata fields are updated per table above
3. [ ] Verify all screenshots uploaded and ordered per visual-assets-spec.md
4. [ ] Export Compliance: "Does your app use encryption?" -- No
5. [ ] Content Rights: "Does your app contain third-party content?" -- No
6. [ ] Advertising Identifier: "Does this app use the Advertising Identifier?" -- No
7. [ ] Review Notes (optional): "v1.1 feature update. Adds AVIF format support, Shortcuts.app integration, Finder Quick Action, before/after comparison, selective metadata control, and clipboard history. No changes to pricing or IAPs."
8. [ ] Click "Submit for Review"
9. [ ] Confirm status: "Waiting for Review"

---

## Post-Submission Monitoring

- [ ] Check status daily (morning and evening)
- [ ] Expected timeline: 1-3 business days
- [ ] If "In Review": do not modify submission
- [ ] If rejected: read reason carefully, fix, resubmit same day
- [ ] If approved: proceed to Phase 6 of prelaunch-checklist.md

---

## Common Rejection Risks for v1.1

| Risk | Likelihood | Prevention |
|------|-----------|------------|
| Shortcuts integration issues | LOW | Test OptimizeImageIntent in Shortcuts.app before submission |
| Finder Quick Action not registering | LOW | Verify Quick Action appears in Finder on clean install |
| Privacy concern with metadata access | VERY LOW | App only reads/writes image metadata, no user data |
| SKStoreReviewController misuse | VERY LOW | Only call once per version, respect system rate limiting |
| Missing entitlement | LOW | Verify App Sandbox and Hardened Runtime are enabled |

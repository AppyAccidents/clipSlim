# Resubmission Timeline - ClipSlim

**Submission Target:** March 16, 2026 (today)
**Today's Date:** March 16, 2026
**Context:** Resubmission after Guideline 3.1.1 rejection (BMC replaced with StoreKit 2 tip jar)
**Platform:** Mac App Store (macOS)
**App Store ID:** 6759780567
**Expected Review Time:** 1-3 business days (resubmissions are sometimes faster)

---

## Today: Monday, March 16, 2026 -- Submission Day

### Morning (9:00 AM - 12:00 PM)

**9:00 AM - Final Code Verification (30 minutes)**
- [ ] Run full grep for BMC references across entire project (expect zero matches)
- [ ] Run test suite: `xcodebuild -project ClipSlim.xcodeproj -scheme ClipSlim -destination 'platform=macOS' test`
- [ ] Launch app and manually verify SupportTab shows native tip buttons only
- [ ] Confirm no external URLs are opened from any UI element

**9:30 AM - Build and Upload (45 minutes)**
- [ ] Build Release archive: Product > Archive in Xcode
- [ ] Upload to App Store Connect via Xcode Organizer
- [ ] Wait for build processing (typically 15-30 minutes)
- [ ] Verify build status: "Ready to Submit"

**10:15 AM - App Store Connect IAP Setup (45 minutes)**
- [ ] Create all three consumable IAPs in App Store Connect (if not done yet):
  - Small Tip: `com.appyaccidents.clipslim.tip.small` at $2.99
  - Medium Tip: `com.appyaccidents.clipslim.tip.medium` at $4.99
  - Large Tip: `com.appyaccidents.clipslim.tip.large` at $9.99
- [ ] Upload review screenshot for each IAP (SupportTab screenshot)
- [ ] Add review notes for each IAP
- [ ] Verify all three show "Ready to Submit"

**11:00 AM - Metadata and Review Notes (30 minutes)**
- [ ] Verify all metadata is clean (no BMC references in description, promo text)
- [ ] Update App Review notes with resubmission explanation (see prelaunch-checklist.md Phase 5)
- [ ] Verify screenshots are accurate (no BMC UI visible)
- [ ] Verify all URLs load (privacy policy, support)

**11:30 AM - Submit for Review**
- [ ] Select build in App Store Connect
- [ ] Ensure IAPs are included in submission
- [ ] Review submission summary one final time
- [ ] Click "Submit to App Review"
- [ ] Confirm status: "Waiting for Review"
- [ ] Record submission time: _______

### Afternoon
- [ ] Monitor App Store Connect for status changes
- [ ] Prepare for potential reviewer questions (keep App Store Connect app on phone)
- [ ] If "In Review" status appears today, be available to respond

---

## Tuesday, March 17, 2026 -- Waiting for Review

### Morning Check (9:00 AM, 5 minutes)
- [ ] Check App Store Connect status
- [ ] Check email for App Review messages
- [ ] Expected status: "Waiting for Review" or "In Review"

### If Status is "In Review"
- [ ] Be available for reviewer questions via App Store Connect messaging
- [ ] Keep phone nearby for status notifications
- [ ] Do NOT make changes to the submission while in review

### If No Status Change
- [ ] Normal -- Apple review queue can take 1-3 business days
- [ ] Continue monitoring twice daily (morning and evening)
- [ ] Use waiting time to prepare post-approval announcements

### Productive Waiting Tasks
- [ ] Draft "We're back on the App Store" announcement for social media
- [ ] Update DMG download page to note MAS version coming soon
- [ ] Prepare What's New text for first post-approval update
- [ ] Review and respond to any existing user feedback from DMG distribution

---

## Wednesday, March 18, 2026 -- Review Expected

### Morning Check (9:00 AM)
- [ ] Check App Store Connect status
- [ ] Check email for resolution

### If APPROVED
- [ ] Verify app is live on Mac App Store (search for "ClipSlim")
- [ ] Download from MAS and verify tip jar works in production
- [ ] Post announcement on Twitter/X, Reddit r/macapps
- [ ] Update website/landing page with Mac App Store link
- [ ] Proceed to Post-Approval actions (see below)

### If REJECTED AGAIN
- [ ] Read rejection reason carefully and completely
- [ ] Do NOT panic -- common second rejections:
  - IAP metadata incomplete (fix in App Store Connect, resubmit same day)
  - Reviewer found residual BMC reference you missed (fix code, rebuild, resubmit)
  - Different guideline issue unrelated to 3.1.1 (address the new issue)
- [ ] Fix the issue immediately
- [ ] Resubmit with updated App Review notes addressing the new feedback
- [ ] See Contingency Planning section below

---

## Thursday, March 19, 2026 -- Approval Expected (if not Wednesday)

### Morning Check (9:00 AM)
- [ ] Check App Store Connect status
- [ ] Same protocol as Wednesday

### If Still "In Review" or "Waiting for Review"
- [ ] This is unusual but not alarming for resubmissions
- [ ] Check Apple Developer System Status page for any review delays
- [ ] If past 4 business days with no response, consider contacting App Review via the Resolution Center

---

## Friday, March 20, 2026 -- Deadline Check

### If Still Not Resolved
- [ ] Contact App Review via Resolution Center in App Store Connect
- [ ] Message: "This is a resubmission addressing Guideline 3.1.1. We replaced the external donation link with native StoreKit 2 in-app purchases. The submission has been waiting since March 16. Could you provide an update on the review status?"
- [ ] Also try the App Review phone line if email does not get a response within 4 hours

---

## Post-Approval: Week 1 (Approval Day through 7 days after)

### Approval Day (Day 0)
- [ ] Verify app is live and searchable on Mac App Store
- [ ] Download and test from MAS (fresh install)
- [ ] Verify StoreKit tip jar loads real products (not sandbox)
- [ ] Test one tip purchase to confirm real transaction flow
- [ ] Post announcements:
  - Twitter/X: "ClipSlim is live on the Mac App Store!"
  - Reddit r/macapps: share or update existing thread
  - Update website with MAS badge and link
- [ ] Update promotional text in App Store Connect (can change without review):
  "Now with native Tip Jar! Automatic clipboard image optimization, 100% local. Free forever -- tips optional."

### Days 1-3 Post-Approval
- [ ] Monitor for initial reviews on MAS
- [ ] Respond to all reviews within 24 hours (use review-responses.md templates)
- [ ] Monitor crash reports in App Store Connect
- [ ] Track daily downloads in App Store Connect > Trends
- [ ] Watch for any StoreKit-related crashes or errors in logs

### Days 4-7 Post-Approval
- [ ] First week download report
- [ ] Check keyword rankings (manual search for primary keywords)
- [ ] Review conversion rate in App Store Connect Analytics
- [ ] Compile any bug reports for v1.1 planning
- [ ] Submit to Product Hunt (Tuesday or Wednesday for best visibility)

---

## Post-Approval: Weeks 2-4 (Optimization Phase)

### Week 2 (Approval + 7-14 days)
- [ ] Monday: Full keyword ranking check for all tracked terms
- [ ] Monday: Conversion rate analysis (impressions > page views > installs)
- [ ] Wednesday: Update promotional text if messaging needs refinement
- [ ] Friday: Week 2 metrics summary

### Week 3 (Approval + 14-21 days)
- [ ] Evaluate A/B test readiness (need 1,000+ impressions for significance)
- [ ] Plan v1.1 update scope based on user feedback
- [ ] Begin v1.1 development if fixes identified
- [ ] Keyword adjustment if data supports changes

### Week 4 (Approval + 21-28 days)
- [ ] Submit v1.1 update (bug fixes, polish)
- [ ] Include review request prompt (SKStoreReviewController) in v1.1
- [ ] Month 1 ASO health report
- [ ] Evaluate if promotional text changes impacted conversion

---

## Milestones Summary

| Date | Milestone | Status |
|------|-----------|--------|
| March 16 | Resubmission to App Review | Today |
| March 17-19 | Expected approval window (1-3 business days) | Pending |
| March 20 | Deadline to contact App Review if no response | Pending |
| Approval Day | Live on Mac App Store | Pending |
| Approval + 7 | First week metrics review | Pending |
| Approval + 14 | Keyword optimization based on data | Pending |
| Approval + 21 | v1.1 update submitted | Pending |
| Approval + 28 | Month 1 ASO health report | Pending |

---

## Contingency Planning

### If Rejected Again for 3.1.1
**Most likely cause:** Residual BMC reference the grep missed, or IAP metadata incomplete.
**Action:**
1. Read the rejection message word-for-word
2. Check if the rejection references specific code or UI
3. Fix immediately (should be a small change)
4. Rebuild, re-upload, resubmit same day
5. Update App Review notes to explicitly address the specific feedback
**Expected delay:** 1-2 additional days

### If Rejected for a Different Guideline
**Possible issues for menubar apps:**
- Guideline 4.2 (Minimum Functionality) -- unlikely given ClipSlim's feature set
- Guideline 2.4.5 (Accessibility) -- ensure VoiceOver labels are present
- Guideline 5.1.1 (Privacy) -- ensure privacy policy URL works
**Action:**
1. Address the specific guideline cited
2. Resubmit with updated review notes
**Expected delay:** 2-5 additional days

### If Review Takes Longer Than 5 Business Days
**Action:**
1. Contact App Review via Resolution Center
2. If no response in 24 hours, use the App Review phone line
3. Politely reference the resubmission context and ask for an update
4. Do not submit additional builds while one is in review (causes delays)

### If StoreKit Products Do Not Load for Reviewer
**Possible cause:** IAPs not in "Ready to Submit" state or not included in submission.
**Prevention:** Verify all IAPs are linked to the app version before submitting.
**If it happens:** Respond in Resolution Center explaining the IAPs are configured and ask for a re-review.

---

## Time Budget

| Day | Hours | Focus |
|-----|-------|-------|
| March 16 (Mon) | 2-3 hours | Final validation, IAP setup, submit |
| March 17 (Tue) | 15 minutes | Status check, prepare announcements |
| March 18 (Wed) | 30 min - 2 hours | Approval response OR rejection fix |
| March 19 (Thu) | 15 minutes | Status check if still waiting |
| March 20 (Fri) | 30 minutes | Contact App Review if needed |
| Post-Approval Week 1 | 1-2 hours/day | Monitoring, responses, optimization |

**Total estimated effort:** 8-12 hours over the first week (including post-approval)

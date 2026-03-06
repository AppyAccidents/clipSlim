# Testing and Monitoring Tasks - clipSlim

**Last Updated:** 2026-03-05
**Launch Target:** March 7-8, 2026
**Developer:** AppyAccidents

---

## PRE-LAUNCH TESTING TASKS

### Metadata Validation (Complete Before Submission)

Run these checks on the copy in `02-metadata/apple-metadata.md` before pasting into App Store Connect.

- [ ] App Name: count characters manually or with a character counter tool. Must be 30 or fewer.
  - Primary: "clipSlim - Image Optimizer" = 25 characters. PASS.
- [ ] Subtitle: count characters. Must be 30 or fewer.
  - Primary: "Clipboard & Folder Compression" = 30 characters. PASS (at limit).
- [ ] Promotional Text: count characters. Must be 170 or fewer.
  - Primary: 148 characters. PASS.
- [ ] Keywords Field: count characters. Must be 100 or fewer. Must contain NO spaces after commas.
  - Primary: 92 characters. PASS.
  - Verify no spaces: "image,compress,png,jpeg,optimizer,resize,batch,shrink,menubar,photo,converter,heic,clipboard" - confirmed no spaces.
- [ ] Description: count characters. Must be 4,000 or fewer.
  - Primary: ~2,847 characters. PASS.
- [ ] What's New: count characters. Must be 4,000 or fewer.
  - Primary: ~840 characters. PASS.

**Tool for quick character counting:** Paste any field into https://charactercounttool.com or use macOS's built-in word count in TextEdit.

### Keywords Field Spot Check
- [ ] Open the Keywords field in apple-metadata.md
- [ ] Confirm no word in the keywords field also appears in the App Name or Subtitle
  - App Name words: clipSlim, Image, Optimizer
  - Subtitle words: Clipboard, Folder, Compression
  - Keywords field: image, compress, png, jpeg, optimizer, resize, batch, shrink, menubar, photo, converter, heic, clipboard
  - CONFLICT FOUND: "image" appears in App Name AND keywords field. Remove "image" from keywords field.
  - CONFLICT FOUND: "optimizer" appears in App Name AND keywords field. Remove "optimizer" from keywords field.
  - CONFLICT FOUND: "clipboard" appears in Subtitle AND keywords field. Remove "clipboard" from keywords field.

**Corrected Keywords Field (after deduplication):**
```
compress,png,jpeg,resize,batch,shrink,menubar,photo,converter,heic,local,privacy,lossless
```
Character count: 76/100 characters.

You now have room to add more keywords. Candidates to fill remaining 24 characters:
- `screenshot` (10 chars) - very relevant for Mac utility users
- `bulk` (4 chars) - covers batch use case with a synonym
- `filesize` (8 chars) - direct match for "reduce file size" searches

**Updated Keywords Field (93/100 chars):**
```
compress,png,jpeg,resize,batch,shrink,menubar,photo,converter,heic,screenshot,bulk,filesize
```

Update the keywords field in `02-metadata/apple-metadata.md` with this corrected version before submitting.

### App Store Connect Pre-Submission Review
- [ ] Log in and confirm app record is in "Ready for Submission" or "Prepare for Submission" state
- [ ] Confirm privacy data selections are complete (Data Not Collected)
- [ ] Confirm privacy policy URL is live and accessible
- [ ] Confirm support URL or support email is set
- [ ] Confirm all required screenshots are uploaded
- [ ] Preview the product page in App Store Connect's built-in preview tool
- [ ] Check how the App Name and Subtitle appear on the simulated search result card
- [ ] Check how Screenshot 1 appears at thumbnail size in the simulated browse view

---

## LAUNCH DAY TASKS (March 7-8, 2026)

- [ ] Confirm app is approved and live in the Mac App Store
- [ ] Search "clipSlim" in the Mac App Store - confirm the listing appears correctly
- [ ] Search "image optimizer mac" - note position (may not rank immediately, that's normal)
- [ ] Download and install the app from the store yourself (confirm store download works)
- [ ] Test clipboard optimization flow after store download
- [ ] Test folder watcher after store download
- [ ] Share the App Store link via AppyAccidents social channels / website
- [ ] Record Day 0 baseline metrics from App Store Connect Analytics (impressions, page views, installs)

---

## WEEK 1 MONITORING TASKS

Check App Store Connect Analytics daily for the first 7 days.

Daily check (5 minutes):
- [ ] Impressions count (is the app being surfaced in search?)
- [ ] Product page views
- [ ] Installs
- [ ] Conversion rate (installs / page views)

Watch for:
- Sudden drop in impressions: could indicate a metadata keyword was flagged
- High impressions but low conversion: screenshot 1 or icon may need improvement
- High conversion but low impressions: keywords need expansion

### Day 7 Metrics Snapshot

Record these in the test log in `03-testing/ab-test-setup.md`:

| Metric | Value |
|--------|-------|
| Total Impressions | |
| Total Product Page Views | |
| Total Installs | |
| Conversion Rate | |
| Top 3 Search Terms | |

---

## WEEKS 2-4 MONITORING TASKS

### Week 2
- [ ] Review all user reviews received. Categorize by: positive feature mention, bug report, feature request.
- [ ] Check if any reviews mention a feature that is not called out in the description. If so, add it.
- [ ] Update Promotional Text in App Store Connect (no submission needed) if you have a new hook.
- [ ] Decide whether to start Icon A/B test (requires Day 14 baseline data - see ab-test-setup.md).

### Week 3
- [ ] Compare Week 3 metrics to Week 1 baseline.
- [ ] If install rate has declined week-over-week: investigate whether a competitor launched or an App Store algorithm change occurred.
- [ ] If install rate is stable or growing: no metadata changes needed yet.

### Week 4
- [ ] Pull the "Search Terms" report from App Store Connect Analytics.
- [ ] Identify the top 5 terms driving installs. Confirm they match your keyword strategy.
- [ ] Identify any unexpected terms (terms you did not optimize for but are still driving installs). Consider adding them to the keywords field.
- [ ] Record Month 1 summary metrics.

---

## MONTH 1 REVIEW

After 30 days, run a full metadata audit:

**Conversion Funnel Check:**
- [ ] Impressions to page views rate (benchmark: 20-35% is healthy)
- [ ] Page views to installs rate (benchmark: 20-40% for Mac utilities)
- [ ] If page-view-to-install rate is below 15%: prioritize Screenshot 1 test
- [ ] If impression-to-page-view rate is below 15%: icon or title may be the problem

**Keyword Review:**
- [ ] List the top 10 search terms from App Store Connect
- [ ] Compare against original keyword targets
- [ ] Remove keywords with no observed traffic from the keywords field
- [ ] Add new keyword candidates based on actual search terms found

**Review Sentiment:**
- [ ] Calculate average star rating
- [ ] Identify the most-mentioned features in positive reviews
- [ ] Identify the most-mentioned complaints or missing features
- [ ] Update description to emphasize most-mentioned positive features

**A/B Test Status:**
- [ ] Is Icon Test 1 complete? (see ab-test-setup.md)
- [ ] Has a winner been implemented?
- [ ] Is Screenshot 1 test queued?

---

## QUARTERLY METADATA REFRESH

Every 3 months, run a full metadata refresh cycle:

1. Pull updated App Store Connect analytics
2. Identify lowest-performing keywords (no installs traceable to them)
3. Research new keyword candidates (search autocomplete, competitor metadata, App Store top charts category)
4. Update keywords field with replacements
5. Refresh description with any new features added since last update
6. Update What's New to reflect current version
7. Refresh Promotional Text

---

## REVIEW MONITORING

Reviews affect both conversion rate (social proof) and App Store algorithm ranking.

**Setup review monitoring:**
- [ ] Enable email notifications for new reviews in App Store Connect (under Notifications settings)
- [ ] Respond to every 1-star and 2-star review within 48 hours
- [ ] Respond to 3-star reviews that include specific feedback
- [ ] Use positive reviews as source material for description testimonial section (after collecting 10+)

**Review response template for a bug report:**
```
Thanks for letting us know. We take this seriously - please reach out to support@appyaccidents.com with your macOS version and we will get this fixed quickly.
```

**Review response template for a feature request:**
```
Good idea - this is on our list. Follow us for updates as we roll out new features. Thanks for trying clipSlim.
```

---

## FILES REFERENCE

| File | Purpose |
|------|---------|
| `02-metadata/apple-metadata.md` | All copy - primary + 3 variants |
| `02-metadata/visual-assets-spec.md` | Icon and screenshot specs |
| `02-metadata/action-metadata.md` | Submission and maintenance tasks |
| `03-testing/ab-test-setup.md` | A/B test configuration |
| `03-testing/action-testing.md` | This file |

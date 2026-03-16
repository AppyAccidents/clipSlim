# A/B Test Setup - ClipSlim

**Platform:** Mac App Store (Product Page Optimization)
**Last Updated:** 2026-03-16
**Developer:** AppyAccidents

---

## OVERVIEW

Mac App Store A/B testing is done through App Store Connect's Product Page Optimization feature. It supports testing up to 3 treatment variants against a control for:

- App icon
- Screenshots
- App preview video

**Important limitation:** App Name, Subtitle, and Keywords cannot be tested through Product Page Optimization. Those fields require submitting separate metadata-only updates and comparing time periods, which is less statistically reliable.

**Do not start A/B tests immediately at launch.** Collect a clean baseline for at least 14 days first. You need stable impression and conversion rate numbers before a test result means anything.

---

## TEST PRIORITY ORDER

| Priority | Element | Expected CVR Impact | Setup Effort | Status |
|----------|---------|-------------------|-------------|--------|
| 1 | App Icon | 15-30% improvement possible | High - requires new icon design | Not started |
| 2 | Screenshot 1 (Hero) | 10-20% improvement possible | Medium - requires new screenshot | Not started |
| 3 | App Name (sequential submission) | 5-10% improvement possible | Low - copy only | Not started |
| 4 | Screenshots 2-5 | 3-8% improvement possible | Medium | Not started |
| 5 | App Preview Video presence | 5-15% improvement possible | High - requires video production | Not started |

---

## BASELINE METRICS (Record Before Starting Any Test)

Record these numbers from App Store Connect Analytics at Day 7, Day 14, and Day 30 after the current version goes live:

| Metric | Day 7 | Day 14 | Day 30 |
|--------|-------|--------|--------|
| Impressions (total) | | | |
| Product Page Views | | | |
| Installs | | | |
| Conversion Rate (installs / page views) | | | |
| Top Referral Source (Search / Browse / Referral) | | | |
| Top Search Terms (App Store Connect > Analytics > Search tab) | | | |

**Industry benchmark for Mac utilities:** Conversion rate of 20-40% from product page view to install is typical.
- Below 20%: icon or screenshot 1 needs work (start with Test 1 and Test 2)
- 20-35%: solid, focus on increasing top-of-funnel impressions through keywords
- Above 35%: strong product-market fit, maintain metadata and drive more discovery

---

## TEST 1: APP ICON (HIGHEST PRIORITY)

### Hypothesis
An icon with a clearer compression or reduction visual metaphor will increase install conversion rate by 15% or more compared to the current icon.

### Prerequisites
Design 2 alternative icon concepts before setting up this test. See visual-assets-spec.md for design guidance:
- Concept B: Slim Document Stack
- Concept C: Clipboard with Bolt

### Configuration Steps

**Step 1: Navigate to Product Page Optimization**
1. Log in to https://appstoreconnect.apple.com
2. Go to My Apps > ClipSlim
3. In the left sidebar under App Store, click "Product Page Optimization"
4. Click "Create Product Page Optimization Test"

**Step 2: Name and Configure the Test**
1. Test Name: `Icon Test 1 - Stack vs Bolt`
2. Reference Page: Default Product Page (current live metadata)
3. Click Next

**Step 3: Add Treatment Variants**

Treatment A:
- Name: `Icon - Slim Stack`
- Upload: `icon-slim-stack-1024x1024.png` (Concept B from visual-assets-spec.md)
- Change: App Icon only (keep screenshots identical to control)

Treatment B:
- Name: `Icon - Clipboard Bolt`
- Upload: `icon-clipboard-bolt-1024x1024.png` (Concept C from visual-assets-spec.md)
- Change: App Icon only

**Step 4: Set Traffic Allocation**
- Control (Original Icon): 34%
- Treatment A (Slim Stack): 33%
- Treatment B (Clipboard Bolt): 33%

**Step 5: Set Duration**
- Minimum: 7 days
- Recommended: 14 days
- Required sample: minimum 1,000 product page visitors per variant (aim for 3,000+)
- If traffic is low at launch, extend to 21-28 days before drawing conclusions

**Step 6: Set Success Metrics**
- Primary metric: Install conversion rate (installs / product page views)
- Target: 10% or greater improvement over control
- Confidence threshold: 95% (App Store Connect calculates and displays this)

**Step 7: Launch**
1. Review all settings
2. Click "Start Test"
3. Record start date in the Test Log below
4. Set a calendar reminder to check results at Day 7 and Day 14

### Analysis Instructions

At Day 7 and Day 14:
1. Return to Product Page Optimization > click the running test
2. Check the Improvement column for each treatment
3. Wait for 95% confidence before concluding - App Store Connect shows this as a signal in the dashboard

**Decision rules:**
- Treatment shows 95% confidence + 10% or greater improvement: apply it permanently, stop test
- Results within 5% with no statistical confidence: extend test 7 more days
- A treatment is performing worse than control: remove it from traffic allocation to concentrate on stronger variants

**Applying the winner:**
1. In Product Page Optimization, click "Apply Treatment" on the winning variant
2. This replaces the control icon permanently without requiring an app submission

### Expected Outcome
15-25% conversion rate improvement.
Timeline: 1 week (icon design) + 2 weeks (test run) = 3 weeks total.

---

## TEST 2: SCREENSHOT 1 - HERO (SECOND PRIORITY)

Run this test only after Test 1 has concluded. Do not run both simultaneously - it splits traffic and extends time to significance.

### Hypothesis
A hero screenshot leading with the measured output (a specific before/after file size) will convert better than one leading with the UI overview.

### Variants

**Control (Current):** App panel open showing a compression result. Text overlay: "Compress images the moment you copy them."

**Treatment A - Output Lead:**
Full-screen before/after callout with large bold text: "4.8MB compressed to 1.9MB. Automatically." App UI visible but secondary. Tests whether a result-first approach beats a UI-first approach.

**Treatment B - Privacy Lead:**
Strong privacy headline as the dominant element: "100% local. Zero uploads." App UI shows network activity monitor with no connections. Tests whether privacy-focused users are a significant enough segment to warrant leading with that angle.

### Configuration Steps

1. Go to Product Page Optimization > Create New Test
2. Test Name: `Screenshot 1 - Output vs Privacy Lead`
3. Upload Treatment A: `screenshot-01-output-lead-2560x1600.png`
4. Upload Treatment B: `screenshot-01-privacy-lead-2560x1600.png`
5. Traffic: 34% / 33% / 33%
6. Duration: 14 days minimum
7. Metric: Install conversion rate

### Expected Outcome
10-20% improvement with the winning variant.

---

## TEST 3: APP NAME (SEQUENTIAL SUBMISSION METHOD)

App Name cannot be A/B tested through Product Page Optimization. Test it by submitting metadata-only updates and comparing install velocity across time periods.

**Important caveat:** Time-period comparisons are less statistically reliable than true A/B tests. Treat results as directional signals, not definitive proof. External factors (App Store algorithm changes, seasonal traffic, competitor activity) can affect results.

### Variants to Test

**Current (Control):** `ClipSlim - Clipboard Optimizer` (30 chars)
Strength: "Clipboard Optimizer" is a unique keyword combination with zero competitor overlap.

**Variant A:** `ClipSlim - Image Compressor` (28 chars)
Theory: "Image Compressor" has the highest estimated search volume of any primary keyword. Trades the unique differentiator angle for broader reach. Test if discovery volume increases enough to offset loss of unique positioning.

**Variant B:** `ClipSlim - Photo Compressor` (27 chars)
Theory: "Photo" searches are broader than "Image" in some contexts. "Compressor" is the most common suffix used by competitor apps. Tests a more conventional naming pattern.

### Method
1. Run the current name for 4 full weeks after the current version goes live. Record weekly installs.
2. Submit a metadata-only update with Variant A name (no binary change needed if only metadata changes).
3. Run Variant A for 4 weeks. Compare weekly install counts to the same weeks from the control period.
4. If Variant A shows a consistent 10%+ install improvement: keep it. If not: try Variant B or revert to control.

---

## TEST 4: APP PREVIEW VIDEO (OPTIONAL)

### Hypothesis
Adding a 30-second app preview video will increase conversion rate for users who engage with the product page beyond the first screenshot.

**Note:** Not all Mac App Store visitors watch preview videos. This test is lower priority than icon and screenshot tests. Produce the video only if Tests 1 and 2 are complete and you have bandwidth for video production.

### Setup
Once the 30-second preview video is produced (see visual-assets-spec.md for script):

1. Go to Product Page Optimization > Create New Test
2. Test Name: `Video Presence Test`
3. Treatment A: Upload the video (no other changes)
4. Control: No video (current state)
5. Traffic: 50% / 50%
6. Duration: 14 days minimum

---

## TEST LOG

Track all tests run against this table. Update after each test concludes.

| Test | Start Date | End Date | Control CVR | Winner CVR | Improvement | Implemented | Notes |
|------|-----------|----------|-------------|-----------|-------------|-------------|-------|
| Icon Test 1 | | | | | | | |
| Screenshot 1 Test | | | | | | | |
| App Name Test A | | | | | | | |
| App Name Test B | | | | | | | |
| Video Presence Test | | | | | | | |

---

## TOOLS FOR ONGOING ASO MONITORING

| Tool | Purpose | Cost |
|------|---------|------|
| App Store Connect Analytics | Install data, conversion rate, referral sources, search terms | Free |
| AppFollow | Keyword ranking, review monitoring, competitor tracking | Paid (free tier available) |
| Sensor Tower | Competitor analysis, keyword trend data | Paid |
| MobileAction | Keyword difficulty and volume estimates | Paid |
| AppTweak | Keyword suggestions, metadata optimization scoring | Paid |

**For the first 60 days:** App Store Connect Analytics is sufficient. The Search tab shows which actual search terms are driving impressions. Use that data to inform keyword field rotations before spending on third-party tools.

# A/B Test Setup - clipSlim

**Platform:** Mac App Store (Product Page Optimization)
**Last Updated:** 2026-03-05
**Developer:** AppyAccidents

---

## OVERVIEW

Mac App Store A/B testing is done through App Store Connect's **Product Page Optimization** feature. It allows testing up to 3 treatment variants against a control (original) for:
- App icon
- Screenshots
- App preview video

**Important limitation:** Title, Subtitle, and Keywords cannot be A/B tested through Product Page Optimization. Those fields require separate metadata-only app submissions to test.

---

## TEST PRIORITY ORDER

Based on typical Mac utility app conversion rate impact:

| Priority | Element | Expected CVR Impact | Setup Effort |
|----------|---------|-------------------|-------------|
| 1 | App Icon | 15-30% improvement possible | High (requires new icon design) |
| 2 | Screenshot 1 (Hero) | 10-20% improvement possible | Medium (requires new screenshot) |
| 3 | App Name via sequential submission | 5-10% improvement possible | Low (copy only) |
| 4 | Screenshots 2-5 | 3-8% improvement possible | Medium |
| 5 | App Preview Video presence | 5-15% improvement possible | High (requires video production) |

**Recommendation for launch week:** Do NOT run A/B tests immediately at launch. Collect baseline conversion data for at least 14 days with your original metadata before starting any test. You need a clean baseline.

---

## TEST 1: APP ICON (HIGHEST PRIORITY)

### Hypothesis
An icon with a stronger compression/action visual metaphor will increase install conversion rate by 15% or more compared to the current icon.

### Prerequisite
Design 2 alternative icon concepts before setting up this test. See visual-assets-spec.md for design guidance on Concept B (Slim Document Stack) and Concept C (Scissor/Clip Hybrid).

### Configuration Steps

**Step 1: Navigate to Product Page Optimization**
1. Log in to https://appstoreconnect.apple.com
2. Go to My Apps > clipSlim
3. In the left sidebar, click "Product Page Optimization" (under the App Store section)
4. If this is your first test, click "Create Product Page Optimization Test"

**Step 2: Create the Test**
1. Test Name: `Icon Test - Compression Bolt vs Slim Stack`
2. Reference Page: Use Default Product Page (your current live metadata)
3. Click "Next"

**Step 3: Add Treatment Variants**
Treatment A:
- Name: `Icon - Slim Stack`
- Upload: `icon-slim-stack-1024x1024.png` (Concept B from visual-assets-spec.md)
- Change only: App Icon (keep screenshots identical to control)

Treatment B:
- Name: `Icon - Scissor Clip`
- Upload: `icon-scissor-clip-1024x1024.png` (Concept C from visual-assets-spec.md)
- Change only: App Icon (keep screenshots identical to control)

**Step 4: Set Traffic Allocation**
- Control (Original Icon): 34%
- Treatment A (Slim Stack): 33%
- Treatment B (Scissor Clip): 33%

**Step 5: Set Duration**
- Minimum: 7 days
- Recommended: 14 days
- Required sample size: minimum 1,000 visitors per variant (aim for 3,000+)
- If traffic is low at launch, extend to 21-28 days

**Step 6: Set Success Metrics**
- Primary metric: Install conversion rate (installs / product page views)
- Target: 10% or greater improvement over control
- Confidence threshold: 95%

**Step 7: Launch the Test**
1. Review all settings
2. Click "Start Test"
3. Note the start date in action-testing.md
4. Schedule a calendar reminder to check results after 7 days

### Analysis Instructions

After minimum 7 days (14 recommended):
1. Return to Product Page Optimization
2. Click on the running test
3. Check the "Improvement" column for each variant
4. App Store Connect displays statistical confidence - wait for 95% confidence before concluding

**Decision rules:**
- If a variant shows 95% confidence with 10%+ improvement: implement it permanently, stop test
- If results are close (under 5% improvement, no confidence): extend test 7 more days
- If a variant is performing worse than control: eliminate it from the test to concentrate traffic on the stronger variants

**Implementing the winner:**
1. In Product Page Optimization, click "Apply Treatment" on the winning variant
2. This replaces the control permanently without requiring an app submission

### Expected Outcome
15-25% conversion rate improvement.
Timeline to implement: 1 week (design) + 2 weeks (test) = 3 weeks total.

---

## TEST 2: SCREENSHOT 1 - HERO (SECOND PRIORITY)

### Hypothesis
A hero screenshot that leads with the compression percentage result (the output benefit) will convert better than one that leads with the UI overview (the app itself).

Two approaches to test:

**Control (Current):** Shows the app panel open with a recent compression result. Text overlay: "Compress images the moment you copy them."

**Treatment A - Benefit Lead:** Screenshot opens with a before/after comparison. Large text: "4.8MB compressed to 1.9MB. Automatically." App UI visible but smaller.

**Treatment B - Privacy Lead:** Screenshot leads with bold privacy messaging. Large text: "100% local. Zero uploads." App UI shows network activity monitor showing no connections.

### Configuration Steps

Follow the same steps as Test 1 but upload new screenshots instead of new icons:

1. Go to Product Page Optimization > Create New Test
2. Test Name: `Screenshot 1 Test - Benefit vs Privacy Lead`
3. Upload Treatment A: `screenshot-01-benefit-lead-2560x1600.png`
4. Upload Treatment B: `screenshot-01-privacy-lead-2560x1600.png`
5. Traffic: 34% / 33% / 33%
6. Duration: 14 days minimum

### Run this test AFTER Test 1 concludes.
Do not run both tests simultaneously - it splits traffic further and requires longer run times to reach significance.

---

## TEST 3: APP NAME (SEQUENTIAL SUBMISSION)

Since App Name cannot be A/B tested through Product Page Optimization, test it by submitting metadata-only updates and comparing time periods.

**Important caveat:** Period-over-period comparisons are less reliable than true A/B tests because external factors (seasonality, App Store algorithm changes, competitor activity) can affect results. Treat these as directional signals, not definitive conclusions.

**Current name (Primary):** `clipSlim - Image Optimizer`

**Test variant (Variant A):** `clipSlim: Shrink Any Image`
- Theory: "Shrink" is a more emotional/action-oriented word that may increase click-through rate from search results

**Test variant (Variant B):** `clipSlim - Photo Compressor`
- Theory: "Photo" has broader search appeal than "Image" and "Compressor" is a common search term

### Method
1. Run the current name for 4 weeks after launch and record weekly install numbers
2. Submit a metadata-only update with Variant A name
3. Run for 4 weeks and compare weekly installs (same weeks of the month if possible)
4. If Variant A shows 10%+ improvement: keep it. If not: test Variant B or return to original.

---

## TEST 4: APP PREVIEW VIDEO (OPTIONAL)

### Hypothesis
Adding a 30-second app preview video will increase conversion rate for users who engage with the product page.

**Note:** Not all Mac App Store users see or watch preview videos. This test is lower priority than icon and screenshot tests.

**Setup:** Once you have produced a 30-second app preview (see visual-assets-spec.md for script):
1. Go to Product Page Optimization > Create New Test
2. Treatment A: Add the video (no other changes)
3. Control: No video (current state)
4. Traffic: 50% / 50%
5. Duration: 14 days

---

## TOOLS FOR ONGOING ASO MONITORING

| Tool | Purpose | Cost |
|------|---------|------|
| App Store Connect Analytics | Install data, conversion rate, source breakdown | Free (included) |
| AppFollow | Keyword ranking, review monitoring | Paid (free tier available) |
| Sensor Tower | Competitor analysis, keyword trends | Paid |
| MobileAction | Keyword difficulty and volume estimates | Paid |
| AppTweak | Keyword suggestions, metadata optimization scoring | Paid |

**For launch on a budget:** App Store Connect Analytics alone is sufficient for the first 60 days. Add a third-party tool once you have enough data volume to justify the cost.

---

## BASELINE METRICS TO RECORD AT LAUNCH

Before starting any A/B test, document these numbers from App Store Connect Analytics:

Record on Day 7 after launch, Day 14, and Day 30:

| Metric | Day 7 | Day 14 | Day 30 |
|--------|-------|--------|--------|
| Impressions (total) | | | |
| Product Page Views | | | |
| Installs | | | |
| Conversion Rate (installs/views) | | | |
| Top Referral Source (Search / Browse / Referral) | | | |
| Top Search Terms (from Search tab) | | | |

These numbers establish your baseline conversion rate. Any A/B test result should be compared against this baseline, not against an assumed industry average.

**Industry benchmark for Mac utilities:** Conversion rate of 20-40% from product page view to install is typical. Below 20% suggests the icon or screenshot 1 needs work. Above 40% suggests strong product-market fit.

---

## TEST LOG

Use this table to track all tests run:

| Test | Start Date | End Date | Winner | CVR Improvement | Implemented |
|------|-----------|----------|--------|----------------|-------------|
| Icon Test 1 | | | | | |
| Screenshot 1 Test | | | | | |
| App Name Test A | | | | | |

# A/B Test Setup - ClipSlim v1.1

**Platform:** Mac App Store (Product Page Optimization)
**Last Updated:** 2026-04-06
**Developer:** AppyAccidents

---

## OVERVIEW

Mac App Store A/B testing uses App Store Connect's Product Page Optimization. It supports testing up to 3 treatment variants against a control for:
- App icon
- Screenshots
- App preview video

**Limitation:** App Name, Subtitle, and Keywords cannot be A/B tested. Those require sequential metadata submissions and time-period comparison.

**Prerequisite:** Do NOT start A/B tests until 14 days after v1.1 goes live. You need a stable baseline of impression and conversion data first.

---

## TEST PRIORITY ORDER

| Priority | Element | Expected CVR Impact | Setup Effort | When |
|----------|---------|-------------------|-------------|------|
| 1 | Screenshot 1 (Hero) | 10-20% | Medium | v1.1 + 14 days |
| 2 | Screenshots 2-5 (v1.1 features) | 5-10% | Medium | After Test 1 |
| 3 | App Icon | 15-30% | High (design) | After Test 2 |
| 4 | Subtitle (sequential) | 5-10% | Low (copy) | After Test 3 |
| 5 | App Preview Video | 5-15% | High (production) | After Tests 1-3 |

---

## BASELINE METRICS (Record Before Any Test)

Record from App Store Connect Analytics at Day 7 and Day 14 after v1.1 goes live:

| Metric | Day 7 | Day 14 |
|--------|-------|--------|
| Impressions (total) | | |
| Product Page Views | | |
| Installs | | |
| Conversion Rate (installs / page views) | | |
| Top Referral Source | | |
| Top Search Terms | | |

**Mac utility benchmarks:**
- Below 20% CVR: screenshots or icon need work (prioritize Test 1)
- 20-35% CVR: solid, focus on keyword-driven impressions
- Above 35% CVR: strong, maintain and drive more discovery

---

## TEST 1: SCREENSHOT 1 -- HERO (HIGHEST PRIORITY)

### Hypothesis
A hero screenshot leading with a measured result (specific before/after file size) will convert better than a UI overview screenshot.

### Variants

**Control:** App panel showing compression result. Caption: "Compress images the moment you copy them."

**Treatment A -- Result Lead:**
Large bold text: "4.8MB to 1.1MB. Automatically." App UI visible but secondary. Tests result-first vs UI-first.

**Treatment B -- AVIF Lead:**
Large text: "AVIF, WebP, HEIC -- from your menubar." Format badges visible. Tests whether the modern format angle drives higher conversion from developer/designer audiences.

### Configuration
1. App Store Connect > Product Page Optimization > Create Test
2. Test Name: `Screenshot 1 - Result vs AVIF Lead`
3. Upload Treatment A and Treatment B screenshots (2560x1600)
4. Traffic: 34% control / 33% A / 33% B
5. Duration: 14 days minimum
6. Success metric: Install conversion rate
7. Target: 10%+ improvement over control at 95% confidence

### Decision Rules
- 95% confidence + 10% improvement: apply winner permanently
- Within 5%, no confidence: extend 7 more days
- Treatment worse than control: remove from allocation

---

## TEST 2: FEATURE SCREENSHOTS (v1.1 FEATURES)

### Hypothesis
Showcasing v1.1 features (comparison slider, Shortcuts, Finder) in screenshots 2-5 will increase conversion for users who scroll past the hero.

### Variants

**Control:** Current screenshot order (core features only)

**Treatment A -- v1.1 Feature Lead:**
Screenshots 2-5 show: AVIF output, comparison slider, Shortcuts integration, Finder Quick Action. Tests whether new features convince scrollers.

**Treatment B -- Use-Case Lead:**
Screenshots 2-5 show: "For web developers" (AVIF/WebP), "For designers" (presets/metadata), "For everyone" (clipboard auto), "Privacy" (local processing). Tests persona-based messaging.

### Configuration
- Same setup as Test 1 but for screenshots 2-5
- Run only after Test 1 concludes
- 14 days minimum

---

## TEST 3: APP ICON

### Hypothesis
An icon with a clearer compression visual metaphor will increase conversion.

### Concepts
- **Concept A (Current):** Existing icon
- **Concept B -- Compression Arrow:** Image with downward arrow, neon cyan accent
- **Concept C -- Format Badge:** Current icon with small "AVIF" badge

### Configuration
- 34% / 33% / 33% traffic split
- 14 days minimum
- Apply winner permanently when 95% confidence reached

---

## TEST 4: SUBTITLE (Sequential Method)

App Name/Subtitle cannot be Product Page Optimization tested. Use sequential submission comparison.

### Variants
- **Current:** `Image & PDF Compressor for Mac` (30 chars)
- **Variant A:** `AVIF, WebP & PDF Compressor` (28 chars)
- **Variant B:** `Auto-Optimize with Shortcuts` (29 chars)

### Method
1. Run current subtitle for 4 weeks post-v1.1. Record weekly installs.
2. Submit metadata-only update with Variant A. Run 4 weeks. Compare.
3. If 10%+ improvement: keep. Otherwise try Variant B or revert.

**Caveat:** Sequential testing is less reliable than true A/B. Treat results as directional.

---

## TEST LOG

| Test | Start Date | End Date | Control CVR | Winner CVR | Improvement | Applied? |
|------|-----------|----------|-------------|-----------|-------------|----------|
| Screenshot 1 | | | | | | |
| Feature Screenshots | | | | | | |
| App Icon | | | | | | |
| Subtitle A | | | | | | |
| Subtitle B | | | | | | |
| Video Presence | | | | | | |

---

## TOOLS

| Tool | Purpose | Cost |
|------|---------|------|
| App Store Connect Analytics | Impressions, CVR, search terms | Free |
| AppFollow | Keyword ranking, competitor tracking | Paid (free tier) |
| Sensor Tower | Competitor analysis | Paid |

**First 60 days:** App Store Connect Analytics is sufficient. The Search tab shows which terms drive impressions.

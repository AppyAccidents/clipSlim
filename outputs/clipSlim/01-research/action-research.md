# Research Action Checklist - clipSlim

**Date:** 2026-03-05
**Launch Target:** March 7-8, 2026
**Status:** Research Complete -- Ready for Implementation

---

## Phase 1: Review Research Findings (Est: 30 min)

- [ ] Read `keyword-list.md` completely
- [ ] Confirm top 6 primary keywords align with app features
- [ ] Read `competitor-gaps.md` completely
- [ ] Note the ZERO-competition opportunities (clipboard optimization, folder watcher, focus mode)
- [ ] Review competitor title patterns -- decide on title approach
- [ ] Verify keyword field fits within 100 characters

---

## Phase 2: Mac App Store Metadata Implementation (Est: 1-2 hours)

### Title and Subtitle
- [ ] Finalize App Store title (30 chars max)
  - Recommended: `clipSlim - Image Compressor` (28 chars)
  - Alternative: `clipSlim: Clipboard Optimizer` (30 chars)
- [ ] Finalize App Store subtitle (30 chars max)
  - Recommended: `Clipboard Image Compression` (28 chars)
  - Alternative: `Auto Clipboard Optimizer` (25 chars)

### Keyword Field
- [ ] Finalize 100-character keyword field
  - Recommended: `png,jpg,jpeg,reduce,file,size,batch,photo,resize,optimize,menubar,folder,watch,automatic,lightweight`
  - Do NOT duplicate words already in title/subtitle
  - Adjust based on final title/subtitle choice

### Description
- [ ] Write Mac App Store description (max 4,000 chars)
- [ ] Include these phrases at least once:
  - [ ] "image compression" / "compress images"
  - [ ] "file size" / "reduce file size"
  - [ ] "clipboard" + optimization context
  - [ ] "menu bar"
  - [ ] "png" and "jpg"
  - [ ] "local processing" / "no data collection"
  - [ ] "folder watcher" / "folder monitoring"
  - [ ] "presets"
  - [ ] "keyboard shortcuts" / "hotkeys"
  - [ ] "automatic" / "automatically"
- [ ] Use bullet points for features (4/5 top competitors do this)
- [ ] Lead with the unique value prop (automatic clipboard optimization)
- [ ] Include use cases section (designers, developers, content creators)
- [ ] End with privacy note (25/84 competitors mention privacy)

### Category Selection
- [ ] Primary category: **Utilities** (less saturated than Photo & Video)
- [ ] Secondary category: **Productivity** or **Graphics & Design**

### Visual Assets
- [ ] App icon leverages neon aesthetic (unique in category)
- [ ] Screenshots highlight:
  - [ ] Menu bar integration
  - [ ] Clipboard auto-optimization in action
  - [ ] Preset selection
  - [ ] Folder watcher setup
  - [ ] Before/after file size comparison
- [ ] Consider App Preview video showing the automatic workflow

---

## Phase 3: Direct Distribution (Website/DMG) (Est: 1 hour)

- [ ] Create landing page with SEO targeting:
  - Page title: "clipSlim - Automatic Clipboard Image Compressor for Mac"
  - H1: "Compress clipboard images automatically on macOS"
  - Meta description: Include "menu bar", "image compressor", "clipboard", "macOS"
- [ ] Include structured data (schema.org SoftwareApplication)
- [ ] Create download page optimized for "mac image compressor download"
- [ ] Add comparison table vs competitors (ImageOptim, Squash, etc.)

---

## Phase 4: Pre-Launch Keyword Validation (Est: 30 min)

- [ ] Search Mac App Store for each primary keyword -- verify competition level
  - [ ] "image compressor" -- check top 5 results
  - [ ] "clipboard optimizer" -- check top 5 results (expect very few)
  - [ ] "image optimizer mac" -- check top 5 results
  - [ ] "compress png" -- check top 5 results
  - [ ] "clipboard image" -- check results (expect very few)
- [ ] Verify no new competitors launched since research date
- [ ] Confirm keyword field has no wasted words (all unique, all relevant)

---

## Phase 5: Post-Launch Monitoring Setup (Est: 30 min)

- [ ] Bookmark competitor App Store pages for periodic review:
  - [ ] Resize it - compress any image (top rated compressor)
  - [ ] Paste -- Limitless Clipboard (top clipboard manager)
  - [ ] Clipboard - Paste Keyboard (highest rated clipboard tool)
  - [ ] Any Image Compressor JPG PNG (relevant positioning)
  - [ ] Image Tool+ (premium compressor)
- [ ] Set calendar reminders:
  - [ ] Week 1 post-launch: Check keyword rankings
  - [ ] Week 2: Review first ratings/reviews
  - [ ] Month 1: Full keyword performance review
  - [ ] Month 3: Repeat competitor research (re-run this analysis)
- [ ] Track these metrics:
  - [ ] Impressions per keyword (App Store Connect)
  - [ ] Conversion rate by keyword
  - [ ] Rating count growth
  - [ ] Category ranking position

---

## Phase 6: Rating Momentum Strategy (Est: ongoing)

Most competitors in the image compressor space have ZERO ratings. Even 10-20 ratings will establish credibility.

- [ ] Implement in-app rating prompt (SKStoreReviewController)
  - Trigger after: 3+ successful compressions
  - Do not trigger during first session
- [ ] Request reviews from beta testers on launch day
- [ ] Share on developer communities (indie dev, macOS subs) for initial visibility
- [ ] Consider Product Hunt launch in week 1-2

---

## Validation Criteria

Before marking research phase complete:

- [x] At least 10 primary keywords identified (32 total keywords found)
- [x] At least 3 competitors analyzed (8 competitors analyzed in depth)
- [x] Clear implementation locations for each keyword (title, subtitle, keyword field, description mapped)
- [x] Competitive gaps documented (5 ZERO-competition gaps, 6 low-competition gaps)
- [x] Data sourced from real iTunes API (84 apps fetched and analyzed)
- [x] Raw data saved to `raw-data/` directory

---

## Key Metrics from Research

| Metric | Value |
|--------|-------|
| Total apps analyzed | 84 |
| Direct competitors (image compressors) | 35+ |
| Clipboard managers analyzed | 20+ |
| Primary keywords identified | 6 |
| Secondary keywords identified | 11 |
| Long-tail keywords identified | 15 |
| ZERO-competition gaps found | 5 |
| Competitors with 100+ ratings | 4 (all clipboard managers, not compressors) |

---

## Handoff Notes

**For metadata optimization phase (aso-optimizer):**
- Use `keyword-list.md` for title, subtitle, and keyword field implementation
- Use `competitor-gaps.md` for description messaging priorities
- clipSlim's strongest positioning: ONLY app that combines clipboard monitoring + image compression
- Lead with automation angle -- every competitor requires manual interaction
- Privacy messaging is a differentiator (local processing, no data collection)

**Data limitations:**
- Search volume estimates are approximations (no Apple Search Ads data available)
- Some well-known tools (ImageOptim, Squash) are not on the Mac App Store and could not be fetched via iTunes API
- Competition scores are based on title/description keyword frequency, not actual App Store ranking algorithms
- Rating counts reflect Mac App Store only, not direct distribution popularity

---

## File Inventory

```
outputs/clipSlim/01-research/
  keyword-list.md          -- Prioritized keywords with implementation guide
  competitor-gaps.md       -- Competitive intelligence and gap analysis
  action-research.md       -- This checklist
  raw-data/
    competitors.json       -- Detailed competitor data (15 apps)
    all_itunes_results.json -- Full iTunes API dataset (84 apps)
```

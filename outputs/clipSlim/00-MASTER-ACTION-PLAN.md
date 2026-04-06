# ClipSlim v1.1 - Master ASO Action Plan

**Updated:** April 6, 2026
**Platform:** Mac App Store (macOS)
**App Store ID:** 6759780567
**Current Status:** Live (v1.0.0, approved March 21, 2026, 0 ratings)
**Goal:** Optimize metadata and discoverability for v1.1 feature update

---

## Overview

ClipSlim v1.1 adds six major features (AVIF, Shortcuts, Finder Quick Action, comparison slider, metadata control, clipboard history) that open significant new keyword opportunities. This plan updates the ASO strategy from the v1.0 launch audit to capture these opportunities while addressing the #1 competitive weakness: zero ratings.

**Key strategic insights:**
- AVIF is the biggest keyword opportunity (2 competing apps, 0 ratings on MAS)
- v1.1 closes 6 feature gaps vs Zipic (the nearest MAS competitor)
- 0 ratings is the single biggest conversion barrier -- SKStoreReviewController is critical
- Title and subtitle should NOT change (preserve ranking equity from 16 days live)
- Keyword field updated with 6 new terms for v1.1 features

---

## Quick Start

1. Read this master plan (you are here)
2. Follow phases in order (01 through 05)
3. Check boxes as you complete tasks
4. All copy-paste ready metadata is in 02-metadata/apple-metadata.md

---

## Phase 1: Research Review (Est: 30 minutes)
**See:** 01-research/

### Tasks
- [ ] Review keyword-list.md -- 51 keywords identified, 16 new for v1.1
- [ ] Review competitor-gaps.md -- v1.1 closes 6 feature gaps vs Zipic
- [ ] Note: AVIF is Tier 1 (easy win) keyword opportunity
- [ ] Note: "clipboard optimizer" remains unchallenged on MAS
- [ ] Confirm keyword strategy aligns with your v1.1 feature priorities

**Key files:**
- `01-research/keyword-list.md` -- Full keyword list with priority tiers
- `01-research/competitor-gaps.md` -- Competitive landscape and gap analysis
- `01-research/action-research.md` -- Research action checklist

**Dependencies:** None
**Next:** Phase 2

---

## Phase 2: Metadata Implementation (Est: 2-3 hours)
**See:** 02-metadata/

### Tasks
- [ ] Finalize v1.1 build (all features working, SKStoreReviewController implemented)
- [ ] Capture 6 new screenshots per visual-assets-spec.md
- [ ] Open apple-metadata.md and prepare all text
- [ ] In App Store Connect, create version 1.1.0:
  - [ ] Paste What's New (497/4,000 chars)
  - [ ] Replace Description (3,847/4,000 chars)
  - [ ] Update Keywords: `compress,png,jpeg,resize,batch,shrink,menubar,photo,avif,heic,webp,shortcuts,metadata,quick,action`
  - [ ] Upload new screenshots
  - [ ] Update Promotional Text (159/170 chars)
- [ ] Verify App Name and Subtitle are UNCHANGED
- [ ] Run character count validation on all fields

**Key files:**
- `02-metadata/apple-metadata.md` -- All metadata, copy-paste ready
- `02-metadata/visual-assets-spec.md` -- Screenshot specs and design guidelines
- `02-metadata/action-metadata.md` -- Step-by-step implementation checklist

**Dependencies:** Phase 1 review complete
**Next:** Phase 3

---

## Phase 3: Testing Setup (Est: 1 hour now, 30 min ongoing)
**See:** 03-testing/

### Tasks
- [ ] Prepare 2 alternative hero screenshots for A/B testing (Treatment A: result-lead, Treatment B: AVIF-lead)
- [ ] Record Day 7 baseline metrics after v1.1 approval
- [ ] Record Day 14 baseline metrics
- [ ] At Day 15: set up Screenshot 1 A/B test per ab-test-setup.md
- [ ] At Day 29: analyze results, apply winner or extend

**Key files:**
- `03-testing/ab-test-setup.md` -- Full A/B test plan with 4 test configurations
- `03-testing/action-testing.md` -- Testing action checklist

**Dependencies:** Phase 2 complete, 14 days of baseline data
**Next:** Phase 4

---

## Phase 4: Launch Execution (Est: 3-4 hours on submission day)
**See:** 04-launch/

### Tasks
- [ ] Complete prelaunch-checklist.md (35 items across 6 phases)
- [ ] Follow submission-guide.md step by step
- [ ] Submit v1.1 to App Store Connect
- [ ] Monitor review status (1-3 business days expected)
- [ ] On approval: execute announcement plan
- [ ] On approval: begin rating collection (SKStoreReviewController + social CTA)

**Key files:**
- `04-launch/prelaunch-checklist.md` -- Complete pre-submission checklist
- `04-launch/submission-guide.md` -- Detailed submission steps
- `04-launch/timeline.md` -- Full timeline with milestones
- `04-launch/action-launch.md` -- Submission day and approval day checklists

**Dependencies:** Phase 2 metadata ready, v1.1 build ready
**Next:** Phase 5

---

## Phase 5: Ongoing Optimization (Continuous)
**See:** 05-optimization/

### Daily Tasks (15-20 min, first 2 weeks)
- [ ] Check reviews, crashes, downloads
- [ ] Respond to all reviews within 24 hours

### Weekly Tasks (1 hour, starting week 3)
- [ ] Keyword ranking check (8 tracked terms)
- [ ] Conversion rate analysis
- [ ] Competitor check (Clop, Zipic)

### Monthly Tasks (2-3 hours)
- [ ] Full ASO health review
- [ ] Rotate Promotional Text
- [ ] Screenshot and metadata evaluation
- [ ] Review deep dive

**Key files:**
- `05-optimization/ongoing-tasks.md` -- Full daily/weekly/monthly/quarterly task schedules
- `05-optimization/review-responses.md` -- Response templates for all review types
- `05-optimization/action-optimization.md` -- Optimization action checklist with success metrics

**Dependencies:** v1.1 live on MAS
**Next:** Repeat monthly

---

## Success Metrics

| Metric | Target | Timeline |
|--------|--------|----------|
| v1.1 submitted and live | Yes | ASAP |
| Ratings count | 10+ | Month 1 post-v1.1 |
| Ratings count | 50+ | Month 3 post-v1.1 |
| Average rating | 4.0+ stars | Month 2 |
| Conversion rate | 20%+ | Month 1 |
| "avif converter" ranking | Top 5 | Month 1 |
| "clipboard optimizer" ranking | #1 | Month 1 |
| Monthly downloads | Growing 10%+ MoM | Month 2+ |

---

## Critical Path

The single most impactful actions, in order:

1. **Ship v1.1 with SKStoreReviewController** -- 0 ratings is the #1 problem
2. **Update keyword field with AVIF** -- near-zero competition, growing demand
3. **Update description with v1.1 features** -- AVIF, Shortcuts, Finder in the text
4. **Post announcements on r/macapps and r/webdev** -- immediate visibility
5. **Collect 10 ratings** -- transforms conversion rate
6. **Run Screenshot 1 A/B test** -- data-driven optimization

---

## File Directory

```
outputs/clipSlim/
  00-MASTER-ACTION-PLAN.md      -- This file (start here)
  FINAL-REPORT.md               -- Executive summary
  01-research/
    keyword-list.md             -- 51 keywords, prioritized with tiers
    competitor-gaps.md          -- Competitive intelligence, gap analysis
    action-research.md          -- Research action checklist
  02-metadata/
    apple-metadata.md           -- All metadata, copy-paste ready
    visual-assets-spec.md       -- Screenshot and video specifications
    action-metadata.md          -- Implementation checklist
  03-testing/
    ab-test-setup.md            -- A/B test configurations
    action-testing.md           -- Testing checklist
  04-launch/
    prelaunch-checklist.md      -- Pre-submission checklist (35 items)
    submission-guide.md         -- Step-by-step submission
    timeline.md                 -- Full timeline with milestones
    action-launch.md            -- Submission and approval day plans
  05-optimization/
    ongoing-tasks.md            -- Daily/weekly/monthly task schedules
    review-responses.md         -- Response templates
    action-optimization.md      -- Optimization checklist with metrics
```

---

## What Changed from v1.0 Audit

| Area | v1.0 (March 2026) | v1.1 (April 2026) |
|------|-------------------|-------------------|
| Keywords tracked | 35 | 51 (+16) |
| Keyword field | 14 terms | 15 terms (6 replaced) |
| Feature gaps vs Zipic | 6 gaps | 0 gaps (all closed) |
| Description | 2,963 chars | 3,847 chars (v1.1 features added) |
| What's New | Tip jar update | 10-item v1.1 feature list |
| Rating strategy | Not yet needed | Critical priority (#1 action) |
| A/B tests | Deferred to post-launch | Screenshot tests prioritized |
| Promotional text | Tip jar angle | AVIF/Shortcuts angle |

**Bottom line:** v1.1 transforms ClipSlim from a strong niche tool into a comprehensive competitor with format parity, automation parity, and unique features no competitor has. The only remaining weakness is rating volume.

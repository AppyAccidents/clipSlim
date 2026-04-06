# Testing Action Checklist - ClipSlim v1.1

**Last Updated:** 2026-04-06
**Phase:** 03-Testing

---

## Pre-Test Checklist (Before v1.1 Submission)

- [ ] Confirm SKStoreReviewController is implemented in v1.1 build
- [ ] Confirm review prompt triggers after 3rd successful optimization (not first launch)
- [ ] Prepare Treatment A screenshot for Test 1 (result-lead: "4.8MB to 1.1MB")
- [ ] Prepare Treatment B screenshot for Test 1 (AVIF-lead: "AVIF, WebP, HEIC")
- [ ] Both screenshots at 2560x1600 resolution

## Post-v1.1 Launch (Day 1-14)

- [ ] Record Day 7 baseline metrics (see ab-test-setup.md)
- [ ] Record Day 14 baseline metrics
- [ ] Evaluate conversion rate against benchmarks (20-35% is target range)
- [ ] If CVR below 20%: prioritize Screenshot 1 test immediately
- [ ] If CVR 20-35%: proceed with normal test schedule

## Test Schedule

| Test | Start | Duration | Prerequisite |
|------|-------|----------|-------------|
| Screenshot 1 (Hero) | v1.1 + 14 days | 14 days | Baseline data collected |
| Feature Screenshots | After Test 1 | 14 days | Test 1 concluded |
| App Icon | After Test 2 | 14 days | Test 2 concluded, new icon designed |
| Subtitle | After Test 3 | 4 weeks per variant | Test 3 concluded |

## Decision Framework

After each test:
- [ ] Check results at Day 7 (directional only)
- [ ] Final decision at Day 14 (require 95% confidence)
- [ ] Apply winner if 10%+ improvement
- [ ] Extend 7 days if results are inconclusive
- [ ] Document results in test log (ab-test-setup.md)

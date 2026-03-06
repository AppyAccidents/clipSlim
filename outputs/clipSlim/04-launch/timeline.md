# Launch Timeline - ClipSlim

**Launch Target:** March 7-8, 2026 (this weekend)
**Today's Date:** March 5, 2026
**Time to Launch:** 2-3 days (URGENT)
**Distribution:** Direct (notarized DMG) primary, Mac App Store secondary

---

## Day 1: Thursday, March 5, 2026 -- Foundation Day

### Morning (9 AM - 12 PM)

**9:00 AM - Legal and Privacy (1 hour)**
- [ ] Write privacy policy (simple -- no data collected, all local)
- [ ] Host privacy policy at a public URL (GitHub Pages or similar)
- [ ] Test that the privacy policy URL loads correctly

**10:00 AM - App Store Connect Setup (1.5 hours)**
- [ ] Log into App Store Connect
- [ ] Create new macOS app record
- [ ] Reserve app name "ClipSlim"
- [ ] Set bundle ID to match Xcode project
- [ ] Set category: Utilities
- [ ] Set pricing (Free or chosen price tier)
- [ ] Set availability: Worldwide

**11:30 AM - Metadata Entry (1.5 hours)**
- [ ] Enter app name/title
- [ ] Enter subtitle: "Clipboard Auto-Compression"
- [ ] Write and enter promotional text (170 chars)
- [ ] Enter keywords (100 chars, comma-separated)
- [ ] Write and enter full description (focus on benefits, features, privacy)
- [ ] Enter support URL
- [ ] Enter marketing URL
- [ ] Enter privacy policy URL
- [ ] Complete app privacy details ("Data Not Collected")
- [ ] Complete age rating questionnaire
- [ ] Write App Review notes (explain menubar UI, how to test)

### Afternoon (1 PM - 6 PM)

**1:00 PM - Technical Build: DMG (2 hours)**
- [ ] Run full test suite: `xcodebuild test`
- [ ] Fix any test failures
- [ ] Build release: `xcodebuild -configuration Release build`
- [ ] Sign with Developer ID Application certificate
- [ ] Create DMG: `./scripts/create_stylized_dmg.sh`
- [ ] Sign DMG
- [ ] Notarize: `xcrun notarytool submit --keychain-profile clipslim-notary --wait`
- [ ] Staple: `xcrun stapler staple`
- [ ] Verify: `spctl --assess --type execute -vv`

**3:00 PM - Sandbox Decision for MAS (1 hour)**
- [ ] Evaluate sandbox requirements for Mac App Store
- [ ] Test clipboard watcher behavior under sandbox (quick test)
- [ ] Test folder watcher with sandbox file access entitlements
- [ ] Decision: submit to MAS this weekend or defer to next week

**4:00 PM - MAS Build (if proceeding) (1.5 hours)**
- [ ] Add sandbox entitlements
- [ ] Add required file access entitlements for folder watcher
- [ ] Build with MAS signing identity (Apple Distribution)
- [ ] Upload to App Store Connect via Xcode
- [ ] Verify build processes without errors

**5:30 PM - Day 1 Review**
- [ ] Privacy policy live and URL working
- [ ] App Store Connect record created with all metadata
- [ ] DMG built, signed, notarized, and verified
- [ ] MAS build uploaded (or deferred decision documented)

---

## Day 2: Friday, March 6, 2026 -- Polish Day

### Morning (9 AM - 12 PM)

**9:00 AM - Screenshots (2.5 hours)**
- [ ] Launch ClipSlim on a clean desktop
- [ ] Capture screenshot 1: Menubar popover with optimization result (hero)
- [ ] Capture screenshot 2: Settings panel showing presets
- [ ] Capture screenshot 3: Folder watcher view
- [ ] Capture screenshot 4: Overlay resize controls in action
- [ ] Capture screenshot 5: Debug log with events
- [ ] Add text overlays/annotations to each screenshot
  - Use consistent style matching neon terminal aesthetic
  - Ensure text readable at Mac App Store thumbnail size
- [ ] Export at correct resolution (2880x1800 for Retina Mac)
- [ ] Upload screenshots to App Store Connect

**11:30 AM - Final Metadata Review (30 min)**
- [ ] Re-read all metadata for typos and clarity
- [ ] Verify all URLs are accessible (privacy, support, marketing)
- [ ] Confirm screenshots display correctly in App Store Connect preview

### Afternoon (1 PM - 6 PM)

**1:00 PM - Website / Landing Page (2 hours)**
- [ ] Create minimal landing page (can be single HTML page or GitHub Pages)
  - App name, tagline, and description
  - Key features list
  - Download button for DMG
  - Screenshots or animated GIF
  - System requirements (macOS 14.0+ Sonoma)
  - Privacy policy link
  - Support contact
- [ ] Deploy and test download link
- [ ] Verify DMG downloads correctly and installs

**3:00 PM - Marketing Preparation (1.5 hours)**
- [ ] Draft Twitter/X launch tweet
  - Focus: "Introducing ClipSlim -- automatic clipboard image optimization for macOS. 100% local, zero data collection. Free download."
  - Include screenshot or GIF
- [ ] Draft Reddit r/macapps post
  - Title: "I built ClipSlim -- a menubar utility that automatically optimizes images on your clipboard (100% local)"
  - Body: what it does, why, link to download
- [ ] Draft Hacker News "Show HN" post
  - Title: "Show HN: ClipSlim -- macOS menubar app that auto-optimizes clipboard images locally"
- [ ] Prepare social media images (app icon + hero screenshot)

**4:30 PM - Final DMG Testing (1 hour)**
- [ ] Fresh install test: download DMG from website, mount, drag to /Applications
- [ ] First launch test: app appears in menubar, onboarding works
- [ ] Core flow test: copy image, verify optimization happens automatically
- [ ] Folder watcher test: enable, drop image in watched folder
- [ ] Hotkey test: Option+1 and Option+2 work
- [ ] Quit and relaunch test: settings persist

**5:30 PM - Submit to Mac App Store (if build ready)**
- [ ] Select build in App Store Connect
- [ ] Submit for review
- [ ] Expected review time: 1-3 business days (may not be approved by weekend)
- [ ] Note: MAS launch may happen March 10-12 instead

**6:00 PM - Day 2 Review**
- [ ] Screenshots created and uploaded
- [ ] Website live with working download
- [ ] Marketing materials drafted and ready to post
- [ ] MAS submitted (or DMG-only plan confirmed)
- [ ] Final DMG verified via fresh install test

---

## Day 3: Saturday, March 7, 2026 -- LAUNCH DAY (Direct Distribution)

### Morning (9 AM - 12 PM)

**9:00 AM - Pre-Launch Verification (30 min)**
- [ ] Website loads correctly
- [ ] DMG download link works
- [ ] DMG installs cleanly on a test machine (or clean user account)
- [ ] Privacy policy URL accessible
- [ ] Support channel ready (email or GitHub Issues)

**9:30 AM - Launch Announcements (2 hours)**
- [ ] Post on Twitter/X
- [ ] Post on Reddit r/macapps
- [ ] Post on Hacker News (Show HN)
- [ ] Post on Mastodon (if applicable)
- [ ] Share in any relevant Slack/Discord communities
- [ ] Email friends/contacts who might be interested

**11:30 AM - Monitor First Reactions (ongoing)**
- [ ] Watch Reddit comments and respond
- [ ] Watch HN comments and respond
- [ ] Monitor Twitter mentions
- [ ] Check email for support requests

### Afternoon and Evening

**1:00 PM - Engagement (ongoing)**
- [ ] Respond to all comments and questions within 1 hour
- [ ] Note any bug reports for immediate triage
- [ ] Track download numbers (website analytics / server logs)

**5:00 PM - Day 3 Review**
- [ ] Total downloads recorded
- [ ] Feedback themes documented
- [ ] Any critical bugs? If yes, plan hotfix for tomorrow
- [ ] Social media engagement metrics noted

---

## Day 4: Sunday, March 8, 2026 -- Post-Launch Day 1

### Morning
- [ ] Check overnight feedback (Reddit, HN, Twitter, email)
- [ ] Respond to all outstanding comments
- [ ] If critical bug reported: fix, rebuild, re-notarize DMG, update website
- [ ] Check Mac App Store review status (likely still "In Review")

### Afternoon
- [ ] Write follow-up post on Reddit if initial post gained traction
- [ ] Cross-post to additional communities:
  - [ ] r/apple
  - [ ] r/productivity
  - [ ] Indie hacker communities
- [ ] Begin documenting feedback for v1.1 roadmap

---

## Week 1: March 9-14, 2026 -- Early Traction

### Monday, March 9
- [ ] Check Mac App Store review status
- [ ] Respond to any new reviews or feedback
- [ ] If MAS approved: announce on social media
- [ ] If MAS rejected: address rejection reasons, resubmit
- [ ] Track download numbers (DMG + MAS)

### Tuesday, March 10
- [ ] Product Hunt launch preparation (if not done yet)
- [ ] Submit to Product Hunt
- [ ] Draft blog post about building ClipSlim (dev story)
- [ ] Check keyword rankings (manual search in App Store)

### Wednesday, March 11
- [ ] Product Hunt monitoring and engagement
- [ ] Respond to all reviews (MAS and social)
- [ ] Compile bug reports and prioritize v1.1 fixes
- [ ] Begin v1.1 development if needed

### Thursday, March 12
- [ ] Mid-week analytics review:
  - DMG downloads
  - MAS downloads (if live)
  - Website visitors
  - Social media reach
- [ ] Adjust marketing messaging based on feedback
- [ ] Reach out to Mac app review blogs/YouTubers

### Friday, March 14
- [ ] Week 1 retrospective:
  - Total downloads across channels
  - User feedback themes
  - Bug count and severity
  - Marketing channel effectiveness
- [ ] Plan Week 2 activities
- [ ] v1.1 scope finalized

---

## Week 2: March 15-21, 2026 -- Optimization

### Monday, March 15
- [ ] Run ASO health check on Mac App Store listing
- [ ] Analyze which keywords are driving impressions
- [ ] Update promotional text if messaging needs refinement
- [ ] Respond to all new reviews

### Wednesday, March 17
- [ ] A/B test ideas for screenshots (if MAS data available)
- [ ] Review conversion rate in App Store Connect analytics
- [ ] Submit v1.1 update (if fixes ready)

### Friday, March 21
- [ ] Week 2 metrics review
- [ ] Compare to Week 1 baseline
- [ ] Adjust keyword strategy based on data
- [ ] Plan localization if international interest exists

---

## Milestones Summary

| Date | Milestone | Status |
|------|-----------|--------|
| March 5 | Metadata and DMG build finalized | Pending |
| March 6 | Screenshots, website, marketing materials ready | Pending |
| March 6 | Mac App Store submission (if sandbox resolved) | Pending |
| March 7 | **DMG LAUNCH -- Direct distribution live** | Pending |
| March 7 | Social media announcements posted | Pending |
| March 9-12 | Mac App Store approval (estimated) | Pending |
| March 10-11 | Product Hunt launch | Pending |
| March 14 | Week 1 retrospective | Pending |
| March 21 | v1.1 update submitted | Pending |

---

## Contingency Planning

**If Mac App Store rejects due to sandbox:**
- Launch DMG-only as planned (this is the primary distribution anyway)
- Address sandbox issues during Week 1
- Resubmit to MAS by March 14

**If critical bug found on launch day:**
- Fix immediately, rebuild, re-notarize (process takes ~30 min total)
- Update DMG on website
- Post update on social media acknowledging the fix

**If low engagement on launch posts:**
- Try different communities (IndieHackers, MacStories forum, etc.)
- Create a demo GIF/video showing the before/after of clipboard optimization
- Reach out directly to Mac utility reviewers

**If Reddit/HN post gets removed:**
- Check subreddit rules, adjust post format
- Try alternative subreddits
- Focus on other channels

---

## Time Budget Summary

| Day | Hours | Focus |
|-----|-------|-------|
| March 5 (Thu) | 6-8 hours | Metadata, legal, builds |
| March 6 (Fri) | 6-8 hours | Screenshots, website, marketing |
| March 7 (Sat) | 4-6 hours | Launch, announcements, monitoring |
| March 8 (Sun) | 2-3 hours | Follow-up, engagement |
| March 9-14 | 1-2 hours/day | Monitoring, MAS follow-up, v1.1 |

**Total estimated effort:** 25-35 hours over 10 days

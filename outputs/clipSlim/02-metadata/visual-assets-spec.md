# Visual Assets Specification - clipSlim

**Platform:** Mac App Store
**Last Updated:** 2026-03-05
**Developer:** AppyAccidents
**Launch Target:** March 7-8, 2026

---

## APP ICON

### Specifications

| Property | Requirement |
|----------|-------------|
| Dimensions | 1024x1024 px |
| Format | PNG |
| Alpha channel | NOT allowed (Mac App Store requirement) |
| Color space | sRGB |
| Bit depth | 8-bit per channel |
| Corner rounding | Do NOT round corners yourself - macOS applies system rounding |

### Design Guidance

The app icon is the single highest-impact visual element for conversion rate. Users decide to tap/click in under 100ms.

**clipSlim's existing neon terminal aesthetic creates a natural direction:**

Concept A - Compression Bolt (Recommended)
A bold lightning bolt or downward arrow rendered in neon cyan on a deep dark background (near-black, #0d0d0d or similar). The bolt shape communicates "instant action" and "reduction". Thin neon glow effect around the bolt. No text. Reads clearly at 32x32px.

Concept B - Slim Document Stack
Two stacked rectangles (representing "before" and "after" file sizes). The top rectangle is large/faded, the bottom one is smaller and bright cyan. Communicates file size reduction without words.

Concept C - Scissor/Clip Hybrid
Combines the "clip" of clipboard with scissors - scissors cutting a wide image into a slim one. Rendered in the neon terminal palette. Slightly more complex but communicates the "slim" brand name directly.

**Design rules for all concepts:**
- Background: Dark (#0d0d0d to #111111 range)
- Primary accent: Neon cyan (#00ffcc or similar) matching in-app theme
- Secondary accent: Orange (#ff6600 or similar) used sparingly
- Monospaced typography only if any text is included (it should not be)
- No gradients that fade to white
- High contrast - must read on both dark and light dock backgrounds
- Test at 32x32, 64x64, 128x128 before finalizing

**What to avoid:**
- Generic camera or photo icons (too common in this category)
- Text in the icon (unreadable at small sizes)
- Soft pastels or light backgrounds (brand inconsistency, poor visibility in dark dock)
- Overly complex illustrations with more than 2-3 elements

### Icon Sizes Required for Xcode

Xcode generates all required sizes from your 1024x1024 source via an Asset Catalog. Provide only the 1024x1024 source in `Assets.xcassets/AppIcon.appiconset/`.

For reference, the sizes macOS actually uses:
| Size | Usage |
|------|-------|
| 16x16 | Finder sidebar, menu bar (small) |
| 32x32 | Finder sidebar |
| 64x64 | Finder list view |
| 128x128 | Finder icon view (small) |
| 256x256 | Finder icon view (large) |
| 512x512 | Launchpad, App Store listing |
| 1024x1024 | App Store product page |

---

## SCREENSHOTS (Mac App Store)

### Platform Requirements

| Property | Requirement |
|----------|-------------|
| Format | PNG or JPEG |
| Color space | sRGB |
| Minimum quantity | 1 (strongly recommend 3+) |
| Maximum quantity | 10 |
| Must include | At least one screenshot at each required resolution |

### Required Resolutions

Mac App Store requires screenshots for the following display sizes:

| Display | Required Resolution | Notes |
|---------|-------------------|-------|
| MacBook Pro 16" | 2560x1600 px | REQUIRED |
| MacBook Pro 13" | 2560x1600 px | Same resolution, different device frame |

Apple also accepts (and shows on product page):
| Display | Resolution |
|---------|-----------|
| iMac (5K) | 5120x2880 px |
| MacBook Air M1/M2 | 2560x1664 px |

**Minimum viable set for launch: 2560x1600 screenshots.**

### Screenshot Strategy

First impressions are everything. The first screenshot is shown in search results without any user scrolling. Design for the thumbnail view first.

#### Screenshot 1 - Hero (MOST IMPORTANT)
**Goal:** Explain what the app does in under 3 seconds at thumbnail size.

Content:
- Show the menubar icon in context (menubar at top of screen)
- Show the popup panel open with a recent compression result (e.g., "PNG compressed 58% - 4.2MB to 1.8MB")
- Text overlay at the top or bottom: "Compress images from your clipboard - automatically"
- Use the app's actual neon terminal UI (dark background, cyan accents) - this is a differentiator and will stand out in a sea of white/blue utility app screenshots

Layout:
```
[ Dark screenshot background - macOS desktop with menubar visible ]
[ clipSlim panel open showing: optimization result with percentage ]
[ Overlay text banner: "Compress images the moment you copy them" ]
```

#### Screenshot 2 - Folder Watcher Feature
**Goal:** Surface the second major use case (folder monitoring).

Content:
- Show the Folder Watcher tab in the app panel
- Show a folder being watched with some processed files shown in the log
- Text overlay: "Set it and forget it. Watch any folder."

#### Screenshot 3 - Presets and Settings
**Goal:** Show flexibility and customization.

Content:
- Show the Presets panel (4 presets visible: Web, High, Compressed, Custom)
- Text overlay: "4 presets. 3 intensity levels. Your call."

#### Screenshot 4 - Privacy and Local Processing
**Goal:** Address the #1 concern of privacy-conscious Mac users.

Content:
- Show the app panel with privacy-related UI elements visible
- Add a text overlay with a clear privacy statement
- Text overlay: "100% local. Zero uploads. Your files stay home."
- Optional: Show network activity monitor with zero network usage

#### Screenshot 5 - Debug Log / Stats
**Goal:** Appeal to developer/power user audience.

Content:
- Show the debug log with several timestamped events
- Show compression percentages for multiple images (conveying reliability and output quality)
- Text overlay: "Full event log. See exactly what was saved."

### Screenshot Design Specifications

**Text Overlays:**
- Font: SF Pro Display Bold or your app's monospace font for brand consistency
- Minimum font size: 28pt at 2x (56px actual)
- Text color: White (#FFFFFF) or neon cyan (#00ffcc) against dark backgrounds
- Add a subtle dark gradient behind light text if placed over a light area of the screenshot
- Maximum 10 words per overlay headline

**Visual Style:**
- Dark backgrounds preferred (matches app aesthetic, stands out from competitors)
- Neon accents (cyan, orange) consistent with in-app theme
- No heavy drop shadows or glossy button effects (looks dated)
- No device frames are required for Mac App Store (app window screenshot is sufficient)
- Adding a MacBook outline/device frame is optional but adds context for new users

**File Naming for Submission:**
```
screenshot-01-hero-2560x1600.png
screenshot-02-folder-watcher-2560x1600.png
screenshot-03-presets-2560x1600.png
screenshot-04-privacy-2560x1600.png
screenshot-05-debug-log-2560x1600.png
```

---

## APP PREVIEW VIDEO (Optional but Recommended)

### Specifications

| Property | Requirement |
|----------|-------------|
| Duration | 15-30 seconds |
| Format | MOV, MP4, or M4V |
| Frame rate | 30fps minimum |
| Resolution | Matches screenshot resolution (2560x1600 for Mac) |
| Audio | Optional - app auto-plays on mute in App Store |
| Subtitles | Strongly recommended (most users watch muted) |

### Recommended App Preview Script (30 seconds)

```
0:00 - 0:05
Screen: User copies a large PNG screenshot
Subtitle: "You just copied a 4.8MB PNG"

0:05 - 0:10
Screen: clipSlim notification appears "Compressed 61% - 4.8MB to 1.9MB"
Subtitle: "clipSlim already compressed it"

0:10 - 0:18
Screen: Open the panel, show presets, show folder watcher tab
Subtitle: "4 presets. Folder watching. All local."

0:18 - 0:25
Screen: Paste the image somewhere (Slack, docs) - show it's already slim
Subtitle: "Paste the slim version. Every time."

0:25 - 0:30
Screen: App icon / product name on dark background
Subtitle: "clipSlim - Image Optimizer. Free on the Mac App Store."
```

---

## LAUNCH CHECKLIST - Visual Assets

- [ ] App icon created at 1024x1024 px, PNG, no alpha channel
- [ ] App icon tested at 32x32, 64x64, 128x128 to confirm legibility
- [ ] App icon added to Xcode Assets.xcassets
- [ ] Minimum 3 screenshots created at 2560x1600 px
- [ ] Screenshot 1 (hero) reviewed at thumbnail size (search result preview)
- [ ] Text overlays confirmed readable at thumbnail size
- [ ] Screenshots uploaded to App Store Connect under the correct display size slot
- [ ] (Optional) App preview video recorded and uploaded

---

## TOOLS RECOMMENDED

| Task | Tool |
|------|------|
| Icon design | Figma, Sketch, or Pixelmator Pro |
| Screenshot design | Figma, Sketch, or ScreenSnapAI |
| Screenshot capture | macOS built-in (Cmd+Shift+3/4), CleanMyMac, Rottenwood |
| Video recording | QuickTime Player, ScreenFlow, Loom |
| Image compression check | Use clipSlim itself (dogfooding) |

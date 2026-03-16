# Visual Assets Specification - ClipSlim

**Platform:** Mac App Store
**Last Updated:** 2026-03-16
**Developer:** AppyAccidents
**Category:** Utilities (macOS)

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
| Corner rounding | Do NOT round corners yourself - macOS applies system squircle mask automatically |

### Design Guidance

The app icon is the single highest-impact element for install conversion rate. Users decide whether to tap or click in under 100ms. For a menubar utility, the icon also appears at approximately 22x22 points in the menubar itself - it must read at that scale.

ClipSlim's existing neon terminal aesthetic (dark background, cyan #00F5FF, orange #FF8A00) provides a strong design direction that already differentiates from the soft-gradient icons dominant in this category.

**Concept A - Compression Arrow (Recommended)**
A bold downward-pointing arrow or squeeze shape rendered in neon cyan on a near-black background (#111111). The arrow communicates "reduction" and "instant action". A subtle glow around the stroke is consistent with the in-app aesthetic. No text. Reads clearly at 22x22 and at 512x512.

**Concept B - Slim Document Stack**
Two stacked rectangles representing "before" and "after" file sizes. The top rectangle is larger and desaturated. The bottom is narrower and bright cyan. Communicates size reduction without words. Simple enough to read at menubar scale.

**Concept C - Clipboard with Bolt**
A clipboard silhouette with a lightning bolt or compression indicator overlaid. Connects the "clipboard" brand to the "fast/instant" action. Slightly more complex - test at 22x22 before committing.

**Design rules for all concepts:**
- Background: #111111 to #0d0d0d (near-black, not pure black)
- Primary accent: Neon cyan (#00F5FF) matching the in-app theme
- Secondary accent: Orange (#FF8A00) used sparingly for contrast
- No gradients that fade to white
- No text (unreadable at menubar and sidebar sizes)
- High contrast - must read on both dark and light dock backgrounds
- Test at 22x22, 32x32, 64x64, and 128x128 before finalizing

**What to avoid:**
- Generic camera or photo app icons (too common in the Utilities category)
- Text in the icon
- Soft pastels or light backgrounds (brand inconsistency, poor visibility in dark mode dock)
- More than 2-3 visual elements (too complex at small sizes)

### Icon Sizes Required

Xcode generates all required sizes from your 1024x1024 source via the Asset Catalog. Provide only the 1024x1024 source PNG in `Assets.xcassets/AppIcon.appiconset/`.

macOS display sizes for reference:

| Size | Usage |
|------|-------|
| 16x16 | Finder sidebar (small) |
| 22x22 | Menubar (this is what users see most often) |
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
| Minimum quantity | 1 (strongly recommend 4+) |
| Maximum quantity | 10 |
| Required resolution | At least one set at 2560x1600 px |

### Required Resolutions

| Display | Resolution | Status |
|---------|-----------|--------|
| MacBook Pro 16" / 13" | 2560x1600 px | REQUIRED |
| iMac 5K | 5120x2880 px | Optional, shown on product page |
| MacBook Air M1/M2 | 2560x1664 px | Optional |

**Minimum viable set for any submission: three screenshots at 2560x1600 px.**

### Screenshot Strategy

The first screenshot is displayed in search result cards before a user taps through to the product page. It must explain the app in under 3 seconds at thumbnail size. Design screenshot 1 for the thumbnail view first, then verify it still works full-size.

#### Screenshot 1 - Hero (Most Important)

**Goal:** Answer "what does this app do?" in under 3 seconds at search result card size.

**Content:**
- Show the menubar icon in context at the top of a macOS desktop
- Show the ClipSlim panel open with a real compression result (e.g., "PNG compressed 61% - 4.8MB to 1.9MB")
- Text overlay headline: "Compress images the moment you copy them"
- Use the actual dark/neon UI - this stands out against the white and blue utility app screenshots that dominate the category

**Layout:**
```
[ Dark macOS desktop, menubar visible at top with ClipSlim icon highlighted ]
[ ClipSlim panel open showing: before size, after size, percentage saved ]
[ Text banner bottom: "Compress images the moment you copy them" ]
```

#### Screenshot 2 - PDF Compression

**Goal:** Surface the PDF feature, which is a strong differentiator and captures a distinct search audience.

**Content:**
- Show the app handling a PDF compression event
- Highlight the before/after file sizes for a PDF document
- Text overlay: "Compresses PDFs too. From your clipboard."

#### Screenshot 3 - Folder Watcher

**Goal:** Show the second major automation use case.

**Content:**
- Show the Folder Watcher tab with a monitored folder and a few processed files in the log
- Text overlay: "Set it and forget it. Watch any folder."

#### Screenshot 4 - Privacy and Local Processing

**Goal:** Address the top concern of privacy-conscious Mac users. This is a search-driven audience that actively filters for local-only tools.

**Content:**
- Show the app UI with a clear privacy statement visible
- Text overlay: "100% local. Zero uploads. Your files stay home."
- Optional: macOS Activity Monitor in background showing zero network usage

#### Screenshot 5 - Tip Jar and Support

**Goal:** Communicate the free-with-tip-jar model positively. Reassures users there is no subscription trap.

**Content:**
- Show the Support tab with the tip jar UI visible ($2.99 / $4.99 / $9.99 options)
- Text overlay: "Free forever. Leave a tip if ClipSlim saves you time."

### Screenshot Design Specifications

**Text Overlays:**
- Font: SF Pro Display Bold, or ClipSlim's monospace font for brand consistency
- Minimum font size: 28pt at 2x resolution (56px actual)
- Text color: White (#FFFFFF) or neon cyan (#00F5FF) on dark backgrounds
- Add a dark semi-transparent gradient behind text placed over lighter areas
- Maximum 10 words per headline overlay

**Visual Style:**
- Dark backgrounds (matches app aesthetic, stands out from competitors)
- Neon accents (cyan, orange) consistent with in-app theme
- No device frames required for Mac App Store submissions (app window screenshot is sufficient)
- Adding a MacBook outline as context is optional but helps users understand the app's menubar nature

**File Naming Convention:**
```
screenshot-01-hero-2560x1600.png
screenshot-02-pdf-compression-2560x1600.png
screenshot-03-folder-watcher-2560x1600.png
screenshot-04-privacy-2560x1600.png
screenshot-05-tip-jar-2560x1600.png
```

---

## APP PREVIEW VIDEO (Optional but Recommended)

### Specifications

| Property | Requirement |
|----------|-------------|
| Duration | 15-30 seconds |
| Format | MOV, MP4, or M4V |
| Frame rate | 30fps minimum |
| Resolution | 2560x1600 px (matches required screenshot resolution) |
| Audio | Optional - App Store auto-plays on mute |
| Subtitles | Strongly recommended (most users watch without audio) |

### Recommended App Preview Script (30 seconds)

```
0:00 - 0:05
Screen: User copies a large PNG screenshot from Finder
Subtitle: "You just copied a 4.8MB screenshot"

0:05 - 0:10
Screen: ClipSlim overlay notification appears: "Compressed 61% - 4.8MB to 1.9MB"
Subtitle: "ClipSlim compressed it before you even switched apps"

0:10 - 0:18
Screen: Open the panel, show quality presets, show Folder Watcher tab, show PDF result
Subtitle: "Images, PDFs, and whole folders. All local."

0:18 - 0:25
Screen: User pastes into Slack or email - file size shown as 1.9MB
Subtitle: "Paste the slim version. Every single time."

0:25 - 0:30
Screen: ClipSlim icon and app name on dark background
Subtitle: "ClipSlim - Clipboard Optimizer. Free on the Mac App Store."
```

---

## VISUAL ASSETS LAUNCH CHECKLIST

- [ ] App icon created at 1024x1024 px, PNG, no alpha channel
- [ ] App icon tested at 22x22 (menubar display size) for legibility
- [ ] App icon tested at 32x32, 64x64, and 128x128
- [ ] App icon added to Xcode Assets.xcassets/AppIcon.appiconset/
- [ ] Minimum 3 screenshots created at 2560x1600 px
- [ ] Screenshot 1 reviewed at thumbnail size (search result card preview)
- [ ] Text overlays confirmed readable at thumbnail size
- [ ] Screenshots uploaded to App Store Connect under the 2560x1600 display size slot
- [ ] Screenshot order confirmed: hero first, PDF compression second, folder watcher third
- [ ] (Optional) App preview video recorded at 2560x1600 and uploaded

---

## RECOMMENDED TOOLS

| Task | Tool |
|------|------|
| Icon design | Figma, Sketch, or Pixelmator Pro |
| Screenshot design | Figma, Sketch, or ScreenSnapAI |
| Screenshot capture | macOS built-in (Cmd+Shift+3/4) or CleanMyMac |
| Video recording | QuickTime Player or ScreenFlow |
| File size verification | Use ClipSlim itself (dogfooding - compress your own screenshots before uploading) |
| Icon small-size preview | Image Preview app, or Figma at reduced zoom |

# ClipSlim

A production-grade macOS menubar app that automatically optimizes images copied to the clipboard, and optionally optimizes images in a watched folder. All processing is local-only — no data ever leaves your device.

## Features

- **Clipboard Optimization** — Automatically detects and optimizes images on the clipboard
- **Folder Watcher** — Monitor a folder for new images via FSEvents and optimize them automatically
- **Presets** — Web, High Quality, Small, and Custom optimization presets
- **Transparency-Aware** — Preserves PNG alpha channels when needed
- **Loop Prevention** — Triple-layer protection (changeCount, write flag, SHA256 hash) prevents infinite clipboard loops
- **Notifications** — Optional banner notifications with optimization stats
- **Debug Log** — Timestamped event history with source filtering
- **Neon Terminal UI** — Dark theme with cyan/orange neon accents and monospaced typography
- **Automatic Conversion** — Converts less compatible formats (HEIC/TIFF) to PNG or JPEG automatically
- **Automatic Compression** — Compresses images on the clipboard or in watched folders without user intervention
- **Clipboard Replace Behavior** — Optimized images replace originals on the clipboard by default
- **Save Originals and Optimized** — Saves both original and optimized images to disk in separate folders
- **Global Hotkeys** — Option+1 to copy optimized image, Option+2 to copy original image to clipboard

## Clop Parity (Target Behaviors)

1. **Clipboard Auto-Optimization Flow**  
   Detects images on the clipboard, automatically optimizes them, and replaces the clipboard content with the optimized version by default.

2. **HEIC to PNG Conversion**  
   If the input image is HEIC (from clipboard or folder), it is converted to PNG by default unless the user selects JPEG as the preferred format.

3. **Save to Disk Behavior**  
   When saving images, both the original and the optimized versions are kept. Originals are saved in an `Originals/` subfolder, and optimized outputs are saved in an `Optimized/` subfolder (or similarly named). Filenames include timestamps or suffixes to prevent overwriting.

4. **Hotkeys**  
   - `⌥1` (Option+1) copies the last optimized image to the clipboard.  
   - `⌥2` (Option+2) copies the last original image to the clipboard.  
   These are global hotkeys that work when the app is running.

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 15.4+

## Architecture

```
ClipSlim/
├── App/            # @main entry point, AppDelegate
├── Models/         # AppSettings, Presets, Results, Events, ImageFormat
├── Services/       # ImageOptimizer, ClipboardWatcher, FolderWatcher, Notifications
├── ViewModels/     # AppViewModel coordinator
├── Views/          # MenuBarView, Settings tabs, Debug log, Components
├── Theme/          # VibeCheckTheme (Neon Terminal aesthetic)
├── Utilities/      # os.Logger wrapper
└── Resources/      # Info.plist, entitlements, Assets.xcassets
```

### Data Flow

```
Timer polls NSPasteboard.changeCount (0.5s)
  └─ Change detected → extract image data
      └─ Check loop prevention (changeCount + isWriting flag + SHA256 hash)
          └─ ImageOptimizer.optimize(data, preset) [background thread]
              └─ Result → write optimized data back to pasteboard
                  └─ Log OptimizationEvent + send notification
```

### Clipboard Versions

ClipSlim keeps the last original and last optimized image in memory (or on disk if saving is enabled) so the user can switch what they paste using the global hotkeys ⌥1 (optimized) and ⌥2 (original).

## Build

```bash
xcodebuild -project ClipSlim.xcodeproj -scheme ClipSlim -configuration Debug build
```

## Presets

| Preset       | Quality | Max Dimension | Strip Metadata | Allow Transparency Loss |
|-------------|---------|---------------|----------------|------------------------|
| Web          | 75%     | 1920px        | Yes            | Yes                    |
| High Quality | 90%     | 3840px        | No             | No                     |
| Small        | 60%     | 1280px        | Yes            | Yes                    |
| Custom       | User    | User          | User           | User                   |

## Hotkeys

- `⌥1` Copy last optimized image to clipboard  
- `⌥2` Copy last original image to clipboard  
- `⌃⇧C` (optional) Manually optimize current clipboard  

*Note: The manual optimize hotkey is a fallback and not required.*

## Privacy

ClipSlim processes all images locally using Apple's ImageIO framework. No network requests are made. No data is collected or transmitted. The app requires no sandbox (to access the system clipboard and arbitrary folders) but uses hardened runtime.

## License

See [LICENSE](LICENSE) for details.

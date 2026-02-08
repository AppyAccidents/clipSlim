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

### Key Design Decisions

- **No third-party dependencies** — Uses only Apple frameworks (ImageIO, CoreGraphics, CryptoKit, FSEvents, UserNotifications)
- **@Observable** — Modern Swift Observation framework (macOS 14+)
- **Off-main-thread** — All image optimization runs on background threads via async/await
- **Safe** — Never crashes on bad input; validates data, checks sizes, handles errors gracefully
- **LSUIElement** — Runs as a menubar-only app (no Dock icon)

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

## Privacy

ClipSlim processes all images locally using Apple's ImageIO framework. No network requests are made. No data is collected or transmitted. The app requires no sandbox (to access the system clipboard and arbitrary folders) but uses hardened runtime.

## License

See [LICENSE](LICENSE) for details.

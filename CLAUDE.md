# ClipSlim

macOS menubar app for automatic clipboard, folder, and drag-and-drop image/PDF optimization.

## Build & Run

```bash
# Debug build
xcodebuild -project ClipSlim.xcodeproj -scheme ClipSlim -configuration Debug build

# Release build
xcodebuild -project ClipSlim.xcodeproj -scheme ClipSlim -configuration Release build

# Run tests
xcodebuild -project ClipSlim.xcodeproj -scheme ClipSlim -destination 'platform=macOS' test
```

## Architecture

**Pattern**: MVVM with `@Observable` (Swift Observation framework)
**UI**: SwiftUI + AppKit (NSPanel for overlays, NSPasteboard for clipboard)
**Concurrency**: Swift 6 style — `@MainActor` isolation, `Sendable` types, `Task.detached` for background work

### Key Files

| File | Role |
|------|------|
| `ClipSlim/ViewModels/AppViewModel.swift` | Main coordinator — owns all services, orchestrates processing |
| `ClipSlim/Services/ImageOptimizer.swift` | CGContext-based image optimization (JPEG/PNG) |
| `ClipSlim/Services/PDFOptimizer.swift` | PDF compression via page-by-page re-rendering at reduced DPI (25M pixel cap per page) |
| `ClipSlim/Services/ClipboardWatcher.swift` | Adaptive-polling NSPasteboard monitor with hash-based dedup |
| `ClipSlim/Services/FolderWatcher.swift` | FSEventStream-based folder monitor |
| `ClipSlim/Services/DropZoneService.swift` | Drag-and-drop NSPanel window (100-item cap, observer lifecycle managed) |
| `ClipSlim/Services/OverlayService.swift` | Floating result overlay NSPanel |
| `ClipSlim/Models/AppSettings.swift` | UserDefaults-backed `@Observable` settings |
| `ClipSlim/Theme/VibeCheckTheme.swift` | Design system (colors, typography, spacing) |
| `ClipSlim/Views/Components/SettingsDesign.swift` | Reusable settings UI: `VibeSettingsPage`, `VibeSettingsCard`, `VibeHintText` |

### Services

- **ClipboardWatcher**: Polls NSPasteboard with adaptive intervals (0.5s→3s). Detects images and PDFs. `updateHashTracking()` updates dedup state without touching pasteboard content.
- **FolderWatcher**: FSEventStream with 300ms debounce. Outputs to `Optimized/` subfolder.
- **DropZoneService**: NSPanel-based drag-and-drop window. Accepts images and PDFs. Capped at 100 items. Observer properly stored and removed on `shutdown()`.
- **ImageOptimizer**: `Sendable` singleton. CGImageSource → resize → CGImageDestination pipeline.
- **PDFOptimizer**: `Sendable` singleton. CGPDFDocument → render pages at target DPI → write compressed PDF. Per-page bitmap capped at 25M pixels to prevent OOM.
- **OverlayService**: Non-activating floating panel showing optimization results.

### Data Flow

1. Input detected (clipboard/folder/drop zone)
2. AppViewModel checks `isProcessing` guard — prevents clipboard and drop zone from interleaving
3. AppViewModel routes to ImageOptimizer or PDFOptimizer based on file type
4. For clipboard PDFs: optimized data written with correct `com.adobe.pdf` type, hash tracking updated without re-writing pasteboard
5. Results displayed via OverlayService (clipboard) or written to disk (folder/drop zone)
6. OptimizationEvent logged for session stats (capped at 100 events)

## Conventions

- **Pure Apple frameworks** — no external dependencies
- **Swift 6 concurrency**: `@MainActor` for UI, `Sendable` for optimizers, `Task.detached(priority: .utility)` for heavy work
- **Settings**: UserDefaults with `didSet` auto-save pattern in `AppSettings`
- **File naming**: `PascalCase.swift` for all files
- **Design**: VibeCheckTheme for all colors, fonts, spacing — neon cyan (#00F5FF) + orange (#FF8A00). Settings tabs use `VibeSettingsPage` > `VibeSettingsCard` > `VibeHintText` pattern
- **List caps**: Events (100), drop items (100) — bounded to prevent unbounded memory growth

## Features

- Clipboard image optimization (auto-detect and compress)
- Folder watching with FSEventStream
- Drag-and-drop optimization (Drop Zone window)
- PDF compression (re-render at configurable DPI)
- Format override (JPEG/PNG), resize, crop (square/circle)
- Dominant color extraction
- Focus mode (skip overlay for specific apps)
- Pause/resume with timed intervals
- Global hotkeys (Option+1: copy optimized, Option+2: copy original)
- Save to disk (Originals + Optimized subfolders)

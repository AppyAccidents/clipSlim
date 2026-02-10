# ClipSlim Manual QA Checklist

- On first launch, onboarding appears with 3 steps.
- Onboarding step 1 sets preferred format (JPEG/PNG).
- Onboarding step 2 allows adding multiple folders and skipping.
- Completing onboarding persists selections and onboarding no longer appears on next launch.
- "Run onboarding again" in Settings re-opens onboarding.

- Add multiple watched folders in Settings.
- Remove watched folders in Settings.
- Relaunch app and verify watched folders restore from bookmarks.
- Verify stale/inaccessible bookmark handling logs and does not crash.

- Drop images into watched folders and verify outputs are written into `Optimized/` subfolder.
- Verify folder watcher does not re-optimize files from `Optimized/`.

- Preferred output format is respected for clipboard and folder pipelines.
- Transparency behavior is deterministic: JPEG preference + alpha input results in PNG (unless transparency loss allowed).

- Clipboard-triggered optimization shows overlay.
- Folder-triggered optimization does not show overlay.
- Rapid clipboard copies update same overlay instead of stacking windows.
- Overlay auto-dismisses after timeout, pauses on hover, and has close button.
- Overlay actions work: Undo, Save As, Remove from clipboard, Ignore image, Ignore app, one-off format override.

- Pause 10m / 1h / until tomorrow stops clipboard optimization.
- Resume restores clipboard optimization.
- Focus mode prevents optimization when frontmost app bundle ID is in focus list.

- Undo restores original clipboard payload for last optimization.
- Remove from clipboard removes image content while preserving non-image types when possible.

- Idle CPU remains low and adaptive polling backs off to 1.5s then 3s after idle thresholds.

- In StoreKit config/App Store environment, support products load.
- Purchase flow shows success/cancel/pending/failure messaging.
- Thank-you state appears after successful purchase.
- App remains fully functional with no purchases (no paywall).

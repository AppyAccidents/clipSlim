#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH_DEFAULT="$(
  find "$HOME/Library/Developer/Xcode/DerivedData" -path '*Build/Products/Release/ClipSlim.app' -print0 \
    | xargs -0 ls -td 2>/dev/null \
    | head -n 1
)"
if [[ -z "${APP_PATH_DEFAULT}" ]]; then
  APP_PATH_DEFAULT="$(
    find "$HOME/Library/Developer/Xcode/DerivedData" -path '*Build/Products/Debug/ClipSlim.app' -print0 \
      | xargs -0 ls -td 2>/dev/null \
      | head -n 1
  )"
fi
APP_PATH="${1:-$APP_PATH_DEFAULT}"

if [[ -z "${APP_PATH}" || ! -d "${APP_PATH}" ]]; then
  echo "Could not find ClipSlim.app. Pass app path as first arg." >&2
  exit 1
fi

mkdir -p "$DIST_DIR"

TS="$(date +%Y%m%d-%H%M%S)"
VOL_NAME="ClipSlim"
DMG_TMP="$DIST_DIR/ClipSlim-${TS}-tmp.dmg"
DMG_OUT="$DIST_DIR/ClipSlim-${TS}.dmg"
STAGE_DIR="/tmp/clipslim-stage-${TS}"
MOUNT_DIR=""
BG_DIR="${STAGE_DIR}/.background"
BG_PATH="${BG_DIR}/background.png"

cleanup() {
  hdiutil detach "${MOUNT_DIR}" -quiet >/dev/null 2>&1 || true
  rm -rf "${STAGE_DIR}" >/dev/null 2>&1 || true
  rm -f "${DMG_TMP}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

mkdir -p "${BG_DIR}"

swift - <<'SWIFT' "${BG_PATH}"
import AppKit

let outPath = CommandLine.arguments[1]
let size = NSSize(width: 700, height: 420)
let image = NSImage(size: size)

image.lockFocus()
let rect = NSRect(origin: .zero, size: size)

let bg = NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.11, alpha: 1.0)
bg.setFill()
rect.fill()

let accent = NSColor(calibratedRed: 0.0, green: 0.90, blue: 0.95, alpha: 0.18)
accent.setFill()
NSBezierPath(roundedRect: NSRect(x: 24, y: 50, width: 652, height: 320), xRadius: 20, yRadius: 20).fill()

let line = NSBezierPath()
line.move(to: NSPoint(x: 24, y: 46))
line.line(to: NSPoint(x: 676, y: 46))
line.lineWidth = 2
accent.setStroke()
line.stroke()

let textAttrs: [NSAttributedString.Key: Any] = [
    .foregroundColor: NSColor(calibratedRed: 0.0, green: 0.93, blue: 0.97, alpha: 0.95),
    .font: NSFont.monospacedSystemFont(ofSize: 26, weight: .bold)
]
let subtitleAttrs: [NSAttributedString.Key: Any] = [
    .foregroundColor: NSColor(calibratedWhite: 0.8, alpha: 0.92),
    .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
]

NSAttributedString(string: "ClipSlim", attributes: textAttrs).draw(at: NSPoint(x: 42, y: 315))
NSAttributedString(string: "Drag ClipSlim to Applications", attributes: subtitleAttrs).draw(at: NSPoint(x: 42, y: 285))

image.unlockFocus()

guard
  let tiff = image.tiffRepresentation,
  let rep = NSBitmapImageRep(data: tiff),
  let png = rep.representation(using: .png, properties: [:])
else {
  exit(1)
}

try png.write(to: URL(fileURLWithPath: outPath))
SWIFT

cp -R "${APP_PATH}" "${STAGE_DIR}/ClipSlim.app"
ln -s /Applications "${STAGE_DIR}/Applications"

hdiutil create -volname "${VOL_NAME}" -srcfolder "${STAGE_DIR}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW "${DMG_TMP}" >/dev/null
ATTACH_OUTPUT="$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_TMP}")"
MOUNT_DIR="$(printf "%s\n" "${ATTACH_OUTPUT}" | awk -F'\t' '/\/Volumes\// {print $NF; exit}')"

if [[ -z "${MOUNT_DIR}" ]]; then
  echo "Failed to detect mounted DMG volume path." >&2
  exit 1
fi

MOUNT_NAME="$(basename "${MOUNT_DIR}")"
sleep 1

if ! osascript <<OSA
tell application "Finder"
  tell disk "${MOUNT_NAME}"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {100, 100, 800, 560}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 120
    set text size of viewOptions to 12
    set background picture of viewOptions to file ".background:background.png"
    set position of item "ClipSlim.app" of container window to {185, 235}
    set position of item "Applications" of container window to {515, 235}
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
OSA
then
  echo "Warning: Finder styling failed; continuing with functional DMG layout." >&2
fi

hdiutil detach "${MOUNT_DIR}" >/dev/null
hdiutil convert "${DMG_TMP}" -format UDZO -imagekey zlib-level=9 -o "${DMG_OUT}" >/dev/null

echo "${DMG_OUT}"

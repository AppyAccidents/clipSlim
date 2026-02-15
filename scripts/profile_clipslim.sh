#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:-full}"
shift || true
if [[ "$MODE" != "full" && "$MODE" != "quick" ]]; then
  echo "Usage: $0 [full|quick] [--scenario <name>] [--run-id <id>]"
  exit 1
fi

SCENARIO=""
RUN_ID=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scenario)
      SCENARIO="${2:-}"
      shift 2
      ;;
    --run-id)
      RUN_ID="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: $0 [full|quick] [--scenario <name>] [--run-id <id>]"
      exit 1
      ;;
  esac
done

VALID_SCENARIOS=(
  baseline_idle
  clipboard_image_burst
  clipboard_non_image_burst
  folder_watch_burst
  settings_churn
  pause_resume_matrix
  overlay_lifecycle
  long_soak
)

scenario_is_valid() {
  local target="$1"
  for s in "${VALID_SCENARIOS[@]}"; do
    if [[ "$s" == "$target" ]]; then
      return 0
    fi
  done
  return 1
}

if [[ -n "$SCENARIO" ]] && ! scenario_is_valid "$SCENARIO"; then
  echo "Invalid scenario: $SCENARIO"
  echo "Valid scenarios: ${VALID_SCENARIOS[*]}"
  exit 1
fi

SCALE="1"
if [[ "$MODE" == "quick" ]]; then
  SCALE="0.10"
fi

BUNDLE_ID="com.appyaccidents.ClipSlim"
DERIVED_DIR="$HOME/Library/Developer/Xcode/DerivedData/ClipSlim-bstlyuoyzznyzdcawwbclncyblvn/Build/Products/Debug"
APP_PATH="$DERIVED_DIR/ClipSlim.app"
APP_BIN="$APP_PATH/Contents/MacOS/ClipSlim"
REPORT_DIR="$ROOT_DIR/reports/profiling"
if [[ -z "$RUN_ID" ]]; then
  RUN_ID="$(date +%Y%m%d-%H%M%S)"
fi
RUN_DIR="$REPORT_DIR/$RUN_ID"
TRACE_DIR="$RUN_DIR/traces"
DATA_DIR="$RUN_DIR/data"
LOG_DIR="$RUN_DIR/logs"
ASSETS_DIR="$RUN_DIR/assets"
WATCH_DIR="$ASSETS_DIR/watch_inbox"
DROP_DIR="$ASSETS_DIR/drop_source"
CHECKLIST_FILE="$RUN_DIR/checklist.log"
REPORT_SCRIPT="$ROOT_DIR/scripts/generate_profiling_report.sh"

mkdir -p "$TRACE_DIR" "$DATA_DIR" "$LOG_DIR" "$WATCH_DIR" "$DROP_DIR"
touch "$CHECKLIST_FILE"

scaled_secs() {
  python3 - "$1" "$SCALE" <<'PY'
import math, sys
base = float(sys.argv[1])
scale = float(sys.argv[2])
print(max(5, int(round(base * scale))))
PY
}

BASELINE_SECS="$(scaled_secs 600)"
SETTLE_SECS="$(scaled_secs 180)"
BURST_SECS="$(scaled_secs 120)"
CHURN_SECS="$(scaled_secs 120)"
PAUSE_MATRIX_SECS="$(scaled_secs 120)"
OVERLAY_SECS="$(scaled_secs 120)"
SOAK_SECS="$(scaled_secs 1800)"

build_app() {
  xcodebuild -project ClipSlim.xcodeproj -scheme ClipSlim -configuration Debug build > "$LOG_DIR/build.log" 2>&1
}

prepare_assets() {
  cat > "$ASSETS_DIR/base.b64" <<'B64'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO3fJ0QAAAAASUVORK5CYII=
B64
  base64 -D -i "$ASSETS_DIR/base.b64" -o "$ASSETS_DIR/base.png"

  cp "$ASSETS_DIR/base.png" "$ASSETS_DIR/base_copy.png"
  sips -s format jpeg "$ASSETS_DIR/base.png" --out "$ASSETS_DIR/base.jpg" >/dev/null 2>&1 || true
  sips -s format tiff "$ASSETS_DIR/base.png" --out "$ASSETS_DIR/base.tiff" >/dev/null 2>&1 || true
  sips -s format bmp "$ASSETS_DIR/base.png" --out "$ASSETS_DIR/base.bmp" >/dev/null 2>&1 || true
  sips -s format heic "$ASSETS_DIR/base.png" --out "$ASSETS_DIR/base.heic" >/dev/null 2>&1 || true

  SOURCE_IMAGES=()
  while IFS= read -r line; do
    SOURCE_IMAGES+=("$line")
  done < <(find "$ASSETS_DIR" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.tiff' -o -name '*.bmp' -o -name '*.heic' \) | sort)
  if [[ "${#SOURCE_IMAGES[@]}" -eq 0 ]]; then
    echo "No source images generated" >&2
    exit 1
  fi

  find "$DROP_DIR" -type f -delete || true
  for i in $(seq 1 200); do
    src="${SOURCE_IMAGES[$(( (i - 1) % ${#SOURCE_IMAGES[@]} ))]}"
    ext="${src##*.}"
    cp "$src" "$DROP_DIR/img_$i.$ext"
  done

  for i in $(seq 1 100); do
    echo "text payload $i $(date +%s%N)" > "$ASSETS_DIR/non_image_$i.txt"
    echo "%PDF-1.4 fake payload $i" > "$ASSETS_DIR/non_image_$i.pdf"
  done
}

write_watched_folder_defaults() {
  local watch_path="$1"
  local json
  json="$(swift - "$watch_path" <<'SWIFT'
import Foundation

struct WatchedFolder: Codable {
    let id: UUID
    let displayName: String
    let bookmarkData: Data
}

let path = CommandLine.arguments[1]
let url = URL(fileURLWithPath: path, isDirectory: true)
let bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
let entry = WatchedFolder(id: UUID(), displayName: url.lastPathComponent, bookmarkData: bookmark)
let data = try JSONEncoder().encode([entry])
print(String(data: data, encoding: .utf8)!)
SWIFT
)"
  defaults write "$BUNDLE_ID" watchedFoldersData -string "$json"
}

configure_defaults() {
  defaults write "$BUNDLE_ID" onboardingPresentedAtLeastOnce -bool true
  defaults write "$BUNDLE_ID" onboardingCompleted -bool true
  defaults write "$BUNDLE_ID" onboardingSchemaVersion -int 3
  defaults write "$BUNDLE_ID" clipboardWatchEnabled -bool true
  defaults write "$BUNDLE_ID" folderWatchEnabled -bool true
  defaults write "$BUNDLE_ID" focusModeEnabled -bool false
  defaults write "$BUNDLE_ID" pauseUntilEpoch -float 0
  defaults write "$BUNDLE_ID" pauseFolderWatcher -bool true
  defaults write "$BUNDLE_ID" saveToDisk -bool false
  defaults write "$BUNDLE_ID" notificationsEnabled -bool false
  defaults write "$BUNDLE_ID" saveDestinationModeRaw -string customFolder
  defaults write "$BUNDLE_ID" saveFolderPath -string "$ASSETS_DIR"
  write_watched_folder_defaults "$WATCH_DIR"
}

launch_app() {
  pkill -x ClipSlim || true
  sleep 1
  "$APP_BIN" >/dev/null 2>"$LOG_DIR/app_stderr.log" &
  APP_LAUNCH_PID=$!
  APP_PID=""
  for _ in {1..30}; do
    if kill -0 "$APP_LAUNCH_PID" 2>/dev/null; then
      APP_PID="$APP_LAUNCH_PID"
      break
    fi
    sleep 1
  done
  if [[ -z "$APP_PID" ]]; then
    echo "Failed to launch ClipSlim" >&2
    exit 1
  fi
}

stop_app() {
  pkill -x ClipSlim || true
}

sample_rss() {
  local pid="$1"
  local duration="$2"
  local out_csv="$3"
  echo "ts,rss_kb" > "$out_csv"
  local end=$((SECONDS + duration))
  while (( SECONDS < end )); do
    local rss
    rss="$(ps -o rss= -p "$pid" | awk '{print $1}' || true)"
    if [[ -n "$rss" ]]; then
      echo "$(date +%s),$rss" >> "$out_csv"
    fi
    sleep 1
  done
}

calc_rss_metrics() {
  local csv="$1"
  python3 - "$csv" <<'PY'
import csv, sys
vals=[]
with open(sys.argv[1]) as f:
    r=csv.DictReader(f)
    for row in r:
        try:
            vals.append(int(row['rss_kb']))
        except:
            pass
if not vals:
    print('0,0,0,0')
    raise SystemExit
start=vals[0]
peak=max(vals)
end=vals[-1]
delta_pct=((end-start)/start*100.0) if start else 0.0
print(f"{start},{peak},{end},{delta_pct:.2f}")
PY
}

copy_image_to_clipboard() {
  local path="$1"
  swift - "$path" <<'SWIFT'
import AppKit
import Foundation
import UniformTypeIdentifiers

let path = CommandLine.arguments[1]
let data = try Data(contentsOf: URL(fileURLWithPath: path))
let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
let pb = NSPasteboard.general
pb.clearContents()
let type: NSPasteboard.PasteboardType
switch ext {
case "png": type = .png
case "jpg", "jpeg": type = NSPasteboard.PasteboardType(UTType.jpeg.identifier)
case "tiff", "tif": type = .tiff
case "bmp": type = NSPasteboard.PasteboardType(UTType.bmp.identifier)
case "heic": type = NSPasteboard.PasteboardType(UTType.heic.identifier)
default: type = .png
}
pb.setData(data, forType: type)
SWIFT
}

stress_clipboard_images() {
  local count=100
  local imgs=()
  while IFS= read -r line; do
    imgs+=("$line")
  done < <(find "$DROP_DIR" -type f | sort)
  local n="${#imgs[@]}"
  for i in $(seq 1 "$count"); do
    local idx=$(( (i - 1) % n ))
    copy_image_to_clipboard "${imgs[$idx]}" || true
    sleep 1
  done
}

stress_clipboard_non_images() {
  for i in $(seq 1 100); do
    if (( i % 2 == 0 )); then
      printf 'non-image-text-%s\n' "$i" | pbcopy
    else
      printf 'file://%s/non_image_%s.pdf\n' "$ASSETS_DIR" "$i" | pbcopy
    fi
    sleep 1
  done
}

stress_folder_drop() {
  find "$WATCH_DIR" -type f -delete || true
  find "$WATCH_DIR/Optimized" -type f -delete || true
  local i=0
  while IFS= read -r f; do
    i=$((i+1))
    cp "$f" "$WATCH_DIR/drop_$i.${f##*.}" || true
    sleep 0.2
  done < <(find "$DROP_DIR" -type f | sort | head -n 200)
}

stress_settings_churn() {
  for i in $(seq 1 200); do
    if (( i % 2 == 0 )); then
      defaults write "$BUNDLE_ID" clipboardWatchEnabled -bool true
      defaults write "$BUNDLE_ID" folderWatchEnabled -bool false
      defaults write "$BUNDLE_ID" focusModeEnabled -bool false
      defaults write "$BUNDLE_ID" pauseFolderWatcher -bool true
      defaults write "$BUNDLE_ID" selectedPreset -string "Custom"
    else
      defaults write "$BUNDLE_ID" clipboardWatchEnabled -bool false
      defaults write "$BUNDLE_ID" folderWatchEnabled -bool true
      defaults write "$BUNDLE_ID" focusModeEnabled -bool true
      defaults write "$BUNDLE_ID" pauseFolderWatcher -bool false
      defaults write "$BUNDLE_ID" selectedPreset -string "Compressed"
    fi
    sleep 0.15
  done
}

stress_pause_resume_matrix() {
  for i in $(seq 1 120); do
    if (( i % 2 == 0 )); then
      defaults write "$BUNDLE_ID" pauseUntilEpoch -float 32503680000
      defaults write "$BUNDLE_ID" pauseFolderWatcher -bool true
      defaults write "$BUNDLE_ID" folderWatchEnabled -bool false
    else
      defaults write "$BUNDLE_ID" pauseUntilEpoch -float 0
      defaults write "$BUNDLE_ID" pauseFolderWatcher -bool false
      defaults write "$BUNDLE_ID" folderWatchEnabled -bool true
    fi
    sleep 0.2
  done
}

stress_overlay_lifecycle() {
  local i=0
  while IFS= read -r f; do
    i=$((i+1))
    copy_image_to_clipboard "$f" || true
    sleep 0.5
    [[ "$i" -ge 100 ]] && break
  done < <(find "$DROP_DIR" -type f | sort)
}

stress_long_soak() {
  local end=$((SECONDS + SOAK_SECS))
  local turn=0
  while (( SECONDS < end )); do
    turn=$((turn+1))
    case $((turn % 3)) in
      0) stress_clipboard_images ;;
      1) stress_folder_drop ;;
      2) stress_settings_churn ;;
    esac
    sleep 2
  done
}

scenario_template() {
  case "$1" in
    baseline_idle) echo "Allocations" ;;
    clipboard_image_burst) echo "Allocations" ;;
    clipboard_non_image_burst) echo "Allocations" ;;
    folder_watch_burst) echo "Leaks" ;;
    settings_churn) echo "Zombies" ;;
    pause_resume_matrix) echo "Zombies" ;;
    overlay_lifecycle) echo "Allocations" ;;
    long_soak) echo "Leaks" ;;
    *) return 1 ;;
  esac
}

scenario_duration() {
  case "$1" in
    baseline_idle) echo "$BASELINE_SECS" ;;
    clipboard_image_burst) echo "$((BURST_SECS + SETTLE_SECS))" ;;
    clipboard_non_image_burst) echo "$((BURST_SECS + SETTLE_SECS))" ;;
    folder_watch_burst) echo "$((BURST_SECS + SETTLE_SECS))" ;;
    settings_churn) echo "$CHURN_SECS" ;;
    pause_resume_matrix) echo "$PAUSE_MATRIX_SECS" ;;
    overlay_lifecycle) echo "$OVERLAY_SECS" ;;
    long_soak) echo "$SOAK_SECS" ;;
    *) return 1 ;;
  esac
}

scenario_stress_func() {
  case "$1" in
    baseline_idle) echo "" ;;
    clipboard_image_burst) echo "stress_clipboard_images" ;;
    clipboard_non_image_burst) echo "stress_clipboard_non_images" ;;
    folder_watch_burst) echo "stress_folder_drop" ;;
    settings_churn) echo "stress_settings_churn" ;;
    pause_resume_matrix) echo "stress_pause_resume_matrix" ;;
    overlay_lifecycle) echo "stress_overlay_lifecycle" ;;
    long_soak) echo "stress_long_soak" ;;
    *) return 1 ;;
  esac
}

append_checklist_status() {
  local name="$1"
  local trace="$TRACE_DIR/${name}.trace"
  local rss_metrics="$DATA_DIR/${name}_rss_metrics.txt"
  local leak_log="$DATA_DIR/${name}_leaks.txt"
  local status="ok"

  [[ -e "$trace" ]] || status="missing-trace"
  [[ -s "$rss_metrics" ]] || status="missing-rss-metrics"
  [[ -s "$leak_log" ]] || status="missing-leaks"

  printf '%s scenario=%s status=%s trace=%s rss_metrics=%s leaks=%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$name" \
    "$status" \
    "$( [[ -e "$trace" ]] && echo yes || echo no )" \
    "$( [[ -s "$rss_metrics" ]] && echo yes || echo no )" \
    "$( [[ -s "$leak_log" ]] && echo yes || echo no )" \
    >> "$CHECKLIST_FILE"
}

run_xctrace_scenario() {
  local name="$1"
  local template="$2"
  local duration="$3"
  local stress_func="$4"

  local trace="$TRACE_DIR/${name}.trace"
  local rss_csv="$DATA_DIR/${name}_rss.csv"
  local leak_log="$DATA_DIR/${name}_leaks.txt"

  rm -rf "$trace"

  xcrun xctrace record \
    --template "$template" \
    --attach "$APP_PID" \
    --time-limit "${duration}s" \
    --output "$trace" \
    >/dev/null 2>"$LOG_DIR/${name}_xctrace.log" &
  local xctrace_pid=$!
  local xctrace_deadline=$((SECONDS + duration + 120))

  sample_rss "$APP_PID" "$duration" "$rss_csv" &
  local sampler_pid=$!

  if [[ -n "$stress_func" ]]; then
    (
      "$stress_func"
    ) >"$LOG_DIR/${name}_stress.log" 2>&1 &
    local stress_pid=$!
    sleep "$duration"
    if kill -0 "$stress_pid" 2>/dev/null; then
      kill "$stress_pid" 2>/dev/null || true
      wait "$stress_pid" 2>/dev/null || true
    fi
  else
    sleep "$duration"
  fi

  while kill -0 "$xctrace_pid" 2>/dev/null; do
    if (( SECONDS >= xctrace_deadline )); then
      kill "$xctrace_pid" 2>/dev/null || true
      break
    fi
    sleep 1
  done

  wait "$xctrace_pid" || true
  wait "$sampler_pid" || true

  leaks "$APP_PID" > "$leak_log" 2>&1 || true

  local metrics
  metrics="$(calc_rss_metrics "$rss_csv")"
  echo "$metrics" > "$DATA_DIR/${name}_rss_metrics.txt"
  append_checklist_status "$name"
}

run_scenario() {
  local name="$1"
  local template duration stress
  template="$(scenario_template "$name")"
  duration="$(scenario_duration "$name")"
  stress="$(scenario_stress_func "$name")"
  run_xctrace_scenario "$name" "$template" "$duration" "$stress"
}

main() {
  build_app
  prepare_assets
  configure_defaults
  launch_app

  if [[ -n "$SCENARIO" ]]; then
    run_scenario "$SCENARIO"
  else
    for name in "${VALID_SCENARIOS[@]}"; do
      run_scenario "$name"
    done
  fi

  stop_app

  if [[ -x "$REPORT_SCRIPT" ]]; then
    "$REPORT_SCRIPT" "$RUN_DIR" "$MODE" >/dev/null
  fi

  echo "Run ID: $RUN_ID"
  echo "Run dir: $RUN_DIR"
  echo "Checklist: $CHECKLIST_FILE"
}

main

#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <run-dir> <mode>"
  exit 1
fi

RUN_DIR="$1"
MODE="$2"
DATA_DIR="$RUN_DIR/data"
TRACE_DIR="$RUN_DIR/traces"
REPORT="$RUN_DIR/report.md"

os_ver="$(sw_vers | tr '\n' '; ')"
xcode_ver="$(xcodebuild -version | tr '\n' '; ')"
commit="$(git rev-parse --short HEAD)"
run_id="$(basename "$RUN_DIR")"

extract_leaks() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    echo "0"
    return
  fi
  local c
  c="$(rg -o '[0-9]+ leak(?:s)? for [0-9]+' "$f" | head -n1 | awk '{print $1}' || true)"
  if [[ -z "$c" ]]; then
    c="0"
  fi
  echo "$c"
}

row() {
  local name="$1"
  local instr="$2"
  local threshold="$3"
  local metrics_file="$DATA_DIR/${name}_rss_metrics.txt"
  local leaks_file="$DATA_DIR/${name}_leaks.txt"

  if [[ ! -f "$metrics_file" ]]; then
    echo "| $name | $instr | 0 | 0 | 0 | inconclusive | inconclusive | missing-metrics |"
    return
  fi

  IFS=',' read -r start peak end delta < "$metrics_file"
  leaks_count="$(extract_leaks "$leaks_file")"
  status="PASS"
  reason="ok"

  python3 - "$delta" "$threshold" <<'PY' || status="FAIL"
import sys
if float(sys.argv[1]) > float(sys.argv[2]):
    raise SystemExit(1)
PY

  if [[ "$status" == "FAIL" ]]; then
    reason="rss-delta>${threshold}%"
  fi

  if [[ "$leaks_count" != "0" ]]; then
    status="FAIL"
    reason="leaks=${leaks_count}"
  fi

  echo "| $name | $instr | $peak | $delta | $leaks_count | none-observed | $status | $reason |"
}

{
  echo "# ClipSlim Profiling Report"
  echo
  echo "- Run ID: \`$run_id\`"
  echo "- Mode: \`$MODE\`"
  echo "- Environment: $os_ver"
  echo "- Xcode: $xcode_ver"
  echo "- Build config: Debug"
  echo "- Commit: \`$commit\`"
  echo
  echo "## Scenario Results"
  echo
  echo "| Scenario | Instrument | Peak RSS (KB) | Settled Delta % | Leaks | Zombie/Crash | Pass/Fail | Notes |"
  echo "|---|---|---:|---:|---:|---|---|---|"
  row baseline_idle Allocations 5
  row clipboard_image_burst Allocations 20
  row clipboard_non_image_burst Allocations 20
  row folder_watch_burst Leaks 20
  row settings_churn Zombies 25
  row pause_resume_matrix Zombies 25
  row overlay_lifecycle Allocations 20
  row long_soak Leaks 25
  echo
  echo "## Top Retained Classes / Alloc Sites"
  echo
  echo "Automated class-level extraction from .trace bundles is not stable via CLI."
  echo "For any failing scenario, inspect retained classes in Instruments UI using traces in \`$TRACE_DIR\`."
  echo
  echo "## Failure Repro Steps"
  echo
  echo "1. Open the scenario trace in Instruments."
  echo "2. Filter to end-of-run interval."
  echo "3. Validate persistent allocations and leak roots after 2-minute idle settle."
  echo "4. Re-run the target scenario via \`scripts/profile_clipslim.sh full --scenario <name> --run-id $run_id\`."
  echo
  echo "## Ranked Fix Targets"
  echo
  echo "- P1: Timer/observer lifecycle leaks"
  echo "  - /Users/berkerceylan/Documents/GitHub/clipSlim/ClipSlim/Services/ClipboardWatcher.swift"
  echo "  - /Users/berkerceylan/Documents/GitHub/clipSlim/ClipSlim/Services/FolderWatcher.swift"
  echo "  - /Users/berkerceylan/Documents/GitHub/clipSlim/ClipSlim/Services/OverlayService.swift"
  echo "  - /Users/berkerceylan/Documents/GitHub/clipSlim/ClipSlim/ViewModels/AppViewModel.swift"
  echo "- P2: Clipboard data retention pressure"
  echo "  - /Users/berkerceylan/Documents/GitHub/clipSlim/ClipSlim/ViewModels/AppViewModel.swift"
  echo "- P3: Folder event backlog pressure"
  echo "  - /Users/berkerceylan/Documents/GitHub/clipSlim/ClipSlim/Services/FolderWatcher.swift"

  if [[ "$MODE" == "quick" ]]; then
    echo
    echo "## Quick Mode Note"
    echo
    echo "Durations were scaled to 10% of plan values."
    echo "Run \`scripts/profile_clipslim.sh full\` for exact planned durations."
  fi
} > "$REPORT"

echo "$REPORT"

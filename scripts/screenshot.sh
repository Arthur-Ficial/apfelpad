#!/bin/zsh
# Launch the built app and capture ONLY its window (not the desktop) to site/img/.
# Uses a tiny inline Swift program to query CoreGraphics for the window ID,
# then `screencapture -l <windowID>` for window-only capture.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT_DIR/build/apfelpad.app"
OUT_DIR="$ROOT_DIR/site/img"
mkdir -p "$OUT_DIR"

if [[ ! -d "$APP" ]]; then
    print "==> Building .app first..."
    "$ROOT_DIR/scripts/build-app.sh"
fi

# Kill any existing instances so we start from a clean slate
osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
sleep 0.5

print "==> Launching apfelpad..."
open "$APP"
# Wait longer so =apfel(...) formula in the welcome doc finishes streaming
# before we capture — otherwise the screenshot shows the "evaluating" placeholder.
sleep 20.0

# Find the window ID via CoreGraphics (Swift inline script)
WINDOW_ID=$(swift - <<'SWIFT'
import Foundation
import CoreGraphics

let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
guard let windows = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else {
    exit(1)
}
for w in windows {
    let owner = w[kCGWindowOwnerName as String] as? String ?? ""
    let layer = w[kCGWindowLayer as String] as? Int ?? 0
    let bounds = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
    let width = bounds["Width"] as? Double ?? 0
    let height = bounds["Height"] as? Double ?? 0
    if owner == "apfelpad" && layer == 0 && width > 100 && height > 100 {
        if let num = w[kCGWindowNumber as String] as? Int {
            print(num)
            exit(0)
        }
    }
}
exit(1)
SWIFT
)

if [[ -z "$WINDOW_ID" ]]; then
    print "ERROR: could not find apfelpad window" >&2
    osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
    exit 1
fi

print "==> Capturing window ID $WINDOW_ID to $OUT_DIR/screen-math.png"
# -l <id>: capture specific window by ID (WINDOW ONLY — not the whole desktop)
# -o    : omit window drop shadow
# -x    : silent (no sound)
screencapture -l "$WINDOW_ID" -o -x "$OUT_DIR/screen-math.png"

# QA: assert the result is window-sized, not desktop-sized.
WIDTH=$(sips -g pixelWidth "$OUT_DIR/screen-math.png" | awk '/pixelWidth/ {print $2}')
HEIGHT=$(sips -g pixelHeight "$OUT_DIR/screen-math.png" | awk '/pixelHeight/ {print $2}')
print "    dimensions: ${WIDTH}×${HEIGHT}"

if [[ "$WIDTH" -gt 2400 ]]; then
    print "ERROR: screenshot too wide (${WIDTH}px) — looks like a desktop capture, not a window capture" >&2
    osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
    exit 1
fi

# Cleanup: close the app
osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
print "==> Screenshot saved to $OUT_DIR/screen-math.png (${WIDTH}×${HEIGHT})"

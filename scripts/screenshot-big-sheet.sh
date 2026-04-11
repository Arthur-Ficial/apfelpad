#!/bin/zsh
# Builds apfelpad, opens the big sheet demo fixture, waits for evaluation,
# and captures a window-only screenshot for the landing page hero.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT_DIR/build/apfelpad.app"
OUT="$ROOT_DIR/site/img/screen-big-sheet.png"
FIXTURE="$ROOT_DIR/Tests/Fixtures/20-the-big-sheet.md"

if [[ ! -d "$APP" ]]; then
    print "==> Building .app..."
    SIGN_IDENTITY="-" "$ROOT_DIR/scripts/build-app.sh"
fi

osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
sleep 0.8

print "==> Launching apfelpad with $FIXTURE..."
open -a "$APP" "$FIXTURE"
# Wait a generous window for =apfel streaming to complete
sleep 25.0

WINDOW_ID=$(swift - <<'SWIFT'
import Foundation
import CoreGraphics
let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
guard let windows = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else { exit(1) }
for w in windows {
    let owner = w[kCGWindowOwnerName as String] as? String ?? ""
    let layer = w[kCGWindowLayer as String] as? Int ?? 0
    let bounds = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
    let width = bounds["Width"] as? Double ?? 0
    let height = bounds["Height"] as? Double ?? 0
    if owner == "apfelpad" && layer == 0 && width > 100 && height > 100 {
        if let num = w[kCGWindowNumber as String] as? Int { print(num); exit(0) }
    }
}
exit(1)
SWIFT
)

if [[ -z "$WINDOW_ID" ]]; then
    print "ERROR: could not find apfelpad window" >&2
    exit 1
fi

screencapture -l "$WINDOW_ID" -o -x "$OUT"
WIDTH=$(sips -g pixelWidth "$OUT" | awk '/pixelWidth/ {print $2}')
HEIGHT=$(sips -g pixelHeight "$OUT" | awk '/pixelHeight/ {print $2}')
print "==> Saved $OUT (${WIDTH}×${HEIGHT})"

if [[ "$WIDTH" -gt 2400 ]]; then
    print "ERROR: too wide — desktop captured instead of window" >&2
    exit 1
fi

osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true

#!/bin/zsh
# End-to-end test for the formula catalogue sidebar.
# Launches the built .app, clicks the "Formulas" toolbar button, and
# clicks a row to assert a formula gets inserted into the document.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT_DIR/build/apfelpad.app"

if ! command -v peekaboo >/dev/null 2>&1; then
    print "ERROR: peekaboo not installed" >&2
    exit 1
fi

if [[ ! -d "$APP" ]]; then
    SIGN_IDENTITY="-" "$ROOT_DIR/scripts/build-app.sh"
fi

osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
sleep 0.8

# Reset the sidebar state to CLOSED so the test always starts the same
defaults delete com.fullstackoptimization.apfelpad apfelpad_formula_catalogue_sidebar_open 2>/dev/null || true
# Also clear any cached document
rm -rf ~/Library/Application\ Support/apfelpad/ 2>/dev/null || true

print "==> Launching apfelpad..."
open "$APP"
sleep 4

# Step 1: verify the sidebar is NOT visible (no Insert =math row)
SNAPSHOT=$(peekaboo see --annotate --app apfelpad 2>&1)
if print -- "$SNAPSHOT" | grep -qE "button\) - Insert =math"; then
    print "ERROR: sidebar is open on first launch — expected closed" >&2
    exit 1
fi
print "    sidebar starts closed ✓"

# Step 2: click the Formulas toolbar button to open the sidebar
print "==> Clicking the Formulas toolbar button..."
BUTTON=$(print -- "$SNAPSHOT" | grep -E "button\) - Formulas" | head -1 | sed -E 's/.*elem_([0-9]+).*/elem_\1/')
if [[ -z "$BUTTON" ]]; then
    print "ERROR: could not find Formulas toolbar button" >&2
    exit 1
fi
peekaboo click --on "$BUTTON" > /dev/null
sleep 0.8

# Step 3: verify the sidebar is now open
print "==> Verifying sidebar is visible..."
SNAPSHOT=$(peekaboo see --annotate --app apfelpad 2>&1)
MATH_ROW=$(print -- "$SNAPSHOT" | grep -E "button\) - Insert =math" | head -1 | sed -E 's/.*elem_([0-9]+).*/elem_\1/')
if [[ -z "$MATH_ROW" ]]; then
    print "ERROR: sidebar not visible after click (no Insert =math row)" >&2
    exit 1
fi
print "    sidebar visible, found Insert =math at $MATH_ROW"

# Step 3: click the =math row
print "==> Clicking Insert =math..."
peekaboo click --on "$MATH_ROW" > /dev/null
sleep 0.8

# Step 4: verify the window title now says "Untitled — Edited" (insert made it dirty)
print "==> Verifying document is now dirty..."
SNAPSHOT=$(peekaboo see --app apfelpad 2>&1)
if print -- "$SNAPSHOT" | grep -qE "Window: Untitled — Edited"; then
    print "    [PASS] insert made the document dirty"
    osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
    exit 0
fi

print "ERROR: expected 'Untitled — Edited' window title after insert" >&2
print -- "$SNAPSHOT" | head -5 >&2
osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
exit 1

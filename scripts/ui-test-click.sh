#!/bin/zsh
# End-to-end click-to-edit test for apfelpad.
# Launches the built .app, uses peekaboo to find a rendered formula span
# element, clicks it, and asserts the formula bar text field now contains
# the clicked formula's source. Exits 0 on success, non-zero on mismatch.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT_DIR/build/apfelpad.app"

if ! command -v peekaboo >/dev/null 2>&1; then
    print "ERROR: peekaboo not installed — install via brew" >&2
    exit 1
fi

if [[ ! -d "$APP" ]]; then
    print "==> Building .app first..."
    SIGN_IDENTITY="-" "$ROOT_DIR/scripts/build-app.sh"
fi

# Clean state so the welcome doc is fresh
osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
sleep 0.8

print "==> Launching apfelpad..."
open "$APP"
sleep 4

# Inspect the UI — look for a formula span exposed as a link
print "==> Locating the 8760 formula link..."
SNAPSHOT=$(peekaboo see --app apfelpad 2>&1)

# The welcome doc contains =math(365*24) which renders to 8760. Find its
# peekaboo element id by grepping the snapshot output.
LINK_ELEM=$(print -- "$SNAPSHOT" | grep -E "link\) - 8760" | head -1 | sed -E 's/.*elem_([0-9]+).*/elem_\1/')
if [[ -z "$LINK_ELEM" ]]; then
    print "ERROR: could not find the 8760 formula link in the UI" >&2
    print "peekaboo output:" >&2
    print -- "$SNAPSHOT" >&2
    osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
    exit 1
fi
print "    found at $LINK_ELEM"

# Click it
print "==> Clicking $LINK_ELEM..."
peekaboo click --on "$LINK_ELEM" > /dev/null
sleep 0.5

# Re-inspect and look for the formula bar's new text
print "==> Verifying formula bar updated..."
AFTER=$(peekaboo see --app apfelpad 2>&1)
if print -- "$AFTER" | grep -qE "textField\) - =math\(365\*24\)"; then
    print "    [PASS] formula bar now shows =math(365*24)"
    osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
    exit 0
fi

print "ERROR: formula bar did not update to =math(365*24) after click" >&2
print "Full element list after click:" >&2
print -- "$AFTER" >&2
osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
exit 1

#!/bin/zsh
# End-to-end click-to-edit test for apfelpad.
# Launches the built .app, uses peekaboo to find a rendered formula span
# element, clicks it, and asserts the formula bar text field now contains
# the clicked formula's source. Exits 0 on success, non-zero on mismatch.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT_DIR/build/apfelpad.app"
BIN="$APP/Contents/MacOS/apfelpad"
LOG="/tmp/apfelpad-ui-click.log"

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
pkill -f "/Contents/MacOS/apfelpad" 2>/dev/null || true
sleep 1

defaults delete com.fullstackoptimization.apfelpad apfelpad_formula_catalogue_sidebar_open 2>/dev/null || true
rm -rf ~/Library/Application\ Support/apfelpad/ 2>/dev/null || true

print "==> Launching apfelpad..."
APFELPAD_USE_STUB_LLM=1 APFELPAD_SKIP_SERVER=1 "$BIN" >"$LOG" 2>&1 &
APP_PID=$!
trap 'kill $APP_PID 2>/dev/null || true' EXIT

for _ in {1..20}; do
    if peekaboo app list | rg -q "apfelpad"; then break; fi
    sleep 0.5
done
sleep 3

osascript -e 'tell application "apfelpad" to activate' >/dev/null
sleep 0.5

# Inspect the UI via JSON to find the "loud words" link element.
# The welcome doc contains =lower("LOUD WORDS") which renders to "loud words".
print "==> Locating the 'loud words' formula link..."
peekaboo see --json --app apfelpad > /tmp/apfelpad-click-snap.json

LINK_ELEM=$(python3 -c "
import json, sys
els = json.load(open('/tmp/apfelpad-click-snap.json'))['data']['ui_elements']
for el in els:
    if el.get('role') == 'link' and el.get('label','').strip() == 'loud words':
        print(el['id'])
        sys.exit(0)
sys.exit(1)
") || {
    print "ERROR: could not find the 'loud words' formula link in the UI" >&2
    exit 1
}
print "    found at $LINK_ELEM"

# Click it
print "==> Clicking $LINK_ELEM..."
peekaboo click --on "$LINK_ELEM" --app apfelpad > /dev/null
sleep 0.5

# Re-inspect and look for the formula bar's new text
print "==> Verifying formula bar updated..."
peekaboo see --json --app apfelpad > /tmp/apfelpad-click-after.json

python3 - <<'PY'
import json, sys
els = json.load(open('/tmp/apfelpad-click-after.json'))['data']['ui_elements']
for el in els:
    if el.get('role') == 'textField' and '=lower("LOUD WORDS")' in (el.get('label') or ''):
        print('    [PASS] formula bar now shows =lower("LOUD WORDS")')
        sys.exit(0)
print('ERROR: formula bar did not update to =lower("LOUD WORDS") after click', file=sys.stderr)
for el in els:
    if el.get('role') == 'textField':
        lbl = (el.get('label') or '')[:80]
        if lbl:
            print(f"  textField: {lbl}", file=sys.stderr)
sys.exit(1)
PY

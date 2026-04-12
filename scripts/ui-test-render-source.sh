#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT_DIR/build/apfelpad.app"
BIN="$APP/Contents/MacOS/apfelpad"
LOG="/tmp/apfelpad-ui-render-source.log"

if ! command -v peekaboo >/dev/null 2>&1; then
    print "ERROR: peekaboo not installed" >&2
    exit 1
fi

if [[ ! -d "$APP" ]]; then
    SIGN_IDENTITY="-" "$ROOT_DIR/scripts/build-app.sh"
fi

osascript -e 'tell application "apfelpad" to quit' 2>/dev/null || true
pkill -f "/Contents/MacOS/apfelpad" 2>/dev/null || true
sleep 1

defaults delete com.fullstackoptimization.apfelpad apfelpad_formula_catalogue_sidebar_open 2>/dev/null || true
rm -rf ~/Library/Application\ Support/apfelpad/ 2>/dev/null || true

APFELPAD_USE_STUB_LLM=1 APFELPAD_SKIP_SERVER=1 "$BIN" >"$LOG" 2>&1 &
APP_PID=$!
trap 'kill $APP_PID 2>/dev/null || true' EXIT

for _ in {1..20}; do
    if peekaboo app list | rg -q "apfelpad"; then break; fi
    sleep 0.5
done
sleep 3

osascript <<'APPLESCRIPT' >/dev/null
tell application "apfelpad" to activate
tell application "System Events"
    tell process "apfelpad"
        keystroke "e" using {command down, shift down}
    end tell
end tell
APPLESCRIPT
sleep 0.8

peekaboo see --json --app apfelpad > /tmp/apfelpad-render-source-before.json
peekaboo window set-bounds --app apfelpad --x 80 --y 80 --width 1440 --height 960 >/dev/null
sleep 0.5
peekaboo type "\nRender mode e2e line.\n" --app apfelpad >/dev/null
sleep 1
osascript <<'APPLESCRIPT' >/dev/null
tell application "System Events"
    tell process "apfelpad"
        keystroke "2" using {command down}
    end tell
end tell
APPLESCRIPT
sleep 1
peekaboo see --json --app apfelpad > /tmp/apfelpad-render-source-after.json

python3 - <<'PY'
import json, sys
els=json.load(open('/tmp/apfelpad-render-source-after.json'))['data']['ui_elements']
source = next((el.get('label','') for el in els if el.get('role') == 'textField' and '=math(@hours * @rate)' in (el.get('label') or '')), '')
if 'Render mode e2e line.' not in source:
    print('ERROR: source mode does not contain the render edit', file=sys.stderr)
    sys.exit(1)
if '=math(@hours * @rate)' not in source:
    print('ERROR: source mode no longer shows raw formula source', file=sys.stderr)
    sys.exit(1)
print('PASS: render edit round-tripped into source mode')
PY

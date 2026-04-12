#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT_DIR/build/apfelpad.app"
BIN="$APP/Contents/MacOS/apfelpad"
LOG="/tmp/apfelpad-ui-calculator.log"

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
        keystroke "i" using {command down, option down}
    end tell
end tell
APPLESCRIPT
sleep 0.8
peekaboo type "Nimbus Labs" --clear --app apfelpad >/dev/null
sleep 0.6
osascript <<'APPLESCRIPT' >/dev/null
tell application "System Events"
    tell process "apfelpad"
        keystroke "]" using {command down, option down}
        keystroke "]" using {command down, option down}
    end tell
end tell
APPLESCRIPT
sleep 0.8
peekaboo type "200" --clear --app apfelpad >/dev/null
sleep 1
osascript <<'APPLESCRIPT' >/dev/null
tell application "System Events"
    tell process "apfelpad"
        keystroke "e" using {command down, shift down}
    end tell
end tell
APPLESCRIPT
sleep 0.5
peekaboo see --json --app apfelpad > /tmp/apfelpad-render-calculator.json

python3 - <<'PY'
import json, sys
els=json.load(open('/tmp/apfelpad-render-calculator.json'))['data']['ui_elements']
render = next((el.get('label','') for el in els if el.get('role') == 'textField' and '# Welcome to apfelpad' in (el.get('label') or '')), '')
checks = {
    'Nimbus Labs': 'client widget did not update',
    'Rate echo:  200': 'rate widget did not update',
    'Grand total: $ 10368': 'calculator did not recalculate the new grand total',
    'Quote for Nimbus Labs totals $10368.': 'summary line did not react to the new inputs',
}
for needle, message in checks.items():
    if needle not in render:
        print(f'ERROR: {message}', file=sys.stderr)
        sys.exit(1)
print('PASS: render calculator inputs stay live and update dependent formulas')
PY

#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT_DIR/build/apfelpad.app"
BIN="$APP/Contents/MacOS/apfelpad"
LOG="/tmp/apfelpad-ui-ai.log"

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

osascript -e 'tell application "apfelpad" to activate' >/dev/null
sleep 0.5

peekaboo see --json --app apfelpad > /tmp/apfelpad-render-ai.json

python3 - <<'PY'
import json, sys
els=json.load(open('/tmp/apfelpad-render-ai.json'))['data']['ui_elements']
render = next((el.get('label','') for el in els if el.get('role') == 'textField' and '# Welcome to apfelpad' in (el.get('label') or '')), '')
if 'Stub response 7' not in render:
    print('ERROR: seeded =apfel workbook example did not resolve through the stub LLM', file=sys.stderr)
    sys.exit(1)
if 'Stub response 3' not in render:
    print('ERROR: anonymous =() workbook example did not resolve through the stub LLM', file=sys.stderr)
    sys.exit(1)
if 'Stub response 11:' not in render:
    print('ERROR: composed document-context =apfel example did not resolve through the stub LLM', file=sys.stderr)
    sys.exit(1)
print('PASS: workbook AI examples resolve through the deterministic stub LLM')
PY

#!/bin/zsh
# release.sh — one script to rule them all
# Usage: ./scripts/release.sh
# Runs tests, builds, signs, notarises, tags, pushes, creates GitHub release,
# pushes Homebrew cask, and deploys the website to Cloudflare Pages.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="apfelpad"
VERSION="$(tr -d '\n' < "$ROOT_DIR/.version")"
TAG="v${VERSION}"
ARCH="$(uname -m)"
DIST_DIR="$ROOT_DIR/dist"

# ── Signing defaults ────────────────────────────────────────────────────────
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Franz Enzenhofer (7D2YX5DQ6M)}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-notarytool}"
ENTITLEMENTS="${ENTITLEMENTS:-$ROOT_DIR/apfelpad.entitlements}"

# ── Pre-flight ──────────────────────────────────────────────────────────────
print "==> Release $TAG"

BRANCH="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" != "main" && "$BRANCH" != "master" ]]; then
    print "ERROR: Must be on main or master branch (currently: $BRANCH)" >&2; exit 1
fi

if ! git -C "$ROOT_DIR" diff-index --quiet HEAD --; then
    print "ERROR: Uncommitted changes. Commit or stash first." >&2; exit 1
fi

if git -C "$ROOT_DIR" tag --list "$TAG" | grep -q "^${TAG}$"; then
    print "ERROR: Tag $TAG already exists. Bump .version and try again." >&2; exit 1
fi

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    print "ERROR: No Developer ID Application cert in Keychain." >&2; exit 1
fi

# ── Tests ───────────────────────────────────────────────────────────────────
print ""
print "==> Running tests..."
swift test --package-path "$ROOT_DIR"

# ── Build + Sign + Notarise ─────────────────────────────────────────────────
print ""
print "==> Building, signing, and notarising..."
SIGN_IDENTITY="$SIGN_IDENTITY" KEYCHAIN_PROFILE="$KEYCHAIN_PROFILE" ENTITLEMENTS="$ENTITLEMENTS" \
    "$ROOT_DIR/scripts/build-dist.sh"

# Verify the zip actually has a notarisation ticket before releasing
APP_ZIP="$DIST_DIR/${APP_NAME}-${TAG}-macos-${ARCH}.zip"
VERIFY_DIR="$(mktemp -d)"
ditto -x -k "$APP_ZIP" "$VERIFY_DIR"
if ! xcrun stapler validate "$VERIFY_DIR/${APP_NAME}.app" >/dev/null 2>&1; then
    print "ERROR: Notarisation ticket missing from app bundle. Aborting." >&2
    rm -rf "$VERIFY_DIR"
    exit 1
fi
rm -rf "$VERIFY_DIR"
print "==> Notarisation ticket verified."

# ── Regenerate screenshots (window-only) ────────────────────────────────────
print ""
print "==> Regenerating screenshots..."
"$ROOT_DIR/scripts/screenshot.sh"
if ! git -C "$ROOT_DIR" diff --quiet site/img/; then
    git -C "$ROOT_DIR" add site/img/
    git -C "$ROOT_DIR" commit -m "chore: regenerate screenshots for $TAG"
fi

# ── Update landing page: softwareVersion, downloadUrl, and download button ──
print ""
print "==> Updating site/index.html for $VERSION..."
VERSIONED_ZIP_URL="https://github.com/Arthur-Ficial/${APP_NAME}/releases/download/${TAG}/${APP_NAME}-${TAG}-macos-${ARCH}.zip"

sed -i '' "s|\"softwareVersion\": \"[^\"]*\"|\"softwareVersion\": \"$VERSION\"|" "$ROOT_DIR/site/index.html"
sed -i '' "s|\"downloadUrl\": \"[^\"]*\"|\"downloadUrl\": \"$VERSIONED_ZIP_URL\"|" "$ROOT_DIR/site/index.html"
sed -i '' "s|id=\"download-btn\" class=\"download\" href=\"[^\"]*\"|id=\"download-btn\" class=\"download\" href=\"$VERSIONED_ZIP_URL\"|" "$ROOT_DIR/site/index.html"

if ! git -C "$ROOT_DIR" diff --quiet site/index.html; then
    git -C "$ROOT_DIR" add site/index.html
    git -C "$ROOT_DIR" commit -m "chore: update softwareVersion to $VERSION in site/index.html"
fi

# ── Git tag + push ──────────────────────────────────────────────────────────
print ""
print "==> Tagging $TAG and pushing..."
git -C "$ROOT_DIR" tag "$TAG"
git -C "$ROOT_DIR" push origin "$BRANCH"
git -C "$ROOT_DIR" push origin "$TAG"

# ── GitHub Release ──────────────────────────────────────────────────────────
print ""
print "==> Creating GitHub release $TAG..."
APP_ZIP_STABLE="$DIST_DIR/${APP_NAME}-macos-${ARCH}.zip"
CLI_TARBALL="$DIST_DIR/${APP_NAME}-${TAG}-cli-macos-${ARCH}.tar.gz"
SHA_FILE="$DIST_DIR/SHA256SUMS"
HOMEBREW_CASK="$DIST_DIR/homebrew/${APP_NAME}.rb"

gh release create "$TAG" \
    --repo Arthur-Ficial/${APP_NAME} \
    --title "${APP_NAME} ${TAG}" \
    --generate-notes \
    "$APP_ZIP" \
    "$APP_ZIP_STABLE" \
    "$CLI_TARBALL" \
    "$SHA_FILE" \
    "$HOMEBREW_CASK"

# ── Push cask to homebrew-tap ────────────────────────────────────────────────
print ""
print "==> Pushing cask to Arthur-Ficial/homebrew-tap..."
CASK_B64="$(base64 < "$HOMEBREW_CASK")"
EXISTING_SHA="$(gh api repos/Arthur-Ficial/homebrew-tap/contents/Casks/${APP_NAME}.rb --jq '.sha' 2>/dev/null || true)"
if [[ -n "$EXISTING_SHA" ]]; then
    gh api repos/Arthur-Ficial/homebrew-tap/contents/Casks/${APP_NAME}.rb \
        -X PUT \
        -f message="cask: update ${APP_NAME} to ${TAG}" \
        -f content="$CASK_B64" \
        -f sha="$EXISTING_SHA" \
        --jq '.commit.sha' > /dev/null
else
    gh api repos/Arthur-Ficial/homebrew-tap/contents/Casks/${APP_NAME}.rb \
        -X PUT \
        -f message="cask: add ${APP_NAME} ${TAG}" \
        -f content="$CASK_B64" \
        --jq '.commit.sha' > /dev/null
fi
print "    Cask updated in tap."

# ── Deploy website ──────────────────────────────────────────────────────────
print ""
print "==> Deploying website to Cloudflare Pages..."
source ~/.env 2>/dev/null || true
npx wrangler pages deploy "$ROOT_DIR/site" --project-name ${APP_NAME}

# ── Ensure custom domain is wired up (idempotent) ───────────────────────────
print ""
print "==> Ensuring ${APP_NAME}.franzai.com is configured..."
EXISTING_DOMAINS="$(curl -s \
    "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects/${APP_NAME}/domains" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    | python3 -c "import json,sys; [print(d['name']) for d in json.load(sys.stdin).get('result',[])]" 2>/dev/null || true)"

if ! print -- "$EXISTING_DOMAINS" | grep -q "${APP_NAME}.franzai.com"; then
    print "    Adding custom domain to Cloudflare Pages..."
    curl -s -X POST \
        "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects/${APP_NAME}/domains" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"${APP_NAME}.franzai.com\"}" > /dev/null
else
    print "    Custom domain already registered."
fi

EXISTING_DNS="$(curl -s \
    "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=${APP_NAME}.franzai.com" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    | python3 -c "import json,sys; r=json.load(sys.stdin).get('result',[]); print(r[0]['type'] if r else '')" 2>/dev/null || true)"

if [[ -z "$EXISTING_DNS" ]]; then
    print "    Creating CNAME ${APP_NAME}.franzai.com → ${APP_NAME}.pages.dev..."
    curl -s -X POST \
        "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"CNAME\",\"name\":\"${APP_NAME}\",\"content\":\"${APP_NAME}.pages.dev\",\"ttl\":1,\"proxied\":true}" > /dev/null
else
    print "    DNS CNAME already exists."
fi

# ── Post-deploy tests ───────────────────────────────────────────────────────
print ""
print "==> Running post-deploy tests..."

FAIL=0
pass() { print "    [PASS] $1"; }
fail() { print "    [FAIL] $1" >&2; FAIL=1; }

# 1. GitHub release exists and has all expected assets
RELEASE_TMPFILE="$(mktemp)"
gh release view "$TAG" --repo Arthur-Ficial/${APP_NAME} --json assets,isDraft,tagName > "$RELEASE_TMPFILE" 2>/dev/null
[[ "$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['isDraft'])" "$RELEASE_TMPFILE")" == "False" ]] \
    && pass "GitHub release $TAG is published" || fail "GitHub release $TAG is draft or missing"

for ASSET in "${APP_NAME}-${TAG}-macos-${ARCH}.zip" \
             "${APP_NAME}-macos-${ARCH}.zip" \
             "${APP_NAME}-${TAG}-cli-macos-${ARCH}.tar.gz" \
             "SHA256SUMS" "${APP_NAME}.rb"; do
    python3 -c "import json,sys; d=json.load(open(sys.argv[1])); names=[a['name'] for a in d['assets']]; exit(0 if sys.argv[2] in names else 1)" "$RELEASE_TMPFILE" "$ASSET" \
        && pass "Asset present: $ASSET" || fail "Asset MISSING: $ASSET"
done
rm -f "$RELEASE_TMPFILE"

# 2. Versioned ZIP is downloadable and SHA256 matches
DOWNLOAD_DIR="$(mktemp -d)"
DOWNLOADED_ZIP="$DOWNLOAD_DIR/${APP_NAME}-${TAG}-macos-${ARCH}.zip"
print "    Downloading versioned ZIP from GitHub..."
if curl -fsSL -o "$DOWNLOADED_ZIP" \
    "https://github.com/Arthur-Ficial/${APP_NAME}/releases/download/${TAG}/${APP_NAME}-${TAG}-macos-${ARCH}.zip" 2>/dev/null; then
    EXPECTED_SHA="$(grep "${APP_NAME}-${TAG}-macos-${ARCH}.zip" "$SHA_FILE" | awk '{print $1}')"
    ACTUAL_SHA="$(shasum -a 256 "$DOWNLOADED_ZIP" | awk '{print $1}')"
    [[ "$EXPECTED_SHA" == "$ACTUAL_SHA" ]] \
        && pass "SHA256 matches" || fail "SHA256 MISMATCH (expected=$EXPECTED_SHA actual=$ACTUAL_SHA)"

    # 3. Extract and validate app bundle from downloaded ZIP
    EXTRACT_DIR="$(mktemp -d)"
    ditto -x -k "$DOWNLOADED_ZIP" "$EXTRACT_DIR"
    EXTRACTED_APP="$EXTRACT_DIR/${APP_NAME}.app"

    PLIST_VERSION="$(defaults read "$EXTRACTED_APP/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)"
    [[ "$PLIST_VERSION" == "$VERSION" ]] \
        && pass "App version is $VERSION" || fail "App version is '$PLIST_VERSION', expected '$VERSION'"

    spctl --assess --type execute "$EXTRACTED_APP" 2>/dev/null \
        && pass "Gatekeeper: accepted" || fail "Gatekeeper: REJECTED"

    xcrun stapler validate "$EXTRACTED_APP" >/dev/null 2>&1 \
        && pass "Notarisation ticket valid" || fail "Notarisation ticket MISSING"

    [[ -x "$EXTRACTED_APP/Contents/Helpers/apfel" ]] \
        && pass "apfel binary embedded in Contents/Helpers/" || fail "apfel binary NOT embedded"

    SIGNER="$(codesign -dvvv "$EXTRACTED_APP" 2>&1 | grep "^Authority=" | head -1)"
    [[ "$SIGNER" == *"Franz Enzenhofer"* ]] \
        && pass "Signed by Franz Enzenhofer (7D2YX5DQ6M)" || fail "Unexpected signer: $SIGNER"

    rm -rf "$EXTRACT_DIR"
else
    fail "Could not download versioned ZIP from GitHub"
fi
rm -rf "$DOWNLOAD_DIR"

# 4. Landing page is live on both Pages URL and custom domain
SITE_STATUS="$(curl -so /dev/null -w "%{http_code}" https://${APP_NAME}.pages.dev || echo 000)"
[[ "$SITE_STATUS" == "200" ]] \
    && pass "Pages URL (${APP_NAME}.pages.dev) HTTP $SITE_STATUS" || fail "Pages URL HTTP $SITE_STATUS"

CUSTOM_STATUS="$(curl -so /dev/null -w "%{http_code}" https://${APP_NAME}.franzai.com || echo 000)"
[[ "$CUSTOM_STATUS" == "200" ]] \
    && pass "Custom domain (${APP_NAME}.franzai.com) HTTP $CUSTOM_STATUS" || fail "Custom domain HTTP $CUSTOM_STATUS (DNS or Pages custom domain not configured)"

# 5. GitHub API returns this tag (download button will show correct version)
API_TAG="$(curl -s https://api.github.com/repos/Arthur-Ficial/${APP_NAME}/releases/latest | python3 -c "import json,sys; print(json.load(sys.stdin).get('tag_name',''))" 2>/dev/null || true)"
[[ "$API_TAG" == "$TAG" ]] \
    && pass "GitHub API latest = $TAG (download button correct)" || fail "GitHub API latest = '$API_TAG', expected '$TAG'"

# 6. Stable download URL redirects to this tag's ZIP
REDIRECT_LOCATION="$(curl -sI "https://github.com/Arthur-Ficial/${APP_NAME}/releases/latest/download/${APP_NAME}-macos-${ARCH}.zip" | grep -i "^location:" | tr -d '\r' || true)"
[[ "$REDIRECT_LOCATION" == *"$TAG"* ]] \
    && pass "Stable URL redirects to $TAG" || fail "Stable URL redirects to wrong version: $REDIRECT_LOCATION"

# 7. Homebrew tap has correct version
TAP_VERSION="$(gh api repos/Arthur-Ficial/homebrew-tap/contents/Casks/${APP_NAME}.rb --jq '.content' 2>/dev/null | base64 -d | grep '^  version ' | tr -d ' "' | sed 's/version//' || true)"
[[ "$TAP_VERSION" == "$VERSION" ]] \
    && pass "homebrew-tap cask version = $VERSION" || fail "homebrew-tap cask version = '$TAP_VERSION', expected '$VERSION'"

print ""
if [[ $FAIL -eq 0 ]]; then
    print "==> All post-deploy tests passed."
else
    print "ERROR: One or more post-deploy tests FAILED." >&2
    exit 1
fi

# ── Done ────────────────────────────────────────────────────────────────────
print ""
print "==> Done! $TAG is live."
print "    Release: https://github.com/Arthur-Ficial/${APP_NAME}/releases/tag/$TAG"
print "    Site:    https://${APP_NAME}.franzai.com"

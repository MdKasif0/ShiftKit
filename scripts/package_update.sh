#!/usr/bin/env bash
set -euo pipefail

echo "========================================================"
echo "       ShiftKit Sparkle 2 Update Packaging Pipeline      "
echo "========================================================"

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_DIR"

APP_NAME="ShiftKit"
VERSION="1.0.0"
BUILD="1"
ACCOUNT_NAME="shiftkit_updates"

UPDATES_DIR="$WORKSPACE_DIR/updates"
RELEASES_DIR="$UPDATES_DIR/releases"
mkdir -p "$RELEASES_DIR"
mkdir -p "$UPDATES_DIR/notes"

echo "1. Building Release Universal Application..."
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
xcodebuild build \
    -project ShiftKit.xcodeproj \
    -scheme ShiftKit \
    -configuration Release \
    -destination "platform=macOS" \
    SYMROOT="$WORKSPACE_DIR/build" \
    OBJROOT="$WORKSPACE_DIR/build/obj" \
    > "$WORKSPACE_DIR/build/update_build.log" 2>&1

BUILT_APP="$WORKSPACE_DIR/build/Release/$APP_NAME.app"
if [ ! -d "$BUILT_APP" ]; then
    BUILT_APP="$(find ~/Library/Developer/Xcode/DerivedData/ShiftKit-*/Build/Products/Release -name "$APP_NAME.app" -type d | head -n 1)"
fi

if [ ! -d "$BUILT_APP" ]; then
    echo "ERROR: Failed to find built $APP_NAME.app"
    exit 1
fi

echo "✓ Application built at: $BUILT_APP"

# Verify Sparkle.framework is embedded
if [ ! -d "$BUILT_APP/Contents/Frameworks/Sparkle.framework" ]; then
    echo "ERROR: Sparkle.framework is not embedded in $BUILT_APP/Contents/Frameworks"
    exit 1
fi
echo "✓ Verified Sparkle.framework embedded in bundle"

ZIP_FILENAME="${APP_NAME}-${VERSION}.zip"
ZIP_PATH="$RELEASES_DIR/$ZIP_FILENAME"

echo "2. Archiving application update to ZIP..."
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$BUILT_APP" "$ZIP_PATH"
ZIP_SIZE=$(stat -f%z "$ZIP_PATH")
echo "✓ Created update archive: $ZIP_PATH ($ZIP_SIZE bytes)"

echo "3. Signing archive with EdDSA (Keychain account: $ACCOUNT_NAME)..."
SIGN_BIN="$WORKSPACE_DIR/scripts/bin/sign_update"
if [ ! -x "$SIGN_BIN" ]; then
    echo "ERROR: $SIGN_BIN not found or not executable. Run setup first."
    exit 1
fi

SIGNATURE=$("$SIGN_BIN" --account "$ACCOUNT_NAME" -p "$ZIP_PATH")
echo "✓ EdDSA Signature: $SIGNATURE"

echo "4. Generating / Updating appcast.xml with generate_appcast..."
GEN_APPCAST="$WORKSPACE_DIR/scripts/bin/generate_appcast"
"$GEN_APPCAST" --account "$ACCOUNT_NAME" \
    --download-url-prefix "https://github.com/MdKasif0/ShiftKit/releases/download/v${VERSION}/" \
    --release-notes-url-prefix "https://raw.githubusercontent.com/MdKasif0/ShiftKit/main/updates/notes/" \
    -o "$UPDATES_DIR/appcast.xml" \
    "$RELEASES_DIR"

echo "✓ Appcast generated at: $UPDATES_DIR/appcast.xml"

echo "========================================================"
echo "✓ Sparkle 2 Update Package Ready!"
echo "Archive: $ZIP_PATH ($ZIP_SIZE bytes)"
echo "Signature: $SIGNATURE"
echo "Appcast: $UPDATES_DIR/appcast.xml"
echo "========================================================"

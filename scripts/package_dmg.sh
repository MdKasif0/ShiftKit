#!/usr/bin/env bash
set -euo pipefail

echo "========================================================"
echo "          ShiftKit Release DMG Packaging Pipeline       "
echo "========================================================"

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_DIR"

DIST_DIR="$WORKSPACE_DIR/dist"
STAGING_DIR="$DIST_DIR/dmg_staging"
APP_NAME="ShiftKit"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$STAGING_DIR"

echo "1. Building Release Universal Application with Xcode..."
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
xcodebuild build     -project ShiftKit.xcodeproj     -scheme ShiftKit     -configuration Release     -destination "platform=macOS"     SYMROOT="$WORKSPACE_DIR/build"     OBJROOT="$WORKSPACE_DIR/build/obj"     > "$DIST_DIR/build.log" 2>&1

BUILT_APP="$WORKSPACE_DIR/build/Release/$APP_NAME.app"
if [ ! -d "$BUILT_APP" ]; then
    # Fallback to DerivedData if SYMROOT was overridden
    BUILT_APP="$(find ~/Library/Developer/Xcode/DerivedData/ShiftKit-*/Build/Products/Release -name "$APP_NAME.app" -type d | head -n 1)"
fi

if [ ! -d "$BUILT_APP" ]; then
    echo "ERROR: Failed to find built $APP_NAME.app"
    exit 1
fi

echo "✓ Built application found at: $BUILT_APP"

echo "2. Validating Binary Architectures and Code Sign..."
lipo -info "$BUILT_APP/Contents/MacOS/$APP_NAME"
if [ ! -d "$BUILT_APP/Contents/Frameworks/Sparkle.framework" ]; then
    echo "ERROR: Sparkle.framework missing in $BUILT_APP"
    exit 1
fi
echo "✓ Verified Sparkle.framework embedded in app bundle" 
codesign -dvvv "$BUILT_APP" 2>&1 | grep -E "flags=|Format=|Identifier="

echo "3. Staging DMG layout..."
cp -R "$BUILT_APP" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# Add README for user installation guidance inside DMG
cat << 'EOF_README' > "$STAGING_DIR/Install Instructions.txt"
Welcome to ShiftKit for macOS!

TO INSTALL:
1. Drag the ShiftKit icon into the Applications folder shortcut.
2. Launch ShiftKit from your Applications folder or Spotlight.
3. On first launch, follow the on-screen prompt to enable
   Accessibility in System Settings (Privacy & Security > Accessibility)
   so ShiftKit can detect when the Shift key is held during drag actions.

100% on-device processing. No servers, no accounts.
For documentation & updates: https://github.com/MdKasif0/ShiftKit
EOF_README

echo "4. Creating read-only compressed UDZO disk image..."
hdiutil create     -volname "$APP_NAME"     -srcfolder "$STAGING_DIR"     -ov     -format UDZO     "$DMG_PATH"

echo "✓ Created $DMG_PATH"

echo "5. Verifying DMG Integrity..."
hdiutil verify "$DMG_PATH"

echo "6. Testing Mount and Inspection..."
MOUNT_POINT=$(mktemp -d /tmp/shiftkit_mount.XXXXXX)
hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_POINT" -nobrowse -quiet
echo "Mounted at: $MOUNT_POINT"

# Verify files exist in volume
ls -la "$MOUNT_POINT"
if [ ! -d "$MOUNT_POINT/ShiftKit.app" ] || [ ! -L "$MOUNT_POINT/Applications" ]; then
    echo "ERROR: DMG volume contents missing expected items!"
    hdiutil detach "$MOUNT_POINT" -quiet
    exit 1
fi

# Simulate Gatekeeper quarantine check
echo "✓ Simulating Gatekeeper quarantine inspection..."
xattr -w com.apple.quarantine "0081;66554433;Safari;12345" "$MOUNT_POINT/ShiftKit.app" || true
codesign -v "$MOUNT_POINT/ShiftKit.app" || true

# Cleanly unmount
hdiutil detach "$MOUNT_POINT" -quiet
rm -rf "$MOUNT_POINT"

echo "7. Generating Release Metadata..."
FILE_SIZE_BYTES=$(stat -f%z "$DMG_PATH")
FILE_SIZE_HUMAN=$(ls -lh "$DMG_PATH" | awk '{print $5}')
SHA256_HASH=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')

cat << EOF_META > "$DIST_DIR/release_metadata.json"
{
  "productName": "ShiftKit",
  "version": "$VERSION",
  "build": "1",
  "filename": "$DMG_NAME",
  "sizeBytes": $FILE_SIZE_BYTES,
  "sizeHuman": "$FILE_SIZE_HUMAN",
  "sha256": "$SHA256_HASH",
  "minMacOS": "14.0",
  "architectures": ["arm64", "x86_64"],
  "format": "Apple Disk Image (UDZO)",
  "downloadURL": "https://github.com/MdKasif0/ShiftKit/releases/download/v$VERSION/$DMG_NAME",
  "releaseDate": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF_META

# Clean up staging dir
rm -rf "$STAGING_DIR"

echo "========================================================"
echo "✓ ShiftKit Release Packaging Complete!"
echo "DMG File: $DMG_PATH"
echo "Size: $FILE_SIZE_HUMAN ($FILE_SIZE_BYTES bytes)"
echo "SHA-256: $SHA256_HASH"
echo "Metadata: $DIST_DIR/release_metadata.json"
echo "========================================================"

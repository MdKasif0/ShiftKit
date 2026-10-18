# Code Signing and Notarization Guide for ShiftKit

This document outlines the exact Apple Developer ID signing, Hardened Runtime configuration, and notarization workflows required for distributing ShiftKit outside the Mac App Store.

---

## 1. Current Signing Status

In the local development environment:
- **Build Configuration**: Release Universal Binary (`x86_64` + `arm64`).
- **Hardened Runtime**: Enabled (`-o runtime`, flags `0x10002`).
- **Entitlements**: `ShiftKit.entitlements` applied.
- **Current Signature**: Signed ad-hoc (`"-"`) because no active **Developer ID Application** certificate is currently installed in the developer Keychain.

> **Important**: Ad-hoc signed binaries will trigger macOS Gatekeeper alerts on other users' Macs. To distribute publicly, follow the steps below with an active Apple Developer Program account.

---

## 2. Requirements

1. An active Apple Developer Program membership ($99/yr).
2. A **Developer ID Application** certificate installed in Keychain Access.
3. An App Store Connect API Key or an App-Specific Password stored in the macOS Keychain.

---

## 3. Step-by-Step Signing Procedure

### Step 3.1: Locate your Signing Identity
```bash
security find-identity -v -p codesigning
# Example output:
# 1) ABC123XYZ "Developer ID Application: Your Name / Organization (TEAMID123)"
```

### Step 3.2: Sign the Application Bundle
Sign the helper binaries and the main app bundle with the hardened runtime and timestamp:

```bash
# 1. Sign helper binaries inside the bundle (if any)
codesign --force --timestamp --options runtime \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  build/Release/ShiftKit.app/Contents/Resources/bin/*

# 2. Sign the main application bundle with entitlements
codesign --force --timestamp --options runtime \
  --entitlements ShiftKit/Resources/ShiftKit.entitlements \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  build/Release/ShiftKit.app

# 3. Verify the signature
codesign --verify --deep --strict --verbose=2 build/Release/ShiftKit.app
spctl --assess --type execute --verbose build/Release/ShiftKit.app
```

---

## 4. Packaging and Signing the DMG

Once the app bundle is signed, package the DMG and sign the disk image itself:

```bash
# 1. Create the DMG
./scripts/package_dmg.sh

# 2. Sign the DMG
codesign --force --timestamp \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  dist/ShiftKit-1.0.0.dmg
```

---

## 5. Apple Notarization Workflow (`notarytool`)

Apple's current notarization service uses `notarytool`:

### Step 5.1: Store Notarization Credentials
```bash
xcrun notarytool store-credentials "ShiftKit-Notarization" \
  --apple-id "your-apple-id@example.com" \
  --team-id "TEAMID123" \
  --password "xxxx-xxxx-xxxx-xxxx" # App-specific password from appleid.apple.com
```

### Step 5.2: Submit for Notarization
```bash
xcrun notarytool submit dist/ShiftKit-1.0.0.dmg \
  --keychain-profile "ShiftKit-Notarization" \
  --wait
```

### Step 5.3: Staple the Notarization Ticket
Once notarization succeeds, staple the ticket to the DMG so it can be verified offline by macOS Gatekeeper:

```bash
xcrun stapler staple dist/ShiftKit-1.0.0.dmg

# Validate stapling
xcrun stapler validate dist/ShiftKit-1.0.0.dmg
spctl --assess --type open --context context:primary-signature --verbose dist/ShiftKit-1.0.0.dmg
```

---

## 6. Official Apple References

- [Notarizing macOS Software Before Distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Packaging Mac Software for Distribution](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution)
- [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime)

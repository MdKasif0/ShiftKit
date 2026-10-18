# ShiftKit Automatic Updates Architecture & Release Guide (Sparkle 2)

ShiftKit incorporates **Sparkle 2** (v2.9.6) to deliver cryptographic, background, and user-initiated software updates without requiring users to manually download and reinstall the application.

---

## 1. Sparkle 2 Integration Overview

### Technology Stack
- **Framework**: Sparkle 2 (`v2.9.6`)
- **Package Manager**: Swift Package Manager via XcodeGen (`project.yml`)
- **Controller Architecture**: `SPUStandardUpdaterController` with custom `SparkleUpdaterDelegate`
- **SwiftUI Interface**: Reactive `@Observable @MainActor` state management via `UpdateManager`
- **Signature Mechanism**: 256-bit EdDSA (`ed25519`) cryptographic signatures

### Component Architecture
```
ShiftKit/
  Updates/
    UpdateManager.swift          # MainActor manager controlling update lifecycle & state
    UpdateState.swift            # Enum tracking idle, checking, available, upToDate, error
    SparkleUpdaterDelegate.swift # SPUUpdaterDelegate bridging Sparkle callbacks to UpdateManager
    UpdateSettingsView.swift     # SwiftUI Settings tab adhering to ShiftKit design system
    UpdateStatusView.swift       # Visual indicator with badge & timestamps
```

---

## 2. Cryptographic Security & EdDSA Key Management

Sparkle 2 uses 256-bit EdDSA (`ed25519`) keys rather than legacy RSA/DSA signatures.

### Key Pair Generation
The keypair for ShiftKit was generated using Sparkle’s official `generate_keys` tool:
```bash
./scripts/bin/generate_keys --account shiftkit_updates
```

- **Public Key (`SUPublicEDKey`)**:
  ```text
  rn9Fy9EOgEMZXt8FA0H6v7hLuQzgaAcjPsukDFkle9I=
  ```
  This 32-byte base64-encoded public key is embedded in `ShiftKit/Resources/Info.plist` and `project.yml`. It is safe to be distributed publicly inside the compiled application bundle.

- **Private Key**:
  The private signing key is stored in the developer’s local macOS Keychain under the item **"Private key for signing Sparkle updates"** (account: `shiftkit_updates`).
  
  > [!CAUTION]
  > **Strict Security Rules:**
  > - NEVER commit the private key to git.
  > - NEVER embed the private key in the application bundle or DMG.
  > - NEVER upload the private key to a public web server or unencrypted CI pipeline.
  > - Backup your private key to an encrypted offline storage drive using:
  >   ```bash
  >   ./scripts/bin/generate_keys --account shiftkit_updates -x ~/Desktop/ShiftKit_ed25519_backup.key
  >   ```

---

## 3. Feed URL Configuration (`SUFeedURL`)

The application queries an HTTPS-hosted RSS appcast feed to discover updates.

### Configured Feed
In `ShiftKit/Resources/Info.plist` and `project.yml`:
```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/MdKasif0/ShiftKit/main/updates/appcast.xml</string>
```

### Production Domain Configuration
If you migrate to a dedicated domain or static CDN bucket (e.g. `https://updates.shiftkit.app/appcast.xml`):
1. Update `SUFeedURL` in `project.yml` under `info.properties`.
2. Update `SUFeedURL` in `ShiftKit/Resources/Info.plist`.
3. Update `scripts/package_update.sh` with the new download prefix.
4. Regenerate the project: `xcodegen generate`.

---

## 4. Release vs. In-App Update Workflow

ShiftKit maintains two parallel distribution channels:

| Distribution Channel | Target Audience | File Format | Delivery Mechanism |
| :--- | :--- | :--- | :--- |
| **New Installs** | New users / Fresh machines | `.dmg` (Disk Image) | Website download button (`/dist/ShiftKit-1.0.0.dmg`) |
| **In-App Updates** | Existing users with app installed | `.zip` (Compressed bundle) | Sparkle 2 background/manual check (`/updates/releases/*.zip`) |

> [!IMPORTANT]
> Sparkle in-app updates must be packaged as `.zip` or `.tar.xz` archives containing `ShiftKit.app`. Do not feed a `.dmg` file to Sparkle for in-app updates.

---

## 5. Automated Step-by-Step Release Workflow

ShiftKit provides an automated script [`scripts/package_update.sh`](../scripts/package_update.sh) to build, archive, sign, and update the appcast feed.

### Step 1: Increment Version Numbers
In `project.yml`:
```yaml
settings:
  base:
    MARKETING_VERSION: "1.0.1"   # User-facing version (CFBundleShortVersionString)
    CURRENT_PROJECT_VERSION: "2" # Monotonically increasing build integer (CFBundleVersion)
```
Regenerate project:
```bash
xcodegen generate
```

### Step 2: Write Release Notes
Create an HTML file named with the marketing version:
`updates/notes/1.0.1.html`
```html
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>ShiftKit 1.0.1</title></head>
<body>
  <h2>What’s New in 1.0.1</h2>
  <ul>
    <li>Performance improvements for 4K video trimming.</li>
    <li>Added keyboard shortcuts in image crop view.</li>
  </ul>
</body>
</html>
```

### Step 3: Run the Packaging Script
```bash
chmod +x scripts/package_update.sh
./scripts/package_update.sh
```

This script will:
1. Compile the Release Universal Mach-O binary (`x86_64` + `arm64`).
2. Verify that `Sparkle.framework` and its helper tools are embedded and codesigned.
3. Archive `ShiftKit.app` into `updates/releases/ShiftKit-1.0.1.zip` using `ditto`.
4. Sign the archive using the Keychain EdDSA key with `scripts/bin/sign_update`.
5. Update `updates/appcast.xml` using `scripts/bin/generate_appcast`.

### Step 4: Run the DMG Packaging Script (For New Users)
```bash
chmod +x scripts/package_dmg.sh
./scripts/package_dmg.sh
```

### Step 5: Publish the Release
1. Commit and push the updated `updates/appcast.xml` and `updates/notes/` to GitHub.
2. Create a GitHub Release tagged `v1.0.1` at `https://github.com/MdKasif0/ShiftKit/releases/new`.
3. Upload `updates/releases/ShiftKit-1.0.1.zip` and `dist/ShiftKit-1.0.1.dmg` to the release assets.

---

## 6. Testing Updates Locally

To test that Sparkle detects and installs an update before publishing:

### Scenario A: Testing Update Detection
1. Build an app with `CURRENT_PROJECT_VERSION = "1"`.
2. Generate an update archive with `CURRENT_PROJECT_VERSION = "2"`.
3. Host `appcast.xml` and `ShiftKit-1.0.1.zip` on a local HTTP test server:
   ```bash
   cd updates && python3 -m http.server 8000
   ```
4. Point `SUFeedURL` to `http://localhost:8000/appcast.xml` (temporarily in debug).
5. Launch ShiftKit and click **Check for Updates** in Settings > Updates.
6. Verify that Sparkle presents the update window showing release notes and the "Install and Relaunch" button.

### Scenario B: Testing Signature Rejection
1. Modify a byte inside `ShiftKit-1.0.1.zip` after signing.
2. Trigger update check.
3. Verify that Sparkle aborts with a signature verification failure and does NOT extract or run the modified archive.

---

## 7. Key Rotation & Disaster Recovery

### Key Rotation Procedure
If your private key is ever compromised or needs rotation:
1. Generate a new keypair:
   ```bash
   ./scripts/bin/generate_keys --account shiftkit_updates_v2
   ```
2. Ship an intermediate release (e.g. `1.1.0`) containing both the old and new public keys using Sparkle’s multi-key transition support.
3. Sign subsequent updates with the new key.

### Recovery from a Broken Release
If an update introduces a critical bug:
1. Increment the build number (e.g. `1.0.2` / build `3`).
2. Revert the problematic code.
3. Build and package the update with `./scripts/package_update.sh`.
4. Run `generate_appcast` with `--critical-update-version 1.0.1` so that Sparkle immediately flags the hotfix as critical to affected users.

---

## 8. Requirements for Developer ID Signing & Notarization

When distributing outside the Mac App Store:
1. **Apple Developer Account**: Requires paid enrollment ($99/year).
2. **Developer ID Application Certificate**:
   ```bash
   security find-identity -v -p codesigning
   # Must list: "Developer ID Application: Your Name (TEAM_ID)"
   ```
3. **Hardened Runtime**: Already enabled in `project.yml` (`ENABLE_HARDENED_RUNTIME: "YES"`).
4. **Notarization Workflow**:
   ```bash
   xcrun notarytool submit updates/releases/ShiftKit-1.0.1.zip \
     --keychain-profile "AC_PASSWORD" \
     --wait
   ```
5. In the current local developer environment where Developer ID certificates are not yet imported, ShiftKit is signed with ad-hoc signatures (`"-"`) and tested locally.

# Building and Packaging ShiftKit

This guide details the procedure for compiling ShiftKit from source and generating a distribution DMG.

---

## 1. Prerequisites

1. **macOS 14.0 Sonoma** or later.
2. **Xcode 15 or 16** installed at `/Applications/Xcode.app`.
3. **Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   ```
4. **XcodeGen**:
   ```bash
   brew install xcodegen
   ```
5. **Python 3 with Pillow** (for compiling multi-resolution icons):
   ```bash
   pip3 install pillow
   ```

---

## 2. Generating the Xcode Project

ShiftKit uses `project.yml` with XcodeGen to ensure clean, git-conflict-free project files:

```bash
cd /path/to/ShiftKit
xcodegen generate
```

---

## 3. Compiling the Application

### Debug Build (for testing)
```bash
xcodebuild build   -project ShiftKit.xcodeproj   -scheme ShiftKit   -configuration Debug   -destination "platform=macOS"
```

### Release Build (Universal: Apple Silicon & Intel)
```bash
xcodebuild build   -project ShiftKit.xcodeproj   -scheme ShiftKit   -configuration Release   -destination "platform=macOS"
```

The compiled release binary is placed in:
`build/Release/ShiftKit.app`

---

## 4. Running the Test Suite

Execute the full suite of 150+ unit and integration tests:

```bash
xcodebuild test   -project ShiftKit.xcodeproj   -scheme ShiftKit   -destination "platform=macOS"
```

---

## 5. Automated DMG Packaging

Run the automated release packaging script:

```bash
chmod +x scripts/package_dmg.sh
./scripts/package_dmg.sh
```

### Packaging Steps Performed:
1. Compiles `ShiftKit.app` with Release optimizations.
2. Verifies Universal binary architectures (`x86_64` and `arm64`).
3. Embeds `AppIcon.icns`.
4. Creates a read-only compressed disk image `dist/ShiftKit-1.0.0.dmg`.
5. Verifies CRC32 checksums.
6. Mounts and inspects the DMG structure with `/Applications` shortcut.
7. Produces `dist/release_metadata.json` with SHA-256 hash.

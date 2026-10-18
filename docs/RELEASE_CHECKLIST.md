# ShiftKit Release Checklist & Versioning Instructions

Follow this checklist before tagging and publishing any public release of ShiftKit.

---

## 1. Pre-Flight Verification

- [ ] **Run All Unit & Integration Tests**:
  ```bash
  xcodebuild test -project ShiftKit.xcodeproj -scheme ShiftKit -destination "platform=macOS"
  ```
  Ensure 150+ tests pass with 0 unexpected failures.

- [ ] **Verify No Placeholder Code or Fake Functionality**:
  - All radial actions map to working implementations.
  - Features requiring external engines (e.g. LibreOffice or FFmpeg) verify availability before presenting buttons.

- [ ] **Audit Privacy & Security**:
  - Confirm zero network communication (`grep -rn "URLSession" ShiftKit/`).
  - Confirm temporary files are cleaned up upon completion or cancellation.

- [ ] **Check Palette Compliance**:
  - Colors strictly adhere to warm palette (`#FAF8F3`, `#F3EEE4`, `#FFFFFF`, `#A8B5A0`, `#465343`, `#D98768`, `#F5D5C2`, `#E5D8C7`, `#34312D`).
  - Zero purple and zero blue.

---

## 2. Versioning Instructions

1. Open `project.yml`.
2. Update:
   - `MARKETING_VERSION`: e.g. `"1.1.0"`
   - `CURRENT_PROJECT_VERSION`: e.g. `"2"`
3. Regenerate the project:
   ```bash
   xcodegen generate
   ```
4. Update `website/src/components/DownloadSection.tsx` and `website/src/components/Navbar.tsx` version displays.

---

## 3. Packaging the Release DMG

```bash
chmod +x scripts/package_dmg.sh
./scripts/package_dmg.sh
```

- [ ] Confirm `dist/ShiftKit-X.Y.Z.dmg` is generated.
- [ ] Inspect `dist/release_metadata.json` for file size and SHA-256 hash.
- [ ] Mount and test dragging `ShiftKit.app` to `/Applications`.

---

## 4. Code Signing & Notarization (When Developer ID Available)

- [ ] Sign helper binaries and application bundle with Developer ID certificate.
- [ ] Sign the DMG image with hardened runtime.
- [ ] Submit to Apple Notary Service (`xcrun notarytool submit ...`).
- [ ] Staple the ticket (`xcrun stapler staple dist/ShiftKit-X.Y.Z.dmg`).

---

## 5. Publishing & Website Deployment

1. Create a GitHub Release with tag `vX.Y.Z` and attach `dist/ShiftKit-X.Y.Z.dmg`.
2. Copy the direct release asset URL.
3. In `website/.env.local` (or hosting environment variables):
   ```bash
   NEXT_PUBLIC_SHIFTKIT_DMG_URL="https://github.com/MdKasif0/ShiftKit/releases/download/vX.Y.Z/ShiftKit-X.Y.Z.dmg"
   ```
4. Deploy the website:
   ```bash
   cd website && npm run build
   ```
5. Test downloading the DMG directly from the live website.

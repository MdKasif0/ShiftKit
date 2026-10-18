# ShiftKit Troubleshooting & Known Limitations

This guide addresses common questions, operational edge-cases, and known platform limitations.

---

## 1. Troubleshooting Common Issues

### Issue 1: Shift+Drag does not summon the radial menu
- **Cause**: macOS Accessibility permissions are disabled or outdated.
- **Solution**:
  1. Open **System Settings > Privacy & Security > Accessibility**.
  2. Toggle **ShiftKit** off and then back on.
  3. Alternatively, use the global fallback shortcut **⌥⇧S** (Option+Shift+S) to summon the floating drop target directly at your cursor.

### Issue 2: "Developer Cannot Be Verified" warning
- **Cause**: ShiftKit is currently distributed with an ad-hoc or self-signed developer signature prior to commercial notarization.
- **Solution**:
  1. Locate `ShiftKit.app` in your `/Applications` folder.
  2. **Right-click** (or Control-click) the application icon and select **Open**.
  3. Click **Open** in the confirmation dialog. You only need to perform this step once.

### Issue 3: Video/Audio operations report "Engine Not Available"
- **Cause**: An advanced audio/video codec (e.g. WebM, FLAC, OGG) requires the local FFmpeg helper binary, but FFmpeg is not installed on your system.
- **Solution**:
  - Native formats (MP4, MOV, M4A) work out of the box via Apple's native AVFoundation engine.
  - For universal open formats, install FFmpeg via Homebrew:
    ```bash
    brew install ffmpeg
    ```
    ShiftKit will automatically detect it at `/opt/homebrew/bin/ffmpeg` or `/usr/local/bin/ffmpeg`.

### Issue 4: Insufficient Disk Space error during large batch conversion
- **Cause**: ShiftKit enforces strict pre-flight disk space safety checks. It requires at least 2.5× the input file size available on your target volume to prevent data truncation.
- **Solution**:
  - Free up storage on your primary volume.
  - Open **ShiftKit Settings > Privacy** and click **Purge Temporary Files** to clean up any orphaned cache artifacts.

---

## 2. Known Platform Limitations

1. **Sandboxed Drag Sessions from Finder**:
   - macOS security architecture does not allow a third-party application to intercept an in-progress Finder drag session without user interaction. ShiftKit respects this sandbox boundary by observing modifier keys and presenting a floating radial target at the cursor.

2. **Video Merging Stream Constraints**:
   - Joining multiple video clips into a single file requires identical video codecs, aspect ratios, and audio sampling rates for stream-copy operations. If clips differ, ShiftKit flags the mismatch and suggests converting them to matching MP4 profiles first.

3. **Lossless vs Lossy Conversions**:
   - Converting a lossy JPEG into a lossless PNG container cannot mathematically recover high-frequency detail discarded during original JPEG compression. ShiftKit marks such operations with an explicit container fidelity warning in the UI.

4. **Multi-Display Virtual Desktop Boundaries**:
   - On setups with multiple monitors having differing display scaling or menu bar arrangements, AppKit uses flipped coordinate systems. ShiftKit dynamically converts cursor positions relative to `NSScreen.screens` to position the radial HUD accurately on the active display.

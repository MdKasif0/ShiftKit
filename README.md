# ShiftKit

<p align="center">
  <strong>Every file. One gesture.</strong><br>
  A local-first circular radial utility for macOS.
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/MdKasif0/ShiftKit/main/website/public/favicon.svg" width="96" height="96" alt="ShiftKit Logo" />
</p>

<p align="center">
  <a href="#key-features">Features</a> •
  <a href="#signature-interaction">Interaction</a> •
  <a href="#system-requirements">Requirements</a> •
  <a href="#building-from-source">Build</a> •
  <a href="#packaging-dmg">DMG Packaging</a> •
  <a href="#privacy-guarantee">Privacy</a> •
  <a href="#license">License</a>
</p>

---

## What is ShiftKit?

**ShiftKit** is a native macOS application that allows you to convert, compress, crop, trim, merge, and edit files through a circular radial action menu. 

Every transformation executes **100% on-device** using native Apple system frameworks (`ImageIO`, `CoreGraphics`, `PDFKit`, `AVFoundation`) and local media engines. **Your files never leave your Mac.**

---

## Signature Interaction

1. **Select** one or more files in Finder.
2. **Hold Shift** and begin dragging the file.
3. The **ShiftKit circular action menu** blooms at your cursor.
4. **Choose an action** (Convert, Compress, Crop, Trim, Merge, or Metadata).
5. The result is verified and saved locally beside your original or to a designated folder.

---

## Key Features

### 🖼️ Universal Image Conversion
- High-performance conversions between **WebP, PNG, JPEG, HEIC, TIFF, BMP, GIF, and AVIF**.
- Hardware-accelerated encoding on Apple Silicon.
- Dedicated **Visual Crop Studio** with presets (1:1 Square, 4:3 Document, 16:9 Widescreen, Freeform) and live pixel dimensions.

### 🎬 Video & Audio Processing
- Frame-accurate video and audio trimming with interactive waveforms and keyframe snapping.
- Transcoding between **MP4, MOV, WebM, MP3, AAC, WAV, and M4A**.
- Audio track extraction from video files in one gesture.

### 📄 PDF & Document Studio
- Multi-file PDF merging and page reordering.
- Convert loose images into single or multi-page PDF documents.
- Split documents, extract selected page ranges, rotate orientations, and export high-DPI raster images.
- Smart PDF compression reducing file size while preserving readability.

### 🛡️ Privacy & Metadata Scrubbing
- Strip camera EXIF, GPS geolocation tags, lens models, and timestamps from photos.
- Clean author, creation date, and software metadata from PDF documents.
- Remove ID3 metadata tags from audio recordings before sharing.

### ⚡ Batch Queue & Concurrency Management
- Drop dozens of files simultaneously.
- Dynamic concurrency throttling (1–8 parallel workers) preventing thermal throttling or system memory pressure.
- Per-file progress bars, pause/resume queue controls, and single-click retry for failed items.

---

## System Requirements

| Requirement | Specification |
| :--- | :--- |
| **Operating System** | macOS 14.0 (Sonoma) or macOS 15 (Sequoia) |
| **Architecture** | Universal Binary (Apple Silicon M1/M2/M3/M4 & Intel 64-bit) |
| **Permissions** | macOS Accessibility (to detect Shift key during drag operations) |
| **Network** | 100% Offline (No conversion server required) |

---

## Building from Source

### Prerequisites
- macOS 14.0+ with Xcode 15 or 16 installed (`xcode-select --install`).
- `xcodegen` (`brew install xcodegen`).

### Build Instructions
```bash
# 1. Clone the repository
git clone https://github.com/MdKasif0/ShiftKit.git
cd ShiftKit

# 2. Generate the Xcode project
xcodegen generate

# 3. Build the Release application
xcodebuild build   -project ShiftKit.xcodeproj   -scheme ShiftKit   -configuration Release   -destination "platform=macOS"
```

The compiled application bundle will be created at `build/Release/ShiftKit.app`.

### Running Unit Tests
```bash
xcodebuild test   -project ShiftKit.xcodeproj   -scheme ShiftKit   -destination "platform=macOS"
```

---

## Packaging DMG

ShiftKit includes an automated, repeatable packaging script:

```bash
chmod +x scripts/package_dmg.sh
./scripts/package_dmg.sh
```

This pipeline will:
1. Build the Universal Release binary (`x86_64` + `arm64`) with Hardened Runtime enabled.
2. Compile and verify `AppIcon.icns`.
3. Stage the volume layout with the `/Applications` shortcut and installation instructions.
4. Create the compressed `dist/ShiftKit-1.0.0.dmg`.
5. Verify the disk image integrity and generate `dist/release_metadata.json` with SHA-256 checksums.

---

## Privacy Guarantee

- **No Remote Conversion Servers**: File contents are processed locally on your Mac.
- **Ephemeral Storage**: Intermediate working files are placed in your user cache directory and purged immediately upon completion.
- **Local-Only History**: Operational logs (filenames, timestamps, sizes) are stored in `~/Library/Application Support/com.shiftkit.mac/history.json` and can be wiped with one click.
- **Zero Telemetry**: No third-party analytics SDKs, trackers, or behavioral profiling.

---

## Documentation

- [User Installation & Permissions Guide](docs/USER_INSTALLATION_GUIDE.md)
- [Code Signing & Notarization Guide](docs/CODE_SIGNING_AND_NOTARIZATION.md)
- [Third-Party Licenses & Dependency Notices](THIRD_PARTY_LICENSES.md)
- [Troubleshooting & Known Limitations](docs/TROUBLESHOOTING.md)

---

## License

ShiftKit is distributed under the [MIT License](LICENSE). Third-party dependencies are acknowledged in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

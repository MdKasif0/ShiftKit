# ShiftKit User Installation & Getting Started Guide

Welcome to ShiftKit! This guide walks you through installing, configuring permissions, and using ShiftKit on macOS.

---

## 1. Installation

1. Download **ShiftKit-1.0.0.dmg** from the official release page or website.
2. Double-click the `.dmg` file to open it in Finder.
3. Drag the **ShiftKit** icon into the **Applications** folder shortcut.
4. Eject the disk image and open **Applications** in Finder.

---

## 2. First Launch & Security Permissions

### macOS Gatekeeper
If macOS indicates that the developer cannot be verified on unsigned development builds:
1. In Finder, open your **Applications** folder.
2. **Right-click** (or Control-click) on `ShiftKit.app` and choose **Open**.
3. In the confirmation dialog, click **Open**.
*(Note: Once notarized with an official Apple Developer ID certificate, this dialog will be replaced with a standard notarization verification).*

---

## 3. Configuring Accessibility Permissions

ShiftKit needs **Accessibility permissions** to monitor when the physical **Shift** key is pressed while you drag a file:

1. When ShiftKit launches, it will display the **Interaction Explainer** modal.
2. Click **Open System Settings**.
3. In macOS System Settings, navigate to **Privacy & Security > Accessibility**.
4. Enable the toggle next to **ShiftKit**.
5. Return to ShiftKit. Global Shift+Drag detection is now active!

---

## 4. How to Use ShiftKit

### Method A: The Signature Shift+Drag Gesture
1. In Finder or on your Desktop, select any supported file (e.g., photo, video, PDF).
2. **Hold the Shift key** on your keyboard.
3. **Click and drag** the file.
4. The circular action menu will bloom at your cursor.
5. Move your pointer over the desired action (e.g. `To WebP`, `Compress`, `Crop`) and release.

### Method B: Floating Target (Accessibility Fallback)
If Accessibility permissions are not granted:
1. Press the global shortcut **⌥⇧S** (Option+Shift+S) or click **Summon Drop Target** in the menu bar.
2. A small, elegant drop target appears at your cursor.
3. Drop any file onto it to reveal the radial action menu.

### Method C: Menu Bar
Click the ShiftKit icon in your macOS menu bar to:
- Open Recent Operations history
- Access the Job Queue dashboard
- Launch ShiftKit Settings

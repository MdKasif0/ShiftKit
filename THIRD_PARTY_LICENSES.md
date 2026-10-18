# Third-Party Licenses and Open Source Notices

ShiftKit incorporates or interfaces with open-source software libraries. This document provides mandatory license notices, build configuration details, and copyright attributions in compliance with each component's distribution requirements.

---

## 1. FFmpeg (Media Processing Engine)

- **Project**: FFmpeg (https://ffmpeg.org)
- **License**: GNU General Public License v3.0 (GPLv3) / GNU Lesser General Public License v2.1+ (LGPL)
- **Local Machine Configuration**:
  ```
  ffmpeg version 8.1.2 Copyright (c) 2000-2026 the FFmpeg developers
  built with Apple clang version 21.0.0 (clang-2100.0.123.102)
  configuration: --prefix=/opt/homebrew/Cellar/ffmpeg/8.1.2_1 --enable-shared --enable-pthreads --enable-version3 --cc=clang --enable-gpl --enable-libsvtav1 --enable-libopus --enable-libx264 --enable-libmp3lame --enable-libdav1d --enable-libvmaf --enable-libvpx --enable-libx265 --enable-openssl --enable-videotoolbox --enable-audiotoolbox --enable-neon
  ```

### Licensing & Distribution Requirements:
1. **Dynamic Execution via Subprocess**: ShiftKit invokes FFmpeg as an independent subprocess using `Process()` without linking against FFmpeg dynamic C libraries (`libavcodec.dylib`, `libavformat.dylib`).
2. **GPL vs. LGPL Notice**:
   - Because the local Homebrew build includes `--enable-gpl` (enabling `libx264` and `libx265`), redistribution of this specific executable binary falls under **GPLv3**.
   - If distributing ShiftKit commercially or within a closed-source package without providing the source code, an **LGPL-only static build** of FFmpeg (configured without `--enable-gpl` or using native Apple `VideoToolbox` H.264/HEVC hardware acceleration) must be bundled instead.
   - FFmpeg source code can be obtained at https://ffmpeg.org/download.html.

---

## 2. Google libwebp (cwebp & dwebp)

- **Project**: libwebp (https://chromium.googlesource.com/webm/libwebp)
- **Version**: 1.4.0
- **License**: 3-Clause BSD License
- **Copyright**: Copyright (c) 2010, Google Inc. All rights reserved.

### License Text:
```
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

  * Neither the name of Google nor the names of its contributors may
    be used to endorse or promote products derived from this software
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

---

## 3. Apple System Frameworks

The following frameworks are native components of macOS and are governed by Apple's Developer Agreement and macOS Software License:
- **ImageIO & Core Graphics**: Used for lossless raster transformations, EXIF extraction, and canvas geometry.
- **PDFKit**: Used for document vector rendering, page reordering, annotation manipulation, and page-to-image rasterization.
- **AVFoundation**: Used for hardware-accelerated ProRes, H.264, and HEVC video encoding and audio extraction.
- **AppKit & SwiftUI**: Used for windowing, event monitors (`CGEventTap`), and menu segment rendering.

---

## 4. Next.js and Web Front-End Dependencies

The ShiftKit marketing and distribution website (`website/`) utilizes:
- **Next.js**: MIT License, Copyright (c) Vercel, Inc.
- **React & React DOM**: MIT License, Copyright (c) Meta Platforms, Inc.
- **Tailwind CSS**: MIT License, Copyright (c) Tailwind Labs, Inc.
- **Lucide Icons**: ISC License, Copyright (c) Lucide Contributors.


---

## 5. Sparkle 2 (Automatic Software Update Framework)

- **Project**: Sparkle (https://sparkle-project.org)
- **Version**: 2.9.6
- **License**: MIT License
- **Copyright**: Copyright (c) 2006-2026 Andy Matuschak, Kornel Lesiński, Mayur Pawashe, Graham Miln, et al.

### License Text:
```
Copyright (c) 2006-2026 Andy Matuschak, Kornel Lesiński, Mayur Pawashe, Graham Miln, et al.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

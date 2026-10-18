import SwiftUI
import AppKit

// MARK: - Crop Editor View
public struct CropEditorView: View {
    public let file: InspectedFile
    public let onApply: (CGRect, ConversionOptions, OutputFormat) -> Void
    public let onCancel: () -> Void

    @State private var originalImage: NSImage?
    @State private var imagePixelSize: CGSize = .zero
    @State private var geometryEngine: CropGeometryEngine = CropGeometryEngine(imageSize: .zero)
    
    // Crop State
    @State private var selectedPreset: CropAspectRatioPreset = .free
    @State private var pixelCropRect: CGRect = .zero
    @State private var widthText: String = ""
    @State private var heightText: String = ""
    
    // Output Options
    @State private var targetFormat: OutputFormat = .png
    @State private var quality: Double = 0.85
    @State private var stripMetadata: Bool = false
    @State private var isLossless: Bool = false

    // Drag tracking
    @State private var activeHandle: CropHandle? = nil
    @State private var dragStartRect: CGRect = .zero

    public init(
        file: InspectedFile,
        onApply: @escaping (CGRect, ConversionOptions, OutputFormat) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.file = file
        self.onApply = onApply
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Header Bar
            headerBar

            Divider()
                .background(ShiftKitColors.border)

            // 2. Central Interactive Crop Canvas
            ZStack {
                ShiftKitColors.warmIvory
                    .ignoresSafeArea()

                if let nsImage = originalImage, imagePixelSize.width > 0 {
                    GeometryReader { proxy in
                        let canvasSize = proxy.size
                        let fitRect = calculateAspectFitRect(imageSize: imagePixelSize, in: canvasSize)

                        ZStack(alignment: .topLeading) {
                            // Base Canvas Background (Pure White card with subtle shadow)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ShiftKitColors.pureWhite)
                                .frame(width: fitRect.width, height: fitRect.height)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(ShiftKitColors.border, lineWidth: 1)
                                )
                                .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.08), radius: 8, x: 0, y: 4)

                            // Rendered Image
                            Image(nsImage: nsImage)
                                .resizable()
                                .interpolation(.high)
                                .frame(width: fitRect.width, height: fitRect.height)
                                .clipped()

                            // Interactive Scrim & Crop Box Overlay
                            cropOverlay(in: fitRect)
                        }
                        .position(x: canvasSize.width / 2.0, y: canvasSize.height / 2.0)
                    }
                    .padding(24)
                } else {
                    ProgressView()
                        .tint(ShiftKitColors.deepOlive)
                }
            }

            Divider()
                .background(ShiftKitColors.border)

            // 3. Bottom Control & Adjustment Bar
            bottomControlBar
        }
        .frame(minWidth: 840, minHeight: 620)
        .background(ShiftKitColors.warmIvory)
        .onAppear {
            loadImageData()
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "crop")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(ShiftKitColors.softTerracotta)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ShiftKitColors.textPrimary)

                HStack(spacing: 8) {
                    Text("\(Int(imagePixelSize.width)) × \(Int(imagePixelSize.height)) px")
                    Text("•")
                    Text(file.metadata.formattedSize)
                    if let uti = file.metadata.uti {
                        Text("•")
                        Text(uti)
                    }
                }
                .font(.system(size: 11))
                .foregroundColor(ShiftKitColors.textMuted)
            }

            Spacer()

            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ShiftKitColors.charcoalBrown.opacity(0.7))
                    .frame(width: 24, height: 24)
                    .background(ShiftKitColors.softCream)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(ShiftKitColors.pureWhite)
    }

    // MARK: - Crop Overlay
    @ViewBuilder
    private func cropOverlay(in fitRect: CGRect) -> some View {
        let viewScaleX = fitRect.width / imagePixelSize.width
        let viewScaleY = fitRect.height / imagePixelSize.height

        let boxX = pixelCropRect.origin.x * viewScaleX
        let boxY = pixelCropRect.origin.y * viewScaleY
        let boxW = pixelCropRect.width * viewScaleX
        let boxH = pixelCropRect.height * viewScaleY
        let displayCropRect = CGRect(x: boxX, y: boxY, width: boxW, height: boxH)

        ZStack(alignment: .topLeading) {
            // Darkened Dimming Mask (Everything outside crop box)
            Path { path in
                path.addRect(CGRect(origin: .zero, size: fitRect.size))
                path.addRect(displayCropRect)
            }
            .fill(ShiftKitColors.charcoalBrown.opacity(0.48), style: FillStyle(eoFill: true))

            // Selection Outline (Terracotta Border)
            Rectangle()
                .path(in: displayCropRect)
                .stroke(ShiftKitColors.softTerracotta, lineWidth: 2)

            // Rule of Thirds Grid Lines
            gridLines(in: displayCropRect)

            // Center Drag Hitbox
            Rectangle()
                .fill(Color.white.opacity(0.001)) // Invisible hit test area
                .frame(width: max(0, displayCropRect.width - 24), height: max(0, displayCropRect.height - 24))
                .position(x: displayCropRect.midX, y: displayCropRect.midY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if dragStartRect == .zero {
                                dragStartRect = pixelCropRect
                            }
                            let pixelDelta = CGPoint(
                                x: value.translation.width / viewScaleX,
                                y: value.translation.height / viewScaleY
                            )
                            pixelCropRect = geometryEngine.moveCropRect(dragStartRect, delta: pixelDelta)
                            updateDimensionFields()
                        }
                        .onEnded { _ in
                            dragStartRect = .zero
                        }
                )

            // 8 Interactive Handles
            handlesView(in: displayCropRect, viewScaleX: viewScaleX, viewScaleY: viewScaleY)
        }
    }

    // MARK: - Handles View
    @ViewBuilder
    private func handlesView(in box: CGRect, viewScaleX: CGFloat, viewScaleY: CGFloat) -> some View {
        let handleRadius: CGFloat = 7.0

        // Corner Handles
        cornerHandle(at: CGPoint(x: box.minX, y: box.minY), handle: .topLeft, viewScaleX: viewScaleX, viewScaleY: viewScaleY, radius: handleRadius)
        cornerHandle(at: CGPoint(x: box.maxX, y: box.minY), handle: .topRight, viewScaleX: viewScaleX, viewScaleY: viewScaleY, radius: handleRadius)
        cornerHandle(at: CGPoint(x: box.minX, y: box.maxY), handle: .bottomLeft, viewScaleX: viewScaleX, viewScaleY: viewScaleY, radius: handleRadius)
        cornerHandle(at: CGPoint(x: box.maxX, y: box.maxY), handle: .bottomRight, viewScaleX: viewScaleX, viewScaleY: viewScaleY, radius: handleRadius)

        // Edge Handles
        edgeHandle(at: CGPoint(x: box.midX, y: box.minY), handle: .top, isHorizontal: true, viewScaleX: viewScaleX, viewScaleY: viewScaleY)
        edgeHandle(at: CGPoint(x: box.midX, y: box.maxY), handle: .bottom, isHorizontal: true, viewScaleX: viewScaleX, viewScaleY: viewScaleY)
        edgeHandle(at: CGPoint(x: box.minX, y: box.midY), handle: .left, isHorizontal: false, viewScaleX: viewScaleX, viewScaleY: viewScaleY)
        edgeHandle(at: CGPoint(x: box.maxX, y: box.midY), handle: .right, isHorizontal: false, viewScaleX: viewScaleX, viewScaleY: viewScaleY)
    }

    @ViewBuilder
    private func cornerHandle(at point: CGPoint, handle: CropHandle, viewScaleX: CGFloat, viewScaleY: CGFloat, radius: CGFloat) -> some View {
        Circle()
            .fill(ShiftKitColors.softTerracotta)
            .frame(width: radius * 2, height: radius * 2)
            .overlay(
                Circle()
                    .stroke(ShiftKitColors.pureWhite, lineWidth: 2)
            )
            .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.2), radius: 2, x: 0, y: 1)
            .position(point)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if dragStartRect == .zero {
                            dragStartRect = pixelCropRect
                        }
                        let pixelDelta = CGPoint(
                            x: value.translation.width / viewScaleX,
                            y: value.translation.height / viewScaleY
                        )
                        pixelCropRect = geometryEngine.resizeCropRect(
                            dragStartRect,
                            handle: handle,
                            delta: pixelDelta,
                            preset: selectedPreset
                        )
                        updateDimensionFields()
                    }
                    .onEnded { _ in
                        dragStartRect = .zero
                    }
            )
    }

    @ViewBuilder
    private func edgeHandle(at point: CGPoint, handle: CropHandle, isHorizontal: Bool, viewScaleX: CGFloat, viewScaleY: CGFloat) -> some View {
        Capsule()
            .fill(ShiftKitColors.softTerracotta)
            .frame(width: isHorizontal ? 20 : 6, height: isHorizontal ? 6 : 20)
            .overlay(
                Capsule()
                    .stroke(ShiftKitColors.pureWhite, lineWidth: 1.5)
            )
            .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.15), radius: 2, x: 0, y: 1)
            .position(point)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if dragStartRect == .zero {
                            dragStartRect = pixelCropRect
                        }
                        let pixelDelta = CGPoint(
                            x: value.translation.width / viewScaleX,
                            y: value.translation.height / viewScaleY
                        )
                        pixelCropRect = geometryEngine.resizeCropRect(
                            dragStartRect,
                            handle: handle,
                            delta: pixelDelta,
                            preset: selectedPreset
                        )
                        updateDimensionFields()
                    }
                    .onEnded { _ in
                        dragStartRect = .zero
                    }
            )
    }

    @ViewBuilder
    private func gridLines(in box: CGRect) -> some View {
        Path { path in
            let col1 = box.minX + box.width / 3.0
            let col2 = box.minX + (box.width * 2.0) / 3.0
            let row1 = box.minY + box.height / 3.0
            let row2 = box.minY + (box.height * 2.0) / 3.0

            path.move(to: CGPoint(x: col1, y: box.minY))
            path.addLine(to: CGPoint(x: col1, y: box.maxY))

            path.move(to: CGPoint(x: col2, y: box.minY))
            path.addLine(to: CGPoint(x: col2, y: box.maxY))

            path.move(to: CGPoint(x: box.minX, y: row1))
            path.addLine(to: CGPoint(x: box.maxX, y: row1))

            path.move(to: CGPoint(x: box.minX, y: row2))
            path.addLine(to: CGPoint(x: box.maxX, y: row2))
        }
        .stroke(ShiftKitColors.pureWhite.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }

    // MARK: - Bottom Control Bar
    private var bottomControlBar: some View {
        VStack(spacing: 12) {
            // Row 1: Aspect Ratio Presets & Dimensions
            HStack(spacing: 16) {
                // Preset Buttons
                HStack(spacing: 4) {
                    ForEach(CropAspectRatioPreset.allCases) { preset in
                        let isSelected = selectedPreset == preset
                        Button {
                            selectedPreset = preset
                            pixelCropRect = geometryEngine.initialCropRect(for: preset)
                            updateDimensionFields()
                        } label: {
                            Text(preset.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(isSelected ? ShiftKitColors.softTerracotta : ShiftKitColors.softCream)
                                .foregroundColor(isSelected ? ShiftKitColors.pureWhite : ShiftKitColors.textPrimary)
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(ShiftKitColors.softCream)
                .cornerRadius(6)

                Spacer()

                // Dimensions (Width x Height) Inputs
                HStack(spacing: 6) {
                    TextField("W", text: $widthText)
                        .frame(width: 55)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                        .onSubmit { applyManualDimensions() }

                    Text("×")
                        .font(.system(size: 11))
                        .foregroundColor(ShiftKitColors.textMuted)

                    TextField("H", text: $heightText)
                        .frame(width: 55)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                        .onSubmit { applyManualDimensions() }

                    Text("px")
                        .font(.system(size: 11))
                        .foregroundColor(ShiftKitColors.textMuted)
                }

                // Reset Button
                Button {
                    selectedPreset = .free
                    pixelCropRect = geometryEngine.initialCropRect(for: .free)
                    updateDimensionFields()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ShiftKitColors.deepOlive)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(ShiftKitColors.softCream)
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }

            // Row 2: Format, Options & Actions
            HStack(spacing: 16) {
                // Target Format Picker
                HStack(spacing: 6) {
                    Text("Export as:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ShiftKitColors.textPrimary)

                    Picker("", selection: $targetFormat) {
                        Text("PNG (Lossless)").tag(OutputFormat.png)
                        Text("JPEG (Photo)").tag(OutputFormat.jpeg)
                        Text("WebP (Modern)").tag(OutputFormat.webp)
                        Text("HEIC (Apple)").tag(OutputFormat.heic)
                        Text("TIFF (Archival)").tag(OutputFormat.tiff)
                        Text("PDF Document").tag(OutputFormat.pdf)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }

                // Lossy Quality Slider if format is lossy
                if targetFormat == .jpeg || (targetFormat == .webp && !isLossless) || targetFormat == .heic {
                    HStack(spacing: 6) {
                        Text("Quality:")
                            .font(.system(size: 11))
                            .foregroundColor(ShiftKitColors.textPrimary)

                        Slider(value: $quality, in: 0.1...1.0, step: 0.05)
                            .frame(width: 80)
                            .tint(ShiftKitColors.softTerracotta)

                        Text("\(Int(quality * 100))%")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(ShiftKitColors.textMuted)
                            .frame(width: 32, alignment: .trailing)
                    }
                }

                // Strip EXIF / GPS Checkbox
                Toggle(isOn: $stripMetadata) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.slash")
                        Text("Strip GPS & EXIF")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(ShiftKitColors.textPrimary)
                }
                .toggleStyle(.checkbox)

                Spacer()

                // Cancel Button
                Button("Cancel") {
                    onCancel()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ShiftKitColors.charcoalBrown)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(ShiftKitColors.softCream)
                .cornerRadius(6)
                .buttonStyle(.plain)

                // Apply Crop Button
                Button {
                    let options = ConversionOptions(
                        quality: quality,
                        isLosslessPreferred: isLossless,
                        preserveAlpha: targetFormat.supportsAlpha,
                        stripMetadata: stripMetadata
                    )
                    onApply(pixelCropRect, options, targetFormat)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text("Apply Crop")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(ShiftKitColors.pureWhite)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(ShiftKitColors.softTerracotta)
                    .cornerRadius(6)
                    .shadow(color: ShiftKitColors.softTerracotta.opacity(0.35), radius: 3, x: 0, y: 1.5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(ShiftKitColors.pureWhite)
    }

    // MARK: - Internal Helpers
    private func loadImageData() {
        guard let nsImage = NSImage(contentsOf: file.url) else { return }
        self.originalImage = nsImage

        if let rep = nsImage.representations.first {
            self.imagePixelSize = CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        } else {
            self.imagePixelSize = nsImage.size
        }

        self.geometryEngine = CropGeometryEngine(imageSize: imagePixelSize)
        self.pixelCropRect = geometryEngine.initialCropRect(for: .free)

        // Set default target format based on file
        if let current = file.metadata.detectedFormat {
            self.targetFormat = current
        } else {
            self.targetFormat = .png
        }

        updateDimensionFields()
    }

    private func updateDimensionFields() {
        self.widthText = "\(Int(round(pixelCropRect.width)))"
        self.heightText = "\(Int(round(pixelCropRect.height)))"
    }

    private func applyManualDimensions() {
        guard let w = Double(widthText), let h = Double(heightText), w > 0, h > 0 else {
            updateDimensionFields()
            return
        }
        let requested = CGRect(x: pixelCropRect.origin.x, y: pixelCropRect.origin.y, width: CGFloat(w), height: CGFloat(h))
        self.pixelCropRect = geometryEngine.clampToImageBounds(requested)
        updateDimensionFields()
    }

    private func calculateAspectFitRect(imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
            return .zero
        }
        let widthRatio = containerSize.width / imageSize.width
        let heightRatio = containerSize.height / imageSize.height
        let scale = min(widthRatio, heightRatio)

        let fitWidth = imageSize.width * scale
        let fitHeight = imageSize.height * scale

        return CGRect(
            x: (containerSize.width - fitWidth) / 2.0,
            y: (containerSize.height - fitHeight) / 2.0,
            width: fitWidth,
            height: fitHeight
        )
    }
}

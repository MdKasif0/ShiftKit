import SwiftUI
import AppKit
import PDFKit
import AVFoundation

// MARK: - Reusable File Preview View
public struct FilePreviewView: View {
    public let file: InspectedFile
    public let size: CGFloat

    @State private var thumbnailImage: NSImage?
    @State private var isLoadingThumbnail: Bool = false

    public init(file: InspectedFile, size: CGFloat = 64) {
        self.file = file
        self.size = size
    }

    public var body: some View {
        ZStack {
            if let image = thumbnailImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(ShiftKitColors.sandBeige, lineWidth: 1)
                    )
                    .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.08), radius: 3, x: 0, y: 1)
                    .transition(.opacity.animation(.easeInOut(duration: 0.15)))
            } else {
                // Attractive native-style placeholder
                fallbackIconView
            }
        }
        .frame(width: size, height: size)
        .task(id: file.url) {
            await loadThumbnailAsync()
        }
    }

    // MARK: - Native-style Fallback Icon
    private var fallbackIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ShiftKitColors.softCream)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(ShiftKitColors.sandBeige, lineWidth: 1)
                )

            VStack(spacing: 3) {
                Image(systemName: file.fileType.systemIcon)
                    .font(.system(size: size * 0.36, weight: .medium))
                    .foregroundColor(ShiftKitColors.deepOlive)

                Text(file.metadata.fileExtension.uppercased())
                    .font(.system(size: max(8, size * 0.16), weight: .bold, design: .monospaced))
                    .foregroundColor(ShiftKitColors.charcoalBrown.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Thumbnail Loader
    private func loadThumbnailAsync() async {
        guard !isLoadingThumbnail else { return }
        isLoadingThumbnail = true
        defer { isLoadingThumbnail = false }

        let targetPixelSize = Int(size * 2) // Retina 2x

        let generatedImage: NSImage? = await Task.detached(priority: .userInitiated) { () -> NSImage? in
            let url = file.url
            let path = url.path
            guard FileManager.default.fileExists(atPath: path) else { return nil }

            switch file.fileType {
            case .image:
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: targetPixelSize,
                    kCGImageSourceCreateThumbnailWithTransform: true
                ]
                if let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                    return NSImage(cgImage: cgThumb, size: NSSize(width: size, height: size))
                }

            case .pdf:
                if let doc = PDFDocument(url: url), let page = doc.page(at: 0) {
                    return page.thumbnail(of: CGSize(width: size, height: size), for: .mediaBox)
                }

            case .video:
                let asset = AVURLAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: targetPixelSize, height: targetPixelSize)
                let time = CMTime(seconds: 1.0, preferredTimescale: 600)
                if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                    return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
                }

            default:
                break
            }

            return nil
        }.value

        if let generatedImage {
            withAnimation(.easeInOut(duration: 0.15)) {
                self.thumbnailImage = generatedImage
            }
        }
    }
}

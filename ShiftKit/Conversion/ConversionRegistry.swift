import Foundation

// MARK: - Protocol
public protocol ConversionRegistering: Sendable {
    func actions(for fileType: FileType) -> [ConversionAction]
    func defaultAction(for fileType: FileType) -> ConversionAction?
}

// MARK: - Implementation
public final class ConversionRegistry: ConversionRegistering {
    public init() {}

    public func actions(for fileType: FileType) -> [ConversionAction] {
        switch fileType {
        case .image(let sub):
            var list: [ConversionAction] = []
            switch sub {
            case .png:
                list.append(.imageToJPEG)
                list.append(.imageToWebP)
            case .jpeg:
                list.append(.imageToPNG)
                list.append(.imageToWebP)
            case .webp:
                list.append(.imageToPNG)
                list.append(.imageToJPEG)
            case .heic:
                list.append(.imageToJPEG)
                list.append(.imageToPNG)
            default:
                list.append(.imageToPNG)
                list.append(.imageToJPEG)
            }
            list.append(.imageCompress)
            list.append(.imageCropSquare)
            list.append(.imageStripMetadata)
            return list

        case .video:
            return [
                .videoToMP4,
                .videoToGIF,
                .videoExtractAudio,
                .videoCompress,
                .videoTrim
            ]

        case .audio:
            return [
                .audioToMP3,
                .audioToM4A,
                .audioCompress
            ]

        case .pdf:
            return [
                .pdfCompress,
                .pdfToImages,
                .pdfMerge
            ]

        case .document, .archive, .unknown:
            return [
                ConversionAction(
                    id: "inspect_meta",
                    title: "Inspect",
                    subtitle: "View detailed metadata",
                    systemIcon: "info.circle",
                    category: .utility
                )
            ]
        }
    }

    public func defaultAction(for fileType: FileType) -> ConversionAction? {
        actions(for: fileType).first
    }
}

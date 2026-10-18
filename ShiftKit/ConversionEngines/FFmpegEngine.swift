import Foundation

public final class FFmpegEngine: ConversionEngine {
    public let engineID = "com.shiftkit.engine.ffmpeg"
    public let engineName = "Dedicated Local FFmpeg"

    public init() {}

    /// Checks possible standard local installation locations for FFmpeg.
    public static func locateBinary(customPath: String? = nil) -> URL? {
        let fm = FileManager.default

        // 1. Check user custom path
        if let customPath, !customPath.isEmpty, fm.isExecutableFile(atPath: customPath) {
            return URL(fileURLWithPath: customPath)
        }

        // 2. Check bundled resources inside app bundle
        if let bundled = Bundle.main.url(forResource: "ffmpeg", withExtension: nil),
           fm.isExecutableFile(atPath: bundled.path) {
            return bundled
        }

        // 3. Check Apple Silicon Homebrew
        let armHomebrew = "/opt/homebrew/bin/ffmpeg"
        if fm.isExecutableFile(atPath: armHomebrew) {
            return URL(fileURLWithPath: armHomebrew)
        }

        // 4. Check Intel Homebrew / standard Unix paths
        let intelHomebrew = "/usr/local/bin/ffmpeg"
        if fm.isExecutableFile(atPath: intelHomebrew) {
            return URL(fileURLWithPath: intelHomebrew)
        }

        let usrBin = "/usr/bin/ffmpeg"
        if fm.isExecutableFile(atPath: usrBin) {
            return URL(fileURLWithPath: usrBin)
        }

        return nil
    }

    public static var isAvailable: Bool {
        locateBinary() != nil
    }

    public func canHandle(action: ConversionAction, fileType: FileType) -> Bool {
        switch fileType {
        case .video, .audio:
            // FFmpeg handles advanced media operations (GIF creation, MP3, WebM, MKV, etc.)
            return action.id == "vid_to_gif" || action.id == "audio_to_mp3" || action.targetFormat == "webm" || action.targetFormat == "gif"
        default:
            return false
        }
    }

    public func execute(
        request: ConversionRequest,
        outputURL: URL,
        progressHandler: @Sendable @escaping (Double, String) -> Void
    ) async throws -> URL {
        guard let binaryURL = Self.locateBinary() else {
            throw ShiftKitError.engineNotAvailable(
                engineName: "FFmpeg binary not found. Place ffmpeg in /opt/homebrew/bin/ffmpeg or app bundle."
            )
        }

        progressHandler(0.1, "Configuring local FFmpeg pipeline...")

        var arguments: [String] = [
            "-y", // overwrite output
            "-i", request.sourceURL.path
        ]

        // Build arguments based on action
        switch request.action.id {
        case "vid_to_gif":
            // High quality palettegen GIF pipeline
            arguments.append(contentsOf: [
                "-vf", "fps=15,scale=480:-1:flags=lanczos",
                "-c:v", "gif"
            ])

        case "audio_to_mp3":
            arguments.append(contentsOf: [
                "-vn",
                "-c:a", "libmp3lame",
                "-q:a", "2"
            ])

        default:
            if let targetFormat = request.action.targetFormat {
                arguments.append(contentsOf: ["-f", targetFormat])
            }
        }

        arguments.append(outputURL.path)

        progressHandler(0.3, "Executing local FFmpeg process...")

        let process = Process()
        process.executableURL = binaryURL
        process.arguments = arguments

        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = Pipe() // Silence stdout

        try process.run()

        // Wait for process completion in background
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    progressHandler(1.0, "FFmpeg processing completed")
                    continuation.resume(returning: outputURL)
                } else {
                    let errData = pipe.fileHandleForReading.readDataToEndOfFile()
                    let errMsg = String(data: errData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(
                        throwing: ShiftKitError.processExecutionFailed(
                            exitCode: process.terminationStatus,
                            message: errMsg.suffix(400).trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    )
                }
            }
        }
    }
}

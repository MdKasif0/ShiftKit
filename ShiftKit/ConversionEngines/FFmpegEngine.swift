import Foundation
import CoreGraphics
import AppKit

// MARK: - FFmpeg Version & Licensing Info
public struct FFmpegVersionInfo: Hashable, Sendable {
    public let version: String
    public let configuration: String
    public let licenseDescription: String
    public let isGPL: Bool
    public let isLGPL: Bool
    public let enabledLibraries: [String]

    public init(
        version: String,
        configuration: String,
        licenseDescription: String,
        isGPL: Bool,
        isLGPL: Bool,
        enabledLibraries: [String]
    ) {
        self.version = version
        self.configuration = configuration
        self.licenseDescription = licenseDescription
        self.isGPL = isGPL
        self.isLGPL = isLGPL
        self.enabledLibraries = enabledLibraries
    }
}

// MARK: - FFmpeg Build Capabilities
public struct FFmpegCapabilities: Hashable, Sendable {
    public let encoders: Set<String>
    public let decoders: Set<String>
    public let muxers: Set<String>
    public let demuxers: Set<String>
    public let filters: Set<String>
    public let hasVideoToolbox: Bool
    public let hasAudioToolbox: Bool

    public init(
        encoders: Set<String> = [],
        decoders: Set<String> = [],
        muxers: Set<String> = [],
        demuxers: Set<String> = [],
        filters: Set<String> = [],
        hasVideoToolbox: Bool = false,
        hasAudioToolbox: Bool = false
    ) {
        self.encoders = encoders
        self.decoders = decoders
        self.muxers = muxers
        self.demuxers = demuxers
        self.filters = filters
        self.hasVideoToolbox = hasVideoToolbox
        self.hasAudioToolbox = hasAudioToolbox
    }
}

// MARK: - FFmpeg Engine Abstraction
public final class FFmpegEngine: ConversionEngine, @unchecked Sendable {
    public let engineID = "com.shiftkit.engine.ffmpeg"
    public let engineName = "Dedicated Local FFmpeg"

    // Cache actor
    private actor Cache {
        static let shared = Cache()
        var capabilities: FFmpegCapabilities?
        var versionInfo: FFmpegVersionInfo?
        func getVersion() -> FFmpegVersionInfo? { versionInfo }
        func setVersion(_ info: FFmpegVersionInfo) { versionInfo = info }
        func getCapabilities() -> FFmpegCapabilities? { capabilities }
        func setCapabilities(_ caps: FFmpegCapabilities) { capabilities = caps }
    }

    public init() {}

    // MARK: - Binary Detection
    /// Checks possible standard local installation locations for FFmpeg.
    public static func locateBinary(customPath: String? = nil) -> URL? {
        let fm = FileManager.default

        if let customPath, !customPath.isEmpty, fm.isExecutableFile(atPath: customPath) {
            return URL(fileURLWithPath: customPath)
        }

        if let bundled = Bundle.main.url(forResource: "ffmpeg", withExtension: nil),
           fm.isExecutableFile(atPath: bundled.path) {
            return bundled
        }

        let armHomebrew = "/opt/homebrew/bin/ffmpeg"
        if fm.isExecutableFile(atPath: armHomebrew) {
            return URL(fileURLWithPath: armHomebrew)
        }

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

    /// Checks possible locations for ffprobe.
    public static func locateProbeBinary() -> URL? {
        let fm = FileManager.default
        if let bundled = Bundle.main.url(forResource: "ffprobe", withExtension: nil),
           fm.isExecutableFile(atPath: bundled.path) {
            return bundled
        }
        let armHomebrew = "/opt/homebrew/bin/ffprobe"
        if fm.isExecutableFile(atPath: armHomebrew) {
            return URL(fileURLWithPath: armHomebrew)
        }
        let intelHomebrew = "/usr/local/bin/ffprobe"
        if fm.isExecutableFile(atPath: intelHomebrew) {
            return URL(fileURLWithPath: intelHomebrew)
        }
        let usrBin = "/usr/bin/ffprobe"
        if fm.isExecutableFile(atPath: usrBin) {
            return URL(fileURLWithPath: usrBin)
        }
        return nil
    }

    public static var isAvailable: Bool {
        locateBinary() != nil
    }

    // MARK: - Version & Licensing Audit
    public static func queryVersionInfo() async throws -> FFmpegVersionInfo {
        if let cached = await Cache.shared.getVersion() {
            return cached
        }

        guard let binaryURL = locateBinary() else {
            throw ShiftKitError.engineNotAvailable(engineName: "FFmpeg binary not found")
        }

        let process = Process()
        process.executableURL = binaryURL
        process.arguments = ["-version"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        var version = "Unknown"
        var configuration = ""
        var isGPL = false
        var isLGPL = false
        var enabledLibs: [String] = []

        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("ffmpeg version") {
                let parts = line.components(separatedBy: " ")
                if parts.count >= 3 {
                    version = parts[2]
                }
            } else if line.hasPrefix("configuration:") {
                configuration = line.replacingOccurrences(of: "configuration: ", with: "")
                if configuration.contains("--enable-gpl") {
                    isGPL = true
                }
                if configuration.contains("--enable-version3") {
                    isLGPL = !isGPL
                }
                let tokens = configuration.components(separatedBy: " ")
                for token in tokens where token.hasPrefix("--enable-") {
                    let lib = token.replacingOccurrences(of: "--enable-", with: "")
                    enabledLibs.append(lib)
                }
            }
        }

        let licenseDesc: String
        if isGPL {
            licenseDesc = "GNU General Public License v3.0 (GPLv3) - Includes GPL components"
        } else if isLGPL {
            licenseDesc = "GNU Lesser General Public License v3.0 (LGPLv3)"
        } else {
            licenseDesc = "LGPLv2.1 or later"
        }

        let info = FFmpegVersionInfo(
            version: version,
            configuration: configuration,
            licenseDescription: licenseDesc,
            isGPL: isGPL,
            isLGPL: isLGPL,
            enabledLibraries: enabledLibs
        )

        await Cache.shared.setVersion(info)

        return info
    }

    // MARK: - Capabilities Query
    public static func queryCapabilities() async -> FFmpegCapabilities {
        if let cached = await Cache.shared.getCapabilities() {
            return cached
        }

        guard let binary = locateBinary() else {
            return FFmpegCapabilities()
        }

        var encoders = Set<String>()
        var decoders = Set<String>()
        var muxers = Set<String>()
        var demuxers = Set<String>()
        var filters = Set<String>()

        // 1. Encoders
        if let encOut = runSimpleCommand(binary: binary, arguments: ["-encoders"]) {
            for line in encOut.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.count > 8, trimmed.contains(" ") {
                    let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if parts.count >= 2 {
                        encoders.insert(parts[1])
                    }
                }
            }
        }

        // 2. Decoders
        if let decOut = runSimpleCommand(binary: binary, arguments: ["-decoders"]) {
            for line in decOut.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.count > 8, trimmed.contains(" ") {
                    let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if parts.count >= 2 {
                        decoders.insert(parts[1])
                    }
                }
            }
        }

        // 3. Formats (Muxers / Demuxers)
        if let formOut = runSimpleCommand(binary: binary, arguments: ["-formats"]) {
            for line in formOut.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.count > 4 {
                    let flags = String(trimmed.prefix(4))
                    let rest = trimmed.dropFirst(4).trimmingCharacters(in: .whitespaces)
                    let name = rest.components(separatedBy: .whitespaces).first ?? ""
                    if !name.isEmpty {
                        if flags.contains("E") { muxers.insert(name) }
                        if flags.contains("D") { demuxers.insert(name) }
                    }
                }
            }
        }

        // 4. Filters
        if let filtOut = runSimpleCommand(binary: binary, arguments: ["-filters"]) {
            for line in filtOut.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if parts.count >= 2 {
                    filters.insert(parts[1])
                }
            }
        }

        let hasVT = encoders.contains("h264_videotoolbox") || encoders.contains("hevc_videotoolbox")
        let hasAT = encoders.contains("aac_at") || decoders.contains("aac_at")

        let caps = FFmpegCapabilities(
            encoders: encoders,
            decoders: decoders,
            muxers: muxers,
            demuxers: demuxers,
            filters: filters,
            hasVideoToolbox: hasVT,
            hasAudioToolbox: hasAT
        )

        await Cache.shared.setCapabilities(caps)

        return caps
    }

    private static func runSimpleCommand(binary: URL, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = binary
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    // MARK: - Validation
    public func validateCodecAndFormat(codec: String?, format: String?) async throws {
        let caps = await Self.queryCapabilities()
        if let codec, !codec.isEmpty {
            let supported = caps.encoders.contains(codec) || caps.decoders.contains(codec)
            if !supported {
                throw ShiftKitError.unsupportedCodecOrFormat(codec: codec, format: format ?? "")
            }
        }
        if let format, !format.isEmpty {
            let clean = format.lowercased()
            let supported = caps.muxers.contains(clean) || caps.demuxers.contains(clean)
            if !supported && clean != "mp4" && clean != "mov" && clean != "mp3" && clean != "wav" && clean != "webm" && clean != "mkv" && clean != "avi" && clean != "ogg" && clean != "opus" && clean != "flac" && clean != "aac" && clean != "aiff" {
                throw ShiftKitError.unsupportedCodecOrFormat(codec: codec ?? "", format: format)
            }
        }
    }

    public func canHandle(action: ConversionAction, fileType: FileType) -> Bool {
        switch fileType {
        case .video, .audio:
            return true
        default:
            return false
        }
    }

    // MARK: - ConversionEngine Protocol Implementation
    public func execute(
        request: ConversionRequest,
        outputURL: URL,
        progressHandler: @Sendable @escaping (Double?, String) -> Void
    ) async throws -> URL {
        guard let binaryURL = Self.locateBinary() else {
            throw ShiftKitError.engineNotAvailable(
                engineName: "FFmpeg binary not found. Please install via Homebrew or place ffmpeg in PATH."
            )
        }

        try verifyDiskSpace(for: request.sourceURL, destinationURL: outputURL)

        let expectedDuration = await resolveSourceDuration(url: request.sourceURL)

        let arguments = try await buildArguments(
            request: request,
            outputURL: outputURL
        )

        return try await runFFmpegProcess(
            binaryURL: binaryURL,
            arguments: arguments,
            outputURL: outputURL,
            sourceURL: request.sourceURL,
            expectedDuration: expectedDuration,
            progressHandler: progressHandler
        )
    }

    // MARK: - Specialized Media Operations

    /// Trims an audio or video file between specified start and end timestamps.
    public func trimMedia(
        sourceURL: URL,
        outputURL: URL,
        startTime: Double,
        endTime: Double,
        options: ConversionOptions = .default,
        progressHandler: @Sendable @escaping (Double?, String) -> Void = { _, _ in }
    ) async throws -> URL {
        guard let binary = Self.locateBinary() else {
            throw ShiftKitError.engineNotAvailable(engineName: "FFmpeg binary not found")
        }

        let totalDuration = (await resolveSourceDuration(url: sourceURL)) ?? (endTime + 1.0)
        guard startTime >= 0, endTime > startTime, startTime < totalDuration else {
            throw ShiftKitError.invalidTimestamp(start: startTime, end: endTime, duration: totalDuration)
        }

        try verifyDiskSpace(for: sourceURL, destinationURL: outputURL)
        let trimmedDuration = endTime - startTime

        var args: [String] = [
            "-y",
            "-ss", String(format: "%.3f", startTime),
            "-to", String(format: "%.3f", endTime),
            "-i", sourceURL.path
        ]

        let targetExt = outputURL.pathExtension.lowercased()
        let srcExt = sourceURL.pathExtension.lowercased()

        if targetExt == srcExt && options.videoCompressionPreset == nil && options.targetWidth == nil {
            args.append(contentsOf: ["-c", "copy"])
        } else {
            appendEncodingArguments(for: targetExt, options: options, to: &args)
        }

        args.append(outputURL.path)

        return try await runFFmpegProcess(
            binaryURL: binary,
            arguments: args,
            outputURL: outputURL,
            expectedDuration: trimmedDuration,
            progressHandler: progressHandler
        )
    }

    /// Extracts audio track from a video file.
    public func extractAudio(
        sourceVideoURL: URL,
        outputURL: URL,
        targetFormat: OutputFormat,
        options: ConversionOptions = .default,
        progressHandler: @Sendable @escaping (Double?, String) -> Void = { _, _ in }
    ) async throws -> URL {
        guard let binary = Self.locateBinary() else {
            throw ShiftKitError.engineNotAvailable(engineName: "FFmpeg binary not found")
        }

        try verifyDiskSpace(for: sourceVideoURL, destinationURL: outputURL)
        let duration = await resolveSourceDuration(url: sourceVideoURL)

        var args: [String] = [
            "-y",
            "-i", sourceVideoURL.path,
            "-vn"
        ]

        appendAudioCodecArguments(for: targetFormat.primaryExtension, options: options, to: &args)
        args.append(outputURL.path)

        return try await runFFmpegProcess(
            binaryURL: binary,
            arguments: args,
            outputURL: outputURL,
            sourceURL: sourceURL,
            expectedDuration: duration,
            progressHandler: progressHandler
        )
    }

    /// Generates a single representative still thumbnail image from a video.
    public func generateThumbnail(
        sourceVideoURL: URL,
        outputURL: URL,
        timestampSeconds: Double = 1.0
    ) async throws -> URL {
        guard let binary = Self.locateBinary() else {
            throw ShiftKitError.engineNotAvailable(engineName: "FFmpeg binary not found")
        }

        let args: [String] = [
            "-y",
            "-ss", String(format: "%.3f", max(0.0, timestampSeconds)),
            "-i", sourceVideoURL.path,
            "-vframes", "1",
            "-q:v", "2",
            outputURL.path
        ]

        return try await runFFmpegProcess(
            binaryURL: binary,
            arguments: args,
            outputURL: outputURL,
            expectedDuration: 1.0,
            progressHandler: { _, _ in }
        )
    }

    /// Adjusts audio properties: volume multiplier, sample rate, and channel count.
    public func adjustAudio(
        sourceURL: URL,
        outputURL: URL,
        volume: Double? = nil,
        sampleRate: Double? = nil,
        channels: Int? = nil,
        progressHandler: @Sendable @escaping (Double?, String) -> Void = { _, _ in }
    ) async throws -> URL {
        guard let binary = Self.locateBinary() else {
            throw ShiftKitError.engineNotAvailable(engineName: "FFmpeg binary not found")
        }

        try verifyDiskSpace(for: sourceURL, destinationURL: outputURL)
        let duration = await resolveSourceDuration(url: sourceURL)

        var args: [String] = [
            "-y",
            "-i", sourceURL.path
        ]

        if let volume {
            args.append(contentsOf: ["-filter:a", String(format: "volume=%.2f", volume)])
        }

        if let sampleRate {
            args.append(contentsOf: ["-ar", "\(Int(sampleRate))"])
        }

        if let channels {
            args.append(contentsOf: ["-ac", "\(channels)"])
        }

        let ext = outputURL.pathExtension.lowercased()
        appendAudioCodecArguments(for: ext, options: .default, to: &args)
        args.append(outputURL.path)

        return try await runFFmpegProcess(
            binaryURL: binary,
            arguments: args,
            outputURL: outputURL,
            sourceURL: sourceURL,
            expectedDuration: duration,
            progressHandler: progressHandler
        )
    }

    /// Joins / concatenates multiple audio files into a single unified output file.
    public func joinAudioFiles(
        sourceURLs: [URL],
        outputURL: URL,
        options: ConversionOptions = .default,
        progressHandler: @Sendable @escaping (Double?, String) -> Void = { _, _ in }
    ) async throws -> URL {
        guard sourceURLs.count >= 2 else {
            throw ShiftKitError.conversionFailed(reason: "At least 2 audio files are required for joining.")
        }
        guard let binary = Self.locateBinary() else {
            throw ShiftKitError.engineNotAvailable(engineName: "FFmpeg binary not found")
        }

        try verifyDiskSpace(for: sourceURLs[0], destinationURL: outputURL)

        var totalDuration = 0.0
        for url in sourceURLs {
            totalDuration += (await resolveSourceDuration(url: url)) ?? 0.0
        }

        var args: [String] = ["-y"]
        for url in sourceURLs {
            args.append(contentsOf: ["-i", url.path])
        }

        let inputIndices = (0..<sourceURLs.count).map { "[\($0):a]" }.joined()
        let filterDesc = "\(inputIndices)concat=n=\(sourceURLs.count):v=0:a=1[outa]"

        args.append(contentsOf: [
            "-filter_complex", filterDesc,
            "-map", "[outa]"
        ])

        let ext = outputURL.pathExtension.lowercased()
        appendAudioCodecArguments(for: ext, options: options, to: &args)
        args.append(outputURL.path)

        return try await runFFmpegProcess(
            binaryURL: binary,
            arguments: args,
            outputURL: outputURL,
            expectedDuration: totalDuration > 0 ? totalDuration : nil,
            progressHandler: progressHandler
        )
    }

    /// Joins / concatenates multiple video clips into a single video file.
    public func joinVideoClips(
        sourceURLs: [URL],
        outputURL: URL,
        options: ConversionOptions = .default,
        progressHandler: @Sendable @escaping (Double?, String) -> Void = { _, _ in }
    ) async throws -> URL {
        guard sourceURLs.count >= 2 else {
            throw ShiftKitError.conversionFailed(reason: "At least 2 video clips are required for joining.")
        }
        guard let binary = Self.locateBinary() else {
            throw ShiftKitError.engineNotAvailable(engineName: "FFmpeg binary not found")
        }

        try verifyDiskSpace(for: sourceURLs[0], destinationURL: outputURL)

        var totalDuration = 0.0
        for url in sourceURLs {
            totalDuration += (await resolveSourceDuration(url: url)) ?? 0.0
        }

        var args: [String] = ["-y"]
        for url in sourceURLs {
            args.append(contentsOf: ["-i", url.path])
        }

        let inputs = (0..<sourceURLs.count).map { "[\($0):v][\($0):a]" }.joined()
        let filterDesc = "\(inputs)concat=n=\(sourceURLs.count):v=1:a=1[outv][outa]"

        args.append(contentsOf: [
            "-filter_complex", filterDesc,
            "-map", "[outv]",
            "-map", "[outa]"
        ])

        let ext = outputURL.pathExtension.lowercased()
        appendEncodingArguments(for: ext, options: options, to: &args)
        args.append(outputURL.path)

        return try await runFFmpegProcess(
            binaryURL: binary,
            arguments: args,
            outputURL: outputURL,
            expectedDuration: totalDuration > 0 ? totalDuration : nil,
            progressHandler: progressHandler
        )
    }

    /// Updates or inserts metadata tags into an audio file.
    public func updateAudioTags(
        sourceURL: URL,
        outputURL: URL,
        tags: [String: String],
        progressHandler: @Sendable @escaping (Double?, String) -> Void = { _, _ in }
    ) async throws -> URL {
        guard let binary = Self.locateBinary() else {
            throw ShiftKitError.engineNotAvailable(engineName: "FFmpeg binary not found")
        }

        try verifyDiskSpace(for: sourceURL, destinationURL: outputURL)

        var args: [String] = [
            "-y",
            "-i", sourceURL.path
        ]

        for (k, v) in tags {
            args.append(contentsOf: ["-metadata", "\(k)=\(v)"])
        }

        args.append(contentsOf: ["-c", "copy", outputURL.path])

        return try await runFFmpegProcess(
            binaryURL: binary,
            arguments: args,
            outputURL: outputURL,
            expectedDuration: 1.0,
            progressHandler: progressHandler
        )
    }

    /// Deep inspection of media metadata using ffprobe / ffmpeg.
    public func inspectMetadata(url: URL) async throws -> MediaMetadataInfo {
        if let probeBinary = Self.locateProbeBinary() {
            let process = Process()
            process.executableURL = probeBinary
            process.arguments = [
                "-v", "quiet",
                "-print_format", "json",
                "-show_format",
                "-show_streams",
                url.path
            ]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            process.standardInput = FileHandle.nullDevice

            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return parseProbeJSON(json, url: url)
            }
        }

        guard let binary = Self.locateBinary() else {
            throw ShiftKitError.engineNotAvailable(engineName: "FFmpeg binary not found")
        }

        let process = Process()
        process.executableURL = binary
        process.arguments = ["-nostdin", "-i", url.path]
        let errPipe = Pipe()
        process.standardError = errPipe
        process.standardOutput = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice

        try process.run()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let errString = String(data: errData, encoding: .utf8) ?? ""

        return parseFFmpegStderr(errString, url: url)
    }

    // MARK: - Private Process Runner
    private func runFFmpegProcess(
        binaryURL: URL,
        arguments: [String],
        outputURL: URL,
        sourceURL: URL? = nil,
        expectedDuration: Double?,
        progressHandler: @Sendable @escaping (Double?, String) -> Void
    ) async throws -> URL {
        progressHandler(0.05, "Preparing media pipeline...")

        let outputDir = outputURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: outputDir.path) {
            try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        }

        let tempURL = outputDir.appendingPathComponent(".tmp_ffmpeg_\(UUID().uuidString.prefix(8)).\(outputURL.pathExtension)")

        var effectiveArgs = arguments
        if let last = effectiveArgs.last, last == outputURL.path {
            effectiveArgs[effectiveArgs.count - 1] = tempURL.path
        }

        effectiveArgs.insert(contentsOf: ["-nostdin", "-progress", "pipe:1", "-nostats", "-v", "warning"], at: 1)

        let process = Process()
        process.executableURL = binaryURL
        process.arguments = effectiveArgs

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = FileHandle.nullDevice

        var errData = Data()
        let pipeLock = NSLock()

        let maxErrBufferSize = 128 * 1024 // 128 KB bounded error tail buffer
        stderrPipe.fileHandleForReading.readabilityHandler = { [weak stderrPipe] handle in
            let data = handle.availableData
            if data.isEmpty {
                stderrPipe?.fileHandleForReading.readabilityHandler = nil
                return
            }
            pipeLock.lock()
            errData.append(data)
            if errData.count > maxErrBufferSize {
                errData.removeSubrange(0..<(errData.count - maxErrBufferSize))
            }
            pipeLock.unlock()
        }

        var outBuffer = Data()
        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak stdoutPipe] handle in
            let data = handle.availableData
            if data.isEmpty {
                stdoutPipe?.fileHandleForReading.readabilityHandler = nil
                return
            }
            pipeLock.lock()
            outBuffer.append(data)
            while let range = outBuffer.range(of: Data("\n".utf8)) {
                let lineData = outBuffer.subdata(in: 0..<range.lowerBound)
                outBuffer.removeSubrange(0..<range.upperBound)
                if let line = String(data: lineData, encoding: .utf8) {
                    Self.parseProgressLineStatic(line, expectedDuration: expectedDuration, progressHandler: progressHandler)
                }
            }
            pipeLock.unlock()
        }

        try process.run()

        return try await withTaskCancellationHandler {
            do {
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    var isResumed = false
                    let resumeLock = NSLock()
                    let safeResume = {
                        resumeLock.lock()
                        defer { resumeLock.unlock() }
                        if !isResumed {
                            isResumed = true
                            continuation.resume()
                        }
                    }

                    process.terminationHandler = { _ in
                        safeResume()
                    }

                    if !process.isRunning {
                        safeResume()
                    }
                }

                process.waitUntilExit()

                if Task.isCancelled {
                    throw ShiftKitError.cancelled
                }

                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil

                if process.terminationStatus != 0 {
                    pipeLock.lock()
                    let errString = String(data: errData, encoding: .utf8) ?? "Unknown process error"
                    pipeLock.unlock()
                    let cleanErr = errString.trimmingCharacters(in: .whitespacesAndNewlines)

                    if cleanErr.contains("Invalid data found") || cleanErr.contains("corrupt input") {
                        throw ShiftKitError.corruptMedia(reason: cleanErr.suffix(250).trimmingCharacters(in: .whitespacesAndNewlines))
                    } else if cleanErr.contains("No space left") {
                        throw ShiftKitError.insufficientDiskSpace(needed: 0, available: 0)
                    } else {
                        let tail = cleanErr.suffix(350).trimmingCharacters(in: .whitespacesAndNewlines)
                        throw ShiftKitError.processExecutionFailed(
                            exitCode: process.terminationStatus,
                            message: tail.isEmpty ? "FFmpeg exited with error code \(process.terminationStatus)" : tail
                        )
                    }
                }

                let fm = FileManager.default
                guard fm.fileExists(atPath: tempURL.path) else {
                    throw ShiftKitError.conversionFailed(reason: "FFmpeg did not produce output file.")
                }

                let attrs = try fm.attributesOfItem(atPath: tempURL.path)
                let size = (attrs[.size] as? NSNumber)?.int64Value ?? 0
                guard size > 0 else {
                    try? fm.removeItem(at: tempURL)
                    throw ShiftKitError.corruptMedia(reason: "Output file was 0 bytes.")
                }

                if let sourceURL {
                    guard outputURL.standardizedFileURL.path != sourceURL.standardizedFileURL.path else {
                        try? fm.removeItem(at: tempURL)
                        throw ShiftKitError.conversionFailed(reason: "Output destination cannot overwrite original source file.")
                    }
                }

                if fm.fileExists(atPath: outputURL.path) {
                    try fm.removeItem(at: outputURL)
                }
                try fm.moveItem(at: tempURL, to: outputURL)

                progressHandler(1.0, "Completed")
                return outputURL

            } catch {
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                try? FileManager.default.removeItem(at: tempURL)
                throw error
            }
        } onCancel: {
            process.terminate()
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    private static func parseProgressLineStatic(
        _ line: String,
        expectedDuration: Double?,
        progressHandler: @Sendable @escaping (Double?, String) -> Void
    ) {
        let parts = line.components(separatedBy: "=")
        guard parts.count == 2 else { return }
        let key = parts[0].trimmingCharacters(in: .whitespaces)
        let val = parts[1].trimmingCharacters(in: .whitespaces)

        if key == "out_time_us" || key == "out_time_ms" {
            let micros = Double(val) ?? 0.0
            let seconds = key == "out_time_us" ? (micros / 1_000_000.0) : (micros / 1_000.0)

            if let duration = expectedDuration, duration > 0 {
                let fraction = min(0.99, max(0.05, seconds / duration))
                progressHandler(fraction, "Encoding: \(String(format: "%.1fs", seconds)) / \(String(format: "%.1fs", duration))")
            } else {
                progressHandler(nil, "Encoding: \(String(format: "%.1fs", seconds)) processed")
            }
        } else if key == "progress" && val == "end" {
            progressHandler(1.0, "Finalizing output...")
        }
    }

    // MARK: - Argument Builders
    private func buildArguments(
        request: ConversionRequest,
        outputURL: URL
    ) async throws -> [String] {
        var args: [String] = ["-y", "-i", request.sourceURL.path]

        let targetExt = outputURL.pathExtension.lowercased()
        let options = request.conversionOptions

        if let start = options.trimStartTime, let end = options.trimEndTime {
            let total = (await resolveSourceDuration(url: request.sourceURL)) ?? (end + 1.0)
            guard start >= 0, end > start, start < total else {
                throw ShiftKitError.invalidTimestamp(start: start, end: end, duration: total)
            }
            args.insert(contentsOf: ["-ss", String(format: "%.3f", start), "-to", String(format: "%.3f", end)], at: 1)
        }

        if let sub = options.subtitleAction {
            switch sub {
            case .copy:
                args.append(contentsOf: ["-c:s", "copy"])
            case .strip:
                args.append("-sn")
            }
        }

        switch request.action.category {
        case .convert:
            if targetExt == "gif" {
                args.append(contentsOf: [
                    "-vf", "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
                    "-c:v", "gif"
                ])
            } else if request.fileType.isAudioTarget(targetExt) || targetExt == "mp3" || targetExt == "m4a" || targetExt == "wav" || targetExt == "flac" || targetExt == "aac" || targetExt == "ogg" || targetExt == "opus" || targetExt == "aiff" {
                appendAudioCodecArguments(for: targetExt, options: options, to: &args)
            } else {
                appendEncodingArguments(for: targetExt, options: options, to: &args)
            }

        case .compress:
            let preset = options.videoCompressionPreset ?? .balanced
            appendCompressionArguments(preset: preset, targetExt: targetExt, options: options, to: &args)

        case .extract:
            args.append("-vn")
            appendAudioCodecArguments(for: targetExt, options: options, to: &args)

        case .cropOrTrim:
            appendEncodingArguments(for: targetExt, options: options, to: &args)

        default:
            appendEncodingArguments(for: targetExt, options: options, to: &args)
        }

        if let tags = options.audioTags {
            for (k, v) in tags {
                args.append(contentsOf: ["-metadata", "\(k)=\(v)"])
            }
        }

        args.append(outputURL.path)
        return args
    }

    private func appendEncodingArguments(for targetExt: String, options: ConversionOptions, to args: inout [String]) {
        switch targetExt {
        case "mp4", "mov":
            args.append(contentsOf: [
                "-c:v", "libx264",
                "-preset", "faster",
                "-crf", "\(options.videoCRF ?? 23)",
                "-c:a", "aac",
                "-b:a", "\(options.audioBitrateKbps ?? 192)k"
            ])

        case "mkv":
            args.append(contentsOf: [
                "-c:v", "libx264",
                "-crf", "\(options.videoCRF ?? 22)",
                "-preset", "faster",
                "-c:a", "aac",
                "-b:a", "\(options.audioBitrateKbps ?? 192)k"
            ])

        case "webm":
            args.append(contentsOf: [
                "-c:v", "libvpx-vp9",
                "-crf", "\(options.videoCRF ?? 30)",
                "-b:v", "0",
                "-deadline", "realtime",
                "-cpu-used", "5",
                "-c:a", "libopus",
                "-b:a", "\(options.audioBitrateKbps ?? 128)k"
            ])

        case "avi":
            args.append(contentsOf: [
                "-c:v", "mpeg4",
                "-q:v", "3",
                "-c:a", "libmp3lame",
                "-q:a", "2"
            ])

        default:
            appendAudioCodecArguments(for: targetExt, options: options, to: &args)
        }

        if let width = options.targetWidth, let height = options.targetHeight {
            args.append(contentsOf: ["-vf", "scale=\(width):\(height)"])
        } else if let maxDim = options.maxDimension {
            args.append(contentsOf: ["-vf", "scale=w=\(maxDim):h=-2:force_original_aspect_ratio=decrease"])
        }

        if let fps = options.videoFrameRate {
            args.append(contentsOf: ["-r", "\(fps)"])
        }
    }

    private func appendCompressionArguments(
        preset: VideoCompressionPreset,
        targetExt: String,
        options: ConversionOptions,
        to args: inout [String]
    ) {
        switch preset {
        case .smallerFile:
            args.append(contentsOf: [
                "-vf", "scale='min(1280,iw)':-2",
                "-c:v", "libx264",
                "-crf", "28",
                "-preset", "faster",
                "-c:a", "aac",
                "-b:a", "96k"
            ])

        case .balanced:
            args.append(contentsOf: [
                "-vf", "scale='min(1920,iw)':-2",
                "-c:v", "libx264",
                "-crf", "22",
                "-preset", "faster",
                "-c:a", "aac",
                "-b:a", "160k"
            ])

        case .highQuality:
            args.append(contentsOf: [
                "-c:v", "libx264",
                "-crf", "18",
                "-preset", "faster",
                "-c:a", "aac",
                "-b:a", "256k"
            ])

        case .custom:
            appendEncodingArguments(for: targetExt, options: options, to: &args)
        }
    }

    private func appendAudioCodecArguments(for ext: String, options: ConversionOptions, to args: inout [String]) {
        switch ext {
        case "mp3":
            args.append(contentsOf: [
                "-c:a", "libmp3lame",
                "-b:a", "\(options.audioBitrateKbps ?? 256)k"
            ])
        case "m4a", "aac":
            args.append(contentsOf: [
                "-c:a", "aac",
                "-b:a", "\(options.audioBitrateKbps ?? 192)k"
            ])
        case "wav":
            args.append(contentsOf: ["-c:a", "pcm_s16le"])
        case "flac":
            args.append(contentsOf: ["-c:a", "flac"])
        case "aiff", "aif":
            args.append(contentsOf: ["-c:a", "pcm_s16be"])
        case "ogg":
            args.append(contentsOf: [
                "-c:a", "libopus",
                "-b:a", "\(options.audioBitrateKbps ?? 128)k"
            ])
        case "opus":
            args.append(contentsOf: [
                "-c:a", "libopus",
                "-b:a", "\(options.audioBitrateKbps ?? 128)k"
            ])
        default:
            break
        }

        if let sr = options.audioSampleRateHz {
            args.append(contentsOf: ["-ar", "\(Int(sr))"])
        }

        if let ch = options.audioChannels {
            args.append(contentsOf: ["-ac", "\(ch)"])
        }

        if let vol = options.volumeMultiplier {
            args.append(contentsOf: ["-filter:a", String(format: "volume=%.2f", vol)])
        }
    }

    // MARK: - Helpers
    private func verifyDiskSpace(for sourceURL: URL, destinationURL: URL) throws {
        let parentDir = destinationURL.deletingLastPathComponent()
        let fm = FileManager.default
        let attrs = (try? fm.attributesOfFileSystem(forPath: parentDir.path)) ?? [:]
        let freeBytes = (attrs[.systemFreeSize] as? NSNumber)?.int64Value ?? Int64.max

        let sourceAttrs = (try? fm.attributesOfItem(atPath: sourceURL.path)) ?? [:]
        let sourceSize = (sourceAttrs[.size] as? NSNumber)?.int64Value ?? 0

        let required = max(50 * 1024 * 1024, sourceSize * 2)
        if freeBytes < required {
            throw ShiftKitError.insufficientDiskSpace(needed: required, available: freeBytes)
        }
    }

    private func resolveSourceDuration(url: URL) async -> Double? {
        if let probe = Self.locateProbeBinary() {
            let process = Process()
            process.executableURL = probe
            process.arguments = [
                "-v", "error",
                "-show_entries", "format=duration",
                "-of", "default=noprint_wrappers=1:nokey=1",
                url.path
            ]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            process.standardInput = FileHandle.nullDevice

            if (try? process.run()) != nil {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   let d = Double(str), d > 0 {
                    return d
                }
            }
        }
        return nil
    }

    private func parseProbeJSON(_ json: [String: Any], url: URL) -> MediaMetadataInfo {
        let format = json["format"] as? [String: Any] ?? [:]
        let duration = Double(format["duration"] as? String ?? "") ?? 0.0
        let formatName = format["format_name"] as? String ?? url.pathExtension
        let size = Int64(format["size"] as? String ?? "") ?? 0
        let bitrate = Int64(format["bit_rate"] as? String ?? "")
        let tags = format["tags"] as? [String: String] ?? [:]

        var videoCodec: String?
        var width: Int?
        var height: Int?
        var fps: Double?
        var pixFmt: String?

        var audioCodec: String?
        var sampleRate: Double?
        var channels: Int?
        var audioBitrate: Int64?
        var channelLayout: String?

        var subCount = 0

        let streams = json["streams"] as? [[String: Any]] ?? []
        for s in streams {
            let type = s["codec_type"] as? String ?? ""
            if type == "video" && videoCodec == nil {
                videoCodec = s["codec_name"] as? String
                width = s["width"] as? Int
                height = s["height"] as? Int
                pixFmt = s["pix_fmt"] as? String
                if let rFrameRate = s["r_frame_rate"] as? String {
                    let parts = rFrameRate.components(separatedBy: "/")
                    if parts.count == 2, let num = Double(parts[0]), let den = Double(parts[1]), den > 0 {
                        fps = num / den
                    }
                }
            } else if type == "audio" && audioCodec == nil {
                audioCodec = s["codec_name"] as? String
                sampleRate = Double(s["sample_rate"] as? String ?? "")
                channels = s["channels"] as? Int
                channelLayout = s["channel_layout"] as? String
                audioBitrate = Int64(s["bit_rate"] as? String ?? "")
            } else if type == "subtitle" {
                subCount += 1
            }
        }

        return MediaMetadataInfo(
            duration: duration,
            formatName: formatName,
            fileSize: size,
            overallBitrate: bitrate,
            videoCodec: videoCodec,
            videoWidth: width,
            videoHeight: height,
            videoFrameRate: fps,
            pixelFormat: pixFmt,
            audioCodec: audioCodec,
            audioSampleRate: sampleRate,
            audioChannels: channels,
            audioBitrate: audioBitrate,
            channelLayout: channelLayout,
            subtitleStreamsCount: subCount,
            tags: tags
        )
    }

    private func parseFFmpegStderr(_ stderr: String, url: URL) -> MediaMetadataInfo {
        var duration = 0.0
        var videoCodec: String?
        var width: Int?
        var height: Int?
        var fps: Double?
        var audioCodec: String?
        var sampleRate: Double?
        var channels: Int?
        var tags: [String: String] = [:]

        for line in stderr.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("Duration:") {
                let parts = trimmed.components(separatedBy: ",")
                if let durPart = parts.first(where: { $0.contains("Duration:") }) {
                    let timeStr = durPart.replacingOccurrences(of: "Duration: ", with: "").trimmingCharacters(in: .whitespaces)
                    duration = parseTimeString(timeStr)
                }
            } else if trimmed.contains("Stream #") && trimmed.contains("Video:") {
                videoCodec = "Video"
            } else if trimmed.contains("Stream #") && trimmed.contains("Audio:") {
                audioCodec = "Audio"
            }
        }

        return MediaMetadataInfo(
            duration: duration,
            formatName: url.pathExtension,
            fileSize: 0,
            overallBitrate: nil,
            videoCodec: videoCodec,
            videoWidth: width,
            videoHeight: height,
            videoFrameRate: fps,
            pixelFormat: nil,
            audioCodec: audioCodec,
            audioSampleRate: sampleRate,
            audioChannels: channels,
            audioBitrate: nil,
            channelLayout: nil,
            subtitleStreamsCount: 0,
            tags: tags
        )
    }

    private func parseTimeString(_ str: String) -> Double {
        let parts = str.components(separatedBy: ":")
        guard parts.count == 3 else { return 0.0 }
        let h = Double(parts[0]) ?? 0.0
        let m = Double(parts[1]) ?? 0.0
        let s = Double(parts[2]) ?? 0.0
        return (h * 3600.0) + (m * 60.0) + s
    }
}

private extension FileType {
    func isAudioTarget(_ ext: String) -> Bool {
        switch self {
        case .audio: return true
        default: return false
        }
    }
}

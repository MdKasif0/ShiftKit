import XCTest
@testable import ShiftKit

final class MediaProcessingTests: XCTestCase {
    private var tempDirectory: URL!
    private var engine: FFmpegEngine!

    override func setUp() async throws {
        try await super.setUp()
        let fm = FileManager.default
        let baseDir = FileManager.default.temporaryDirectory.appendingPathComponent("TestMedia_\(UUID().uuidString.prefix(8))")
        try fm.createDirectory(at: baseDir, withIntermediateDirectories: true)
        self.tempDirectory = baseDir
        self.engine = FFmpegEngine()
    }

    override func tearDown() async throws {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }

    // MARK: - Helpers to Create Synthetic Test Media
    private func createTestWAV(duration: Double = 2.0, name: String = "test.wav") throws -> URL {
        let outputURL = tempDirectory.appendingPathComponent(name)
        guard let binary = FFmpegEngine.locateBinary() else {
            throw ShiftKitError.engineNotAvailable(engineName: "FFmpeg not available")
        }

        let process = Process()
        process.executableURL = binary
        process.arguments = [
            "-nostdin",
            "-y",
            "-f", "lavfi",
            "-i", "sine=frequency=880:duration=\(duration)",
            "-c:a", "pcm_s16le",
            outputURL.path
        ]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        return outputURL
    }

    private func createTestMP4(duration: Double = 2.0, name: String = "test.mp4") throws -> URL {
        let outputURL = tempDirectory.appendingPathComponent(name)
        guard let binary = FFmpegEngine.locateBinary() else {
            throw ShiftKitError.engineNotAvailable(engineName: "FFmpeg not available")
        }

        let process = Process()
        process.executableURL = binary
        process.arguments = [
            "-nostdin",
            "-y",
            "-f", "lavfi",
            "-i", "testsrc=duration=\(duration):size=320x240:rate=15",
            "-f", "lavfi",
            "-i", "sine=frequency=440:duration=\(duration)",
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-c:a", "aac",
            outputURL.path
        ]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        return outputURL
    }

    // MARK: - 1. Engine Detection, Version Audit & Capabilities
    func testFFmpegAvailabilityAndVersionAudit() async throws {
        try XCTSkipUnless(FFmpegEngine.isAvailable, "FFmpeg binary is not installed on this test host")
        guard FFmpegEngine.isAvailable else { return }

        let versionInfo = try await FFmpegEngine.queryVersionInfo()
        XCTAssertFalse(versionInfo.version.isEmpty)
        XCTAssertFalse(versionInfo.configuration.isEmpty)
        XCTAssertFalse(versionInfo.licenseDescription.isEmpty)

        // License audit check
        XCTAssertTrue(versionInfo.isGPL, "This Homebrew build contains GPL modules (x264, x265)")
        XCTAssertTrue(versionInfo.enabledLibraries.contains("libx264"))
        XCTAssertTrue(versionInfo.enabledLibraries.contains("libmp3lame"))
    }

    func testFFmpegCapabilitiesQuery() async throws {
        guard FFmpegEngine.isAvailable else { return }

        let caps = await FFmpegEngine.queryCapabilities()
        XCTAssertFalse(caps.encoders.isEmpty)
        XCTAssertFalse(caps.decoders.isEmpty)
        XCTAssertFalse(caps.muxers.isEmpty)

        // Video Encoders
        XCTAssertTrue(caps.encoders.contains("libx264") || caps.encoders.contains("h264_videotoolbox"))
        XCTAssertTrue(caps.encoders.contains("libvpx") || caps.encoders.contains("libvpx-vp9"))

        // Audio Encoders
        XCTAssertTrue(caps.encoders.contains("libmp3lame"))
        XCTAssertTrue(caps.encoders.contains("aac") || caps.encoders.contains("aac_at"))
        XCTAssertTrue(caps.encoders.contains("flac"))
        XCTAssertTrue(caps.encoders.contains("opus") || caps.encoders.contains("libopus"))
        XCTAssertTrue(caps.encoders.contains("pcm_s16le"))

        // VideoToolbox detection on Apple Silicon
        XCTAssertTrue(caps.hasVideoToolbox)
    }

    func testCodecAndFormatValidation() async throws {
        guard FFmpegEngine.isAvailable else { return }

        // Supported codec and format should not throw
        try await engine.validateCodecAndFormat(codec: "libmp3lame", format: "mp3")

        // Unsupported codec should throw
        do {
            try await engine.validateCodecAndFormat(codec: "fictional_codec_xyz", format: "mp4")
            XCTFail("Expected unsupportedCodecOrFormat error")
        } catch let ShiftKitError.unsupportedCodecOrFormat(codec, _) {
            XCTAssertEqual(codec, "fictional_codec_xyz")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - 2. Audio Conversions & Operations
    func testAudioFormatConversions() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let sourceWAV = try createTestWAV(duration: 1.5)

        // 1. WAV -> MP3
        let outMP3 = tempDirectory.appendingPathComponent("output.mp3")
        let requestMP3 = ConversionRequest(
            sourceURL: sourceWAV,
            fileType: .audio(.wav),
            action: .audioToMP3
        )
        let resMP3 = try await engine.execute(request: requestMP3, outputURL: outMP3) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: resMP3.path))
        let mp3Format = FileTypeDetector().detectActualFormat(for: resMP3)
        XCTAssertEqual(mp3Format?.id, "mp3")

        // 2. WAV -> AAC (M4A)
        let outM4A = tempDirectory.appendingPathComponent("output.m4a")
        let requestM4A = ConversionRequest(
            sourceURL: sourceWAV,
            fileType: .audio(.wav),
            action: .audioToM4A
        )
        let resM4A = try await engine.execute(request: requestM4A, outputURL: outM4A) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: resM4A.path))

        // 3. WAV -> FLAC
        let outFLAC = tempDirectory.appendingPathComponent("output.flac")
        let requestFLAC = ConversionRequest(
            sourceURL: sourceWAV,
            fileType: .audio(.wav),
            action: .audioToFLAC
        )
        let resFLAC = try await engine.execute(request: requestFLAC, outputURL: outFLAC) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: resFLAC.path))
        let flacFormat = FileTypeDetector().detectActualFormat(for: resFLAC)
        XCTAssertEqual(flacFormat?.id, "flac")

        // 4. WAV -> OGG
        let outOGG = tempDirectory.appendingPathComponent("output.ogg")
        let requestOGG = ConversionRequest(
            sourceURL: sourceWAV,
            fileType: .audio(.wav),
            action: .audioToOGG
        )
        let resOGG = try await engine.execute(request: requestOGG, outputURL: outOGG) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: resOGG.path))

        // 5. WAV -> Opus
        let outOpus = tempDirectory.appendingPathComponent("output.opus")
        let requestOpus = ConversionRequest(
            sourceURL: sourceWAV,
            fileType: .audio(.wav),
            action: .audioToOpus
        )
        let resOpus = try await engine.execute(request: requestOpus, outputURL: outOpus) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: resOpus.path))
    }

    func testAudioTrimmingAndDuration() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let sourceWAV = try createTestWAV(duration: 3.0)
        let trimmedOut = tempDirectory.appendingPathComponent("trimmed.wav")

        let result = try await engine.trimMedia(
            sourceURL: sourceWAV,
            outputURL: trimmedOut,
            startTime: 0.5,
            endTime: 2.0
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        let metadata = try await engine.inspectMetadata(url: result)
        XCTAssertEqual(metadata.duration, 1.5, accuracy: 0.2, "Trimmed duration should be ~1.5s")
    }

    func testAudioJoining() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let clip1 = try createTestWAV(duration: 1.0, name: "clip1.wav")
        let clip2 = try createTestWAV(duration: 1.5, name: "clip2.wav")
        let joinedOut = tempDirectory.appendingPathComponent("joined.wav")

        let result = try await engine.joinAudioFiles(
            sourceURLs: [clip1, clip2],
            outputURL: joinedOut
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        let metadata = try await engine.inspectMetadata(url: result)
        XCTAssertEqual(metadata.duration, 2.5, accuracy: 0.3, "Joined audio should equal sum of durations")
    }

    func testAudioVolumeAndSampleRateAdjustment() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let sourceWAV = try createTestWAV(duration: 1.0)
        let adjustedOut = tempDirectory.appendingPathComponent("adjusted.wav")

        let result = try await engine.adjustAudio(
            sourceURL: sourceWAV,
            outputURL: adjustedOut,
            volume: 1.5,
            sampleRate: 22050,
            channels: 1
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        let metadata = try await engine.inspectMetadata(url: result)
        if let sr = metadata.audioSampleRate {
            XCTAssertEqual(sr, 22050.0, accuracy: 10.0)
        }
    }

    func testAudioMetadataTagEditingAndInspection() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let sourceWAV = try createTestWAV(duration: 1.0)
        let taggedMP3 = tempDirectory.appendingPathComponent("tagged.mp3")

        // First convert to mp3
        _ = try await engine.execute(
            request: ConversionRequest(sourceURL: sourceWAV, fileType: .audio(.wav), action: .audioToMP3),
            outputURL: taggedMP3,
            progressHandler: { _, _ in }
        )

        // Then update tags
        let finalTagged = tempDirectory.appendingPathComponent("tagged_final.mp3")
        _ = try await engine.updateAudioTags(
            sourceURL: taggedMP3,
            outputURL: finalTagged,
            tags: [
                "title": "ShiftKit Anthem",
                "artist": "Antigravity Engineers",
                "album": "macOS Utilities"
            ]
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: finalTagged.path))
        let meta = try await engine.inspectMetadata(url: finalTagged)
        XCTAssertEqual(meta.title, "ShiftKit Anthem")
        XCTAssertEqual(meta.artist, "Antigravity Engineers")
    }

    // MARK: - 3. Video Conversions & Operations
    func testVideoFormatConversions() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let sourceMP4 = try createTestMP4(duration: 1.2)

        // 1. MP4 -> WebM (VP9 + Opus)
        let outWebM = tempDirectory.appendingPathComponent("video.webm")
        let reqWebM = ConversionRequest(
            sourceURL: sourceMP4,
            fileType: .video(.mp4),
            action: .videoToWebM
        )
        let resWebM = try await engine.execute(request: reqWebM, outputURL: outWebM) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: resWebM.path))
        let formatWebM = FileTypeDetector().detectActualFormat(for: resWebM)
        XCTAssertEqual(formatWebM?.id, "webm")

        // 2. MP4 -> MKV
        let outMKV = tempDirectory.appendingPathComponent("video.mkv")
        let reqMKV = ConversionRequest(
            sourceURL: sourceMP4,
            fileType: .video(.mp4),
            action: .videoToMKV
        )
        let resMKV = try await engine.execute(request: reqMKV, outputURL: outMKV) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: resMKV.path))

        // 3. MP4 -> GIF
        let outGIF = tempDirectory.appendingPathComponent("video.gif")
        let reqGIF = ConversionRequest(
            sourceURL: sourceMP4,
            fileType: .video(.mp4),
            action: .videoToGIF
        )
        let resGIF = try await engine.execute(request: reqGIF, outputURL: outGIF) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: resGIF.path))
        let gifFormat = FileTypeDetector().detectActualFormat(for: resGIF)
        XCTAssertEqual(gifFormat?.id, "gif")
    }

    func testVideoTrimming() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let sourceMP4 = try createTestMP4(duration: 2.5)
        let trimmedOut = tempDirectory.appendingPathComponent("trimmed.mp4")

        let result = try await engine.trimMedia(
            sourceURL: sourceMP4,
            outputURL: trimmedOut,
            startTime: 0.5,
            endTime: 1.8
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        let meta = try await engine.inspectMetadata(url: result)
        XCTAssertEqual(meta.duration, 1.3, accuracy: 0.3)
    }

    func testVideoCompressionPresets() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let sourceMP4 = try createTestMP4(duration: 2.0)

        // Smaller File Preset
        let smallOut = tempDirectory.appendingPathComponent("small.mp4")
        let reqSmall = ConversionRequest(
            sourceURL: sourceMP4,
            fileType: .video(.mp4),
            action: .videoCompress,
            conversionOptions: ConversionOptions(videoCompressionPreset: .smallerFile)
        )
        let resSmall = try await engine.execute(request: reqSmall, outputURL: smallOut) { _, _ in }

        // High Quality Preset
        let hqOut = tempDirectory.appendingPathComponent("hq.mp4")
        let reqHQ = ConversionRequest(
            sourceURL: sourceMP4,
            fileType: .video(.mp4),
            action: .videoCompress,
            conversionOptions: ConversionOptions(videoCompressionPreset: .highQuality)
        )
        let resHQ = try await engine.execute(request: reqHQ, outputURL: hqOut) { _, _ in }

        let fm = FileManager.default
        let smallSize = (try fm.attributesOfItem(atPath: resSmall.path)[.size] as? NSNumber)?.int64Value ?? 0
        let hqSize = (try fm.attributesOfItem(atPath: resHQ.path)[.size] as? NSNumber)?.int64Value ?? 0

        XCTAssertGreaterThan(smallSize, 0)
        XCTAssertGreaterThan(hqSize, 0)
        // Smaller file preset downscales / compresses more heavily
        XCTAssertLessThanOrEqual(smallSize, hqSize)
    }

    func testVideoAudioExtraction() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let sourceMP4 = try createTestMP4(duration: 1.5)
        let extractedMP3 = tempDirectory.appendingPathComponent("extracted.mp3")

        let result = try await engine.extractAudio(
            sourceVideoURL: sourceMP4,
            outputURL: extractedMP3,
            targetFormat: .mp3
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        let meta = try await engine.inspectMetadata(url: result)
        XCTAssertNil(meta.videoCodec)
        XCTAssertNotNil(meta.audioCodec)
    }

    func testVideoThumbnailGeneration() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let sourceMP4 = try createTestMP4(duration: 1.5)
        let thumbOut = tempDirectory.appendingPathComponent("thumb.jpg")

        let result = try await engine.generateThumbnail(
            sourceVideoURL: sourceMP4,
            outputURL: thumbOut,
            timestampSeconds: 0.5
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        let fm = FileManager.default
        let size = (try fm.attributesOfItem(atPath: result.path)[.size] as? NSNumber)?.int64Value ?? 0
        XCTAssertGreaterThan(size, 0)

        // Verify valid image
        let image = NSImage(contentsOf: result)
        XCTAssertNotNil(image)
    }

    func testVideoJoiningClips() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let clip1 = try createTestMP4(duration: 1.0, name: "vclip1.mp4")
        let clip2 = try createTestMP4(duration: 1.5, name: "vclip2.mp4")
        let joinedOut = tempDirectory.appendingPathComponent("vjoined.mp4")

        let result = try await engine.joinVideoClips(
            sourceURLs: [clip1, clip2],
            outputURL: joinedOut
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        let meta = try await engine.inspectMetadata(url: result)
        XCTAssertEqual(meta.duration, 2.5, accuracy: 0.4)
    }

    // MARK: - 4. Safety & Edge Cases
    func testInvalidTimestampHandling() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let sourceWAV = try createTestWAV(duration: 2.0)
        let dummyOut = tempDirectory.appendingPathComponent("dummy.wav")

        // Start >= End
        do {
            _ = try await engine.trimMedia(
                sourceURL: sourceWAV,
                outputURL: dummyOut,
                startTime: 2.0,
                endTime: 1.0
            )
            XCTFail("Expected invalidTimestamp error")
        } catch let ShiftKitError.invalidTimestamp(s, e, _) {
            XCTAssertEqual(s, 2.0)
            XCTAssertEqual(e, 1.0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // Start >= Total Duration
        do {
            _ = try await engine.trimMedia(
                sourceURL: sourceWAV,
                outputURL: dummyOut,
                startTime: 5.0,
                endTime: 8.0
            )
            XCTFail("Expected invalidTimestamp error")
        } catch is ShiftKitError {
            // Success: rejected invalid timestamp beyond duration
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCorruptMediaHandling() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let corruptFile = tempDirectory.appendingPathComponent("corrupt.mp4")
        let randomGarbage = Data((0..<1024).map { _ in UInt8.random(in: 0...255) })
        try randomGarbage.write(to: corruptFile)

        let out = tempDirectory.appendingPathComponent("fail_out.mp3")

        do {
            _ = try await engine.extractAudio(
                sourceVideoURL: corruptFile,
                outputURL: out,
                targetFormat: .mp3
            )
            XCTFail("Expected corrupt media error")
        } catch is ShiftKitError {
            // Expected
            XCTAssertFalse(FileManager.default.fileExists(atPath: out.path), "Output must not remain after corrupt failure")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testConversionCancellationAndCleanup() async throws {
        guard FFmpegEngine.isAvailable else { return }
        let sourceWAV = try createTestWAV(duration: 5.0)
        let cancelOut = tempDirectory.appendingPathComponent("cancelled.mp3")

        let request = ConversionRequest(
            sourceURL: sourceWAV,
            fileType: .audio(.wav),
            action: .audioToMP3
        )

        let task = Task {
            try await engine.execute(request: request, outputURL: cancelOut) { _, _ in }
        }

        // Immediately cancel
        task.cancel()

        do {
            _ = try await task.value
        } catch {
            // Verify cancelled output does not exist
            XCTAssertFalse(FileManager.default.fileExists(atPath: cancelOut.path), "Partial output must be cleaned up on cancellation")
        }
    }

    func testTrimGeometryEngine() {
        let engine = TrimGeometryEngine(totalDuration: 10.0, minDuration: 0.5)

        // Time to ratio & ratio to time
        XCTAssertEqual(engine.ratio(forTime: 5.0), 0.5, accuracy: 0.001)
        XCTAssertEqual(engine.time(forRatio: 0.5), 5.0, accuracy: 0.001)

        // Coordinates mapping
        XCTAssertEqual(engine.x(forTime: 2.5, inWidth: 400), 100, accuracy: 0.1)
        XCTAssertEqual(engine.time(forX: 100, inWidth: 400), 2.5, accuracy: 0.1)

        // Clamping logic
        let clamped = engine.clampRange(start: 9.8, end: 10.0)
        XCTAssertGreaterThanOrEqual(clamped.end - clamped.start, 0.5)

        // Adjust Start Time
        let adjStart = engine.adjustStartTime(6.0, currentEnd: 6.2)
        XCTAssertEqual(adjStart, 5.7, accuracy: 0.001)

        // Adjust End Time
        let adjEnd = engine.adjustEndTime(2.0, currentStart: 2.0)
        XCTAssertEqual(adjEnd, 2.5, accuracy: 0.001)

        // Timestamp formatting
        XCTAssertEqual(TrimGeometryEngine.formatTimestamp(65.42), "01:05.42")
        XCTAssertEqual(TrimGeometryEngine.formatTimestamp(0.0), "00:00.00")
    }
}

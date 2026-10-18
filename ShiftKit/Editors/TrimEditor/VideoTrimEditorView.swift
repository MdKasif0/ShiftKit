import SwiftUI
import AppKit
import AVKit
import AVFoundation

// MARK: - Native Video Player Representable
public struct NativeVideoPlayerView: NSViewRepresentable {
    public let player: AVPlayer

    public init(player: AVPlayer) {
        self.player = player
    }

    public func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .none
        playerView.showsFrameSteppingButtons = false
        playerView.showsSharingServiceButton = false
        playerView.showsFullScreenToggleButton = false
        playerView.wantsLayer = true
        playerView.layer?.backgroundColor = NSColor(ShiftKitColors.charcoalBrown).cgColor
        return playerView
    }

    public func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
    }
}

// MARK: - Video Trim Editor View
public struct VideoTrimEditorView: View {
    public let file: InspectedFile
    public let onApply: (Double, Double, ConversionOptions, OutputFormat) -> Void
    public let onCancel: () -> Void

    @State private var player: AVPlayer?
    @State private var isPlaying: Bool = false
    @State private var totalDuration: Double = 1.0
    @State private var currentTime: Double = 0.0
    @State private var startTime: Double = 0.0
    @State private var endTime: Double = 1.0
    
    // Geometry
    @State private var geometryEngine: TrimGeometryEngine = TrimGeometryEngine(totalDuration: 1.0)
    @State private var activeDragHandle: TrimHandleType? = nil
    
    // Presets & Output Options
    @State private var selectedPreset: VideoCompressionPreset = .balanced
    @State private var targetFormat: OutputFormat = .mp4
    @State private var customResolution: String = "1080p"
    @State private var customFPS: Double = 30.0
    @State private var timeObserverToken: Any?

    private enum TrimHandleType {
        case start
        case end
        case playhead
    }

    public init(
        file: InspectedFile,
        onApply: @escaping (Double, Double, ConversionOptions, OutputFormat) -> Void,
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

            // 2. Central Video Preview Player
            ZStack {
                ShiftKitColors.warmIvory
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Video View Canvas
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ShiftKitColors.charcoalBrown)
                            .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.12), radius: 10, x: 0, y: 4)

                        if let player {
                            NativeVideoPlayerView(player: player)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .tint(ShiftKitColors.softTerracotta)
                                Text("Loading video...")
                                    .font(ShiftKitTypography.caption)
                                    .foregroundColor(ShiftKitColors.softCream)
                            }
                        }

                        // Play / Pause Floating Overlay
                        VStack {
                            Spacer()
                            HStack {
                                Button {
                                    togglePlayback()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(isPlaying ? "Pause" : "Play")
                                            .font(ShiftKitTypography.captionBold)
                                    }
                                    .foregroundColor(ShiftKitColors.pureWhite)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(ShiftKitColors.softTerracotta)
                                    .clipShape(Capsule())
                                    .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.15), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(.plain)
                                .keyboardShortcut(.space, modifiers: [])

                                Spacer()

                                // Current Playhead Time Readout
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 10))
                                    Text(TrimGeometryEngine.formatTimestamp(currentTime))
                                        .font(ShiftKitTypography.code)
                                }
                                .foregroundColor(ShiftKitColors.pureWhite)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(ShiftKitColors.charcoalBrown.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .padding(12)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // 3. Native Timeline Trimmer & Range Handles
                    timelineSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }
            }

            Divider()
                .background(ShiftKitColors.border)

            // 4. Bottom Preset & Control Bar
            bottomControlBar
        }
        .frame(minWidth: 840, minHeight: 620)
        .background(ShiftKitColors.warmIvory)
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            teardownPlayer()
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Video Trimmer & Compressor")
                    .font(ShiftKitTypography.headline)
                    .foregroundColor(ShiftKitColors.charcoalBrown)

                Text(file.fileName)
                    .font(ShiftKitTypography.caption)
                    .foregroundColor(ShiftKitColors.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            // Time Readouts
            HStack(spacing: 12) {
                timeBadge(title: "Start", time: startTime)
                timeBadge(title: "End", time: endTime)
                timeBadge(title: "Trimmed", time: endTime - startTime, highlight: true)
                timeBadge(title: "Total", time: totalDuration)
            }

            Spacer()

            HStack(spacing: 10) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(ShiftKitSecondaryButtonStyle())

                Button {
                    exportTrimmedVideo()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "scissors")
                        Text("Export Trim")
                    }
                }
                .buttonStyle(ShiftKitPrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(ShiftKitColors.pureWhite)
    }

    private func timeBadge(title: String, time: Double, highlight: Bool = false) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(ShiftKitTypography.caption)
                .foregroundColor(highlight ? ShiftKitColors.softTerracotta : ShiftKitColors.textMuted)

            Text(TrimGeometryEngine.formatTimestamp(time))
                .font(ShiftKitTypography.code)
                .foregroundColor(highlight ? ShiftKitColors.softTerracotta : ShiftKitColors.charcoalBrown)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(highlight ? ShiftKitColors.warmPeach.opacity(0.5) : ShiftKitColors.softCream)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(highlight ? ShiftKitColors.softTerracotta.opacity(0.4) : ShiftKitColors.sandBeige, lineWidth: 1)
        )
    }

    // MARK: - Timeline Section
    private var timelineSection: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let startX = geometryEngine.x(forTime: startTime, inWidth: width)
                let endX = geometryEngine.x(forTime: endTime, inWidth: width)
                let playheadX = geometryEngine.x(forTime: currentTime, inWidth: width)

                ZStack(alignment: .leading) {
                    // Background Track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ShiftKitColors.softCream)
                        .frame(height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ShiftKitColors.sandBeige, lineWidth: 1)
                        )

                    // Filmstrip Tick Lines Pattern
                    HStack(spacing: 8) {
                        ForEach(0..<Int(width / 12), id: \.self) { _ in
                            Rectangle()
                                .fill(ShiftKitColors.sandBeige.opacity(0.5))
                                .frame(width: 1, height: 24)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Dimmed Unselected Regions
                    // Left Dimmed
                    if startX > 0 {
                        Rectangle()
                            .fill(ShiftKitColors.charcoalBrown.opacity(0.25))
                            .frame(width: startX, height: 48)
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 6))
                    }

                    // Right Dimmed
                    if endX < width {
                        Rectangle()
                            .fill(ShiftKitColors.charcoalBrown.opacity(0.25))
                            .frame(width: width - endX, height: 48)
                            .offset(x: endX)
                            .clipShape(UnevenRoundedRectangle(bottomTrailingRadius: 6, topTrailingRadius: 6))
                    }

                    // Active Selected Trim Range Highlight
                    Rectangle()
                        .stroke(ShiftKitColors.softTerracotta, lineWidth: 2)
                        .background(ShiftKitColors.warmPeach.opacity(0.2))
                        .frame(width: max(2, endX - startX), height: 48)
                        .offset(x: startX)

                    // Left Handle (Start Time)
                    handleView(isStart: true)
                        .position(x: startX, y: 24)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    pausePlayback()
                                    let newTime = geometryEngine.time(forX: value.location.x, inWidth: width)
                                    startTime = geometryEngine.adjustStartTime(newTime, currentEnd: endTime)
                                    seekPlayer(to: startTime)
                                }
                        )

                    // Right Handle (End Time)
                    handleView(isStart: false)
                        .position(x: endX, y: 24)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    pausePlayback()
                                    let newTime = geometryEngine.time(forX: value.location.x, inWidth: width)
                                    endTime = geometryEngine.adjustEndTime(newTime, currentStart: startTime)
                                    seekPlayer(to: endTime)
                                }
                        )

                    // Scrubber Playhead
                    VStack(spacing: 0) {
                        Circle()
                            .fill(ShiftKitColors.deepOlive)
                            .frame(width: 10, height: 10)

                        Rectangle()
                            .fill(ShiftKitColors.deepOlive)
                            .frame(width: 2, height: 48)
                    }
                    .position(x: playheadX, y: 24)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                pausePlayback()
                                let scrubTime = geometryEngine.time(forX: value.location.x, inWidth: width)
                                currentTime = min(endTime, max(startTime, scrubTime))
                                seekPlayer(to: currentTime)
                            }
                    )
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    pausePlayback()
                    let tapTime = geometryEngine.time(forX: location.x, inWidth: width)
                    currentTime = min(endTime, max(startTime, tapTime))
                    seekPlayer(to: currentTime)
                }
            }
            .frame(height: 56)
        }
    }

    private func handleView(isStart: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(ShiftKitColors.softTerracotta)
                .frame(width: 14, height: 50)
                .shadow(color: ShiftKitColors.charcoalBrown.opacity(0.2), radius: 3, x: 0, y: 1)

            VStack(spacing: 3) {
                Capsule().fill(ShiftKitColors.pureWhite).frame(width: 2, height: 14)
                Capsule().fill(ShiftKitColors.pureWhite).frame(width: 2, height: 14)
            }
        }
    }

    // MARK: - Bottom Control Bar
    private var bottomControlBar: some View {
        HStack(spacing: 24) {
            // Preset Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Compression Preset")
                    .font(ShiftKitTypography.captionBold)
                    .foregroundColor(ShiftKitColors.charcoalBrown)

                Picker("", selection: $selectedPreset) {
                    ForEach(VideoCompressionPreset.allCases, id: \.self) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 380)
            }

            // Output Format Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Target Format")
                    .font(ShiftKitTypography.captionBold)
                    .foregroundColor(ShiftKitColors.charcoalBrown)

                Picker("", selection: $targetFormat) {
                    Text("MP4 (H.264)").tag(OutputFormat.mp4)
                    Text("QuickTime MOV").tag(OutputFormat.mov)
                    Text("WebM (VP9)").tag(OutputFormat.webm)
                    Text("Matroska MKV").tag(OutputFormat.mkv)
                    Text("Animated GIF").tag(OutputFormat.gif)
                    Text("Extract MP3").tag(OutputFormat.mp3)
                }
                .frame(width: 170)
            }

            Spacer()

            // Preset Description Note
            VStack(alignment: .trailing, spacing: 2) {
                Text(selectedPreset.subtitle)
                    .font(ShiftKitTypography.caption)
                    .foregroundColor(ShiftKitColors.deepOlive)

                Text("Preserves original audio synchronization")
                    .font(ShiftKitTypography.caption)
                    .foregroundColor(ShiftKitColors.textMuted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(ShiftKitColors.softCream)
    }

    // MARK: - Player Lifecycle & Control
    private func setupPlayer() {
        let asset = AVURLAsset(url: file.url)
        let playerItem = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: playerItem)

        Task {
            if let dur = try? await asset.load(.duration) {
                let seconds = CMTimeGetSeconds(dur)
                if seconds.isFinite && seconds > 0 {
                    await MainActor.run {
                        self.totalDuration = seconds
                        self.startTime = 0.0
                        self.endTime = seconds
                        self.currentTime = 0.0
                        self.geometryEngine = TrimGeometryEngine(totalDuration: seconds)
                    }
                }
            }
        }

        // Add periodic time observer (10 times per second)
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserverToken = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak newPlayer] time in
            guard let newPlayer else { return }
            let sec = CMTimeGetSeconds(time)
            if sec.isFinite {
                self.currentTime = sec
                // Check if reached endTime
                if self.currentTime >= self.endTime {
                    newPlayer.pause()
                    self.isPlaying = false
                    self.seekPlayer(to: self.startTime)
                }
            }
        }

        self.player = newPlayer
    }

    private func teardownPlayer() {
        if let token = timeObserverToken, let player {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        player = nil
    }

    private func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if currentTime >= endTime {
                seekPlayer(to: startTime)
            }
            player.play()
            isPlaying = true
        }
    }

    private func pausePlayback() {
        player?.pause()
        isPlaying = false
    }

    private func seekPlayer(to seconds: Double) {
        guard let player else { return }
        currentTime = seconds
        let targetCMTime = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: targetCMTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    // MARK: - Export Action
    private func exportTrimmedVideo() {
        pausePlayback()

        var options = ConversionOptions.default
            .withTrim(start: startTime, end: endTime)
            .withVideoCompression(selectedPreset)

        if targetFormat == .mp3 || targetFormat == .m4a {
            options.audioBitrateKbps = 256
        }

        onApply(startTime, endTime, options, targetFormat)
    }
}

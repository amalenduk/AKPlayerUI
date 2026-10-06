//
//  AKPlayerCoordinator.swift
//  AKPlayerUI
//

import SwiftUI
import Combine
import AVFoundation
import CoreMedia
import AKPlayer

/// Central player coordinator managing `AKPlayer` engine lifecycle, playback state,
/// multiplatform presentation modes, 10-band equalizer DSP, and native ad overlays.
/// Strictly relies on `AKPlayer` as the single core backbone.
@MainActor
public final class AKPlayerCoordinator: NSObject, ObservableObject, @unchecked Sendable {
    
    public static let shared = AKPlayerCoordinator()
    
    // MARK: - Core Playback Engine Backbone
    public let player: AKPlayer
    
    // MARK: - Presentation & Navigation
    @Published public var presentationMode: AKPlayerPresentationMode = .hidden
    @Published public var isAtLiveEdge: Bool = true
    @Published public var liveOffset: TimeInterval = 0
    
    // MARK: - Dedicated UI Presentation State (Separated into AKPlayerUIState)
    public let uiState: AKPlayerUIState
    
    public var activeSheet: AKPlayerAuxiliarySheet? {
        get { uiState.activeSheet }
        set { uiState.activeSheet = newValue }
    }
    
    public var overlayPlacement: AKOverlayPlacementMode {
        get { uiState.overlayPlacement }
        set { uiState.overlayPlacement = newValue }
    }
    
    public var activeInlineOverlay: AKPlayerAuxiliarySheet? {
        get { uiState.activeInlineOverlay }
        set { uiState.activeInlineOverlay = newValue }
    }
    
    public var activeSheetBinding: Binding<AKPlayerAuxiliarySheet?> {
        Binding(
            get: { self.uiState.activeSheet },
            set: { self.uiState.activeSheet = $0 }
        )
    }
    
    public var overlayPlacementBinding: Binding<AKOverlayPlacementMode> {
        Binding(
            get: { self.uiState.overlayPlacement },
            set: { self.uiState.overlayPlacement = $0 }
        )
    }
    
    public var activeInlineOverlayBinding: Binding<AKPlayerAuxiliarySheet?> {
        Binding(
            get: { self.uiState.activeInlineOverlay },
            set: { self.uiState.activeInlineOverlay = $0 }
        )
    }
    
    // MARK: - Active Playback State (Driven by AKPlayer)
    @Published public private(set) var state: AKPlayerState = .idle
    @Published public private(set) var autoPlay: Bool = false
    @Published public private(set) var currentTime: TimeInterval = 0
    @Published public private(set) var duration: TimeInterval = 0
    @Published public private(set) var loadedTimeRanges: [CMTimeRange] = []
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var isBuffering: Bool = false
    @Published public var playbackRate: Float = 1.0
    @Published public var aspectRatio: AKVideoAspectRatio = .fit
    @Published public var isAudioOnly: Bool = false
    
    // MARK: - Active Media & Capabilities
    @Published public private(set) var currentMedia: (any AKPlayable)?
    @Published public private(set) var currentTitle: String = ""
    @Published public private(set) var currentSubtitle: String = ""
    @Published public private(set) var currentArtworkURL: URL?
    @Published public private(set) var currentArtworkImage: AKPlatformImage?
    @Published public private(set) var chapters: [AKChapter] = []
    @Published public private(set) var activeChapter: AKChapter?
    @Published public private(set) var interstitialMarkers: [AKInterstitialMarker] = []
    @Published public var repeatMode: AKRepeatMode = .off
    @Published public var isShuffled: Bool = false
    
    // MARK: - Audio & Subtitle Tracks (from AKPlayer)
    @Published public private(set) var availableAudioTracks: [AKMediaTrackOption] = []
    @Published public private(set) var selectedAudioTrack: AKMediaTrackOption?
    @Published public private(set) var availableSubtitleTracks: [AKMediaTrackOption] = []
    @Published public private(set) var selectedSubtitleTrack: AKMediaTrackOption?
    
    // MARK: - Native Engine Capabilities
    @Published public private(set) var capabilities: AKMediaCapabilities = .empty
    
    // MARK: - Configuration & Theming
    @Published public var configuration: AKPlayerConfiguration = .automatic
    @Published public var theme: AKPlayerTheme = .standard
    
    // MARK: - Domain Sub-Managers (Composed)
    public let equalizer: AKEqualizerManager
    public let adManager: AKAdManager
    
    private var cancellables = Set<AnyCancellable>()
    private var playerEventsTask: Task<Void, Never>?
    
    public override init() {
        self.player = AKPlayer()
        self.equalizer = AKEqualizerManager()
        self.adManager = AKAdManager()
        self.uiState = AKPlayerUIState()
        super.init()
        setupAdManagerCallbacks()
        bindUIState()
        startObservingPlayerEvents()
    }
    
    /// Custom initializer supporting injected AKPlayer instances or testing.
    public init(player: AKPlayer) {
        self.player = player
        self.equalizer = AKEqualizerManager()
        self.adManager = AKAdManager()
        self.uiState = AKPlayerUIState()
        super.init()
        setupAdManagerCallbacks()
        bindUIState()
        startObservingPlayerEvents()
    }
    
    private func bindUIState() {
        uiState.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        playerEventsTask?.cancel()
    }
    
    // MARK: - High-Level Playback Commands (Zero-Boilerplate Entry Point)
    
    /// Loads and begins playback of an `AKPlayable` item (such as `AKMedia`), automatically applying presentation mode.
    public func load(
        media: any AKPlayable,
        autoPlay: Bool = true,
        at startPosition: AKSeekTarget? = nil,
        presentationMode: AKPlayerPresentationMode? = nil,
        isAudioOnly: Bool? = nil,
        configuration: AKPlayerConfiguration? = nil
    ) {
        if let config = configuration {
            self.configuration = config
        }
        
        Task {
            try? await self.player.prepare()
        }
        
        self.currentMedia = media
        self.currentTitle = media.staticMetadata?.title ?? media.url.deletingPathExtension().lastPathComponent
        self.currentSubtitle = media.staticMetadata?.artist ?? ""
        self.currentArtworkImage = nil
        self.currentArtworkURL = nil
        
        // Extract artwork from staticMetadata if provided
        if let artwork = media.staticMetadata?.artwork {
            switch artwork {
            case .image(let img):
                self.currentArtworkImage = img
            case .data(let data):
                self.currentArtworkImage = AKPlatformImage(data: data)
            default:
                break
            }
        }
        
        // Update capabilities based on media type & file characteristics
        updateCapabilities(for: media, explicitAudioOnly: isAudioOnly)
        
        // Reset positions
        self.currentTime = 0
        self.duration = 0
        
        // Present interface
        if let mode = presentationMode {
            self.presentationMode = mode
        } else if self.configuration.playback.openDirectlyInFullScreen {
            self.presentationMode = .fullScreen
        } else {
            self.presentationMode = .miniPlayer
        }
        
        self.loadedTimeRanges = []
        
        // Delegate to AKPlayer engine
        player.load(media: media, autoPlay: autoPlay, at: startPosition)
        

    }
    
    /// Loads a simple URL with optional title and artwork.
    public func load(
        url: URL,
        title: String? = nil,
        subtitle: String? = nil,
        artworkURL: URL? = nil,
        presentationMode: AKPlayerPresentationMode? = nil,
        isAudioOnly: Bool? = nil,
        configuration: AKPlayerConfiguration? = nil
    ) {
        let isLive = url.absoluteString.contains(".m3u8") || url.absoluteString.contains("live")
        let mediaType: AKMediaType = isLive ? .stream(isLive: true) : .clip
        let media = AKMedia(url: url, type: mediaType)
        load(media: media, presentationMode: presentationMode, isAudioOnly: isAudioOnly, configuration: configuration)
        
        if let title = title {
            self.currentTitle = title
        }
        if let subtitle = subtitle {
            self.currentSubtitle = subtitle
        }
        if let artworkURL = artworkURL {
            self.currentArtworkURL = artworkURL
        }
    }
    
    /// Toggles play / pause state.
    public func togglePlayPause() {
        if state.isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    /// Resumes or starts playback.
    public func play() {
        player.play()
    }
    
    /// Pauses active playback.
    public func pause() {
        player.pause()
    }
    
    /// Seeks to an absolute timestamp in seconds.
    public func seek(to seconds: TimeInterval) {
        guard capabilities.canSeek, !adManager.isAdActive else { return }
        
        if capabilities.isLive {
            if let dvrWindow = player.currentMedia?.dvrWindow, dvrWindow.duration.seconds > 0 {
                let targetAbsoluteSeconds: Double
                if seconds >= dvrWindow.start.seconds {
                    // Already an absolute timestamp (e.g. from skipBackward/skipForward)
                    targetAbsoluteSeconds = min(dvrWindow.end.seconds, max(dvrWindow.start.seconds, seconds))
                } else {
                    // Relative to DVR window [0...duration] from the timeline scrubber
                    let clampedDvrPos = max(0, min(dvrWindow.duration.seconds, seconds))
                    targetAbsoluteSeconds = dvrWindow.start.seconds + clampedDvrPos
                }
                let drift = max(0, dvrWindow.end.seconds - targetAbsoluteSeconds)
                self.currentTime = targetAbsoluteSeconds
                self.liveOffset = drift
                self.isAtLiveEdge = drift <= 3.0
                Task {
                    _ = await player.seek(to: .seconds(targetAbsoluteSeconds), scope: .primary)
                }
                return
            }
        }
        
        let clamped = max(0, min(seconds, duration > 0 ? duration : seconds))
        currentTime = clamped
        Task {
            _ = await player.seek(to: .seconds(clamped), scope: .primary)
        }
    }
    
    /// Jumps directly to the live edge of a live stream.
    public func jumpToLive() {
        guard capabilities.isLive else { return }
        Task {
            _ = await player.jumpToLive()
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.isAtLiveEdge = true
                    self.liveOffset = 0
                }
            }
        }
    }
    
    /// Relative seek forward by configured step.
    public func skipForward() {
        guard capabilities.canSeek, !adManager.isAdActive else { return }
        if capabilities.isLive && isAtLiveEdge {
            return
        }
        seek(to: currentTime + configuration.playback.skipForwardDuration)
    }
    
    /// Relative seek backward by configured step.
    public func skipBackward() {
        guard capabilities.canSeek, !adManager.isAdActive else { return }
        seek(to: currentTime - configuration.playback.skipBackwardDuration)
    }
    
    /// Single frame forward or backward stepping.
    public func step(forward: Bool) {
        guard !adManager.isAdActive else { return }
        if forward && capabilities.canStepForward {
            player.step(by: 1)
        } else if !forward && capabilities.canStepBackward {
            player.step(by: -1)
        }
    }
    
    /// Sets playback rate speed multiplier.
    public func setPlaybackRate(_ rate: AKPlaybackRate) {
        player.play(at: rate)
        playbackRate = rate.rate
    }
    
    /// Cycles through repeat modes (.off -> .all -> .one).
    public func toggleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }
    
    /// Toggles shuffle mode.
    public func toggleShuffle() {
        isShuffled.toggle()
    }
    
    /// Expands the player to full-screen mode.
    public func expand() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            presentationMode = .fullScreen
        }
    }
    
    /// Collapses the player into the docked mini player bar.
    public func collapse() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            presentationMode = .miniPlayer
        }
    }
    
    /// Dismisses and hides the player surface completely.
    public func dismiss() {
        pause()
        withAnimation(.easeInOut(duration: 0.25)) {
            presentationMode = .hidden
        }
    }
    
    // MARK: - Auxiliary UI Navigation Commands (Forwarded to AKPlayerUIState)
    
    /// Toggles an auxiliary interface (Lyrics, Chapters, Queue, Equalizer) via uiState.
    public func toggleAuxiliary(_ sheet: AKPlayerAuxiliarySheet) {
        uiState.toggle(sheet, isAudioOnly: isAudioOnly)
    }
    
    /// Dismisses any active auxiliary overlay or sheet via uiState.
    public func dismissAuxiliary() {
        uiState.dismissAuxiliary()
    }
    
    /// Presents an auxiliary sheet or activates the overlay according to mode via uiState.
    public func presentSheet(_ sheet: AKPlayerAuxiliarySheet) {
        uiState.presentSheet(sheet, isAudioOnly: isAudioOnly)
    }
    
    /// Dismisses any active auxiliary sheet or inline overlay via uiState.
    public func dismissSheet() {
        uiState.dismissSheet()
    }
    
    // MARK: - Track Selection Commands (AKMediaTrackOption)
    
    /// Selects an audio track from the available options.
    public func selectAudioTrack(_ option: AKMediaTrackOption?) {
        self.selectedAudioTrack = option
        guard let media = currentMedia else { return }
        Task {
            try? await media.trackSelection.select(option, for: .audio)
        }
    }
    
    /// Selects a subtitle track or subtitle off from the available options.
    public func selectSubtitleTrack(_ option: AKMediaTrackOption?) {
        self.selectedSubtitleTrack = option
        guard let media = currentMedia else { return }
        Task {
            try? await media.trackSelection.select(option, for: .subtitle)
        }
    }
    
    public func refreshAvailableTracks() {
        guard let media = currentMedia else { return }
        Task {
            if let audible = try? await media.trackSelection.availableTracks(for: .audio) {
                self.availableAudioTracks = audible
            }
            if let selectedAudible = try? await media.trackSelection.selectedTrack(for: .audio) {
                self.selectedAudioTrack = selectedAudible
            }
            if let legible = try? await media.trackSelection.availableTracks(for: .subtitle) {
                self.availableSubtitleTracks = legible
            }
            if let selectedLegible = try? await media.trackSelection.selectedTrack(for: .subtitle) {
                self.selectedSubtitleTrack = selectedLegible
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func updateCapabilities(for media: any AKPlayable, explicitAudioOnly: Bool? = nil) {
        let isLive = media.isLive()
        if let explicit = explicitAudioOnly {
            self.isAudioOnly = explicit
        } else {
            let ext = media.url.pathExtension.lowercased()
            let audioExtensions: Set<String> = [
                "mp3", "m4a", "aac", "wav", "flac", "aiff", "alac", "caf", "ogg",
                "m4b", "wma", "opus", "weba", "mid", "midi"
            ]
            let urlString = media.url.absoluteString.lowercased()
            let titleString = (media.staticMetadata?.title ?? currentTitle).lowercased()
            let subtitleString = (media.staticMetadata?.artist ?? currentSubtitle).lowercased()
            
            let isAudioByMeta = media.staticMetadata?.mediaType == .audio
            let isAudioByExt = audioExtensions.contains(ext)
            let isAudioByKeyword = titleString.contains("audiobook") ||
            titleString.contains("audio-only") ||
            subtitleString.contains("audiobook") ||
            subtitleString.contains("audio-only") ||
            urlString.contains("audiobook") ||
            urlString.contains("audio_only")
            
            self.isAudioOnly = isAudioByMeta || isAudioByExt || isAudioByKeyword
        }
        
        self.capabilities = AKMediaCapabilities(
            canSeek: !isLive || (media.liveEdgeThreshold != nil),
            canStepForward: !isLive && !isAudioOnly,
            canStepBackward: !isLive && !isAudioOnly,
            canPause: true,
            canPlayFastForward: !isLive,
            canPlayFastReverse: false,
            isLive: isLive
        )
    }
    
    private func setupAdManagerCallbacks() {
        adManager.onSkipRequested = { [weak self] in
            guard let self = self else { return }
            self.player.interstitialService.cancelCurrent(resumptionOffset: .zero)
            self.adManager.endAdPod()
        }
    }
    
    // MARK: - Unified Player Event Observation
    
    private func startObservingPlayerEvents() {
        playerEventsTask?.cancel()
        playerEventsTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            for await event in self.player.events {
                guard !Task.isCancelled else { break }
                self.handlePlayerEvent(event)
            }
        }
    }
    
    private func handlePlayerEvent(_ event: AKPlayerEvent) {
        switch event {
        case let .stateDidChange(state):
            self.state = state
            self.autoPlay = player.autoPlay
            self.isPlaying = state.isPlaying
            self.isBuffering = state.isBuffering
            
            if state.isLoaded || state.isPlaying {
                let dur = player.currentItemDuration.seconds
                if !dur.isNaN && dur > 0 {
                    self.duration = dur
                }
                if let media = player.currentMedia {
                    self.chapters = media.chapterService.chapters
                    refreshAvailableTracks()
                }
            }
            
        case let .timeDidChange(currentTime):
            let sec = currentTime.seconds
            if !sec.isNaN && sec >= 0 {
                self.currentTime = sec
                if activeChapter == nil || !(activeChapter?.contains(seconds: sec) ?? false) {
                    self.activeChapter = chapters.first { $0.contains(seconds: sec) }
                }
            }
            if player.isLive, let media = player.currentMedia {
                isAtLiveEdge = media.isAtLiveEdge
                liveOffset = media.liveDrift ?? 0
                if let dvrDuration = media.dvrWindow?.duration.seconds, dvrDuration.isFinite, dvrDuration > 0 {
                    self.duration = dvrDuration
                }
            }
            
        case let .playbackRateDidChange(newRate, _):
            self.playbackRate = newRate.rate
            
        case .didReachEnd:
            if configuration.playback.autoplayNextInQueue {
                // Queue advancement
            }
            
        case let .media(mediaEvent):
            switch mediaEvent {
            case let .loadedTimeRangesDidChange(ranges):
                self.loadedTimeRanges = ranges
            case let .seekableTimeRangesDidChange(ranges):
                if self.capabilities.isLive, let last = ranges.last {
                    let dur = last.duration.seconds
                    if dur.isFinite && dur > 0 {
                        self.duration = dur
                    }
                }
            case let .durationDidChange(dur):
                let sec = dur.seconds
                if !sec.isNaN && sec.isFinite && sec > 0 && !self.capabilities.isLive {
                    self.duration = sec
                }
            default:
                break
            }
            
        case let .chapter(chapterEvent):
            switch chapterEvent {
            case let .chaptersDidChange(chapters):
                self.chapters = chapters
                if let current = activeChapter, !chapters.contains(where: { $0.id == current.id }) {
                    self.activeChapter = chapters.first { $0.contains(seconds: self.currentTime) }
                }
            case let .currentChapterDidChange(chapter):
                self.activeChapter = chapter
            }
            
        case let .trackSelection(trackEvent):
            switch trackEvent {
            case let .selectedTrackDidChange(option, for: trackType):
                if trackType == .audio {
                    self.selectedAudioTrack = option
                } else if trackType == .subtitle {
                    self.selectedSubtitleTrack = option
                }
            case let .availableTracksDidChange(options, for: trackType):
                if trackType == .audio {
                    self.availableAudioTracks = options
                } else if trackType == .subtitle {
                    self.availableSubtitleTracks = options
                }
            }
            
        case let .interstitial(interstitialEvent):
            handleInterstitialEvent(interstitialEvent)
            
        case let .mediaDidChange(media):
            self.currentMedia = media
            
        default:
            break
        }
    }
    
    private func handleInterstitialEvent(_ event: AKInterstitialEvent) {
        switch event {
        case .playbackStateDidChange(let state):
            if state == .playing {
                let currentItemCount = player.interstitialService.currentEvent?.templateItems.count ?? 1
                adManager.startAdPod(
                    index: 1,
                    total: currentItemCount,
                    duration: 15.0,
                    skipDelay: configuration.ads.skipCountdownDuration,
                    allowsSkip: configuration.ads.allowsAdSkip
                )
            } else if state == .finished || state == .idle {
                adManager.endAdPod()
            }
        case .progress(let progress):
            adManager.updateProgress(
                currentTime: progress.currentTime,
                duration: progress.duration,
                timeRemaining: progress.timeRemaining
            )
        case .adMarkersDidChange(let markers):
            self.interstitialMarkers = markers
        case .scheduleDidChange:
            self.interstitialMarkers = player.interstitialService.markers
        default:
            break
        }
    }
}

// MARK: - SwiftUI Preview Helper
extension AKPlayerCoordinator {
    /// Provides a fully populated mock coordinator for SwiftUI Previews.
    public static var previewMock: AKPlayerCoordinator {
        let coordinator = AKPlayerCoordinator()
        coordinator.currentTitle = "Interstellar: Beyond the Horizon"
        coordinator.currentSubtitle = "Christopher Nolan • 2024"
        coordinator.currentTime = 1420
        coordinator.duration = 7240
        coordinator.loadedTimeRanges = [CMTimeRange(start: .zero, duration: CMTime(seconds: 2800, preferredTimescale: 600))]
        coordinator.isPlaying = true
        coordinator.presentationMode = .fullScreen
        coordinator.capabilities = .fullVideo
        coordinator.interstitialMarkers = [
            AKInterstitialMarker(time: 300, duration: 15, title: "Ad 1"),
            AKInterstitialMarker(time: 1800, duration: 30, title: "Ad 2"),
            AKInterstitialMarker(time: 3600, duration: 15, title: "Ad 3")
        ]
        return coordinator
    }
    
    /// Provides a mock coordinator in active ad lockdown for testing ad overlays.
    public static var previewAdMock: AKPlayerCoordinator {
        let coordinator = previewMock
        coordinator.adManager.startAdPod(
            index: 1,
            total: 2,
            duration: 15,
            skipDelay: 4,
            allowsSkip: true,
            sponsor: "Acme Streaming Service"
        )
        return coordinator
    }
}

extension AKPlayerCoordinator {
    /// Provides a mock coordinator configured for audio playback previews.
    public static var previewAudioMock: AKPlayerCoordinator {
        let coordinator = AKPlayerCoordinator()
        coordinator.isAudioOnly = true
        coordinator.currentTitle = "Starboy (feat. Daft Punk)"
        coordinator.currentSubtitle = "The Weeknd • Starboy"
        coordinator.currentTime = 115
        coordinator.duration = 230
        coordinator.loadedTimeRanges = [CMTimeRange(start: .zero, duration: CMTime(seconds: 180, preferredTimescale: 600))]
        coordinator.isPlaying = true
        coordinator.presentationMode = .fullScreen
        coordinator.capabilities = AKMediaCapabilities(
            canSeek: true,
            canStepForward: false,
            canStepBackward: false,
            canPause: true,
            canPlayFastForward: true,
            canPlayFastReverse: false,
            isLive: false
        )
        return coordinator
    }
    
    /// Provides a mock coordinator configured with chapter markers.
    public static var previewChapterMock: AKPlayerCoordinator {
        let coordinator = previewMock
        coordinator.chapters = [
            AKChapter(
                id: 1,
                index: 0,
                title: "1. The Dust Bowl & The Secret Base",
                timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 900, preferredTimescale: 600))
            ),
            AKChapter(
                id: 2,
                index: 1,
                title: "2. Launch of the Endurance",
                timeRange: CMTimeRange(start: CMTime(seconds: 900, preferredTimescale: 600), duration: CMTime(seconds: 1200, preferredTimescale: 600))
            ),
            AKChapter(
                id: 3,
                index: 2,
                title: "3. Miller's Water Planet & Massive Wave",
                timeRange: CMTimeRange(start: CMTime(seconds: 2100, preferredTimescale: 600), duration: CMTime(seconds: 1500, preferredTimescale: 600))
            ),
            AKChapter(
                id: 4,
                index: 3,
                title: "4. Gargantua & The Tesseract",
                timeRange: CMTimeRange(start: CMTime(seconds: 3600, preferredTimescale: 600), duration: CMTime(seconds: 3640, preferredTimescale: 600))
            )
        ]
        coordinator.currentTime = 1420
        coordinator.activeChapter = coordinator.chapters[1]
        return coordinator
    }
}

extension AKPlayerCoordinator {
    public static var previewMiniVideoMock: AKPlayerCoordinator {
        let coordinator = previewMock
        coordinator.presentationMode = .miniPlayer
        return coordinator
    }
    
    public static var previewMiniAudioMock: AKPlayerCoordinator {
        let coordinator = previewAudioMock
        coordinator.presentationMode = .miniPlayer
        return coordinator
    }
}


// MARK: - Image + AKPlatformImage Convenience
public extension Image {
    init(platformImage: AKPlatformImage) {
#if os(macOS)
        self.init(nsImage: platformImage)
#else
        self.init(uiImage: platformImage)
#endif
    }
}

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
    @Published public internal(set) var state: AKPlayerState = .idle
    @Published public internal(set) var autoPlay: Bool = false
    @Published public internal(set) var currentTime: TimeInterval = 0
    @Published public internal(set) var duration: TimeInterval = 0
    @Published public internal(set) var loadedTimeRanges: [CMTimeRange] = []
    @Published public internal(set) var playerVolume: Float = 0
    @Published public internal(set) var playerIsMuted: Bool = false
    @Published public var playbackRate: Float = 1.0
    @Published public var aspectRatio: AKVideoAspectRatio = .fit
    @Published public var isAudioOnly: Bool = false
    
    // MARK: - Active Media & Metadata
    @Published public internal(set) var currentMedia: (any AKPlayable)?
    @Published public internal(set) var metadata: AKMediaStaticMetadata = .init()
    @Published public internal(set) var timedMetadata: [AVMetadataItem] = []
    
    public var currentTitle: String {
        metadata.title ?? ""
    }
    
    public var currentSubtitle: String {
        metadata.artist ?? ""
    }
    
    public var currentArtworkImage: AKPlatformImage? {
        metadata.artworkImage
    }
    
    public var currentArtworkURL: URL? {
        metadata.artworkURL
    }
    
    public var isPlaying: Bool {
        state.isPlaying
    }
    
    public var isBuffering: Bool {
        state.isBuffering
    }
    
    public var isLive: Bool {
        if let media = currentMedia {
            switch media.type {
            case let .stream(isLive):
                if !isLive { return false }
                return true
            case .clip:
                return false
            }
        }
        if duration == 0 || player.currentItem?.status != .readyToPlay {
            return false
        }
        return player.isLive
    }
    
    @Published public internal(set) var chapters: [AKChapter] = []
    @Published public internal(set) var activeChapter: AKChapter?
    public var interstitialMarkers: [AKInterstitialMarker] {
        adManager.markers
    }
    @Published public var repeatMode: AKRepeatMode = .off
    @Published public var isShuffled: Bool = false
    
    // MARK: - Media Tracks (from AKPlayer)
    @Published public internal(set) var availableAudioTracks: [AKMediaTrackOption] = []
    @Published public internal(set) var selectedAudioTrack: AKMediaTrackOption?
    @Published public internal(set) var availableSubtitleTracks: [AKMediaTrackOption] = []
    @Published public internal(set) var selectedSubtitleTrack: AKMediaTrackOption?
    @Published public internal(set) var availableClosedCaptionTracks: [AKMediaTrackOption] = []
    @Published public internal(set) var selectedClosedCaptionTrack: AKMediaTrackOption?
    @Published public internal(set) var availableAudioDescriptionTracks: [AKMediaTrackOption] = []
    @Published public internal(set) var selectedAudioDescriptionTrack: AKMediaTrackOption?
    @Published public internal(set) var availableVideoAlternativeTracks: [AKMediaTrackOption] = []
    @Published public internal(set) var selectedVideoAlternativeTrack: AKMediaTrackOption?
    
    // MARK: - Native Engine Capabilities
    @Published public internal(set) var capabilities: AKMediaCapabilities = .empty
    
    // MARK: - Configuration & Theming
    @Published public var configuration: AKPlayerUIConfiguration = .automatic
    @Published public var theme: AKPlayerTheme = .standard
    
    // MARK: - Domain Sub-Managers (Composed)
    public let equalizer: AKEqualizerManager
    public let adManager: AKAdManager
    
    var cancellables = Set<AnyCancellable>()
    var playerEventsTask: Task<Void, Never>?
    
    // MARK: - Initialization & Lifecycle
    
    public override convenience init() {
        self.init(configuration: .automatic, player: nil)
    }
    
    /// Primary initializer configuring both coordinator presentation and core engine.
    /// - Parameters:
    ///   - configuration: The aggregated UI & playback policy configuration.
    ///   - player: An optional pre-configured `AKPlayer` instance. If `nil`, an engine instance
    ///             is instantiated using settings bridged from `configuration`.
    public init(
        configuration: AKPlayerUIConfiguration = .automatic,
        player: AKPlayer? = nil
    ) {
        self.configuration = configuration
        self.player = player ?? AKPlayer(configuration: configuration.makeCorePlayerConfiguration())
        self.equalizer = AKEqualizerManager()
        self.adManager = AKAdManager()
        self.uiState = AKPlayerUIState()
        if configuration.playback.defaultPlaybackSpeed != 1.0 {
            self.playbackRate = configuration.playback.defaultPlaybackSpeed
        }
        super.init()
        setupAdManagerCallbacks()
        bindUIState()
        startObservingPlayerEvents()
        Task { @MainActor [weak self] in
            try? await self?.player.prepare()
        }
    }
    
    /// Convenience initializer supporting injected AKPlayer instances.
    public convenience init(player: AKPlayer) {
        self.init(configuration: .automatic, player: player)
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
}

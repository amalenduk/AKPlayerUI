//
//  AKPlayerCoordinator.swift
//  AKPlayerUI
//

import SwiftUI
import Observation
import Combine
import AVFoundation
import CoreMedia
import AKPlayer

/// Central player coordinator managing `AKPlayer` engine lifecycle, playback state,
/// multiplatform presentation modes, 10-band equalizer DSP, and native ad overlays.
/// Strictly relies on `AKPlayer` as the single core backbone.
@Observable
@MainActor
public final class AKPlayerCoordinator: NSObject, @unchecked Sendable {
    
    public static let shared = AKPlayerCoordinator()
    
    // MARK: - Core Playback Engine Backbone
    public let player: AKPlayer
    
    // MARK: - Presentation & Navigation
    public var presentationMode: AKPlayerPresentationMode = .hidden
    public var isAtLiveEdge: Bool = true
    public var liveOffset: TimeInterval = 0
    
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

    public var landscapeOverlayPlacement: AKOverlayPlacementMode {
        get { uiState.landscapeOverlayPlacement }
        set { uiState.landscapeOverlayPlacement = newValue }
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

    public var landscapeOverlayPlacementBinding: Binding<AKOverlayPlacementMode> {
        Binding(
            get: { self.uiState.landscapeOverlayPlacement },
            set: { self.uiState.landscapeOverlayPlacement = $0 }
        )
    }
    
    public var activeInlineOverlayBinding: Binding<AKPlayerAuxiliarySheet?> {
        Binding(
            get: { self.uiState.activeInlineOverlay },
            set: { self.uiState.activeInlineOverlay = $0 }
        )
    }
    
    // MARK: - Active Playback State (Driven by AKPlayer)
    public internal(set) var state: AKPlayerState = .idle
    public internal(set) var autoPlay: Bool = false
    public internal(set) var currentTime: TimeInterval = 0
    public internal(set) var duration: TimeInterval = 0
    public internal(set) var loadedTimeRanges: [CMTimeRange] = []
    public internal(set) var playerVolume: Float = 0
    public internal(set) var playerIsMuted: Bool = false
    public var playbackRate: Float = 1.0
    public var aspectRatio: AKVideoAspectRatio = .fit
    public var isAudioOnly: Bool = false
    public internal(set) var presentationSize: CGSize = .zero
    
    public var effectivePresentationSize: CGSize {
        if presentationSize != .zero {
            return presentationSize
        }
        if let itemSize = player.player.currentItem?.presentationSize, itemSize != .zero {
            return itemSize
        }
        return .zero
    }
    
    // MARK: - Active Media & Metadata
    public internal(set) var currentMedia: (any AKPlayable)?
    public internal(set) var metadata: AKMediaStaticMetadata = .init()
    public internal(set) var timedMetadata: [AVMetadataItem] = []
    
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
    
    public internal(set) var chapters: [AKChapter] = []
    public internal(set) var activeChapter: AKChapter?
    public var interstitialMarkers: [AKInterstitialMarker] {
        adManager.markers
    }
    public var repeatMode: AKRepeatMode = .off
    public var isShuffled: Bool = false
    
    // MARK: - Media Tracks (from AKPlayer)
    public internal(set) var availableAudioTracks: [AKMediaTrackOption] = []
    public internal(set) var selectedAudioTrack: AKMediaTrackOption?
    public internal(set) var availableSubtitleTracks: [AKMediaTrackOption] = []
    public internal(set) var selectedSubtitleTrack: AKMediaTrackOption?
    public internal(set) var availableClosedCaptionTracks: [AKMediaTrackOption] = []
    public internal(set) var selectedClosedCaptionTrack: AKMediaTrackOption?
    public internal(set) var availableAudioDescriptionTracks: [AKMediaTrackOption] = []
    public internal(set) var selectedAudioDescriptionTrack: AKMediaTrackOption?
    public internal(set) var availableVideoAlternativeTracks: [AKMediaTrackOption] = []
    public internal(set) var selectedVideoAlternativeTrack: AKMediaTrackOption?
    
    // MARK: - Native Engine Capabilities
    public internal(set) var capabilities: AKMediaCapabilities = .empty
    
    // MARK: - Configuration & Theming
    public var configuration: AKPlayerUIConfiguration = .automatic
    public var theme: AKPlayerTheme = .appleMusic
    
    // MARK: - Domain Sub-Managers (Composed)
    public let equalizer: AKEqualizerManager
    public let adManager: AKAdManager
    
    @ObservationIgnored var cancellables = Set<AnyCancellable>()
    @ObservationIgnored var playerEventsTask: Task<Void, Never>?
    
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
        self.uiState = AKPlayerUIState(
            placement: configuration.playback.overlayPlacement,
            landscapePlacement: configuration.playback.landscapeOverlayPlacement
        )
        if configuration.playback.defaultPlaybackSpeed != 1.0 {
            self.playbackRate = configuration.playback.defaultPlaybackSpeed
        }
        super.init()
        setupAdManagerCallbacks()
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
        // uiState is @Observable; nested properties are tracked automatically by Observation.
    }
    
    deinit {
        playerEventsTask?.cancel()
    }
}

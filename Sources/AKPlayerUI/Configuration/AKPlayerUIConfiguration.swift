//
//  AKPlayerUIConfiguration.swift
//  AKPlayerUI
//

import Foundation

/// Central aggregated configuration matrix defining behavioral policies, gestures, video geometry,
/// subtitle appearance, ad policies, and equalizer defaults for `AKPlayerUI`.
public struct AKPlayerUIConfiguration: Sendable, Equatable {
    public var playback: AKPlaybackConfiguration
    public var video: AKVideoConfiguration
    public var gestures: AKGestureConfiguration
    public var subtitles: AKSubtitleConfiguration
    public var ads: AKAdConfiguration
    public var equalizer: AKEqualizerConfiguration
    public var capabilities: AKCapabilityToggles

    public init(
        playback: AKPlaybackConfiguration = AKPlaybackConfiguration(),
        video: AKVideoConfiguration = AKVideoConfiguration(),
        gestures: AKGestureConfiguration = AKGestureConfiguration(),
        subtitles: AKSubtitleConfiguration = AKSubtitleConfiguration(),
        ads: AKAdConfiguration = AKAdConfiguration(),
        equalizer: AKEqualizerConfiguration = AKEqualizerConfiguration(),
        capabilities: AKCapabilityToggles = AKCapabilityToggles()
    ) {
        self.playback = playback
        self.video = video
        self.gestures = gestures
        self.subtitles = subtitles
        self.ads = ads
        self.equalizer = equalizer
        self.capabilities = capabilities
    }

    /// Default placement mode for auxiliary sheets (e.g. in portrait orientation).
    public var overlayPlacement: AKOverlayPlacementMode {
        get { playback.overlayPlacement }
        set { playback.overlayPlacement = newValue }
    }

    /// Placement mode for auxiliary sheets when the player is in landscape orientation.
    public var landscapeOverlayPlacement: AKOverlayPlacementMode {
        get { playback.landscapeOverlayPlacement }
        set { playback.landscapeOverlayPlacement = newValue }
    }


    /// Automatic adaptive baseline configuration.
    public static let automatic = AKPlayerUIConfiguration()

    /// Configuration profile optimized for on-demand cinema and TV series.
    public static let videoDefault = AKPlayerUIConfiguration(
        capabilities: .video
    )

    /// Configuration profile optimized for music and albums.
    public static let audioDefault = AKPlayerUIConfiguration(
        playback: AKPlaybackConfiguration(
            skipBackwardDuration: 15.0,
            skipForwardDuration: 15.0,
            openDirectlyInFullScreen: false
        ),
        capabilities: .audio
    )

    /// Configuration profile optimized for live broadcast streams with DVR rewind window.
    public static let liveDefault = AKPlayerUIConfiguration(
        capabilities: .liveStream
    )

    /// Configuration profile optimized for podcasts and spoken-word content.
    public static let podcastDefault = AKPlayerUIConfiguration(
        playback: AKPlaybackConfiguration(
            skipBackwardDuration: 15.0,
            skipForwardDuration: 30.0,
            defaultPlaybackSpeed: 1.25
        ),
        capabilities: .podcast
    )

    /// Configuration profile optimized for audiobooks.
    public static let audiobookDefault = AKPlayerUIConfiguration(
        playback: AKPlaybackConfiguration(
            skipBackwardDuration: 15.0,
            skipForwardDuration: 30.0,
            defaultPlaybackSpeed: 1.0
        ),
        capabilities: .podcast
    )
}

import AKPlayer

extension AKPlayerUIConfiguration {
    /// Converts this UI configuration into a corresponding core `AKPlayer` engine configuration.
    public func makeCorePlayerConfiguration() -> AKPlayer.Configuration {
        var coreConfig = AKPlayer.Configuration.default
        if capabilities.showsEqualizer == false && playback.defaultPlaybackSpeed != 1.0 {
            coreConfig.audioTimePitchAlgorithm = .timeDomain
        }
        return coreConfig
    }
}

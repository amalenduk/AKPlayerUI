//
//  AKPlayerConfiguration.swift
//  AKPlayerUI
//

import Foundation

/// Central aggregated configuration matrix defining behavioral policies, gestures, video geometry,
/// subtitle appearance, ad policies, and equalizer defaults for `AKPlayerUI`.
public struct AKPlayerConfiguration: Sendable, Equatable {
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

    /// Automatic adaptive baseline configuration.
    public static let automatic = AKPlayerConfiguration()

    /// Configuration profile optimized for on-demand cinema and TV series.
    public static let videoDefault = AKPlayerConfiguration(
        capabilities: .video
    )

    /// Configuration profile optimized for music and albums.
    public static let audioDefault = AKPlayerConfiguration(
        playback: AKPlaybackConfiguration(
            skipBackwardDuration: 15.0,
            skipForwardDuration: 15.0,
            openDirectlyInFullScreen: false
        ),
        capabilities: .audio
    )

    /// Configuration profile optimized for live broadcast streams with DVR rewind window.
    public static let liveDefault = AKPlayerConfiguration(
        capabilities: .liveStream
    )

    /// Configuration profile optimized for podcasts and spoken-word content.
    public static let podcastDefault = AKPlayerConfiguration(
        playback: AKPlaybackConfiguration(
            skipBackwardDuration: 15.0,
            skipForwardDuration: 30.0,
            defaultPlaybackSpeed: 1.25
        ),
        capabilities: .podcast
    )

    /// Configuration profile optimized for audiobooks.
    public static let audiobookDefault = AKPlayerConfiguration(
        playback: AKPlaybackConfiguration(
            skipBackwardDuration: 15.0,
            skipForwardDuration: 30.0,
            defaultPlaybackSpeed: 1.0
        ),
        capabilities: .podcast
    )
}

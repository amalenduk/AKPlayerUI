//
//  AKVideoConfiguration.swift
//  AKPlayerUI
//

import Foundation

/// Preferences governing video canvas sizing, display geometry, and floating mini player.
public struct AKVideoConfiguration: Sendable, Equatable {
    /// Default aspect ratio scaling mode (default: .fit).
    public var defaultAspectRatio: AKVideoAspectRatio

    /// Whether the video surface automatically rotates with device orientation changes.
    public var autoScreenRotation: Bool

    /// Whether picture-in-picture and floating docked mini player are enabled.
    public var allowsFloatingMiniPlayer: Bool

    /// Whether video brightness adjustments are persisted across playback sessions.
    public var remembersVideoBrightness: Bool

    /// Whether VideoToolbox hardware decoding is prioritized.
    public var enablesHardwareAcceleration: Bool

    public init(
        defaultAspectRatio: AKVideoAspectRatio = .fit,
        autoScreenRotation: Bool = true,
        allowsFloatingMiniPlayer: Bool = true,
        remembersVideoBrightness: Bool = true,
        enablesHardwareAcceleration: Bool = true
    ) {
        self.defaultAspectRatio = defaultAspectRatio
        self.autoScreenRotation = autoScreenRotation
        self.allowsFloatingMiniPlayer = allowsFloatingMiniPlayer
        self.remembersVideoBrightness = remembersVideoBrightness
        self.enablesHardwareAcceleration = enablesHardwareAcceleration
    }
}

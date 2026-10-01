//
//  AKPlaybackConfiguration.swift
//  AKPlayerUI
//

import Foundation

/// Developer and user preferences governing core playback behaviors.
public struct AKPlaybackConfiguration: Sendable, Equatable {
    /// Skip backward duration step in seconds (default: 10.0s).
    public var skipBackwardDuration: TimeInterval

    /// Skip forward duration step in seconds (default: 15.0s).
    public var skipForwardDuration: TimeInterval

    /// Whether playback opens directly into full screen or begins in a docked mini player.
    public var openDirectlyInFullScreen: Bool

    /// Whether audio playback should continue when the application moves to the background.
    public var continueAudioInBackground: Bool

    /// Default playback speed multiplier (default: 1.0x).
    public var defaultPlaybackSpeed: Float

    /// Whether to automatically advance to and begin playing the next item in the queue.
    public var autoplayNextInQueue: Bool

    /// Whether playback position is remembered and resumed across sessions.
    public var remembersPlaybackPosition: Bool

    public init(
        skipBackwardDuration: TimeInterval = 10.0,
        skipForwardDuration: TimeInterval = 15.0,
        openDirectlyInFullScreen: Bool = true,
        continueAudioInBackground: Bool = true,
        defaultPlaybackSpeed: Float = 1.0,
        autoplayNextInQueue: Bool = true,
        remembersPlaybackPosition: Bool = true
    ) {
        self.skipBackwardDuration = skipBackwardDuration
        self.skipForwardDuration = skipForwardDuration
        self.openDirectlyInFullScreen = openDirectlyInFullScreen
        self.continueAudioInBackground = continueAudioInBackground
        self.defaultPlaybackSpeed = defaultPlaybackSpeed
        self.autoplayNextInQueue = autoplayNextInQueue
        self.remembersPlaybackPosition = remembersPlaybackPosition
    }
}

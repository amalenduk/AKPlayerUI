//
//  AKCapabilityToggles.swift
//  AKPlayerUI
//

import Foundation

/// Granular capability and visibility toggles for player HUD controls.
public struct AKCapabilityToggles: Sendable, Equatable {
    public var showsPlayPause: Bool
    public var showsScrubber: Bool
    public var showsSkipButtons: Bool
    public var showsStepButtons: Bool
    public var showsSpeedPicker: Bool
    public var showsAirPlay: Bool
    public var showsPictureInPicture: Bool
    public var showsSubtitlesButton: Bool
    public var showsAudioTrackButton: Bool
    public var showsAspectSelector: Bool
    public var showsEqualizer: Bool
    public var showsChapters: Bool
    public var showsSleepTimer: Bool
    public var showsLiveBadge: Bool

    public init(
        showsPlayPause: Bool = true,
        showsScrubber: Bool = true,
        showsSkipButtons: Bool = true,
        showsStepButtons: Bool = true,
        showsSpeedPicker: Bool = true,
        showsAirPlay: Bool = true,
        showsPictureInPicture: Bool = true,
        showsSubtitlesButton: Bool = true,
        showsAudioTrackButton: Bool = true,
        showsAspectSelector: Bool = true,
        showsEqualizer: Bool = true,
        showsChapters: Bool = true,
        showsSleepTimer: Bool = true,
        showsLiveBadge: Bool = false
    ) {
        self.showsPlayPause = showsPlayPause
        self.showsScrubber = showsScrubber
        self.showsSkipButtons = showsSkipButtons
        self.showsStepButtons = showsStepButtons
        self.showsSpeedPicker = showsSpeedPicker
        self.showsAirPlay = showsAirPlay
        self.showsPictureInPicture = showsPictureInPicture
        self.showsSubtitlesButton = showsSubtitlesButton
        self.showsAudioTrackButton = showsAudioTrackButton
        self.showsAspectSelector = showsAspectSelector
        self.showsEqualizer = showsEqualizer
        self.showsChapters = showsChapters
        self.showsSleepTimer = showsSleepTimer
        self.showsLiveBadge = showsLiveBadge
    }

    /// Default profile for on-demand video playback.
    public static let video = AKCapabilityToggles(
        showsPlayPause: true,
        showsScrubber: true,
        showsSkipButtons: true,
        showsStepButtons: true,
        showsSpeedPicker: true,
        showsAirPlay: true,
        showsPictureInPicture: true,
        showsSubtitlesButton: true,
        showsAudioTrackButton: true,
        showsAspectSelector: true,
        showsEqualizer: true,
        showsChapters: true,
        showsSleepTimer: false,
        showsLiveBadge: false
    )

    /// Default profile for audio/music playback.
    public static let audio = AKCapabilityToggles(
        showsPlayPause: true,
        showsScrubber: true,
        showsSkipButtons: true,
        showsStepButtons: false,
        showsSpeedPicker: false,
        showsAirPlay: true,
        showsPictureInPicture: false,
        showsSubtitlesButton: false,
        showsAudioTrackButton: false,
        showsAspectSelector: false,
        showsEqualizer: true,
        showsChapters: false,
        showsSleepTimer: true,
        showsLiveBadge: false
    )

    /// Default profile for live broadcast streams.
    public static let liveStream = AKCapabilityToggles(
        showsPlayPause: true,
        showsScrubber: true,
        showsSkipButtons: true,
        showsStepButtons: false,
        showsSpeedPicker: false,
        showsAirPlay: true,
        showsPictureInPicture: true,
        showsSubtitlesButton: true,
        showsAudioTrackButton: true,
        showsAspectSelector: true,
        showsEqualizer: false,
        showsChapters: false,
        showsSleepTimer: false,
        showsLiveBadge: true
    )

    /// Default profile for podcast and spoken-word audio.
    public static let podcast = AKCapabilityToggles(
        showsPlayPause: true,
        showsScrubber: true,
        showsSkipButtons: true,
        showsStepButtons: false,
        showsSpeedPicker: true,
        showsAirPlay: true,
        showsPictureInPicture: false,
        showsSubtitlesButton: false,
        showsAudioTrackButton: false,
        showsAspectSelector: false,
        showsEqualizer: true,
        showsChapters: true,
        showsSleepTimer: true,
        showsLiveBadge: false
    )
}

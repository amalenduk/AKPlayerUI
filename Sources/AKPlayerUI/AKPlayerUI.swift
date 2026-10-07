//
//  AKPlayerUI.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Public namespace for AKPlayerUI one-liner API.
/// Enables callers to trigger playback from anywhere in their app with zero setup headache.
/// Uses `AKPlayer` as the single core backbone.
public enum AKPlayerUI {

    /// Active shared coordinator instance.
    @MainActor
    public static var shared: AKPlayerCoordinator {
        AKPlayerCoordinator.shared
    }

    /// Active UI and playback presentation configuration.
    @MainActor
    public static var configuration: AKPlayerUIConfiguration {
        get { shared.configuration }
        set { shared.configuration = newValue }
    }

    /// Loads and begins playback from a URL, automatically presenting the player interface.
    @MainActor
    public static func load(
        url: URL,
        title: String? = nil,
        subtitle: String? = nil,
        artworkURL: URL? = nil,
        presentationMode: AKPlayerPresentationMode? = nil,
        isAudioOnly: Bool? = nil
    ) {
        shared.load(
            url: url,
            title: title,
            subtitle: subtitle,
            artworkURL: artworkURL,
            presentationMode: presentationMode,
            isAudioOnly: isAudioOnly
        )
    }

    /// Loads any `AKPlayable` object (such as `AKMedia`) directly.
    @MainActor
    public static func load(
        media: any AKPlayable,
        autoPlay: Bool = true,
        at startPosition: AKSeekTarget? = nil,
        presentationMode: AKPlayerPresentationMode? = nil,
        isAudioOnly: Bool? = nil
    ) {
        shared.load(
            media: media,
            autoPlay: autoPlay,
            at: startPosition,
            presentationMode: presentationMode,
            isAudioOnly: isAudioOnly
        )
    }

    /// Resumes active playback.
    @MainActor
    public static func play() {
        shared.play()
    }

    /// Pauses active playback.
    @MainActor
    public static func pause() {
        shared.pause()
    }

    /// Toggles play / pause state.
    @MainActor
    public static func togglePlayPause() {
        shared.togglePlayPause()
    }

    /// Seeks to a specific timestamp in seconds.
    @MainActor
    public static func seek(to seconds: TimeInterval) {
        shared.seek(to: seconds)
    }

    /// Jumps directly to the live edge of a live stream.
    @MainActor
    public static func jumpToLive() {
        shared.jumpToLive()
    }

    /// Sets playback speed multiplier.
    @MainActor
    public static func setPlaybackRate(_ rate: AKPlaybackRate) {
        shared.setPlaybackRate(rate)
    }

    /// Cycles repeat mode.
    @MainActor
    public static func toggleRepeatMode() {
        shared.toggleRepeatMode()
    }

    /// Dismisses the player surface completely.
    @MainActor
    public static func dismiss() {
        shared.dismiss()
    }
}

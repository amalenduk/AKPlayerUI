//
//  AKPlayerCoordinator+Commands.swift
//  AKPlayerUI
//

import SwiftUI
import CoreMedia
import AVFoundation
import AKPlayer

extension AKPlayerCoordinator {
    
    // MARK: - High-Level Playback Commands (Zero-Boilerplate Entry Point)
    
    /// Loads and begins playback of an `AKPlayable` item (such as `AKMedia`), automatically applying presentation mode.
    public func load(
        media: any AKPlayable,
        autoPlay: Bool = true,
        at startPosition: AKSeekTarget? = nil,
        presentationMode: AKPlayerPresentationMode? = nil,
        isAudioOnly: Bool? = nil
    ) {
        self.currentMedia = media
        var initialMetadata = media.metadataProvider.staticMetadata
        if initialMetadata.title == nil || initialMetadata.title?.isEmpty == true {
            initialMetadata.title = media.url.deletingPathExtension().lastPathComponent
        }
        self.metadata = initialMetadata
        self.timedMetadata = media.metadataProvider.timedMetadata
        
        // Media classification and initial capabilities
        self.isAudioOnly = isAudioOnly ?? media.isAudioOnly
        self.capabilities = AKMediaCapabilities.empty
        
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
        isAudioOnly: Bool? = nil
    ) {
        let isLive = url.absoluteString.contains("live")
        let mediaType: AKMediaType = isLive ? .stream(isLive: true) : .clip
        let media = AKMedia(url: url, type: mediaType)
        load(media: media, presentationMode: presentationMode, isAudioOnly: isAudioOnly)
        
        if title != nil || subtitle != nil || artworkURL != nil {
            var updated = self.metadata
            if let title { updated.title = title }
            if let subtitle { updated.artist = subtitle }
            if let artworkURL { updated.artworkURL = artworkURL }
            self.metadata = updated
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
        guard capabilities.canSeek else { return }
        
        if isLive {
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
            if player.interstitialService.integratedTimeline != nil {
                _ = await player.seek(to: .seconds(clamped), scope: .integrated)
            } else {
                _ = await player.seek(to: .seconds(clamped), scope: .primary)
            }
        }
    }
    
    /// Jumps directly to the live edge of a live stream.
    public func jumpToLive() {
        guard isLive else { return }
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
        guard capabilities.canSeek else { return }
        if isLive && isAtLiveEdge {
            return
        }
        seek(to: currentTime + configuration.playback.skipForwardDuration)
    }
    
    /// Relative seek backward by configured step.
    public func skipBackward() {
        guard capabilities.canSeek else { return }
        seek(to: currentTime - configuration.playback.skipBackwardDuration)
    }
    
    /// Steps a single frame forward or backward (video only).
    public func step(forward: Bool) {
        guard capabilities.canStepForward || capabilities.canStepBackward else { return }
        if forward {
            player.step(by: 1)
        } else {
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
    
    /// Selects a track option for any supported track type.
    public func selectTrack(_ option: AKMediaTrackOption?, for type: AKTrackType) {
        switch type {
        case .audio:
            self.selectedAudioTrack = option
        case .subtitle:
            self.selectedSubtitleTrack = option
        case .closedCaption:
            self.selectedClosedCaptionTrack = option
        case .audioDescription:
            self.selectedAudioDescriptionTrack = option
        case .videoAlternative:
            self.selectedVideoAlternativeTrack = option
        }
        guard let media = currentMedia else { return }
        Task {
            try? await media.trackSelection.select(option, for: type)
        }
    }

    /// Selects an audio track from the available options.
    public func selectAudioTrack(_ option: AKMediaTrackOption?) {
        selectTrack(option, for: .audio)
    }
    
    /// Selects a subtitle track or subtitle off from the available options.
    public func selectSubtitleTrack(_ option: AKMediaTrackOption?) {
        selectTrack(option, for: .subtitle)
    }

    /// Selects a closed caption track from the available options.
    public func selectClosedCaptionTrack(_ option: AKMediaTrackOption?) {
        selectTrack(option, for: .closedCaption)
    }

    /// Selects an audio description track from the available options.
    public func selectAudioDescriptionTrack(_ option: AKMediaTrackOption?) {
        selectTrack(option, for: .audioDescription)
    }

    /// Selects an alternative video track from the available options.
    public func selectVideoAlternativeTrack(_ option: AKMediaTrackOption?) {
        selectTrack(option, for: .videoAlternative)
    }
    
    public func refreshAvailableTracks() {
        guard let media = currentMedia else { return }
        Task {
            let types: [AKTrackType] = [.audio, .subtitle, .closedCaption, .audioDescription, .videoAlternative]
            for type in types {
                if let available = try? await media.trackSelection.availableTracks(for: type) {
                    switch type {
                    case .audio: self.availableAudioTracks = available
                    case .subtitle: self.availableSubtitleTracks = available
                    case .closedCaption: self.availableClosedCaptionTracks = available
                    case .audioDescription: self.availableAudioDescriptionTracks = available
                    case .videoAlternative: self.availableVideoAlternativeTracks = available
                    }
                }
                if let selected = try? await media.trackSelection.selectedTrack(for: type) {
                    switch type {
                    case .audio: self.selectedAudioTrack = selected
                    case .subtitle: self.selectedSubtitleTrack = selected
                    case .closedCaption: self.selectedClosedCaptionTrack = selected
                    case .audioDescription: self.selectedAudioDescriptionTrack = selected
                    case .videoAlternative: self.selectedVideoAlternativeTrack = selected
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    func setupAdManagerCallbacks() {
        adManager.onSkipRequested = { [weak self] in
            guard let self = self else { return }
            self.player.interstitialService.cancelCurrent(resumptionOffset: .zero)
            self.adManager.endAdPod()
        }
    }
}

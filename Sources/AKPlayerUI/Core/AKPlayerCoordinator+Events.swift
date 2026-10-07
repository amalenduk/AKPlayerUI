//
//  AKPlayerCoordinator+Events.swift
//  AKPlayerUI
//

import SwiftUI
import CoreMedia
import AVFoundation
import AKPlayer

extension AKPlayerCoordinator {
    
    private func reevaluateMediaCapabilities() {
        guard let currentMedia,
              let playerItem = currentMedia.playerItem else { capabilities = .empty; return }
        capabilities = AKMediaCapabilities(canSeek: currentMedia.canSeek,
                                           canStepForward: playerItem.canStepForward,
                                           canStepBackward: playerItem.canStepBackward,
                                           canPlayReverse: playerItem.canPlayReverse,
                                           canPlayFastForward: playerItem.canPlayFastForward,
                                           canPlayFastReverse: playerItem.canPlayFastReverse,
                                           canPlaySlowForward: playerItem.canPlaySlowForward,
                                           canPlaySlowReverse: playerItem.canPlaySlowReverse
        )
    }
    
    private func reevaluateIntertialCapabilities() {
        guard player.interstitialService.isPlayingInterstitial else { capabilities = .empty; return }
        capabilities = AKMediaCapabilities(canSeek: player.interstitialService.canSeek,
                                           canPlayFastForward: player.interstitialService.canFastForward,
        )
    }
    
    
    // MARK: - Unified Player Event Observation
    
    func startObservingPlayerEvents() {
        playerEventsTask?.cancel()
        playerEventsTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            for await event in self.player.events {
                guard !Task.isCancelled else { break }
                self.handlePlayerEvent(event)
            }
        }
    }
    
    func handlePlayerEvent(_ event: AKPlayerEvent) {
        switch event {
        case .stateDidChange,
                .timeDidChange,
                .playbackRateDidChange,
                .didReachEnd,
                .mediaDidChange,
                .playerItemNotification(_),
                .boundaryReached(at: _),
                .volumeDidChange(_),
                .muteStatusDidChange(isMuted: _),
                .sharePlayStateDidChange(_),
                .commandUnavailable(reason: _),
                .didFail(with: _):
            handleCorePlaybackEvent(event)
            
        case let .media(mediaEvent):
            handleMediaEvent(mediaEvent)
            
        case let .trackSelection(trackEvent):
            handleTrackSelectionEvent(trackEvent)
            
        case let .chapter(chapterEvent):
            handleChapterEvent(chapterEvent)
            
        case let .metadata(metaEvent):
            handleMetadataEvent(metaEvent)
            
        case let .interstitial(interstitialEvent):
            handleInterstitialEvent(interstitialEvent)
        }
    }
    
    // MARK: - Core Playback Events
    
    private func handleCorePlaybackEvent(_ event: AKPlayerEvent) {
        switch event {
        case let .stateDidChange(state):
            self.state = state
            self.autoPlay = player.autoPlay
            
        case let .timeDidChange(currentTime):
            guard player.interstitialService.integratedTimeline == nil else { return }
            
            let sec = currentTime.seconds
            if !sec.isNaN && sec >= 0 {
                self.currentTime = sec
                if !chapters.isEmpty && !(activeChapter?.contains(seconds: sec) ?? false) {
                    self.activeChapter = currentMedia?.chapterService.currentChapter(at: currentTime)
                }
            }
            if self.isLive, let media = currentMedia {
                self.isAtLiveEdge = media.isAtLiveEdge
                self.liveOffset = media.liveDrift ?? 0
            }
            
        case let .playbackRateDidChange(newRate, _):
            self.playbackRate = newRate.rate
            
        case .didReachEnd:
            if configuration.playback.autoplayNextInQueue {
                // Queue advancement
            }
            
        case let .mediaDidChange(media):
            self.currentMedia = media
            
        case .playerItemNotification(_):
            break
        case .boundaryReached(_):
            break
        case .volumeDidChange(let volume):
            playerVolume = volume
        case .muteStatusDidChange(isMuted: let isMuted):
            playerIsMuted = isMuted
        case .sharePlayStateDidChange(_):
            break
        case .commandUnavailable(let reason):
            print(reason.description)
        case .didFail(_):
            break
        default:
            break
        }
    }
    
    // MARK: - Media Stream Events
    
    private func handleMediaEvent(_ event: AKMediaEvent) {
        switch event {
        case let .loadedTimeRangesDidChange(ranges):
            self.loadedTimeRanges = ranges
            
        case let .seekableTimeRangesDidChange(ranges):
            guard player.interstitialService.integratedTimeline == nil else {
                if !player.interstitialService.isPlayingInterstitial {
                    self.capabilities.canSeek = currentMedia?.canSeek ?? false
                }
                return
            }
            if self.isLive, let last = ranges.last {
                let dur = last.duration.seconds
                if dur.isFinite && dur > 0 {
                    self.duration = dur
                }
            }
            self.capabilities.canSeek = currentMedia?.canSeek ?? false
            
        case let .durationDidChange(dur):
            guard player.interstitialService.integratedTimeline == nil else { return }
            if !self.isLive {
                let sec = dur.seconds
                if !sec.isNaN && sec.isFinite && sec > 0 {
                    self.duration = sec
                }
            }
            
        case let .capabilityDidChange(capability, isSupported):
            switch capability {
            case .stepForward:
                self.capabilities.canStepForward = isSupported && !self.isAudioOnly
            case .stepBackward:
                self.capabilities.canStepBackward = isSupported && !self.isAudioOnly
            case .playReverse:
                self.capabilities.canPlayReverse = isSupported
            case .playFastForward:
                self.capabilities.canPlayFastForward = isSupported
            case .playFastReverse:
                self.capabilities.canPlayFastReverse = isSupported
            case .playSlowForward:
                self.capabilities.canPlaySlowForward = isSupported
            case .playSlowReverse:
                self.capabilities.canPlaySlowReverse = isSupported
            }
            
        default:
            break
        }
    }
    
    // MARK: - Track Selection Events
    
    private func handleTrackSelectionEvent(_ event: AKTrackSelectionEvent) {
        switch event {
        case let .selectedTrackDidChange(option, for: trackType):
            switch trackType {
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
            
        case let .availableTracksDidChange(options, for: trackType):
            switch trackType {
            case .audio:
                self.availableAudioTracks = options
            case .subtitle:
                self.availableSubtitleTracks = options
            case .closedCaption:
                self.availableClosedCaptionTracks = options
            case .audioDescription:
                self.availableAudioDescriptionTracks = options
            case .videoAlternative:
                self.availableVideoAlternativeTracks = options
            }
        }
    }
    
    // MARK: - Chapter Events
    
    private func handleChapterEvent(_ event: AKChapterEvent) {
        switch event {
        case let .chaptersDidChange(chapters):
            self.chapters = chapters
            self.activeChapter = chapters.first { $0.contains(seconds: self.currentTime) }
        }
    }
    
    // MARK: - Metadata Events
    
    private func handleMetadataEvent(_ event: AKMediaMetadataEvent) {
        switch event {
        case let .staticMetadataDidChange(newMeta):
            var updated = newMeta
            if updated.title == nil || updated.title?.isEmpty == true {
                updated.title = currentMedia?.url.deletingPathExtension().lastPathComponent
            }
            self.metadata = updated
            
        case let .timedMetadataDidChange(items):
            self.timedMetadata = items
        }
    }
    
    // MARK: - Interstitial Events
    
    private func handleInterstitialEvent(_ event: AKInterstitialEvent) {
        switch event {
        case .willStart:
            let marker = player.interstitialService.currentMarker
            let currentIndex = player.interstitialService.currentItemIndex
            let totalAds = marker?.templateItemCount ?? 1
            let duration = marker?.duration ?? 0
            let skipDelay = configuration.ads.skipCountdownDuration
            
            let adAllowsSeek = marker?.canSeek ?? player.interstitialService.canSeek
            var allowsSkip = configuration.ads.allowsAdSkip && adAllowsSeek
            
            reevaluateIntertialCapabilities()
            
            if duration > 0 && duration <= skipDelay {
                allowsSkip = false
            }
            
            adManager.startAdPod(
                index: currentIndex,
                total: totalAds,
                duration: duration,
                skipDelay: skipDelay,
                allowsSkip: allowsSkip
            )
            
        case .didStart:
            break
            
        case .didFinish:
            adManager.endAdPod()
            reevaluateMediaCapabilities()
            
        case let .progress(progress):
            adManager.updateProgress(
                currentTime: progress.currentTime,
                duration: progress.duration,
                timeRemaining: progress.timeRemaining
            )
            
        case let .adMarkersDidChange(markers):
            adManager.markers = markers
            
        case .scheduleDidChange:
            break
            
        case let .integratedTimeline(timelineEvent):
            switch timelineEvent {
            case let .timeUpdated(current, _, dur):
                if dur > 0 {
                    self.duration = dur
                } else if self.isLive, let dvrDur = currentMedia?.dvrWindow?.duration.seconds, dvrDur > 0 {
                    self.duration = dvrDur
                }
                self.currentTime = current
                
                if self.isLive {
                    let threshold = currentMedia?.liveEdgeThreshold ?? 4.0
                    let drift = max(0, self.duration - current)
                    self.liveOffset = drift
                    self.isAtLiveEdge = drift <= threshold
                }
                
                if !chapters.isEmpty {
                    self.activeChapter = currentMedia?.chapterService.currentChapter(at: player.currentTime)
                }
                
            case .segmentsUpdated, .snapshotOutOfSync:
                break
            }
            
        case let .playbackStateDidChange(state):
            adManager.interstitialPlaybackState = state
        }
    }
}

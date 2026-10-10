//
//  AKPlayerAuxiliarySheet.swift
//  AKPlayerUI
//

import Foundation

/// Auxiliary sheets and overlay drawers that can be presented from the player HUD.
public enum AKPlayerAuxiliarySheet: String, Identifiable, Sendable {
    case queue
    case lyrics
    case equalizer
    case chapters
    case audioTracks
    case subtitleTracks
    case trackSelection
    case details
    case playbackSpeed
    case moreOptions

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .queue:          return "Queue"
        case .lyrics:         return "Lyrics"
        case .equalizer:      return "10-Band Graphic Equalizer"
        case .chapters:       return "Chapters"
        case .audioTracks:    return "Audio Tracks"
        case .subtitleTracks: return "Subtitles"
        case .trackSelection: return "Audio & Subtitles"
        case .details:        return "Media Details"
        case .playbackSpeed:  return "Playback Speed"
        case .moreOptions:    return "More Options"
        }
    }

    public var badge: String {
        title
    }

    @MainActor
    public func badge(coordinator: AKPlayerCoordinator) -> String {
        title
    }

    @MainActor
    public func displayTitle(coordinator: AKPlayerCoordinator) -> String {
        title
    }

    public var systemIconName: String {
        switch self {
        case .queue:          return "list.bullet"
        case .lyrics:         return "quote.bubble"
        case .equalizer:      return "slider.vertical.3"
        case .chapters:       return "bookmark"
        case .audioTracks:    return "speaker.wave.2.fill"
        case .subtitleTracks: return "captions.bubble.fill"
        case .trackSelection: return "waveform.badge.magnifyingglass"
        case .details:        return "info.circle"
        case .playbackSpeed:  return "speedometer"
        case .moreOptions:    return "line.3.horizontal"
        }
    }
}

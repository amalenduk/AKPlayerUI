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
    case trackSelection
    case details

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .queue:          return "Up Next"
        case .lyrics:         return "Lyrics"
        case .equalizer:      return "10-Band Equalizer"
        case .chapters:       return "Chapters"
        case .trackSelection: return "Audio & Subtitles"
        case .details:        return "Media Information"
        }
    }

    public var systemIconName: String {
        switch self {
        case .queue:          return "list.bullet"
        case .lyrics:         return "quote.bubble"
        case .equalizer:      return "slider.vertical.3"
        case .chapters:       return "bookmark"
        case .trackSelection: return "waveform.badge.magnifyingglass"
        case .details:        return "info.circle"
        }
    }
}

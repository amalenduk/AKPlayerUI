//
//  AKSubtitleConfiguration.swift
//  AKPlayerUI
//

import SwiftUI

/// Available subtitle font typography styles.
public enum AKSubtitleFontFamily: String, CaseIterable, Identifiable, Sendable {
    case system = "System"
    case rounded = "Rounded"
    case serif = "Serif"
    case monospaced = "Monospaced"

    public var id: String { rawValue }

    public var fontDesign: Font.Design {
        switch self {
        case .system:     return .default
        case .rounded:    return .rounded
        case .serif:      return .serif
        case .monospaced: return .monospaced
        }
    }
}

/// Preferences governing subtitle display, typography, and sidecar parsing.
public struct AKSubtitleConfiguration: Sendable, Equatable {
    /// Whether subtitles and closed captions are shown by default or completely hidden.
    public var isSubtitlesEnabled: Bool

    /// Subtitle font scale size in points (range: 12.0 – 36.0 pt, default: 18.0 pt).
    public var fontSize: CGFloat

    /// Subtitle font typography family.
    public var fontFamily: AKSubtitleFontFamily

    /// Whether adjacent sidecar subtitle files (.srt, .vtt) are automatically discovered.
    public var autoLoadSidecarFiles: Bool

    public init(
        isSubtitlesEnabled: Bool = true,
        fontSize: CGFloat = 18.0,
        fontFamily: AKSubtitleFontFamily = .system,
        autoLoadSidecarFiles: Bool = true
    ) {
        self.isSubtitlesEnabled = isSubtitlesEnabled
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.autoLoadSidecarFiles = autoLoadSidecarFiles
    }
}

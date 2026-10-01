//
//  AKTypography.swift
//  AKPlayerUI
//

import SwiftUI

/// Typographic hierarchy tokens for titles, subtitles, timecodes, labels, and badges.
public struct AKTypography: Sendable {
    // MARK: - Standard Typographic Scales
    public var largeTitle: Font
    public var title1: Font
    public var title2: Font
    public var title3: Font
    public var headline: Font
    public var subheadline: Font
    public var body: Font
    public var callout: Font
    public var footnote: Font
    public var caption1: Font
    public var caption2: Font

    // MARK: - Monospaced Timecodes & Numeric Scrubbing
    public var timecode: Font
    public var timecodeSmall: Font

    // MARK: - Badges, Overlays & Buttons
    public var badge: Font
    public var badgeSmall: Font
    public var button: Font

    // MARK: - Specialized (e.g. Synced Lyrics)
    public var lyricsActive: Font
    public var lyricsInactive: Font

    // MARK: - Semantic Convenience Aliases
    public var titleFont: Font { title2 }
    public var subtitleFont: Font { subheadline }
    public var timecodeFont: Font { timecode }
    public var badgeFont: Font { badge }
    public var buttonFont: Font { button }

    public static let standard = AKTypography()
    public static let `default` = AKTypography()

    public init(
        largeTitle: Font = .largeTitle.weight(.bold),
        title1: Font = .title.weight(.bold),
        title2: Font = .title2.weight(.semibold),
        title3: Font = .title3.weight(.semibold),
        headline: Font = .headline.weight(.semibold),
        subheadline: Font = .subheadline,
        body: Font = .body,
        callout: Font = .callout,
        footnote: Font = .footnote,
        caption1: Font = .caption,
        caption2: Font = .caption2,
        timecode: Font = .system(.body, design: .monospaced).weight(.medium),
        timecodeSmall: Font = .system(.caption, design: .monospaced).weight(.medium),
        badge: Font = .system(size: 11, weight: .bold, design: .rounded),
        badgeSmall: Font = .system(size: 9, weight: .bold, design: .rounded),
        button: Font = .system(size: 14, weight: .semibold, design: .default),
        lyricsActive: Font = .system(size: 28, weight: .bold, design: .default),
        lyricsInactive: Font = .system(size: 22, weight: .medium, design: .default)
    ) {
        self.largeTitle = largeTitle
        self.title1 = title1
        self.title2 = title2
        self.title3 = title3
        self.headline = headline
        self.subheadline = subheadline
        self.body = body
        self.callout = callout
        self.footnote = footnote
        self.caption1 = caption1
        self.caption2 = caption2
        self.timecode = timecode
        self.timecodeSmall = timecodeSmall
        self.badge = badge
        self.badgeSmall = badgeSmall
        self.button = button
        self.lyricsActive = lyricsActive
        self.lyricsInactive = lyricsInactive
    }
}

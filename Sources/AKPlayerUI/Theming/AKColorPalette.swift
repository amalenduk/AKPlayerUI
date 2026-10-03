//
//  AKColorPalette.swift
//  AKPlayerUI
//

import SwiftUI

/// Semantic color tokens for the player interface and ad states.
public struct AKColorPalette: Sendable, Equatable {
    /// Active interactive accent color (default: vibrant Cyan/Blue).
    public var accent: Color

    /// Inactive background timeline rail color.
    public var progressRailRemaining: Color

    /// Buffered media progress fill color.
    public var progressRailBuffered: Color

    /// Marker color for ad cue break points along the timeline (default: Amber/Gold).
    public var adBreakIndicator: Color

    /// Progress track color during active ad lockdown (default: Warm Amber).
    public var adActiveProgress: Color

    /// Primary foreground text color.
    public var textPrimary: Color

    /// Secondary subtitle/metadata text color.
    public var textSecondary: Color

    /// Semi-transparent dark glass fill for HUD bars.
    public var hudBackground: Color

    /// Ultra-subtle border stroke color for glass elements.
    public var glassBorder: Color

    /// Background / fill color for play action buttons.
    public var playerActionButtons: Color
    
    public var playerActionBackgroundButtons: Color

    // MARK: - Aliases for Foreground Hierarchy
    public var foregroundPrimary: Color { textPrimary }
    public var foregroundSecondary: Color { textSecondary }
    public var foregroundTertiary: Color { textSecondary.opacity(0.6) }

    public init(
        accent: Color = Color(red: 0.15, green: 0.58, blue: 1.0), // Electric Blue
        progressRailRemaining: Color = Color.white.opacity(0.2),
        progressRailBuffered: Color = Color.white.opacity(0.4),
        adBreakIndicator: Color = Color(red: 1.0, green: 0.76, blue: 0.03), // Gold
        adActiveProgress: Color = Color(red: 1.0, green: 0.65, blue: 0.0), // Amber
        textPrimary: Color = .white,
        textSecondary: Color = Color.white.opacity(0.7),
        hudBackground: Color = Color.black.opacity(0.4),
        glassBorder: Color = Color.white.opacity(0.15),
        playActionButtons: Color = Color.yellow,
        playerActionBackgroundButtons: Color = Color.white.opacity(0.18)
    ) {
        self.accent = accent
        self.progressRailRemaining = progressRailRemaining
        self.progressRailBuffered = progressRailBuffered
        self.adBreakIndicator = adBreakIndicator
        self.adActiveProgress = adActiveProgress
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.hudBackground = hudBackground
        self.glassBorder = glassBorder
        self.playerActionButtons = playActionButtons
        self.playerActionBackgroundButtons = playerActionBackgroundButtons
    }

    public static let standard = AKColorPalette()

    public static let vibrant = AKColorPalette(
        accent: Color(red: 0.85, green: 0.15, blue: 0.95), // Neon Purple/Pink
        adBreakIndicator: Color(red: 1.0, green: 0.84, blue: 0.0),
        adActiveProgress: Color(red: 1.0, green: 0.45, blue: 0.1),
        playActionButtons: Color.yellow
    )

    public static let highContrast = AKColorPalette(
        accent: Color.yellow,
        progressRailRemaining: Color.gray,
        progressRailBuffered: Color.white.opacity(0.7),
        adBreakIndicator: Color.orange,
        adActiveProgress: Color.orange,
        textPrimary: .white,
        textSecondary: .white,
        hudBackground: Color.black.opacity(0.85),
        glassBorder: Color.white.opacity(0.4),
        playActionButtons: Color.yellow
    )
}

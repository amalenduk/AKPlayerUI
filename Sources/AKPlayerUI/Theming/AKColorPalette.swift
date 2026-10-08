//
//  AKColorPalette.swift
//  AKPlayerUI
//

import SwiftUI

/// Semantic color tokens defining the visual appearance across AKPlayerUI.
/// Swapping or customizing palettes transforms the entire player look (video HUDs, audio hero,
/// mini-player, sliders, sheets, and action buttons).
public struct AKColorPalette: Sendable, Equatable {
    // MARK: - Core Accents & Brand Tints
    
    /// Primary interactive accent tint (timeline progress fill, active toggles, highlighted track).
    public var accent: Color
    
    /// Dynamic gradient palette for glowing hero backdrops and vibrant highlights.
    public var accentGradients: [Color]
    
    // MARK: - Canvas & Background Surfaces
    
    /// Root canvas/player background color (default: deep cinematic dark).
    public var background: Color
    
    /// Elevated panel, bottom sheet, and side-drawer background surface fill.
    public var surface: Color
    
    /// Elevated card, track row, popover, and floating container fill.
    public var surfaceElevated: Color
    
    /// Video player HUD top/bottom bars and floating control overlays background tint.
    public var hudBackground: Color
    
    // MARK: - Glassmorphism & Translucency
    
    /// Translucent frosted glass fill tint for pills, buttons, and floating HUD bars.
    public var glassFill: Color
    
    /// Specular border stroke for frosted glass elements (Apple-style hairline highlight).
    public var glassBorder: Color
    
    /// Top specular luminous highlight for 3D frosted glass depth.
    public var glassHighlight: Color
    
    // MARK: - Typography & Hierarchy
    
    /// Primary high-contrast text and prominent icon color.
    public var textPrimary: Color
    
    /// Secondary subtitle, artist metadata, and inactive label color.
    public var textSecondary: Color
    
    /// Tertiary timestamp, auxiliary cue, and chapter number color.
    public var textTertiary: Color
    
    // MARK: - Playback Controls
    
    /// Foreground icon tint for hero action buttons (play, pause, skip, seek).
    public var playerActionButtons: Color
    
    /// Background fill for hero action buttons (defaults to frosted glass fill).
    public var playerActionBackgroundButtons: Color
    
    // MARK: - Timeline & Buffering
    
    /// Inactive timeline rail track color.
    public var progressRailRemaining: Color
    
    /// Buffered/cached media progress rail track color.
    public var progressRailBuffered: Color
    
    /// Active played progress rail track color (defaults to accent).
    public var progressRailFill: Color
    
    // MARK: - Live & Ad Indicators
    
    /// Indicator dot and badge tint for live broadcasts (default: vibrant Red).
    public var liveBadge: Color
    
    /// Marker color for ad cue break points along the timeline (default: Gold).
    public var adBreakIndicator: Color
    
    /// Progress track color during active ad lockdown (default: Warm Amber).
    public var adActiveProgress: Color

    // MARK: - Foreground Aliases
    public var foregroundPrimary: Color { textPrimary }
    public var foregroundSecondary: Color { textSecondary }
    public var foregroundTertiary: Color { textTertiary }

    // MARK: - Initialization
    public init(
        accent: Color = Color(red: 0.15, green: 0.58, blue: 1.0), // Electric Blue
        accentGradients: [Color]? = nil,
        background: Color = .black,
        surface: Color = Color(red: 0.11, green: 0.11, blue: 0.15),
        surfaceElevated: Color = Color(red: 0.16, green: 0.16, blue: 0.22),
        hudBackground: Color = Color.black.opacity(0.45),
        glassFill: Color = Color.white.opacity(0.12),
        glassBorder: Color = Color.white.opacity(0.16),
        glassHighlight: Color = Color.white.opacity(0.25),
        textPrimary: Color = .white,
        textSecondary: Color = Color.white.opacity(0.70),
        textTertiary: Color = Color.white.opacity(0.45),
        progressRailRemaining: Color = Color.white.opacity(0.20),
        progressRailBuffered: Color = Color.white.opacity(0.40),
        progressRailFill: Color? = nil,
        playerActionButtons: Color? = nil,
        playerActionBackgroundButtons: Color? = nil,
        liveBadge: Color = Color(red: 1.0, green: 0.23, blue: 0.19),
        adBreakIndicator: Color = Color(red: 1.0, green: 0.76, blue: 0.03), // Gold
        adActiveProgress: Color = Color(red: 1.0, green: 0.65, blue: 0.0) // Amber
    ) {
        self.accent = accent
        self.accentGradients = accentGradients ?? [accent, accent.opacity(0.65)]
        self.background = background
        self.surface = surface
        self.surfaceElevated = surfaceElevated
        self.hudBackground = hudBackground
        self.glassFill = glassFill
        self.glassBorder = glassBorder
        self.glassHighlight = glassHighlight
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.progressRailRemaining = progressRailRemaining
        self.progressRailBuffered = progressRailBuffered
        self.progressRailFill = progressRailFill ?? accent
        self.playerActionButtons = playerActionButtons ?? accent
        self.playerActionBackgroundButtons = playerActionBackgroundButtons ?? Color.white.opacity(0.18)
        self.liveBadge = liveBadge
        self.adBreakIndicator = adBreakIndicator
        self.adActiveProgress = adActiveProgress
    }

    // MARK: - Presets

    /// Standard modern iOS translucent dark aesthetic with Electric Blue interactive accent.
    public static let standard = AKColorPalette()

    /// Authentic Apple Music Player palette: signature Apple Music Rose-Red (#FA2458),
    /// obsidian dark glass surfaces, luminous hairline borders, and pure white hero controls.
    public static let appleMusic = AKColorPalette(
        accent: Color(red: 0.98, green: 0.14, blue: 0.35), // Apple Music Rose-Red
        accentGradients: [
            Color(red: 0.98, green: 0.14, blue: 0.35),
            Color(red: 0.99, green: 0.38, blue: 0.54)
        ],
        background: Color(red: 0.07, green: 0.07, blue: 0.09),
        surface: Color(red: 0.10, green: 0.10, blue: 0.13),
        surfaceElevated: Color(red: 0.15, green: 0.15, blue: 0.19),
        hudBackground: Color.black.opacity(0.40),
        glassFill: Color.white.opacity(0.14),
        glassBorder: Color.white.opacity(0.18),
        glassHighlight: Color.white.opacity(0.35),
        textPrimary: .white,
        textSecondary: Color.white.opacity(0.68),
        textTertiary: Color.white.opacity(0.42),
        progressRailRemaining: Color.white.opacity(0.18),
        progressRailBuffered: Color.white.opacity(0.38),
        progressRailFill: .white,
        playerActionButtons: .white,
        playerActionBackgroundButtons: Color.white.opacity(0.16),
        liveBadge: Color(red: 0.98, green: 0.14, blue: 0.35)
    )

    /// High-energy neon cyberpunk aesthetic with Neon Purple accent.
    public static let vibrant = AKColorPalette(
        accent: Color(red: 0.85, green: 0.15, blue: 0.95), // Neon Purple/Pink
        accentGradients: [
            Color(red: 0.85, green: 0.15, blue: 0.95),
            Color(red: 0.25, green: 0.45, blue: 1.0)
        ],
        surface: Color(red: 0.12, green: 0.08, blue: 0.16),
        surfaceElevated: Color(red: 0.18, green: 0.12, blue: 0.24),
        glassFill: Color(red: 0.85, green: 0.15, blue: 0.95).opacity(0.12),
        glassBorder: Color(red: 0.85, green: 0.15, blue: 0.95).opacity(0.35),
        playerActionButtons: Color(red: 0.85, green: 0.15, blue: 0.95),
        playerActionBackgroundButtons: Color(red: 0.85, green: 0.15, blue: 0.95).opacity(0.20),
        adBreakIndicator: Color(red: 1.0, green: 0.84, blue: 0.0),
        adActiveProgress: Color(red: 1.0, green: 0.45, blue: 0.1)
    )

    /// Pure OLED Midnight palette: pitch black canvas with cold Ice Cyan accent.
    public static let midnight = AKColorPalette(
        accent: Color(red: 0.0, green: 0.82, blue: 1.0), // Ice Cyan
        accentGradients: [
            Color(red: 0.0, green: 0.82, blue: 1.0),
            Color(red: 0.0, green: 0.45, blue: 0.85)
        ],
        background: .black,
        surface: Color(red: 0.05, green: 0.06, blue: 0.08),
        surfaceElevated: Color(red: 0.09, green: 0.11, blue: 0.15),
        hudBackground: Color.black.opacity(0.60),
        glassFill: Color.white.opacity(0.08),
        glassBorder: Color(red: 0.0, green: 0.82, blue: 1.0).opacity(0.22),
        textSecondary: Color.white.opacity(0.65),
        progressRailRemaining: Color.white.opacity(0.14),
        playerActionButtons: Color(red: 0.0, green: 0.82, blue: 1.0),
        playerActionBackgroundButtons: Color.white.opacity(0.10)
    )

    /// Warm Sunset palette: vibrant Coral Amber with rich warm dark surfaces.
    public static let sunset = AKColorPalette(
        accent: Color(red: 1.0, green: 0.42, blue: 0.24), // Coral Amber
        accentGradients: [
            Color(red: 1.0, green: 0.42, blue: 0.24),
            Color(red: 1.0, green: 0.72, blue: 0.30)
        ],
        surface: Color(red: 0.13, green: 0.09, blue: 0.08),
        surfaceElevated: Color(red: 0.18, green: 0.13, blue: 0.12),
        glassFill: Color(red: 1.0, green: 0.42, blue: 0.24).opacity(0.10),
        glassBorder: Color(red: 1.0, green: 0.42, blue: 0.24).opacity(0.25),
        playerActionButtons: Color(red: 1.0, green: 0.42, blue: 0.24)
    )

    /// Minimalist Studio palette: refined Titanium and monochrome silver.
    public static let monochrome = AKColorPalette(
        accent: Color(white: 0.90),
        accentGradients: [Color(white: 0.95), Color(white: 0.65)],
        background: Color(white: 0.06),
        surface: Color(white: 0.10),
        surfaceElevated: Color(white: 0.16),
        hudBackground: Color.black.opacity(0.50),
        glassFill: Color.white.opacity(0.10),
        glassBorder: Color.white.opacity(0.20),
        textPrimary: .white,
        textSecondary: Color(white: 0.70),
        textTertiary: Color(white: 0.45),
        progressRailRemaining: Color.white.opacity(0.16),
        progressRailBuffered: Color.white.opacity(0.35),
        progressRailFill: .white,
        playerActionButtons: .white,
        playerActionBackgroundButtons: Color.white.opacity(0.14)
    )

    /// High Contrast palette: optimized for maximum accessibility and bright sunlight visibility.
    public static let highContrast = AKColorPalette(
        accent: Color.yellow,
        background: .black,
        surface: Color(white: 0.08),
        surfaceElevated: Color(white: 0.15),
        hudBackground: Color.black.opacity(0.85),
        glassFill: Color.black.opacity(0.70),
        glassBorder: Color.white.opacity(0.50),
        glassHighlight: Color.white.opacity(0.60),
        textPrimary: .white,
        textSecondary: .white,
        textTertiary: Color.white.opacity(0.75),
        progressRailRemaining: Color.gray,
        progressRailBuffered: Color.white.opacity(0.70),
        progressRailFill: Color.yellow,
        playerActionButtons: Color.yellow,
        playerActionBackgroundButtons: Color.white.opacity(0.25),
        liveBadge: Color.red,
        adBreakIndicator: Color.orange,
        adActiveProgress: Color.orange
    )

    // MARK: - Fluent Copy Builder

    /// Returns a copy of the palette with specific overrides applied.
    public func with(
        accent: Color? = nil,
        accentGradients: [Color]? = nil,
        background: Color? = nil,
        surface: Color? = nil,
        surfaceElevated: Color? = nil,
        hudBackground: Color? = nil,
        glassFill: Color? = nil,
        glassBorder: Color? = nil,
        glassHighlight: Color? = nil,
        textPrimary: Color? = nil,
        textSecondary: Color? = nil,
        textTertiary: Color? = nil,
        progressRailRemaining: Color? = nil,
        progressRailBuffered: Color? = nil,
        progressRailFill: Color? = nil,
        playerActionButtons: Color? = nil,
        playerActionBackgroundButtons: Color? = nil,
        liveBadge: Color? = nil,
        adBreakIndicator: Color? = nil,
        adActiveProgress: Color? = nil
    ) -> AKColorPalette {
        AKColorPalette(
            accent: accent ?? self.accent,
            accentGradients: accentGradients ?? self.accentGradients,
            background: background ?? self.background,
            surface: surface ?? self.surface,
            surfaceElevated: surfaceElevated ?? self.surfaceElevated,
            hudBackground: hudBackground ?? self.hudBackground,
            glassFill: glassFill ?? self.glassFill,
            glassBorder: glassBorder ?? self.glassBorder,
            glassHighlight: glassHighlight ?? self.glassHighlight,
            textPrimary: textPrimary ?? self.textPrimary,
            textSecondary: textSecondary ?? self.textSecondary,
            textTertiary: textTertiary ?? self.textTertiary,
            progressRailRemaining: progressRailRemaining ?? self.progressRailRemaining,
            progressRailBuffered: progressRailBuffered ?? self.progressRailBuffered,
            progressRailFill: progressRailFill ?? self.progressRailFill,
            playerActionButtons: playerActionButtons ?? self.playerActionButtons,
            playerActionBackgroundButtons: playerActionBackgroundButtons ?? self.playerActionBackgroundButtons,
            liveBadge: liveBadge ?? self.liveBadge,
            adBreakIndicator: adBreakIndicator ?? self.adBreakIndicator,
            adActiveProgress: adActiveProgress ?? self.adActiveProgress
        )
    }
}

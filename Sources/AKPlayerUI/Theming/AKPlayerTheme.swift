//
//  AKPlayerTheme.swift
//  AKPlayerUI
//

import SwiftUI

/// Aggregated design theme for AKPlayerUI components.
/// Encapsulates semantic colors, glassmorphic material tokens, typography, icon sets, button styles, and spacing.
public struct AKPlayerTheme: Sendable {
    public var palette: AKColorPalette
    public var materials: AKMaterialTokens
    public var typography: AKTypography
    public var icons: AKIconProvider
    public var buttonStyle: AKButtonStyle
    public var spacing: AKSpacing.Type { AKSpacing.self }

    public init(
        palette: AKColorPalette = .standard,
        materials: AKMaterialTokens = .standard,
        typography: AKTypography = .standard,
        icons: AKIconProvider = .standard,
        buttonStyle: AKButtonStyle = .glass
    ) {
        self.palette = palette
        self.materials = materials
        self.typography = typography
        self.icons = icons
        self.buttonStyle = buttonStyle
    }

    // MARK: - Presets

    /// Standard modern iOS dark glass theme with crystalline Apple Glass buttons and Electric Blue accents.
    public static let standard = AKPlayerTheme(
        palette: .standard,
        materials: .standard,
        typography: .standard,
        icons: .standard,
        buttonStyle: .glass
    )

    /// Authentic Apple Music player theme: signature Rose-Pink tint (#FA2458),
    /// multi-layered frosted glass materials, hairline specular highlights, and crystalline Apple Glass buttons.
    public static let appleMusic = AKPlayerTheme(
        palette: .appleMusic,
        materials: .appleMusic,
        typography: .standard,
        icons: .standard,
        buttonStyle: .glass
    )

    /// Cyberpunk neon aesthetic with high-saturation purple and magenta tones and solid filled buttons.
    public static let vibrant = AKPlayerTheme(
        palette: .vibrant,
        materials: .frosted,
        typography: .standard,
        icons: .standard,
        buttonStyle: .filled
    )

    /// OLED Midnight theme: pure deep black canvas with icy cyan accents and sleek frosted glass.
    public static let midnight = AKPlayerTheme(
        palette: .midnight,
        materials: .appleMusic,
        typography: .standard,
        icons: .standard,
        buttonStyle: .glass
    )

    /// Warm Sunset theme: rich coral and golden amber tones.
    public static let sunset = AKPlayerTheme(
        palette: .sunset,
        materials: .standard,
        typography: .standard,
        icons: .standard,
        buttonStyle: .glass
    )

    /// Minimalist Studio Monochrome: neutral titanium and silver glass surfaces.
    public static let monochrome = AKPlayerTheme(
        palette: .monochrome,
        materials: .appleMusic,
        typography: .standard,
        icons: .standard,
        buttonStyle: .glass
    )

    /// High Contrast accessibility theme with high-contrast yellow interactive elements.
    public static let highContrast = AKPlayerTheme(
        palette: .highContrast,
        materials: .prominent,
        typography: .standard,
        icons: .standard,
        buttonStyle: .filled
    )

    // MARK: - Fluent Copy Builder

    /// Returns a copy of the theme with specific components modified.
    public func with(
        palette: AKColorPalette? = nil,
        materials: AKMaterialTokens? = nil,
        typography: AKTypography? = nil,
        icons: AKIconProvider? = nil,
        buttonStyle: AKButtonStyle? = nil
    ) -> AKPlayerTheme {
        AKPlayerTheme(
            palette: palette ?? self.palette,
            materials: materials ?? self.materials,
            typography: typography ?? self.typography,
            icons: icons ?? self.icons,
            buttonStyle: buttonStyle ?? self.buttonStyle
        )
    }
}

// MARK: - Environment Support

private struct AKPlayerThemeKey: EnvironmentKey {
    static let defaultValue: AKPlayerTheme = .standard
}

extension EnvironmentValues {
    /// The current `AKPlayerTheme` applied to player components in this environment.
    public var akPlayerTheme: AKPlayerTheme {
        get { self[AKPlayerThemeKey.self] }
        set { self[AKPlayerThemeKey.self] = newValue }
    }
}

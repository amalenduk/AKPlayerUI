//
//  AKPlayerTheme.swift
//  AKPlayerUI
//

import SwiftUI

/// Aggregated design theme for AKPlayerUI components.
public struct AKPlayerTheme: Sendable {
    public var palette: AKColorPalette
    public var materials: AKMaterialTokens
    public var typography: AKTypography
    public var icons: AKIconProvider

    public init(
        palette: AKColorPalette = .standard,
        materials: AKMaterialTokens = .standard,
        typography: AKTypography = .standard,
        icons: AKIconProvider = .standard
    ) {
        self.palette = palette
        self.materials = materials
        self.typography = typography
        self.icons = icons
    }

    public static let standard = AKPlayerTheme()
    public static let vibrant = AKPlayerTheme(palette: .vibrant)
    public static let highContrast = AKPlayerTheme(palette: .highContrast)
}

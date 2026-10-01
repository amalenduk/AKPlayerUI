//
//  AKMaterialTokens.swift
//  AKPlayerUI
//

import SwiftUI

/// Glassmorphism and ambient blur styling tokens.
public struct AKMaterialTokens: Sendable, Equatable {
    /// Background blur radius for music reactive album artwork glow (default: 48.0 pt).
    public var ambientBlurRadius: CGFloat

    /// Standard control pill corner radius (default: 16.0 pt).
    public var controlCornerRadius: CGFloat

    /// Card container corner radius (default: 20.0 pt).
    public var cardCornerRadius: CGFloat

    public init(
        ambientBlurRadius: CGFloat = 48.0,
        controlCornerRadius: CGFloat = 16.0,
        cardCornerRadius: CGFloat = 20.0
    ) {
        self.ambientBlurRadius = ambientBlurRadius
        self.controlCornerRadius = controlCornerRadius
        self.cardCornerRadius = cardCornerRadius
    }

    public static let standard = AKMaterialTokens()
}

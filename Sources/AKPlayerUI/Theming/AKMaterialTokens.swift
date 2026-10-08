//
//  AKMaterialTokens.swift
//  AKPlayerUI
//

import SwiftUI

/// Glassmorphism, specular highlights, and ambient blur styling tokens for AKPlayerUI.
/// Provides authentic Apple Music player frosted glass, luminous hairline borders, and ambient drop shadows.
public struct AKMaterialTokens: Sendable, Equatable {
    // MARK: - Nested Blur Style
    
    /// Native blur levels for frosted glass surfaces.
    public enum BlurStyle: String, Sendable, Equatable, CaseIterable {
        case ultraThin
        case thin
        case regular
        case thick
        case ultraThick
        case none

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        public var material: Material? {
            switch self {
            case .ultraThin: return .ultraThinMaterial
            case .thin: return .thinMaterial
            case .regular: return .regularMaterial
            case .thick: return .thickMaterial
            case .ultraThick: return .ultraThickMaterial
            case .none: return nil
            }
        }
    }

    // MARK: - Properties
    
    /// Native frosted glass blur level (default: .ultraThin).
    public var blurStyle: BlurStyle

    /// Backward-compatible alias for `blurStyle`.
    public var materialStyle: BlurStyle {
        get { blurStyle }
        set { blurStyle = newValue }
    }

    /// Ambient blur radius for reactive album artwork glow & video backdrops (default: 48.0 pt).
    public var ambientBlurRadius: CGFloat

    /// Standard control pill and button corner radius (default: 16.0 pt).
    public var controlCornerRadius: CGFloat

    /// Card, floating container, and mini-player corner radius (default: 18.0 pt).
    public var cardCornerRadius: CGFloat

    /// Bottom sheet and side-drawer corner radius (default: 24.0 pt).
    public var sheetCornerRadius: CGFloat

    /// Floating HUD bars and pill overlay corner radius (default: 16.0 pt).
    public var hudCornerRadius: CGFloat

    /// Specular border hairline stroke width (default: 0.75 pt).
    public var glassBorderWidth: CGFloat

    /// Specular border opacity multiplier (default: 1.0).
    public var glassBorderOpacity: Double

    /// Ambient elevation shadow blur radius (default: 12.0 pt).
    public var shadowRadius: CGFloat

    /// Ambient shadow vertical offset (default: 4.0 pt).
    public var shadowY: CGFloat

    /// Ambient shadow opacity (default: 0.35).
    public var shadowOpacity: Double

    public init(
        blurStyle: BlurStyle = .ultraThin,
        ambientBlurRadius: CGFloat = 48.0,
        controlCornerRadius: CGFloat = 16.0,
        cardCornerRadius: CGFloat = 18.0,
        sheetCornerRadius: CGFloat = 24.0,
        hudCornerRadius: CGFloat = 16.0,
        glassBorderWidth: CGFloat = 0.75,
        glassBorderOpacity: Double = 1.0,
        shadowRadius: CGFloat = 12.0,
        shadowY: CGFloat = 4.0,
        shadowOpacity: Double = 0.35
    ) {
        self.blurStyle = blurStyle
        self.ambientBlurRadius = ambientBlurRadius
        self.controlCornerRadius = controlCornerRadius
        self.cardCornerRadius = cardCornerRadius
        self.sheetCornerRadius = sheetCornerRadius
        self.hudCornerRadius = hudCornerRadius
        self.glassBorderWidth = glassBorderWidth
        self.glassBorderOpacity = glassBorderOpacity
        self.shadowRadius = shadowRadius
        self.shadowY = shadowY
        self.shadowOpacity = shadowOpacity
    }

    /// Backward-compatible initializer accepting `materialStyle`.
    public init(
        materialStyle: BlurStyle,
        ambientBlurRadius: CGFloat = 48.0,
        controlCornerRadius: CGFloat = 16.0,
        cardCornerRadius: CGFloat = 18.0,
        sheetCornerRadius: CGFloat = 24.0,
        hudCornerRadius: CGFloat = 16.0,
        glassBorderWidth: CGFloat = 0.75,
        glassBorderOpacity: Double = 1.0,
        shadowRadius: CGFloat = 12.0,
        shadowY: CGFloat = 4.0,
        shadowOpacity: Double = 0.35
    ) {
        self.init(
            blurStyle: materialStyle,
            ambientBlurRadius: ambientBlurRadius,
            controlCornerRadius: controlCornerRadius,
            cardCornerRadius: cardCornerRadius,
            sheetCornerRadius: sheetCornerRadius,
            hudCornerRadius: hudCornerRadius,
            glassBorderWidth: glassBorderWidth,
            glassBorderOpacity: glassBorderOpacity,
            shadowRadius: shadowRadius,
            shadowY: shadowY,
            shadowOpacity: shadowOpacity
        )
    }

    // MARK: - Presets

    /// Standard modern iOS translucent glass tokens.
    public static let standard = AKMaterialTokens()

    /// Authentic Apple Music player glass: ultra-thin frost, fine hairline border, and deep ambient glow.
    public static let appleMusic = AKMaterialTokens(
        blurStyle: .ultraThin,
        ambientBlurRadius: 64.0,
        controlCornerRadius: 18.0,
        cardCornerRadius: 20.0,
        sheetCornerRadius: 26.0,
        hudCornerRadius: 18.0,
        glassBorderWidth: 0.75,
        glassBorderOpacity: 1.2,
        shadowRadius: 16.0,
        shadowY: 6.0,
        shadowOpacity: 0.40
    )

    /// Rich frosted glass with heavier blur (.thin material).
    public static let frosted = AKMaterialTokens(
        blurStyle: .thin,
        ambientBlurRadius: 52.0,
        controlCornerRadius: 16.0,
        cardCornerRadius: 18.0,
        sheetCornerRadius: 24.0,
        hudCornerRadius: 16.0,
        glassBorderWidth: 1.0,
        glassBorderOpacity: 1.0,
        shadowRadius: 14.0,
        shadowY: 5.0,
        shadowOpacity: 0.38
    )

    /// Prominent thick material for dense readability over high-motion video.
    public static let prominent = AKMaterialTokens(
        blurStyle: .regular,
        ambientBlurRadius: 40.0,
        controlCornerRadius: 14.0,
        cardCornerRadius: 16.0,
        sheetCornerRadius: 22.0,
        hudCornerRadius: 14.0,
        glassBorderWidth: 1.0,
        glassBorderOpacity: 1.0,
        shadowRadius: 10.0,
        shadowY: 3.0,
        shadowOpacity: 0.30
    )

    /// Flat tokens without frosted blur for ultra-low GPU overhead or minimalistic layouts.
    public static let flat = AKMaterialTokens(
        blurStyle: .none,
        ambientBlurRadius: 0.0,
        controlCornerRadius: 12.0,
        cardCornerRadius: 14.0,
        sheetCornerRadius: 20.0,
        hudCornerRadius: 12.0,
        glassBorderWidth: 1.0,
        glassBorderOpacity: 0.8,
        shadowRadius: 0.0,
        shadowY: 0.0,
        shadowOpacity: 0.0
    )

    // MARK: - Fluent Copy Builder

    /// Returns a copy of the materials with specific overrides applied.
    public func with(
        blurStyle: BlurStyle? = nil,
        ambientBlurRadius: CGFloat? = nil,
        controlCornerRadius: CGFloat? = nil,
        cardCornerRadius: CGFloat? = nil,
        sheetCornerRadius: CGFloat? = nil,
        hudCornerRadius: CGFloat? = nil,
        glassBorderWidth: CGFloat? = nil,
        glassBorderOpacity: Double? = nil,
        shadowRadius: CGFloat? = nil,
        shadowY: CGFloat? = nil,
        shadowOpacity: Double? = nil
    ) -> AKMaterialTokens {
        AKMaterialTokens(
            blurStyle: blurStyle ?? self.blurStyle,
            ambientBlurRadius: ambientBlurRadius ?? self.ambientBlurRadius,
            controlCornerRadius: controlCornerRadius ?? self.controlCornerRadius,
            cardCornerRadius: cardCornerRadius ?? self.cardCornerRadius,
            sheetCornerRadius: sheetCornerRadius ?? self.sheetCornerRadius,
            hudCornerRadius: hudCornerRadius ?? self.hudCornerRadius,
            glassBorderWidth: glassBorderWidth ?? self.glassBorderWidth,
            glassBorderOpacity: glassBorderOpacity ?? self.glassBorderOpacity,
            shadowRadius: shadowRadius ?? self.shadowRadius,
            shadowY: shadowY ?? self.shadowY,
            shadowOpacity: shadowOpacity ?? self.shadowOpacity
        )
    }
}

/// Convenience alias for backward compatibility.
public typealias AKGlassMaterial = AKMaterialTokens.BlurStyle

// MARK: - Reusable Apple Glassmorphism View Modifiers

/// Applies multi-layered Apple-style frosted glass with specular hairline border, inner highlight, and shadow.
public struct AKGlassSurfaceModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var isContinuous: Bool
    
    @Environment(\.akPlayerTheme) private var theme

    public init(cornerRadius: CGFloat = 16, isContinuous: Bool = true) {
        self.cornerRadius = cornerRadius
        self.isContinuous = isContinuous
    }

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: isContinuous ? .continuous : .circular)
        content
            .background(
                ZStack {
                    if let mat = theme.materials.blurStyle.material {
                        shape.fill(mat)
                    } else {
                        shape.fill(Color(white: 0.14))
                    }
                    shape.fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.22), location: 0.0),
                                .init(color: Color.white.opacity(0.08), location: 0.50),
                                .init(color: Color.white.opacity(0.03), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            )
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.55), location: 0.0),
                            .init(color: Color.white.opacity(0.18), location: 0.40),
                            .init(color: Color.white.opacity(0.06), location: 0.70),
                            .init(color: Color.white.opacity(0.18), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(0.75, theme.materials.glassBorderWidth)
                )
            )
            .shadow(
                color: Color.black.opacity(theme.materials.shadowOpacity),
                radius: theme.materials.shadowRadius,
                x: 0,
                y: theme.materials.shadowY
            )
    }
}

/// Applies capsule pill glass styling.
public struct AKGlassPillModifier: ViewModifier {
    @Environment(\.akPlayerTheme) private var theme

    public init() {}

    public func body(content: Content) -> some View {
        let shape = Capsule()
        content
            .background(
                ZStack {
                    if let mat = theme.materials.blurStyle.material {
                        shape.fill(mat)
                    } else {
                        shape.fill(Color(white: 0.18))
                    }
                    shape.fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.28), location: 0.0),
                                .init(color: Color.white.opacity(0.10), location: 0.45),
                                .init(color: Color.white.opacity(0.04), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            )
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.65), location: 0.0),
                            .init(color: Color.white.opacity(0.22), location: 0.40),
                            .init(color: Color.white.opacity(0.08), location: 0.70),
                            .init(color: Color.white.opacity(0.20), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(0.75, theme.materials.glassBorderWidth)
                )
            )
            .shadow(
                color: Color.black.opacity(theme.materials.shadowOpacity * 0.8),
                radius: theme.materials.shadowRadius * 0.7,
                x: 0,
                y: theme.materials.shadowY * 0.6
            )
    }
}

/// Applies circular button glass styling.
public struct AKGlassCircleModifier: ViewModifier {
    @Environment(\.akPlayerTheme) private var theme

    public init() {}

    public func body(content: Content) -> some View {
        let shape = Circle()
        content
            .background(
                ZStack {
                    if let mat = theme.materials.blurStyle.material {
                        shape.fill(mat)
                    } else {
                        shape.fill(Color(white: 0.18))
                    }
                    shape.fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.32), location: 0.0),
                                .init(color: Color.white.opacity(0.12), location: 0.45),
                                .init(color: Color.white.opacity(0.04), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            )
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.70), location: 0.0),
                            .init(color: Color.white.opacity(0.28), location: 0.40),
                            .init(color: Color.white.opacity(0.10), location: 0.70),
                            .init(color: Color.white.opacity(0.25), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(0.75, theme.materials.glassBorderWidth)
                )
            )
            .shadow(
                color: Color.black.opacity(theme.materials.shadowOpacity * 1.2),
                radius: theme.materials.shadowRadius * 0.8,
                x: 0,
                y: theme.materials.shadowY
            )
    }
}

extension View {
    /// Applies an Apple-style frosted glass surface with rounded corners, specular border, and ambient shadow.
    public func akGlassSurface(cornerRadius: CGFloat = 16, isContinuous: Bool = true) -> some View {
        modifier(AKGlassSurfaceModifier(cornerRadius: cornerRadius, isContinuous: isContinuous))
    }

    /// Applies an Apple-style frosted glass card using the theme's `cardCornerRadius`.
    public func akGlassCard() -> some View {
        akGlassSurface(cornerRadius: 18, isContinuous: true)
    }

    /// Applies an Apple-style frosted glass capsule (pill) for tool buttons, badges, and controls.
    public func akGlassPill() -> some View {
        modifier(AKGlassPillModifier())
    }

    /// Applies an Apple-style frosted glass circle for circular control buttons.
    public func akGlassCircle() -> some View {
        modifier(AKGlassCircleModifier())
    }
}

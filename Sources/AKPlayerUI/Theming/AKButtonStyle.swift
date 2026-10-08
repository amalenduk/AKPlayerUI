//
//  AKButtonStyle.swift
//  AKPlayerUI
//

import SwiftUI

/// Defines visual presentation variants for player control buttons across AKPlayerUI.
public enum AKButtonStyle: Sendable, Equatable {
    /// Authentic Apple frosted glass with crystalline specular sheen, lens bevel border, and luminous depth.
    /// (e.g. Apple Music, Apple TV, iOS native media controls).
    case glass

    /// Solid accent background fill with high-contrast textPrimary foreground icon.
    /// (e.g. Spotify, YouTube hero style).
    case filled
    
    /// Translucent frosted glass with accent-tinted icon and subtle ambient glow.
    /// (e.g. Apple Podcasts style).
    case tinted
    
    /// Translucent frosted glass with high-contrast textPrimary foreground icon.
    /// (e.g. neutral chrome).
    case monochrome
    
    /// Accent border stroke on subtle translucent glass fill with accent foreground icon.
    case outlined
}

// MARK: - Reusable Control Button Style

/// A unified circular button style for media playback controls across AKPlayerUI.
/// Accesses `theme.buttonStyle`, `theme.palette`, and `theme.materials` directly from the environment.
public struct AKControlButtonStyle: ButtonStyle {
    public var size: CGFloat
    public var style: AKButtonStyle?
    
    @Environment(\.akPlayerTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    
    public init(size: CGFloat = 44, style: AKButtonStyle? = nil) {
        self.size = size
        self.style = style
    }
    
    private var effectiveStyle: AKButtonStyle {
        style ?? theme.buttonStyle
    }
    
    private var foregroundColor: Color {
        switch effectiveStyle {
        case .glass:
            return theme.palette.playerActionButtons
        case .filled:
            return theme.palette.textPrimary
        case .tinted:
            return theme.palette.accent
        case .monochrome:
            return theme.palette.textPrimary
        case .outlined:
            return theme.palette.accent
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        switch effectiveStyle {
        case .filled:
            Circle()
                .fill(theme.palette.accent)
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1.0)
                )
                .shadow(
                    color: theme.palette.accent.opacity(0.40),
                    radius: size * 0.18,
                    x: 0,
                    y: 3
                )
                
        case .outlined:
            Circle()
                .fill(theme.palette.accent.opacity(0.12))
                .overlay(
                    Circle().strokeBorder(theme.palette.accent, lineWidth: 2.0)
                )
                
        case .glass, .tinted, .monochrome:
            ZStack {
                // 1. Native SwiftUI Material Blur Foundation
                if let mat = theme.materials.materialStyle.material {
                    Circle()
                        .fill(mat)
                } else {
                    Circle()
                        .fill(Color(white: 0.18))
                }
                
                // 2. Luminous Glass Specular Sheen (Curved lens highlight)
                Circle()
                    .fill(
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
                
                // 3. Subtle Ambient Tint (if tinted mode)
                if effectiveStyle == .tinted {
                    Circle()
                        .fill(theme.palette.accent.opacity(0.15))
                }
            }
            .clipShape(Circle())
            // 4. Specular Bevel Refraction Border (Bright top-left highlight, soft bottom bevel)
            .overlay(
                Circle()
                    .strokeBorder(
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
            // 5. Deep Ambient Drop Shadow for authentic floating elevation
            .shadow(
                color: Color.black.opacity(0.45),
                radius: max(8, size * 0.20),
                x: 0,
                y: max(3, size * 0.08)
            )
        }
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        ZStack {
            buttonBackground
                .frame(width: size, height: size)
            
            configuration.label
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundColor(foregroundColor)
                .tint(foregroundColor)
        }
        .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
        .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1.0) : 0.4)
        .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

public typealias AKPlayPauseButtonStyle = AKControlButtonStyle

extension ButtonStyle where Self == AKControlButtonStyle {
    /// A circular control button style inheriting from `AKPlayerTheme.buttonStyle`.
    public static func akControl(size: CGFloat = 44, style: AKButtonStyle? = nil) -> AKControlButtonStyle {
        AKControlButtonStyle(size: size, style: style)
    }
}

//
//  AKButtonStyle.swift
//  AKPlayerUI
//

import SwiftUI

/// Defines visual presentation variants for player control buttons across AKPlayerUI.
public enum AKButtonStyle: Sendable, Equatable {
    /// Solid accent background fill with high-contrast textPrimary foreground icon.
    /// (e.g. Spotify, YouTube, Material 3 hero style).
    case filled
    
    /// Translucent frosted glass background with accent-colored foreground icon.
    /// (e.g. Apple Music, Apple Podcasts style).
    case tinted
    
    /// Translucent frosted glass background with high-contrast textPrimary foreground icon.
    /// (e.g. Apple TV, neutral chrome).
    case monochrome
    
    /// Accent border stroke on subtle translucent glass fill with accent foreground icon.
    case outlined
}

// MARK: - Reusable Control Button Style

/// A unified circular button style for media playback controls across AKPlayerUI.
/// Accesses `theme.buttonStyle` directly from the environment to style background, stroke, shadow, and icon tint.
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
    
    private var backgroundColor: Color {
        switch effectiveStyle {
        case .filled:
            return theme.palette.accent
        case .tinted, .monochrome:
            return Color.white.opacity(0.15)
        case .outlined:
            return theme.palette.accent.opacity(0.12)
        }
    }
    
    private var foregroundColor: Color {
        switch effectiveStyle {
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
    
    private var strokeColor: Color {
        switch effectiveStyle {
        case .filled:
            return Color.white.opacity(0.25)
        case .tinted, .monochrome:
            return Color.white.opacity(0.15)
        case .outlined:
            return theme.palette.accent
        }
    }
    
    private var strokeWidth: CGFloat {
        switch effectiveStyle {
        case .outlined:
            return 2.0
        default:
            return 1.0
        }
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
                .overlay(
                    Circle().stroke(strokeColor, lineWidth: strokeWidth)
                )
                .shadow(
                    color: effectiveStyle == .filled ? theme.palette.accent.opacity(0.35) : Color.clear,
                    radius: effectiveStyle == .filled ? size * 0.15 : 0,
                    y: effectiveStyle == .filled ? 2 : 0
                )
            
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

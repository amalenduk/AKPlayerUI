//
//  AKTransportButton.swift
//  AKPlayerUI
//

import SwiftUI

/// Action type representing a transport command.
public enum AKTransportButtonAction: Sendable, Equatable {
    /// Seek backward or forward by a specific duration in seconds.
    case seek(direction: AKSeekDirection, seconds: TimeInterval = 10)
    /// Step backward or forward by a single video frame.
    case frameStep(direction: AKStepDirection)
    /// Advance to next track in queue/playlist.
    case nextTrack
    /// Return to previous track in queue/playlist.
    case previousTrack
    /// Custom action using arbitrary SF Symbol.
    case custom(icon: String)
}

/// Unified parent view for all non-play/pause media transport controls across AKPlayerUI.
/// Powers `AKSeekButton`, `AKFrameStepButton`, `AKNextTrackButton`, and `AKPreviousTrackButton`.
/// Shares consistent tactile haptics, spring animations, sizing, and theme-driven styles with `AKPlayPauseButton`.
public struct AKTransportButton: View {
    public let action: AKTransportButtonAction
    public let isEnabled: Bool
    public let size: CGFloat
    public let style: AKButtonStyle?
    public let onAction: () -> Void

    @Environment(\.akPlayerTheme) private var theme

    public init(
        action: AKTransportButtonAction,
        isEnabled: Bool = true,
        size: CGFloat = 44,
        style: AKButtonStyle? = nil,
        onAction: @escaping () -> Void
    ) {
        self.action = action
        self.isEnabled = isEnabled
        self.size = size
        self.style = style
        self.onAction = onAction
    }

    private var iconName: String {
        switch action {
        case let .seek(direction, seconds):
            let base = direction == .backward ? theme.icons.skipBackward : theme.icons.skipForward
            let rounded = Int(seconds)
            switch rounded {
            case 5, 10, 15, 30, 45, 60, 75, 90:
                return "\(base).\(rounded)"
            default:
                return base
            }
        case let .frameStep(direction):
            return direction == .backward ? theme.icons.stepBackward : theme.icons.stepForward
        case .nextTrack:
            return theme.icons.nextTrack
        case .previousTrack:
            return theme.icons.previousTrack
        case let .custom(icon):
            return icon
        }
    }

    private var iconFontSize: CGFloat {
        switch action {
        case .frameStep:
            return size * 0.42
        case .nextTrack, .previousTrack:
            return size * 0.44
        case .seek:
            return size * 0.45
        case .custom:
            return size * 0.42
        }
    }

    private var iconWeight: Font.Weight {
        switch action {
        case .frameStep:
            return .regular
        case .nextTrack, .previousTrack:
            return .bold
        case .seek:
            return .semibold
        case .custom:
            return .semibold
        }
    }

    public var body: some View {
        Button(action: onAction) {
            Image(systemName: iconName)
                .font(.system(size: iconFontSize, weight: iconWeight))
        }
        .buttonStyle(AKControlButtonStyle(size: size, style: style))
        .disabled(!isEnabled)
    }
}

// MARK: - Specialized Track Buttons

/// Dedicated Next Track button powered by `AKTransportButton`.
public struct AKNextTrackButton: View {
    public let isEnabled: Bool
    public let size: CGFloat
    public let style: AKButtonStyle?
    public let onAction: () -> Void

    public init(
        isEnabled: Bool = true,
        size: CGFloat = 44,
        style: AKButtonStyle? = nil,
        onAction: @escaping () -> Void
    ) {
        self.isEnabled = isEnabled
        self.size = size
        self.style = style
        self.onAction = onAction
    }

    public var body: some View {
        AKTransportButton(
            action: .nextTrack,
            isEnabled: isEnabled,
            size: size,
            style: style,
            onAction: onAction
        )
    }
}

/// Dedicated Previous Track button powered by `AKTransportButton`.
public struct AKPreviousTrackButton: View {
    public let isEnabled: Bool
    public let size: CGFloat
    public let style: AKButtonStyle?
    public let onAction: () -> Void

    public init(
        isEnabled: Bool = true,
        size: CGFloat = 44,
        style: AKButtonStyle? = nil,
        onAction: @escaping () -> Void
    ) {
        self.isEnabled = isEnabled
        self.size = size
        self.style = style
        self.onAction = onAction
    }

    public var body: some View {
        AKTransportButton(
            action: .previousTrack,
            isEnabled: isEnabled,
            size: size,
            style: style,
            onAction: onAction
        )
    }
}

// MARK: - Previews

#Preview("Transport Action Buttons") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: AKSpacing.md) {
            AKPreviousTrackButton(onAction: {})
            AKTransportButton(action: .seek(direction: .backward, seconds: 15), onAction: {})
            AKTransportButton(action: .frameStep(direction: .backward), onAction: {})
            AKTransportButton(action: .frameStep(direction: .forward), onAction: {})
            AKTransportButton(action: .seek(direction: .forward, seconds: 15), onAction: {})
            AKNextTrackButton(onAction: {})
        }
        .environment(\.akPlayerTheme, .standard)
    }
}

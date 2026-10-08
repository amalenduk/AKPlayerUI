//
//  AKSeekButton.swift
//  AKPlayerUI
//

import SwiftUI

public enum AKSeekDirection: Sendable, Equatable {
    case backward
    case forward
}

/// Single Responsibility: Displays directional seek button with numerical badge offset, emitting `onAction`.
/// Backed directly by `AKTransportButton` and styled consistently with `AKControlButtonStyle`.
public struct AKSeekButton: View {
    public let direction: AKSeekDirection
    public let stepSeconds: TimeInterval
    public let isEnabled: Bool
    public let size: CGFloat
    public let style: AKButtonStyle?
    public let onAction: () -> Void

    public init(
        direction: AKSeekDirection,
        stepSeconds: TimeInterval = 10,
        isEnabled: Bool = true,
        size: CGFloat = 44,
        style: AKButtonStyle? = nil,
        onAction: @escaping () -> Void
    ) {
        self.direction = direction
        self.stepSeconds = stepSeconds
        self.isEnabled = isEnabled
        self.size = size
        self.style = style
        self.onAction = onAction
    }

    public var body: some View {
        AKTransportButton(
            action: .seek(direction: direction, seconds: stepSeconds),
            isEnabled: isEnabled,
            size: size,
            style: style,
            onAction: onAction
        )
    }
}

// MARK: - Previews

#Preview("Seek Buttons") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: AKSpacing.xl) {
            AKSeekButton(direction: .backward, stepSeconds: 10, onAction: {})
            AKSeekButton(direction: .forward, stepSeconds: 15, onAction: {})
            AKSeekButton(direction: .forward, stepSeconds: 30, isEnabled: false, onAction: {})
        }
        .environment(\.akPlayerTheme, .highContrast)
    }
}

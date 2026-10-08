//
//  AKFrameStepButton.swift
//  AKPlayerUI
//

import SwiftUI

public enum AKStepDirection: Sendable, Equatable {
    case backward
    case forward
}

/// Single Responsibility: Displays single-frame stepping control querying media capabilities.
/// Backed directly by `AKTransportButton` and styled consistently with `AKControlButtonStyle`.
public struct AKFrameStepButton: View {
    public let direction: AKStepDirection
    public let isEnabled: Bool
    public let size: CGFloat
    public let style: AKButtonStyle?
    public let onAction: () -> Void

    public init(
        direction: AKStepDirection,
        isEnabled: Bool = true,
        size: CGFloat = 36,
        style: AKButtonStyle? = nil,
        onAction: @escaping () -> Void
    ) {
        self.direction = direction
        self.isEnabled = isEnabled
        self.size = size
        self.style = style
        self.onAction = onAction
    }

    public var body: some View {
        AKTransportButton(
            action: .frameStep(direction: direction),
            isEnabled: isEnabled,
            size: size,
            style: style,
            onAction: onAction
        )
    }
}

// MARK: - Previews

#Preview("Frame Step Buttons") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: AKSpacing.lg) {
            AKFrameStepButton(direction: .backward, isEnabled: true, onAction: {})
            AKFrameStepButton(direction: .forward, isEnabled: true, onAction: {})
            AKFrameStepButton(direction: .forward, isEnabled: false, onAction: {})
        }
        .environment(\.akPlayerTheme, .standard)
    }
}

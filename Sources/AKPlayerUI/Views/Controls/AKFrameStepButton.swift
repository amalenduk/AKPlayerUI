//
//  AKFrameStepButton.swift
//  AKPlayerUI
//

import SwiftUI

public enum AKStepDirection: Sendable {
    case backward
    case forward

    public var systemIconName: String {
        switch self {
        case .backward: return "backward.frame.fill"
        case .forward:  return "forward.frame.fill"
        }
    }
}

/// Single Responsibility: Displays single-frame stepping control querying media capabilities.
public struct AKFrameStepButton: View {
    public let direction: AKStepDirection
    public let isEnabled: Bool
    public let size: CGFloat
    public let foregroundColor: Color
    public let onStep: () -> Void

    public init(
        direction: AKStepDirection,
        isEnabled: Bool = true,
        size: CGFloat = 36,
        foregroundColor: Color = .white,
        onStep: @escaping () -> Void
    ) {
        self.direction = direction
        self.isEnabled = isEnabled
        self.size = size
        self.foregroundColor = foregroundColor
        self.onStep = onStep
    }

    public var body: some View {
        Button(action: onStep) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: size, height: size)

                Image(systemName: direction.systemIconName)
                    .font(.system(size: size * 0.42, weight: .regular))
                    .foregroundColor(foregroundColor)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.35)
    }
}

// MARK: - Previews
#Preview("Frame Step Buttons") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: AKSpacing.lg) {
            AKFrameStepButton(direction: .backward, isEnabled: true, onStep: {})
            AKFrameStepButton(direction: .forward, isEnabled: true, onStep: {})
            AKFrameStepButton(direction: .forward, isEnabled: false, onStep: {})
        }
    }
}

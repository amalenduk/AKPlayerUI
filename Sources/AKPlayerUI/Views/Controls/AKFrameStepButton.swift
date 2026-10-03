//
//  AKFrameStepButton.swift
//  AKPlayerUI
//

import SwiftUI

public enum AKStepDirection: Sendable {
    case backward
    case forward
}

/// Single Responsibility: Displays single-frame stepping control querying media capabilities.
public struct AKFrameStepButton: View {
    public let direction: AKStepDirection
    public let isEnabled: Bool
    public let size: CGFloat
    public let onStep: () -> Void
    
    @Environment(\.akPlayerTheme) private var theme
    
    public var iconName: String {
        switch direction {
        case .backward: return theme.icons.stepBackward
        case .forward:  return theme.icons.stepForward
        }
    }
    
    public init(
        direction: AKStepDirection,
        isEnabled: Bool = true,
        size: CGFloat = 36,
        onStep: @escaping () -> Void
    ) {
        self.direction = direction
        self.isEnabled = isEnabled
        self.size = size
        self.onStep = onStep
    }
    
    public var body: some View {
        Button(action: onStep) {
            ZStack {
                Circle()
                    .fill(theme.palette.playerActionBackgroundButtons)
                    .frame(width: size, height: size)
                
                Image(systemName: iconName)
                    .font(.system(size: size * 0.42, weight: .regular))
                    .foregroundColor(theme.palette.playerActionButtons)
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

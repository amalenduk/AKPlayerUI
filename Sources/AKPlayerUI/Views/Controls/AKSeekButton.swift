//
//  AKSeekButton.swift
//  AKPlayerUI
//

import SwiftUI

public enum AKSeekDirection: Sendable {
    case backward
    case forward
}

/// Single Responsibility: Displays directional seek button with numerical badge offset, emitting seek action.
/// Styled consistently with `AKControlButtonStyle` driven directly by `theme.buttonStyle`.
public struct AKSeekButton: View {
    public let direction: AKSeekDirection
    public let stepSeconds: TimeInterval
    public let isEnabled: Bool
    public let size: CGFloat
    public let onSeek: () -> Void
    
    @Environment(\.akPlayerTheme) private var theme
    
    public var iconBase: String {
        switch direction {
        case .backward: return theme.icons.skipBackward
        case .forward:  return theme.icons.skipForward
        }
    }
    
    public init(
        direction: AKSeekDirection,
        stepSeconds: TimeInterval = 10,
        isEnabled: Bool = true,
        size: CGFloat = 44,
        onSeek: @escaping () -> Void
    ) {
        self.direction = direction
        self.stepSeconds = stepSeconds
        self.isEnabled = isEnabled
        self.size = size
        self.onSeek = onSeek
    }
    
    private var iconName: String {
        let rounded = Int(stepSeconds)
        switch rounded {
        case 5, 10, 15, 30, 45, 60, 75, 90:
            return "\(iconBase).\(rounded)"
        default:
            return iconBase
        }
    }
    
    public var body: some View {
        Button(action: onSeek) {
            Image(systemName: iconName)
                .font(.system(size: size * 0.45, weight: .semibold))
        }
        .buttonStyle(AKControlButtonStyle(size: size))
        .disabled(!isEnabled)
    }
}

// MARK: - Previews

#Preview("Seek Buttons") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: AKSpacing.xl) {
            AKSeekButton(direction: .backward, stepSeconds: 10, onSeek: {})
            AKSeekButton(direction: .forward, stepSeconds: 15, onSeek: {})
            AKSeekButton(direction: .forward, stepSeconds: 30, isEnabled: false, onSeek: {})
        }
        .environment(\.akPlayerTheme, .standard)
    }
}

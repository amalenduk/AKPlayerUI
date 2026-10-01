//
//  AKSeekButton.swift
//  AKPlayerUI
//

import SwiftUI

public enum AKSeekDirection: Sendable {
    case backward
    case forward

    public var systemIconBase: String {
        switch self {
        case .backward: return "gobackward"
        case .forward:  return "goforward"
        }
    }
}

/// Single Responsibility: Displays directional seek button with numerical badge offset, emitting seek action.
public struct AKSeekButton: View {
    public let direction: AKSeekDirection
    public let stepSeconds: TimeInterval
    public let isEnabled: Bool
    public let size: CGFloat
    public let foregroundColor: Color
    public let onSeek: () -> Void

    public init(
        direction: AKSeekDirection,
        stepSeconds: TimeInterval = 10,
        isEnabled: Bool = true,
        size: CGFloat = 44,
        foregroundColor: Color = .white,
        onSeek: @escaping () -> Void
    ) {
        self.direction = direction
        self.stepSeconds = stepSeconds
        self.isEnabled = isEnabled
        self.size = size
        self.foregroundColor = foregroundColor
        self.onSeek = onSeek
    }

    private var iconName: String {
        let rounded = Int(stepSeconds)
        switch rounded {
        case 5, 10, 15, 30, 45, 60, 75, 90:
            return "\(direction.systemIconBase).\(rounded)"
        default:
            return direction.systemIconBase
        }
    }

    public var body: some View {
        Button(action: onSeek) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: size, height: size)

                Image(systemName: iconName)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundColor(foregroundColor)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.4)
    }
}

// MARK: - Previews
#Preview("Seek Buttons") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 24) {
            AKSeekButton(direction: .backward, stepSeconds: 10, onSeek: {})
            AKSeekButton(direction: .forward, stepSeconds: 15, onSeek: {})
            AKSeekButton(direction: .forward, stepSeconds: 30, isEnabled: false, onSeek: {})
        }
    }
}

//
//  AKPlayPauseButton.swift
//  AKPlayerUI
//

import SwiftUI

/// Single Responsibility: Displays play/pause state or buffering spinner, emitting toggle callback.
public struct AKPlayPauseButton: View {
    public let isPlaying: Bool
    public let isBuffering: Bool
    public let isEnabled: Bool
    public let size: CGFloat
    public let iconColor: Color
    public let backgroundColor: Color
    public let onToggle: () -> Void

    public init(
        isPlaying: Bool,
        isBuffering: Bool = false,
        isEnabled: Bool = true,
        size: CGFloat = 64,
        iconColor: Color = .white,
        backgroundColor: Color = Color.white.opacity(0.18),
        onToggle: @escaping () -> Void
    ) {
        self.isPlaying = isPlaying
        self.isBuffering = isBuffering
        self.isEnabled = isEnabled
        self.size = size
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.onToggle = onToggle
    }

    public var body: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                if isBuffering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: iconColor))
                        .scaleEffect(size / 40.0)
                } else {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: size * 0.42, weight: .bold))
                        .foregroundColor(iconColor)
                        .offset(x: isPlaying ? 0 : 2) // Optical center compensation for play triangle
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isPlaying)
        .animation(.easeInOut(duration: 0.2), value: isBuffering)
    }
}

// MARK: - Previews
#Preview("Playing") {
    ZStack {
        Color.black.ignoresSafeArea()
        AKPlayPauseButton(isPlaying: true, onToggle: {})
    }
}

#Preview("Buffering") {
    ZStack {
        Color.black.ignoresSafeArea()
        AKPlayPauseButton(isPlaying: false, isBuffering: true, onToggle: {})
    }
}

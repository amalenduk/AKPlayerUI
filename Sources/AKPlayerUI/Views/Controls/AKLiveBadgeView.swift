//
//  AKLiveBadgeView.swift
//  AKPlayerUI
//

import SwiftUI

/// Single Responsibility: Displays pulsating live broadcast badge or DVR time offset pill.
public struct AKLiveBadgeView: View {
    public let isAtLiveEdge: Bool
    public let offsetSeconds: TimeInterval
    public let typography: AKTypography
    public let onJumpToLive: (() -> Void)?

    @State private var isPulsing: Bool = false

    public init(
        isAtLiveEdge: Bool = true,
        offsetSeconds: TimeInterval = 0,
        typography: AKTypography = .standard,
        onJumpToLive: (() -> Void)? = nil
    ) {
        self.isAtLiveEdge = isAtLiveEdge
        self.offsetSeconds = offsetSeconds
        self.typography = typography
        self.onJumpToLive = onJumpToLive
    }

    public var body: some View {
        Button(action: {
            if !isAtLiveEdge {
                onJumpToLive?()
            }
        }) {
            HStack(spacing: AKSpacing.xs) {
                Circle()
                    .fill(isAtLiveEdge ? Color.red : Color.gray)
                    .frame(width: AKSpacing.xs, height: AKSpacing.xs)
                    .scaleEffect(isAtLiveEdge && isPulsing ? 1.25 : 1.0)
                    .opacity(isAtLiveEdge && isPulsing ? 0.7 : 1.0)

                Text(isAtLiveEdge ? "LIVE" : "- \(formatOffset(offsetSeconds))")
                    .font(typography.badge)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, AKSpacing.sm)
            .padding(.vertical, AKSpacing.xxs)
            .background(
                Capsule()
                    .fill(isAtLiveEdge ? Color.red.opacity(0.25) : Color.white.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(isAtLiveEdge ? Color.red.opacity(0.6) : Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    private func formatOffset(_ seconds: TimeInterval) -> String {
        let absSec = Int(abs(seconds))
        let m = absSec / 60
        let s = absSec % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Previews
#Preview("Live Badges") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: AKSpacing.lg) {
            AKLiveBadgeView(isAtLiveEdge: true)
            AKLiveBadgeView(isAtLiveEdge: false, offsetSeconds: 740)
        }
    }
}

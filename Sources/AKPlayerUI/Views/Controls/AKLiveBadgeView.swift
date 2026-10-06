//
//  AKLiveBadgeView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Single Responsibility: Displays pulsating live broadcast badge or DVR time offset pill.
public struct AKLiveBadgeView: View {
    public let isAtLiveEdge: Bool
    public let liveDrift: TimeInterval
    public let onJumpToLive: (() -> Void)?
    
    @State private var isPulsing: Bool = false
    
    @Environment(\.akPlayerTheme) private var theme
    
    public init(
        isAtLiveEdge: Bool = true,
        liveDrift: TimeInterval = 0,
        onJumpToLive: (() -> Void)? = nil
    ) {
        self.isAtLiveEdge = isAtLiveEdge
        self.liveDrift = liveDrift
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
                
                Text(isAtLiveEdge ? "LIVE" : "- \(liveDrift.humanReadableClock)")
                    .font(theme.typography.badge)
                    .foregroundColor(theme.palette.foregroundPrimary)
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
}

// MARK: - Previews
#Preview("Live Badges") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: AKSpacing.lg) {
            AKLiveBadgeView(isAtLiveEdge: true)
            AKLiveBadgeView(isAtLiveEdge: false, liveDrift: 740)
        }
    }
}

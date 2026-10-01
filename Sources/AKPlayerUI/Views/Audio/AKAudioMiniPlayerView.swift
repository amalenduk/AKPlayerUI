//
//  AKAudioMiniPlayerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Floating / docked mini player bar optimized for audio playback.
/// Features glassmorphism, marquee track details, tactile transport buttons,
/// and smooth gesture transitions into full-screen.
public struct AKAudioMiniPlayerView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var theme: AKPlayerTheme

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        theme: AKPlayerTheme = .standard
    ) {
        self.coordinator = coordinator
        self.theme = theme
    }

    private var progressRatio: Double {
        guard coordinator.duration > 0 else { return 0 }
        return max(0, min(1, coordinator.currentTime / coordinator.duration))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Hairline Progress Bar
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 2.5)

                    Rectangle()
                        .fill(coordinator.adManager.isAdActive ? theme.palette.adActiveProgress : theme.palette.accent)
                        .frame(width: proxy.size.width * CGFloat(progressRatio), height: 2.5)
                        .animation(.linear(duration: 0.25), value: progressRatio)
                }
            }
            .frame(height: 2.5)

            // Main Bar Content
            HStack(spacing: 12) {
                // Artwork Thumbnail
                thumbnailView

                // Track Title & Artist
                trackInfoView

                Spacer(minLength: 8)

                // Compact Transport Buttons
                transportButtons
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 6)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            coordinator.expand()
        }
    }

    // MARK: - Subviews

    private var thumbnailView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [theme.palette.accent.opacity(0.8), Color(white: 0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "music.note")
                        .font(theme.typography.title3)
                        .foregroundColor(.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var trackInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(coordinator.currentTitle)
                .font(theme.typography.subheadline.weight(.semibold))
                .foregroundColor(theme.palette.foregroundPrimary)
                .lineLimit(1)

            HStack(spacing: 6) {
                if coordinator.isPlaying {
                    Image(systemName: "waveform")
                        .font(theme.typography.caption2)
                        .foregroundColor(theme.palette.accent)
                }

                Text(coordinator.currentSubtitle.isEmpty ? "Audio" : coordinator.currentSubtitle)
                    .font(theme.typography.caption1)
                    .foregroundColor(theme.palette.foregroundSecondary)
                    .lineLimit(1)
            }
        }
    }

    private var transportButtons: some View {
        HStack(spacing: 12) {
            // Play / Pause Button
            Button(action: { coordinator.togglePlayPause() }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 36, height: 36)

                    if coordinator.isBuffering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: theme.palette.foregroundPrimary))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: coordinator.isPlaying ? "pause.fill" : "play.fill")
                            .font(theme.typography.button)
                            .foregroundColor(theme.palette.foregroundPrimary)
                            .offset(x: coordinator.isPlaying ? 0 : 1)
                    }
                }
            }
            .buttonStyle(.plain)

            // Skip Forward Button
            Button(action: { coordinator.skipForward() }) {
                Image(systemName: "goforward.15")
                    .font(theme.typography.button)
                    .foregroundColor(theme.palette.foregroundPrimary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - SwiftUI Preview

#Preview("Audio Mini Player — Docked") {
    VStack {
        Spacer()
        AKAudioMiniPlayerView(coordinator: .previewAudioMock)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
    }
    .background(Color.black.ignoresSafeArea())
    .preferredColorScheme(.dark)
}

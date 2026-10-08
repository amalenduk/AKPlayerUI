//
//  AKAudioMiniPlayerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Floating / Docked Audio Mini Player Bar that docks above the host tab bar.
/// Standardized height (~60pt), artwork with animated waveform fallback, tactile controls, and continuous clipping.
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
        if coordinator.isLive {
            return 1.0
        }
        guard coordinator.duration > 0 else { return 0 }
        return max(0, min(1.0, coordinator.currentTime / coordinator.duration))
    }

    public var body: some View {
        VStack(spacing: AKSpacing.zero) {
            HStack(spacing: AKSpacing.sm) {
                // Miniature Artwork Thumbnail or Animated Waveform Fallback
                thumbnailView

                // Track Title & Artist Info
                trackInfoView
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        coordinator.expand()
                    }

                // Play / Pause and Close Controls
                transportButtons
            }
            .padding(.horizontal, AKSpacing.md)
            .padding(.vertical, AKSpacing.xs)

            // Bottom Progress Line (Cleanly clipped inside rounded corners)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(theme.palette.progressRailRemaining)
                        .frame(height: 2.5)

                    Rectangle()
                        .fill(
                            coordinator.adManager.isAdActive ? theme.palette.adActiveProgress :
                                (coordinator.isLive ? theme.palette.liveBadge : theme.palette.progressRailFill)
                        )
                        .frame(width: proxy.size.width * CGFloat(progressRatio), height: 2.5)
                        .animation(.linear(duration: 0.25), value: progressRatio)
                }
            }
            .frame(height: 2.5)
        }
        .background(
            ZStack {
                if let mat = theme.materials.materialStyle.material {
                    RoundedRectangle(cornerRadius: theme.materials.cardCornerRadius, style: .continuous)
                        .fill(mat)
                }
                RoundedRectangle(cornerRadius: theme.materials.cardCornerRadius, style: .continuous)
                    .fill(theme.palette.surface)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.materials.cardCornerRadius, style: .continuous)
                .stroke(
                    theme.palette.glassBorder.opacity(theme.materials.glassBorderOpacity),
                    lineWidth: theme.materials.glassBorderWidth
                )
        )
        .shadow(
            color: Color.black.opacity(theme.materials.shadowOpacity),
            radius: theme.materials.shadowRadius,
            x: 0,
            y: theme.materials.shadowY
        )
        // CRITICAL: Continuous clipping so progress bar cannot bleed outside rounded corners
        .clipShape(RoundedRectangle(cornerRadius: theme.materials.cardCornerRadius, style: .continuous))
        .padding(.horizontal, AKSpacing.sm)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var thumbnailView: some View {
        ZStack {
            if let artworkImage = coordinator.currentArtworkImage {
                Image(platformImage: artworkImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else if let artworkURL = coordinator.currentArtworkURL {
                AsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.6)
                    default:
                        miniWaveformFallback
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                miniWaveformFallback
            }
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            coordinator.expand()
        }
    }

    /// Dynamic animated waveform displayed when no static artwork is available.
    private var miniWaveformFallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.palette.accent.opacity(0.4),
                            Color(red: 0.15, green: 0.15, blue: 0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(theme.palette.accent.opacity(0.3), lineWidth: 1)
                )

            AKMiniWaveformBarView(
                isPlaying: coordinator.isPlaying,
                accentColor: theme.palette.accent
            )
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        .frame(width: 44, height: 44)
    }

    private var trackInfoView: some View {
        VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
            Text(coordinator.currentTitle.isEmpty ? "Audio Media" : coordinator.currentTitle)
                .font(theme.typography.subheadline.weight(.semibold))
                .foregroundColor(theme.palette.foregroundPrimary)
                .lineLimit(1)

            HStack(spacing: AKSpacing.xxs) {
                if coordinator.isPlaying {
                    Image(systemName: "waveform")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(theme.palette.accent)
                }

                Text(coordinator.currentSubtitle.isEmpty ? "Audio" : coordinator.currentSubtitle)
                    .font(theme.typography.caption2)
                    .foregroundColor(theme.palette.foregroundSecondary)
                    .lineLimit(1)
            }
        }
    }

    private var transportButtons: some View {
        HStack(spacing: AKSpacing.xs) {
            // Play / Pause Button
            Button(action: { coordinator.togglePlayPause() }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 36, height: 36)

                    if coordinator.isBuffering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: theme.palette.foregroundPrimary))
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: coordinator.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(theme.palette.foregroundPrimary)
                            .offset(x: coordinator.isPlaying ? 0 : 1)
                    }
                }
            }
            .buttonStyle(.plain)

            // Close / Dismiss Button
            Button(action: { coordinator.dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 30, height: 30)

                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.75))
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Animated Dynamic Waveform Bars for Audio Thumbnail
public struct AKMiniWaveformBarView: View {
    public let isPlaying: Bool
    public let accentColor: Color

    public init(isPlaying: Bool, accentColor: Color) {
        self.isPlaying = isPlaying
        self.accentColor = accentColor
    }

    @State private var phase: CGFloat = 0

    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.15, paused: !isPlaying)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2.5) {
                bar(heightFactor: isPlaying ? sin(date * 6.0) * 0.4 + 0.6 : 0.4)
                bar(heightFactor: isPlaying ? cos(date * 8.0) * 0.35 + 0.65 : 0.8)
                bar(heightFactor: isPlaying ? sin(date * 5.0 + 1.0) * 0.45 + 0.55 : 0.5)
                bar(heightFactor: isPlaying ? cos(date * 7.0 + 2.0) * 0.3 + 0.7 : 0.9)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func bar(heightFactor: Double) -> some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: max(2, geo.size.width),
                        height: max(3, geo.size.height * CGFloat(max(0.2, min(1.0, heightFactor))))
                    )
            }
        }
    }
}

// MARK: - SwiftUI Preview
#Preview("Audio Mini Player — Docked") {
    VStack {
        Spacer()
        AKAudioMiniPlayerView(coordinator: .previewAudioMock)
            .padding(.bottom, AKSpacing.lg)
    }
    .background(Color.black.ignoresSafeArea())
    .preferredColorScheme(.dark)
}

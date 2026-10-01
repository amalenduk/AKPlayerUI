//
//  AKAudioPlayerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Flagship modern, glassmorphic full-screen audio player surface.
/// Features reactive blurred artwork, breathing spring scale animations, waveform scrubbing,
/// transport controls, and auxiliary triggers for lyrics, equalizer, chapters, and queue.
public struct AKAudioPlayerView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var theme: AKPlayerTheme

    @State private var isFavorite: Bool = false
    @State private var artworkScale: CGFloat = 1.0

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        theme: AKPlayerTheme = .standard
    ) {
        self.coordinator = coordinator
        self.theme = theme
    }

    public var body: some View {
        ZStack {
            // 1. Ambient Blurred Artwork Background
            backgroundSurface

            // 2. Main Player Surface
            VStack(spacing: AKSpacing.zero) {
                // Top Navigation Bar
                topBar
                    .padding(.horizontal, AKSpacing.xl)
                    .padding(.top, AKSpacing.md)

                Spacer(minLength: AKSpacing.md)

                // Hero Artwork with spring zoom physics
                heroArtwork
                    .padding(.horizontal, AKSpacing.xxl)
                    .layoutPriority(1)

                Spacer(minLength: AKSpacing.xl)

                // Track Metadata & Favorite
                metadataRow
                    .padding(.horizontal, AKSpacing.xl)

                // Waveform / Progress Scrub Rail
                progressRailSection
                    .padding(.horizontal, AKSpacing.xl)
                    .padding(.top, AKSpacing.lg)

                // Primary Transport Bar (Play/Pause, Skips, Shuffle, Repeat)
                transportControls
                    .padding(.horizontal, AKSpacing.xl)
                    .padding(.top, AKSpacing.sm)

                // Bottom Sheet Triggers (Lyrics, Equalizer, Chapters, Queue)
                bottomAuxiliaryToolbar
                    .padding(.horizontal, AKSpacing.xl)
                    .padding(.top, AKSpacing.xl)
                    .padding(.bottom, AKSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $coordinator.activeSheet) { sheet in
            sheetView(for: sheet)
        }
    }

    // MARK: - Subviews

    private var backgroundSurface: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                // Ambient tinted glow
                theme.palette.accent
                    .opacity(0.18)
                    .blur(radius: 90)
                    .scaleEffect(1.3)

                // Dynamic Artwork or Abstract Gradient
                LinearGradient(
                    colors: [
                        theme.palette.accent.opacity(0.35),
                        Color(white: 0.08).opacity(0.95),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Ultra-thin glass material blur
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .opacity(0.7)
            }
        }
    }

    private var topBar: some View {
        HStack {
            // Collapse Chevron Button
            Button(action: { coordinator.collapse() }) {
                Image(systemName: "chevron.down")
                    .font(theme.typography.button)
                    .foregroundColor(theme.palette.foregroundPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Header Pill
            VStack(spacing: AKSpacing.xxxs) {
                Text("PLAYING FROM PLAYLIST")
                    .font(theme.typography.badgeSmall)
                    .foregroundColor(theme.palette.foregroundTertiary)
                    .tracking(1.2)

                Text(coordinator.currentTitle)
                    .font(theme.typography.caption1.weight(.semibold))
                    .foregroundColor(theme.palette.foregroundSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Action Menu
            Menu {
                Button(action: { coordinator.presentSheet(.equalizer) }) {
                    Label("Equalizer & Audio DSP", systemImage: "slider.vertical.3")
                }
                Button(action: { coordinator.presentSheet(.chapters) }) {
                    Label("Chapters", systemImage: "list.bullet.indent")
                }
                Button(action: { coordinator.presentSheet(.trackSelection) }) {
                    Label("Audio & Subtitles", systemImage: "waveform.badge.magnifyingglass")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(theme.typography.button)
                    .foregroundColor(theme.palette.foregroundPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    private var heroArtwork: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height, 340)
            ZStack {
                // Drop shadow glow
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(theme.palette.accent.opacity(coordinator.isPlaying ? 0.35 : 0.12))
                    .frame(width: side, height: side)
                    .blur(radius: coordinator.isPlaying ? 24 : 12)
                    .offset(y: 12)

                // Artwork Card
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.palette.accent.opacity(0.7),
                                Color(white: 0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: side, height: side)
                    .overlay(
                        VStack(spacing: AKSpacing.md) {
                            Image(systemName: "music.note")
                                .font(.system(size: side * 0.28, weight: .light))
                                .foregroundColor(.white.opacity(0.85))

                            if let chapter = coordinator.activeChapter {
                                Text(chapter.title)
                                    .font(theme.typography.footnote.weight(.medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, AKSpacing.md)
                                    .padding(.vertical, AKSpacing.xs)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .scaleEffect(coordinator.isPlaying ? 1.0 : 0.88)
                    .animation(.spring(response: 0.45, dampingFraction: 0.72), value: coordinator.isPlaying)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var metadataRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: AKSpacing.xxs) {
                Text(coordinator.currentTitle)
                    .font(theme.typography.title2.weight(.bold))
                    .foregroundColor(theme.palette.foregroundPrimary)
                    .lineLimit(1)

                Text(coordinator.currentSubtitle.isEmpty ? "Unknown Artist" : coordinator.currentSubtitle)
                    .font(theme.typography.subheadline)
                    .foregroundColor(theme.palette.foregroundSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Heart / Favorite Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isFavorite.toggle()
                }
            }) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(theme.typography.title2)
                    .foregroundColor(isFavorite ? .red : theme.palette.foregroundSecondary)
                    .scaleEffect(isFavorite ? 1.15 : 1.0)
            }
            .buttonStyle(.plain)
        }
    }

    private var progressRailSection: some View {
        VStack(spacing: AKSpacing.xs) {
            // Interactive Timeline Slider with Cue Points
            AKTimelineSlider(
                currentTime: coordinator.currentTime,
                duration: coordinator.duration,
                bufferedTime: coordinator.bufferedTime,
                cuePoints: coordinator.interstitialMarkers.map { $0.time },
                isAdActive: coordinator.adManager.isAdActive,
                palette: theme.palette,
                typography: theme.typography,
                onScrubEnded: { coordinator.seek(to: $0) }
            )
        }
    }

    private var transportControls: some View {
        HStack(spacing: AKSpacing.zero) {
            // Shuffle Button
            Button(action: { coordinator.toggleShuffle() }) {
                Image(systemName: "shuffle")
                    .font(theme.typography.title3)
                    .foregroundColor(coordinator.isShuffled ? theme.palette.accent : theme.palette.foregroundSecondary)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)

            Spacer()

            // Skip Backward
            AKSeekButton(
                direction: .backward,
                stepSeconds: coordinator.configuration.playback.skipBackwardDuration,
                foregroundColor: theme.palette.foregroundPrimary,
                onSeek: { coordinator.skipBackward() }
            )

            Spacer()

            // Main Play / Pause Button (SRP)
            AKPlayPauseButton(
                isPlaying: coordinator.isPlaying,
                isBuffering: coordinator.isBuffering,
                size: 72,
                iconColor: theme.palette.foregroundPrimary,
                backgroundColor: theme.palette.accent.opacity(0.85),
                onToggle: { coordinator.togglePlayPause() }
            )

            Spacer()

            // Skip Forward
            AKSeekButton(
                direction: .forward,
                stepSeconds: coordinator.configuration.playback.skipForwardDuration,
                foregroundColor: theme.palette.foregroundPrimary,
                onSeek: { coordinator.skipForward() }
            )

            Spacer()

            // Repeat Mode Button
            Button(action: { coordinator.toggleRepeatMode() }) {
                Image(systemName: coordinator.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(theme.typography.title3)
                    .foregroundColor(coordinator.repeatMode != .off ? theme.palette.accent : theme.palette.foregroundSecondary)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
        }
    }

    private var bottomAuxiliaryToolbar: some View {
        HStack {
            // Lyrics Trigger
            Button(action: { coordinator.presentSheet(.lyrics) }) {
                Image(systemName: "quote.bubble")
                    .font(theme.typography.button)
                    .foregroundColor(coordinator.activeSheet == .lyrics ? theme.palette.accent : theme.palette.foregroundSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            // Equalizer Trigger
            Button(action: { coordinator.presentSheet(.equalizer) }) {
                HStack(spacing: AKSpacing.xs) {
                    Image(systemName: "slider.vertical.3")
                        .font(theme.typography.button)
                    if coordinator.equalizer.isEnabled {
                        Circle()
                            .fill(theme.palette.accent)
                            .frame(width: 6, height: 6)
                    }
                }
                .foregroundColor(coordinator.equalizer.isEnabled ? theme.palette.accent : theme.palette.foregroundSecondary)
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            // Chapters Trigger
            Button(action: { coordinator.presentSheet(.chapters) }) {
                Image(systemName: "list.bullet.indent")
                    .font(theme.typography.button)
                    .foregroundColor(coordinator.activeSheet == .chapters ? theme.palette.accent : theme.palette.foregroundSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            // Up Next Queue Trigger
            Button(action: { coordinator.presentSheet(.queue) }) {
                Image(systemName: "list.dash")
                    .font(theme.typography.button)
                    .foregroundColor(coordinator.activeSheet == .queue ? theme.palette.accent : theme.palette.foregroundSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Auxiliary Sheet Resolver

    @ViewBuilder
    private func sheetView(for sheet: AKPlayerAuxiliarySheet) -> some View {
        switch sheet {
        case .equalizer:
            AKEqualizerView(equalizer: coordinator.equalizer, palette: theme.palette, typography: theme.typography)
        case .lyrics:
            AKLyricsView(coordinator: coordinator, palette: theme.palette, typography: theme.typography)
        case .chapters:
            AKChapterSheet(coordinator: coordinator, palette: theme.palette, typography: theme.typography)
        case .queue:
            AKQueueSheet(coordinator: coordinator, palette: theme.palette, typography: theme.typography)
        case .trackSelection:
            AKTrackSelectorSheet(coordinator: coordinator, palette: theme.palette, typography: theme.typography)
        case .details:
            AKEqualizerView(equalizer: coordinator.equalizer, palette: theme.palette, typography: theme.typography)
        }
    }
}

// MARK: - SwiftUI Preview

#Preview("Audio Player") {
    AKAudioPlayerView(coordinator: .previewAudioMock)
        .preferredColorScheme(.dark)
}

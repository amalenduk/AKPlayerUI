//
//  AKAudioPlayerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Flagship modern, glassmorphic full-screen audio player surface.
/// Supports 3 placement modes for auxiliary tools (Lyrics, Chapters, Queue, Equalizer):
/// 1. `.inline`: In-player split view with sticky top playback bar & lower scrollable content.
/// 2. `.sheet`: Interactive Apple-style modal bottom sheet with fractional detents.
/// 3. `.sideDrawer`: Elevated slide-in frosted glass drawer panel.
public struct AKAudioPlayerView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    @ObservedObject public var uiState: AKPlayerUIState
    public var theme: AKPlayerTheme

    @State private var isFavorite: Bool = false

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        uiState: AKPlayerUIState? = nil,
        theme: AKPlayerTheme = .standard
    ) {
        self.coordinator = coordinator
        self.uiState = uiState ?? coordinator.uiState
        self.theme = theme
    }

    private var isInlineActive: Bool {
        uiState.isInlineActive(isAudioOnly: true)
    }

    private var isDrawerActive: Bool {
        uiState.isDrawerActive
    }

    public var body: some View {
        ZStack {
            // 1. Ambient Blurred Artwork Background
            backgroundSurface

            // 2. Main Player Surface
            VStack(spacing: AKSpacing.zero) {
                if isInlineActive, let activeOverlay = uiState.activeInlineOverlay {
                    // INLINE SPLIT MODE: Sticky Top Playback Bar + Lower Content
                    inlineTopPlaybackBar
                        .padding(.horizontal, AKSpacing.lg)
                        .padding(.top, AKSpacing.md)
                        .padding(.bottom, AKSpacing.xs)
                        .transition(.move(edge: .top).combined(with: .opacity))

                    // Lower Auxiliary Content Canvas
                    auxiliaryOverlayView(for: activeOverlay, placement: .inline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    // STANDARD HERO MODE: Full Artwork + Primary Controls
                    topBar
                        .padding(.horizontal, AKSpacing.xl)
                        .padding(.top, AKSpacing.md)

                    Spacer(minLength: AKSpacing.xs)

                    heroArtwork
                        .padding(.horizontal, AKSpacing.xl)
                        .layoutPriority(1)

                    Spacer(minLength: AKSpacing.sm)

                    metadataRow
                        .padding(.horizontal, AKSpacing.xl)

                    progressRailSection
                        .padding(.horizontal, AKSpacing.xl)
                        .padding(.top, AKSpacing.md)

                    transportControls
                        .padding(.horizontal, AKSpacing.xl)
                        .padding(.top, AKSpacing.xs)
                }

                // Bottom Auxiliary Selector Toolbar (always accessible)
                bottomAuxiliaryToolbar
                    .padding(.horizontal, AKSpacing.xl)
                    .padding(.top, AKSpacing.sm)
                    .padding(.bottom, AKSpacing.lg)
            }

            // 3. SIDE DRAWER MODE: Slide-in Floating Frosted Glass Panel
            if isDrawerActive, let activeOverlay = uiState.activeInlineOverlay {
                // Dimmed Backdrop
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        coordinator.dismissAuxiliary()
                    }
                    .transition(.opacity)

                // Trailing Drawer Panel (Restricted to safe area height - non-full-screen)
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Spacer()

                        auxiliaryOverlayView(for: activeOverlay, placement: .sideDrawer)
                            .frame(width: min(geo.size.width * 0.88, 380))
                    }
                }
                .transition(.move(edge: .trailing))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: uiState.activeInlineOverlay)
        .sheet(item: $uiState.activeSheet) { sheet in
            auxiliaryOverlayView(for: sheet, placement: .sheet)
                .presentationDetents([.fraction(0.68), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(red: 0.11, green: 0.11, blue: 0.15).opacity(0.96))
        }
        .environment(\.akPlayerTheme, theme)
    }

    // MARK: - Subviews: Background & Navigation

    private var backgroundSurface: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                // Ambient tinted glow
                theme.palette.accent
                    .opacity(0.22)
                    .blur(radius: 80)
                    .scaleEffect(1.2)

                // Dynamic Abstract Gradient
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

                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .opacity(0.65)
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
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Header Pill
            VStack(spacing: AKSpacing.xxxs) {
                Text("PLAYING FROM LIBRARY")
                    .font(theme.typography.badgeSmall)
                    .foregroundColor(theme.palette.foregroundTertiary)
                    .tracking(1.2)

                Text(coordinator.currentTitle.isEmpty ? "Media Title" : coordinator.currentTitle)
                    .font(theme.typography.caption1.weight(.semibold))
                    .foregroundColor(theme.palette.foregroundSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Menu
            Menu {
                Section("Overlay Placement Mode") {
                    ForEach(AKOverlayPlacementMode.allCases) { mode in
                        Button(action: { uiState.overlayPlacement = mode }) {
                            HStack {
                                Text(mode.rawValue)
                                if uiState.overlayPlacement == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Section("Tools") {
                    Button(action: { uiState.presentSheet(.equalizer) }) {
                        Label("Equalizer & DSP", systemImage: "slider.vertical.3")
                    }
                    Button(action: { uiState.presentSheet(.chapters) }) {
                        Label("Chapters", systemImage: "list.bullet.indent")
                    }
                    Button(action: { uiState.presentSheet(.queue) }) {
                        Label("Queue", systemImage: "list.star")
                    }
                    Button(action: { uiState.presentSheet(.trackSelection) }) {
                        Label("Audio & Subtitles", systemImage: "waveform.badge.magnifyingglass")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(theme.typography.button)
                    .foregroundColor(theme.palette.foregroundPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Subviews: Inline Sticky Top Playback Bar

    private var inlineTopPlaybackBar: some View {
        VStack(spacing: AKSpacing.xxs) {
            HStack(spacing: AKSpacing.sm) {
                // Artwork Thumbnail
                ZStack {
                    if let artworkImage = coordinator.currentArtworkImage {
                        Image(platformImage: artworkImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 42, height: 42)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(theme.palette.accent.opacity(0.4))
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .frame(width: 42, height: 42)

                // Title & Subtitle Info
                VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
                    Text(coordinator.currentTitle)
                        .font(theme.typography.footnote.weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(coordinator.currentSubtitle.isEmpty ? "Audio" : coordinator.currentSubtitle)
                        .font(theme.typography.caption2)
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Compact Transport
                HStack(spacing: AKSpacing.xs) {
                    Button(action: { coordinator.skipBackward() }) {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)

                    Button(action: { coordinator.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(theme.palette.accent)
                                .frame(width: 36, height: 36)

                            Image(systemName: coordinator.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: coordinator.isPlaying ? 0 : 1)
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { coordinator.skipForward() }) {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)

                    // Return to Hero Artwork (Collapse Inline)
                    Button(action: { uiState.dismissAuxiliary() }) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Compact Hairline Scrubber
            GeometryReader { geo in
                let progress = coordinator.duration > 0 ? max(0, min(1.0, coordinator.currentTime / coordinator.duration)) : 0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 3)

                    Capsule()
                        .fill(theme.palette.accent)
                        .frame(width: geo.size.width * CGFloat(progress), height: 3)
                }
            }
            .frame(height: 3)
            .padding(.top, AKSpacing.xxs)
        }
        .padding(.horizontal, AKSpacing.md)
        .padding(.vertical, AKSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.16).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Subviews: Hero Artwork & Standard Controls

    private var heroArtwork: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height, 320)
            ZStack {
                // Drop shadow ambient glow
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.palette.accent.opacity(coordinator.isPlaying ? 0.38 : 0.12))
                    .frame(width: side, height: side)
                    .blur(radius: coordinator.isPlaying ? 24 : 12)
                    .offset(y: 10)

                // Artwork Card
                ZStack {
                    if let artworkImage = coordinator.currentArtworkImage {
                        Image(platformImage: artworkImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: side, height: side)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    } else if let artworkURL = coordinator.currentArtworkURL {
                        AsyncImage(url: artworkURL) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().aspectRatio(contentMode: .fill)
                            default:
                                defaultArtworkPlaceholder(side: side)
                            }
                        }
                        .frame(width: side, height: side)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    } else {
                        defaultArtworkPlaceholder(side: side)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .scaleEffect(coordinator.isPlaying ? 1.0 : 0.92)
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: coordinator.isPlaying)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func defaultArtworkPlaceholder(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.palette.accent.opacity(0.65),
                            Color(white: 0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: AKSpacing.md) {
                Image(systemName: "music.note")
                    .font(.system(size: side * 0.26, weight: .light))
                    .foregroundColor(.white.opacity(0.85))

                if let chapter = coordinator.activeChapter {
                    Text(chapter.title)
                        .font(theme.typography.footnote.weight(.medium))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, AKSpacing.md)
                        .padding(.vertical, AKSpacing.xs)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(width: side, height: side)
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
                    .frame(width: 44, height: 44)
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

            // Play / Pause Central Button (Autonomous AKPlayer binding)
            AKPlayPauseButton(
                player: coordinator.player,
                size: 68
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
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    private var bottomAuxiliaryToolbar: some View {
        HStack(spacing: AKSpacing.sm) {
            // Placement Mode Selector Pill
            Menu {
                ForEach(AKOverlayPlacementMode.allCases) { mode in
                    Button(action: { uiState.overlayPlacement = mode }) {
                        Label(mode.rawValue, systemImage: mode.iconName)
                    }
                }
            } label: {
                HStack(spacing: AKSpacing.xxs) {
                    Image(systemName: uiState.overlayPlacement.iconName)
                    Text(uiState.overlayPlacement.rawValue)
                }
                .font(theme.typography.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, AKSpacing.sm)
                .padding(.vertical, AKSpacing.xs)
                .background(Capsule().fill(Color.white.opacity(0.12)))
            }

            Spacer()

            // Lyrics Button
            auxiliaryButton(sheet: .lyrics, icon: "quote.bubble", label: "Lyrics")

            // Equalizer Button
            auxiliaryButton(sheet: .equalizer, icon: "slider.vertical.3", label: "EQ")

            // Chapters Button
            auxiliaryButton(sheet: .chapters, icon: theme.icons.chapters, label: "Chapters")

            // Queue Button
            auxiliaryButton(sheet: .queue, icon: "music.note.list", label: "Queue")
        }
    }

    private func auxiliaryButton(sheet: AKPlayerAuxiliarySheet, icon: String, label: String) -> some View {
        let isSelected = uiState.activeInlineOverlay == sheet || uiState.activeSheet == sheet

        return Button(action: {
            uiState.toggle(sheet, isAudioOnly: true)
        }) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : theme.palette.foregroundSecondary)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(isSelected ? theme.palette.accent : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Unified Auxiliary Overlay Factory

    @ViewBuilder
    private func auxiliaryOverlayView(for sheet: AKPlayerAuxiliarySheet, placement: AKOverlayPlacementMode) -> some View {
        switch sheet {
        case .lyrics:
            AKLyricsView(
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .chapters:
            AKChapterSheet(
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .queue:
            AKQueueSheet(
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .equalizer:
            AKEqualizerView(
                equalizer: coordinator.equalizer,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                title: "10-Band Graphic Equalizer",
                subtitle: "Digital Signal Processing • 32Hz – 16kHz",
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .trackSelection:
            AKTrackSelectorSheet(
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .details:
            AKEqualizerView(
                equalizer: coordinator.equalizer,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                title: "Audio Details",
                subtitle: coordinator.currentTitle,
                onDismiss: { uiState.dismissAuxiliary() }
            )
        }
    }
}

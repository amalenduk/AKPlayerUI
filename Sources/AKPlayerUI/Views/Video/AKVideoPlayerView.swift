//
//  AKVideoPlayerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Flagship Fullscreen Video Player View featuring autohiding glass HUD, split touch gestures,
/// capability-driven controls, floating bottom HUD island, and native ad overlays.
public struct AKVideoPlayerView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    @ObservedObject public var uiState: AKPlayerUIState
    public let theme: AKPlayerTheme
    
    @State private var isHUDVisible: Bool = true
    @State private var isScreenLocked: Bool = false
    @State private var hideHUDTask: Task<Void, Never>?
    
    public init(
        coordinator: AKPlayerCoordinator = .shared,
        uiState: AKPlayerUIState? = nil,
        theme: AKPlayerTheme = .standard
    ) {
        self.coordinator = coordinator
        self.uiState = uiState ?? coordinator.uiState
        self.theme = theme
    }
    
    private var isDrawerActive: Bool {
        uiState.isDrawerActive
    }
    
    public var body: some View {
        ZStack {
            // Background Canvas
            Color.black.ignoresSafeArea()
            
            // 1. Video Surface Pipeline
            AKVideoSurfaceView(
                player: coordinator.player,
                aspectRatio: coordinator.aspectRatio
            )
            .ignoresSafeArea()
            
            // 2. Gesture Surface (Edge swipes, double-tap seek, pinch zoom)
            if !isScreenLocked {
                AKVideoGestureOverlay(
                    configuration: coordinator.configuration.gestures,
                    coordinator: coordinator,
                    isHUDVisible: isHUDVisible,
                    canSeek: coordinator.capabilities.canSeek,
                    canPlayFastForward: (coordinator.capabilities.canPlayFastForward || (coordinator.currentMedia?.canPlay(at: .custom(2.0)) ?? false) || coordinator.capabilities.canSeek) && !coordinator.adManager.isAdActive,
                    canPlayFastReverse: (coordinator.capabilities.canPlayFastReverse || (coordinator.currentMedia?.canPlay(at: .custom(-2.0)) ?? false)) && !coordinator.adManager.isAdActive,
                    typography: theme.typography,
                    onSingleTap: {
                        toggleHUD()
                    },
                    onDoubleTapSeek: { direction in
                        guard coordinator.capabilities.canSeek else { return }
                        hideHUDTask?.cancel()
                        withAnimation(.easeOut(duration: 0.2)) {
                            isHUDVisible = false
                        }
                        if direction == .backward {
                            coordinator.skipBackward()
                        } else {
                            coordinator.skipForward()
                        }
                    },
                    onVolumeChanged: { _ in
                        resetHUDTimer()
                    },
                    onBrightnessChanged: { _ in
                        resetHUDTimer()
                    },
                    onGestureActiveChanged: { isActive in
                        if isActive {
                            hideHUDTask?.cancel()
                            withAnimation(.easeOut(duration: 0.2)) {
                                isHUDVisible = false
                            }
                        }
                    },
                    onFastPlaybackBegan: { targetRate in
                        coordinator.setPlaybackRate(AKPlaybackRate(rate: targetRate))
                    },
                    onFastPlaybackEnded: {
                        coordinator.setPlaybackRate(.normal)
                    }
                )
            } else {
                // Screen is locked: Tap anywhere reveals unlock button
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isHUDVisible.toggle()
                        }
                        if isHUDVisible {
                            resetHUDTimer()
                        }
                    }
            }
            
            // 3. Native Interstitial Ad Overlay
            AKAdOverlayView(
                adManager: coordinator.adManager,
                palette: theme.palette
            )
            
            // 4. Autohiding Glass HUD Overlays
            if isHUDVisible {
                if isScreenLocked {
                    // Locked State HUD: Only the lock badge on left edge
                    HStack {
                        lockButton
                            .padding(.leading, AKSpacing.xl)
                        Spacer()
                    }
                    .transition(.opacity)
                } else {
                    // Normal Unlocked HUD
                    VStack {
                        // Top Navigation & Tool Bar
                        topBar
                            .transition(.move(edge: .top).combined(with: .opacity))
                        
                        Spacer()
                        
                        // Floating Bottom Island Card
                        bottomCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .overlay(alignment: .leading) {
                        lockButton
                            .padding(.leading, AKSpacing.xl)
                            .padding(.top, 40)
                    }
                }
            }
            
            // 5. Side Drawer Mode: Slide-in Floating Frosted Glass Panel
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
                        
                        sheetView(for: activeOverlay, placement: .sideDrawer)
                            .frame(width: min(geo.size.width * 0.88, 380))
                    }
                }
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: uiState.activeInlineOverlay)
        .animation(.easeInOut(duration: 0.25), value: isScreenLocked)
        .onAppear {
            resetHUDTimer()
        }
        .sheet(item: $uiState.activeSheet) { sheet in
            sheetView(for: sheet, placement: .sheet)
                .presentationDetents(presentationDetents(for: sheet))
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(red: 0.11, green: 0.11, blue: 0.15).opacity(0.96))
        }
        .environment(\.akPlayerTheme, theme)
    }
    
    // MARK: - Subviews
    
    private var lockButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                isScreenLocked.toggle()
            }
            resetHUDTimer()
        }) {
            Image(systemName: isScreenLocked ? "lock.fill" : "lock.open")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isScreenLocked ? theme.palette.accent : theme.palette.textPrimary)
                .frame(width: 40, height: 40)
                .akGlassCircle()
        }
        .buttonStyle(.plain)
    }
    
    private var topBar: some View {
        HStack(spacing: AKSpacing.md) {
            // Collapse / Dismiss Button
            Button(action: {
                coordinator.collapse()
            }) {
                Image(systemName: "chevron.backward")
                    .font(theme.typography.button)
                    .foregroundColor(theme.palette.textPrimary)
                    .frame(width: 40, height: 40)
                    .akGlassCircle()
            }
            .buttonStyle(.plain)
            
            // Media Title & Metadata
            VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
                Text(coordinator.currentTitle)
                    .font(theme.typography.headline.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if !coordinator.currentSubtitle.isEmpty {
                    Text(coordinator.currentSubtitle)
                        .font(theme.typography.caption1)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Auxiliary Tools
            HStack(spacing: AKSpacing.sm) {
                // Audio Track Trigger
                toolButton(icon: "speaker.wave.2.fill") {
                    uiState.presentSheet(.trackSelection, isAudioOnly: coordinator.isAudioOnly)
                }

                // Equalizer Sheet Trigger
                if coordinator.configuration.capabilities.showsEqualizer {
                    toolButton(icon: theme.icons.equalizer) {
                        uiState.presentSheet(.equalizer, isAudioOnly: coordinator.isAudioOnly)
                    }
                }
                
                // Chapters Sheet Trigger
                if coordinator.configuration.capabilities.showsChapters && !coordinator.chapters.isEmpty {
                    toolButton(icon: theme.icons.chapters) {
                        uiState.presentSheet(.chapters, isAudioOnly: coordinator.isAudioOnly)
                    }
                }
                
                // Close / Dismiss Player Button
                toolButton(icon: "xmark") {
                    coordinator.dismiss()
                }
            }
        }
        .padding(.horizontal, AKSpacing.xl)
        .padding(.top, AKSpacing.xl)
    }
    
    // MARK: - Floating Bottom Island HUD Card
    
    private var bottomCard: some View {
        VStack(spacing: AKSpacing.md) {
            // Row 1: Full-Width Scrubber Timeline with Timestamps
            AKTimelineSlider(
                currentTime: coordinator.currentTime,
                duration: coordinator.duration,
                loadedTimeRanges: coordinator.loadedTimeRanges,
                markers: coordinator.adManager.markers,
                cuePoints: coordinator.adManager.cuePoints.isEmpty ? coordinator.configuration.ads.cuePoints : coordinator.adManager.cuePoints,
                isAdActive: coordinator.adManager.isAdActive,
                isSeekEnabled: coordinator.capabilities.canSeek,
                isLive: coordinator.isLive,
                isAtLiveEdge: coordinator.isAtLiveEdge,
                liveOffset: coordinator.liveOffset,
                palette: theme.palette,
                typography: theme.typography,
                onJumpToLive: {
                    coordinator.jumpToLive()
                    resetHUDTimer()
                },
                onScrubBegan: {
                    hideHUDTask?.cancel()
                },
                onScrubChanged: { _ in
                    hideHUDTask?.cancel()
                },
                onScrubEnded: { targetTime in
                    coordinator.seek(to: targetTime)
                    resetHUDTimer()
                }
            )
            
            // Row 2: Central Hero Transport Controls
            HStack(spacing: AKSpacing.xxl) {
                // Skip Backward
                if coordinator.configuration.capabilities.showsSkipButtons {
                    AKSeekButton(
                        direction: .backward,
                        stepSeconds: coordinator.configuration.playback.skipBackwardDuration,
                        isEnabled: coordinator.capabilities.canSeek
                    ) {
                        coordinator.skipBackward()
                        resetHUDTimer()
                    }
                }
                
                // Hero Play/Pause Button (64pt Crystalline Glass)
                AKPlayPauseButton(
                    state: coordinator.state,
                    autoPlay: coordinator.autoPlay,
                    size: 64,
                    style: .glass
                ) {
                    coordinator.player.togglePlayPause()
                    resetHUDTimer()
                }
                
                // Skip Forward
                if coordinator.configuration.capabilities.showsSkipButtons {
                    AKSeekButton(
                        direction: .forward,
                        stepSeconds: coordinator.configuration.playback.skipForwardDuration,
                        isEnabled: coordinator.capabilities.canSeek
                    ) {
                        coordinator.skipForward()
                        resetHUDTimer()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Row 3: Thumb Action Corner Controls
            HStack {
                // Left Thumb: Visual Controls (Aspect Ratio + Subtitles [CC])
                HStack(spacing: AKSpacing.xs) {
                    // Aspect Ratio Pill Menu
                    if coordinator.configuration.capabilities.showsAspectSelector {
                        Menu {
                            ForEach(AKVideoAspectRatio.allCases) { ratio in
                                Button(action: {
                                    coordinator.aspectRatio = ratio
                                    resetHUDTimer()
                                }) {
                                    HStack {
                                        Text(ratio.rawValue)
                                        if coordinator.aspectRatio == ratio {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: AKSpacing.xxs) {
                                Image(systemName: "aspectratio")
                                Text(coordinator.aspectRatio.rawValue)
                                    .font(theme.typography.caption1.weight(.semibold))
                            }
                            .foregroundColor(theme.palette.textPrimary)
                            .padding(.horizontal, AKSpacing.sm)
                            .padding(.vertical, 7)
                            .akGlassPill()
                        }
                    }
                    
                    // Subtitles [CC] Quick Button
                    Button(action: {
                        uiState.presentSheet(.trackSelection, isAudioOnly: coordinator.isAudioOnly)
                    }) {
                        HStack(spacing: AKSpacing.xxs) {
                            Image(systemName: coordinator.selectedSubtitleTrack?.isOff == false ? "captions.bubble.fill" : "captions.bubble")
                            Text("CC")
                                .font(theme.typography.caption1.weight(.bold))
                        }
                        .foregroundColor(coordinator.selectedSubtitleTrack?.isOff == false ? theme.palette.accent : theme.palette.textPrimary)
                        .padding(.horizontal, AKSpacing.sm)
                        .padding(.vertical, 7)
                        .akGlassPill()
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Right Thumb: Audio & Secondary Controls (Speed Pill + More Actions Menu [≡])
                HStack(spacing: AKSpacing.xs) {
                    // Playback Speed Pill (e.g. 1.00x)
                    Button(action: {
                        uiState.presentSheet(.playbackSpeed, isAudioOnly: coordinator.isAudioOnly)
                    }) {
                        HStack(spacing: AKSpacing.xxxs) {
                            Text(AKPlaybackSpeedSheet.format(rate: coordinator.playbackRate))
                                .font(theme.typography.caption1.weight(.bold))
                        }
                        .foregroundColor(coordinator.playbackRate != 1.0 ? theme.palette.accent : theme.palette.textPrimary)
                        .padding(.horizontal, AKSpacing.sm)
                        .padding(.vertical, 7)
                        .akGlassPill()
                    }
                    .buttonStyle(.plain)
                    
                    // More Actions [≡] Button
                    Button(action: {
                        uiState.presentSheet(.moreOptions, isAudioOnly: coordinator.isAudioOnly)
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(theme.palette.textPrimary)
                            .frame(width: 32, height: 32)
                            .akGlassCircle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, AKSpacing.lg)
        .padding(.vertical, AKSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.35), location: 0.0),
                                    .init(color: Color.white.opacity(0.10), location: 0.5),
                                    .init(color: Color.white.opacity(0.05), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
                .shadow(color: Color.black.opacity(0.45), radius: 20, x: 0, y: 8)
        )
        .padding(.horizontal, AKSpacing.lg)
        .padding(.bottom, AKSpacing.md)
    }
    
    private func toolButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(theme.typography.button)
                .foregroundColor(theme.palette.textPrimary)
                .frame(width: 36, height: 36)
                .akGlassCircle()
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func sheetView(for sheet: AKPlayerAuxiliarySheet, placement: AKOverlayPlacementMode = .sheet) -> some View {
        switch sheet {
        case .playbackSpeed:
            AKPlaybackSpeedSheet(
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .moreOptions:
            AKMoreOptionsSheet(
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onSelectAction: { targetSheet in
                    uiState.presentSheet(targetSheet, isAudioOnly: coordinator.isAudioOnly)
                },
                onLockScreen: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isScreenLocked = true
                    }
                },
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .equalizer:
            AKEqualizerView(
                equalizer: coordinator.equalizer,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                title: "10-Band Graphic Equalizer",
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
        case .lyrics:
            AKLyricsView(
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
                title: "Media Details",
                onDismiss: { uiState.dismissAuxiliary() }
            )
        }
    }
    
    // MARK: - Presentation Detents

    private func presentationDetents(for sheet: AKPlayerAuxiliarySheet) -> Set<PresentationDetent> {
        switch sheet {
        case .playbackSpeed:
            return [.height(310)]
        case .moreOptions:
            return [.height(410), .medium]
        case .trackSelection, .equalizer, .chapters, .queue, .lyrics, .details:
            return [.fraction(0.68), .large]
        }
    }

    // MARK: - HUD Autohide Timer
    
    private func toggleHUD() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isHUDVisible.toggle()
        }
        if isHUDVisible {
            resetHUDTimer()
        } else {
            hideHUDTask?.cancel()
        }
    }
    
    private func resetHUDTimer() {
        hideHUDTask?.cancel()
        hideHUDTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if coordinator.isPlaying && uiState.activeSheet == nil && uiState.activeInlineOverlay == nil {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isHUDVisible = false
                    }
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Fullscreen Video Player") {
    AKVideoPlayerView(coordinator: .previewMock)
}

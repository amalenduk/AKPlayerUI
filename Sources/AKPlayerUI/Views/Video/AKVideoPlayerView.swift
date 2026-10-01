//
//  AKVideoPlayerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Flagship Fullscreen Video Player View featuring autohiding glass HUD, split touch gestures,
/// capability-driven controls, and native ad overlays.
public struct AKVideoPlayerView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public let theme: AKPlayerTheme

    @State private var isHUDVisible: Bool = true
    @State private var hideHUDTask: Task<Void, Never>?

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        theme: AKPlayerTheme = .standard
    ) {
        self.coordinator = coordinator
        self.theme = theme
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
            AKVideoGestureOverlay(
                configuration: coordinator.configuration.gestures,
                typography: theme.typography,
                onSingleTap: {
                    toggleHUD()
                },
                onDoubleTapSeek: { direction in
                    if direction == .backward {
                        coordinator.skipBackward()
                    } else {
                        coordinator.skipForward()
                    }
                    resetHUDTimer()
                }
            )

            // 3. Native Interstitial Ad Overlay
            AKAdOverlayView(
                adManager: coordinator.adManager,
                palette: theme.palette
            )

            // 4. Autohiding Glass HUD Overlays
            if isHUDVisible && !coordinator.adManager.isAdActive {
                VStack {
                    // Top Navigation & Tool Bar
                    topBar
                        .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()

                    // Center Transport Controls
                    centerTransport
                        .transition(.scale(scale: 0.95).combined(with: .opacity))

                    Spacer()

                    // Bottom Timeline & Status Bar
                    bottomBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            resetHUDTimer()
        }
        .sheet(item: $coordinator.activeSheet) { sheet in
            sheetView(for: sheet)
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack(spacing: AKSpacing.md) {
            // Collapse / Dismiss Button
            Button(action: {
                coordinator.collapse()
            }) {
                Image(systemName: "chevron.down")
                    .font(theme.typography.button)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.black.opacity(0.4)))
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
                // Equalizer Sheet Trigger
                if coordinator.configuration.capabilities.showsEqualizer {
                    toolButton(icon: "slider.vertical.3") {
                        coordinator.presentSheet(.equalizer)
                    }
                }

                // Chapters Sheet Trigger
                if coordinator.configuration.capabilities.showsChapters && !coordinator.chapters.isEmpty {
                    toolButton(icon: "bookmark.fill") {
                        coordinator.presentSheet(.chapters)
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

    private var centerTransport: some View {
        HStack(spacing: AKSpacing.xxl) {
            // Frame Step Backward (Queries Capabilities)
            if coordinator.configuration.capabilities.showsStepButtons {
                AKFrameStepButton(
                    direction: .backward,
                    isEnabled: coordinator.capabilities.canStepBackward
                ) {
                    coordinator.step(forward: false)
                    resetHUDTimer()
                }
            }

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

            // Play / Pause Central Button
            AKPlayPauseButton(
                isPlaying: coordinator.isPlaying,
                isBuffering: coordinator.isBuffering,
                isEnabled: coordinator.capabilities.canPause
            ) {
                coordinator.togglePlayPause()
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

            // Frame Step Forward (Queries Capabilities)
            if coordinator.configuration.capabilities.showsStepButtons {
                AKFrameStepButton(
                    direction: .forward,
                    isEnabled: coordinator.capabilities.canStepForward
                ) {
                    coordinator.step(forward: true)
                    resetHUDTimer()
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: AKSpacing.sm) {
            // Timeline Scrubber (SRP)
            AKTimelineSlider(
                currentTime: coordinator.currentTime,
                duration: coordinator.duration,
                bufferedTime: coordinator.bufferedTime,
                cuePoints: coordinator.configuration.ads.cuePoints,
                isAdActive: coordinator.adManager.isAdActive,
                isSeekEnabled: coordinator.capabilities.canSeek,
                palette: theme.palette,
                typography: theme.typography,
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

            // Bottom Accessories Row
            HStack {
                // Live Stream Beacon if applicable
                if coordinator.capabilities.isLive {
                    AKLiveBadgeView(
                        isAtLiveEdge: true,
                        offsetSeconds: 0
                    )
                }

                Spacer()

                // Aspect Ratio Selector
                if coordinator.configuration.capabilities.showsAspectSelector {
                    Menu {
                        ForEach(AKVideoAspectRatio.allCases) { ratio in
                            Button(ratio.rawValue) {
                                coordinator.aspectRatio = ratio
                            }
                        }
                    } label: {
                        HStack(spacing: AKSpacing.xxs) {
                            Image(systemName: "aspectratio")
                            Text(coordinator.aspectRatio.rawValue)
                                .font(theme.typography.badgeSmall)
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, AKSpacing.xs)
                        .padding(.vertical, AKSpacing.xxs)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                }
            }
        }
        .padding(.horizontal, AKSpacing.xl)
        .padding(.bottom, AKSpacing.xxl)
    }

    private func toolButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(theme.typography.button)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.black.opacity(0.4)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sheetView(for sheet: AKPlayerAuxiliarySheet) -> some View {
        switch sheet {
        case .equalizer:
            AKEqualizerView(
                equalizer: coordinator.equalizer,
                palette: theme.palette,
                onDismiss: { coordinator.dismissSheet() }
            )
        default:
            Text("Sheet: \(sheet.title)")
                .presentationDetents([.medium, .large])
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
                if coordinator.isPlaying {
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

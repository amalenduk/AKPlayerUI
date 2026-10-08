//
//  AKVideoPlayerHUDView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Dedicated Heads-Up Display (HUD) overlay for video playback.
/// Encapsulates the top navigation & toolbar, floating bottom control island card,
/// screen lock controls, and capability-driven actions.
public struct AKVideoPlayerHUDView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    @ObservedObject public var uiState: AKPlayerUIState
    @Binding public var isScreenLocked: Bool
    public let theme: AKPlayerTheme
    public var onResetHUDTimer: (() -> Void)?
    public var onScrubBegan: (() -> Void)?
    public var onScrubChanged: ((TimeInterval) -> Void)?

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        uiState: AKPlayerUIState? = nil,
        isScreenLocked: Binding<Bool>,
        theme: AKPlayerTheme = .standard,
        onResetHUDTimer: (() -> Void)? = nil,
        onScrubBegan: (() -> Void)? = nil,
        onScrubChanged: ((TimeInterval) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.uiState = uiState ?? coordinator.uiState
        self._isScreenLocked = isScreenLocked
        self.theme = theme
        self.onResetHUDTimer = onResetHUDTimer
        self.onScrubBegan = onScrubBegan
        self.onScrubChanged = onScrubChanged
    }

    public var body: some View {
        if isScreenLocked {
            lockedHUD
        } else {
            unlockedHUD
        }
    }

    // MARK: - Locked State HUD
    private var lockedHUD: some View {
        VStack {
            HStack {
                lockButton
                    .padding(.leading, AKSpacing.xl)
                    .padding(.top, 72)
                Spacer()
            }
            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: - Unlocked State HUD
    private var unlockedHUD: some View {
        VStack {
            // Top Navigation & Tool Bar
            topBar
                .transition(.move(edge: .top).combined(with: .opacity))

            Spacer()

            // Floating Bottom Island Card
            bottomCard
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .overlay(alignment: .topLeading) {
            lockButton
                .padding(.leading, AKSpacing.xl)
                .padding(.top, 72)
        }
    }

    // MARK: - Screen Lock Button
    private var lockButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                isScreenLocked.toggle()
            }
            onResetHUDTimer?()
        }) {
            Image(systemName: isScreenLocked ? "lock.fill" : "lock.open")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isScreenLocked ? theme.palette.accent : theme.palette.textPrimary)
                .frame(width: 40, height: 40)
                .akGlassCircle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Top Navigation Bar
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

            // Close / Dismiss Player Button (rest of tools reside in More Options)
            toolButton(icon: "xmark") {
                coordinator.dismiss()
            }
        }
        .padding(.horizontal, AKSpacing.xl)
        .padding(.top, AKSpacing.xl)
    }

    // MARK: - Floating Bottom Island HUD Card
    private var bottomCard: some View {
        VStack(spacing: AKSpacing.xs) {
            // Tier 1: Full-Width Scrubber Timeline (Track + Left & Right Timestamps)
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
                showsTimeLabels: true,
                palette: theme.palette,
                typography: theme.typography,
                onJumpToLive: {
                    coordinator.jumpToLive()
                    onResetHUDTimer?()
                },
                onScrubBegan: {
                    onScrubBegan?()
                },
                onScrubChanged: { time in
                    onScrubChanged?(time)
                },
                onScrubEnded: { targetTime in
                    coordinator.seek(to: targetTime)
                    onResetHUDTimer?()
                }
            )

            // Tier 2: Central Hero Transport Controls
            HStack(spacing: AKSpacing.xl) {
                // Skip Backward
                if coordinator.configuration.capabilities.showsSkipButtons {
                    AKSeekButton(
                        direction: .backward,
                        stepSeconds: coordinator.configuration.playback.skipBackwardDuration,
                        isEnabled: coordinator.capabilities.canSeek
                    ) {
                        coordinator.skipBackward()
                        onResetHUDTimer?()
                    }
                    .scaleEffect(0.9)
                }

                // Hero Play/Pause Button
                AKPlayPauseButton(
                    state: coordinator.state,
                    autoPlay: coordinator.autoPlay,
                    size: 48,
                    style: .glass
                ) {
                    coordinator.player.togglePlayPause()
                    onResetHUDTimer?()
                }

                // Skip Forward
                if coordinator.configuration.capabilities.showsSkipButtons {
                    AKSeekButton(
                        direction: .forward,
                        stepSeconds: coordinator.configuration.playback.skipForwardDuration,
                        isEnabled: coordinator.capabilities.canSeek
                    ) {
                        coordinator.skipForward()
                        onResetHUDTimer?()
                    }
                    .scaleEffect(0.9)
                }
            }
            .frame(maxWidth: .infinity)

            // Tier 3: Thumb Action Corner Controls
            HStack(alignment: .center) {
                // Left Thumb: Aspect Ratio + Subtitles [CC]
                HStack(spacing: AKSpacing.xs) {
                    if coordinator.configuration.capabilities.showsAspectSelector {
                        Menu {
                            ForEach(AKVideoAspectRatio.allCases) { ratio in
                                Button(action: {
                                    coordinator.aspectRatio = ratio
                                    onResetHUDTimer?()
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
                            HStack(spacing: 4) {
                                Image(systemName: "aspectratio")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(coordinator.aspectRatio.rawValue)
                                    .font(theme.typography.caption2.weight(.semibold))
                            }
                            .foregroundColor(theme.palette.textPrimary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .akGlassPill()
                        }
                    }

                    Button(action: {
                        uiState.presentSheet(.subtitleTracks, isAudioOnly: coordinator.isAudioOnly)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: coordinator.selectedSubtitleTrack?.isOff == false ? "captions.bubble.fill" : "captions.bubble")
                                    .font(.system(size: 11, weight: .semibold))
                            Text("CC")
                                .font(theme.typography.caption2.weight(.bold))
                        }
                        .foregroundColor(coordinator.selectedSubtitleTrack?.isOff == false ? theme.palette.accent : theme.palette.textPrimary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .akGlassPill()
                    }
                    .buttonStyle(.plain)

                    // Audio Tracks Quick Button
                    Button(action: {
                        uiState.presentSheet(.audioTracks, isAudioOnly: coordinator.isAudioOnly)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 11, weight: .semibold))
                            Text("Audio")
                                .font(theme.typography.caption2.weight(.bold))
                        }
                        .foregroundColor(theme.palette.textPrimary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .akGlassPill()
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Right Thumb: Playback Speed Pill + More Actions [≡]
                HStack(spacing: AKSpacing.xs) {
                    // Playback Speed Pill (e.g. 1x)
                    Button(action: {
                        uiState.presentSheet(.playbackSpeed, isAudioOnly: coordinator.isAudioOnly)
                    }) {
                        Text(AKPlaybackSpeedSheet.format(rate: coordinator.playbackRate))
                            .font(theme.typography.caption2.weight(.bold))
                            .foregroundColor(coordinator.playbackRate != 1.0 ? theme.palette.accent : theme.palette.textPrimary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .akGlassPill()
                    }
                    .buttonStyle(.plain)

                    // More Actions [≡] Button
                    Button(action: {
                        uiState.presentSheet(.moreOptions, isAudioOnly: coordinator.isAudioOnly)
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(theme.palette.textPrimary)
                            .frame(width: 28, height: 28)
                            .akGlassCircle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, AKSpacing.md)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
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
                .shadow(color: Color.black.opacity(0.40), radius: 14, x: 0, y: 6)
        )
        .padding(.horizontal, AKSpacing.md)
        .padding(.bottom, AKSpacing.xs)
        .fixedSize(horizontal: false, vertical: true)
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
}

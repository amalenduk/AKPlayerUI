//
//  AKMoreOptionsSheet.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Multi-purpose sheet hosting playback controls, tracks, loop modes, and aspect ratio settings.
/// Structured into clear sections: Quick Controls, Tracks & Accessibility, Playback Loop, and Aspect Ratio.
public struct AKMoreOptionsSheet: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var placementMode: AKOverlayPlacementMode
    public var onSelectAction: ((AKPlayerAuxiliarySheet) -> Void)?
    public var onLockScreen: (() -> Void)?
    public var onDismiss: (() -> Void)?

    @Environment(\.akPlayerTheme) private var theme

    private var palette: AKColorPalette { theme.palette }
    private var typography: AKTypography { theme.typography }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        placementMode: AKOverlayPlacementMode = .sheet,
        onSelectAction: ((AKPlayerAuxiliarySheet) -> Void)? = nil,
        onLockScreen: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.placementMode = placementMode
        self.onSelectAction = onSelectAction
        self.onLockScreen = onLockScreen
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: AKSpacing.xl) {
                // 1. Quick Playback Controls Grid
                quickControlsSection
                    .padding(.top, AKSpacing.md)

                // 2. Tracks & Accessibility Section (Audio, Subtitles, Captions, AD, Others)
                tracksSection

                // 3. Loop & Shuffle Section
                loopSection

                // 4. Aspect Ratio Section
                aspectRatioSection

                Spacer(minLength: AKSpacing.xl)
            }
        }
    }

    // MARK: - Quick Controls Section

    private var quickControlsSection: some View {
        VStack(alignment: .leading, spacing: AKSpacing.sm) {
            Text("QUICK CONTROLS")
                .font(typography.badgeSmall)
                .foregroundColor(palette.textSecondary.opacity(0.7))
                .padding(.horizontal, AKSpacing.lg)

            LazyVGrid(columns: columns, spacing: AKSpacing.lg) {
                // Playback Speed
                gridButton(title: "Speed", icon: "speedometer") {
                    onSelectAction?(.playbackSpeed)
                }

                // Equalizer
                gridButton(title: "Equalizer", icon: "slider.vertical.3") {
                    onSelectAction?(.equalizer)
                }

                // Chapters
                gridButton(title: "Chapters", icon: "bookmark.fill") {
                    onSelectAction?(.chapters)
                }

                // Media Details
                gridButton(title: "Details", icon: "info.circle") {
                    onSelectAction?(.details)
                }

                // Lock Screen
                gridButton(title: "Lock Screen", icon: "lock.fill") {
                    onLockScreen?()
                    onDismiss?()
                }

                // Up Next / Queue
                gridButton(title: "Up Next", icon: "list.bullet") {
                    onSelectAction?(.queue)
                }

                // Lyrics
                gridButton(title: "Lyrics", icon: "quote.bubble") {
                    onSelectAction?(.lyrics)
                }

                // AirPlay
                gridAirPlayButton
            }
            .padding(.horizontal, AKSpacing.md)
        }
    }

    private var gridAirPlayButton: some View {
        VStack(spacing: AKSpacing.xs) {
            AKAirPlayButton(
                isAudioOnly: coordinator.isAudioOnly,
                size: 54,
                palette: palette,
                isGlassStyle: true
            )

            Text("AirPlay")
                .font(typography.caption1.weight(.medium))
                .foregroundColor(palette.textSecondary)
                .lineLimit(1)
        }
    }

    private func gridButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: AKSpacing.xs) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 54, height: 54)
                        .overlay(
                            Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                }

                Text(title)
                    .font(typography.caption1.weight(.medium))
                    .foregroundColor(palette.textSecondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tracks & Accessibility Section

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: AKSpacing.sm) {
            Text("AUDIO & SUBTITLE TRACKS")
                .font(typography.badgeSmall)
                .foregroundColor(palette.textSecondary.opacity(0.7))
                .padding(.horizontal, AKSpacing.lg)

            VStack(spacing: AKSpacing.xs) {
                // Audio Track
                trackRow(
                    title: "Audio Track",
                    value: coordinator.selectedAudioTrack?.title ?? "Default",
                    icon: "speaker.wave.2.fill"
                ) {
                    onSelectAction?(.audioTracks)
                }

                // Subtitles
                trackRow(
                    title: "Subtitles",
                    value: coordinator.selectedSubtitleTrack?.title ?? "Off",
                    icon: "captions.bubble.fill"
                ) {
                    onSelectAction?(.subtitleTracks)
                }

                // Closed Captions (CC / SDH)
                trackRow(
                    title: "Closed Captions (CC)",
                    value: coordinator.selectedClosedCaptionTrack?.title ?? "Off",
                    icon: "captions.bubble"
                ) {
                    onSelectAction?(.closedCaptionTracks)
                }

                // Audio Description (AD)
                trackRow(
                    title: "Audio Description (AD)",
                    value: coordinator.selectedAudioDescriptionTrack?.title ?? "Off",
                    icon: "person.wave.2.fill"
                ) {
                    onSelectAction?(.audioDescriptionTracks)
                }

                // Alternative Angles / Multi-Camera (Video Alternative Tracks)
                if !coordinator.isAudioOnly {
                    let angleLabel = coordinator.availableVideoAlternativeTracks.isEmpty
                        ? "None"
                        : (coordinator.selectedVideoAlternativeTrack?.title ?? "Main")
                    trackRow(
                        title: "Alternative Angles",
                        value: angleLabel,
                        icon: "video.badge.plus"
                    ) {
                        onSelectAction?(.videoAlternativeTracks)
                    }
                }
            }
            .padding(.horizontal, AKSpacing.md)
        }
    }

    private func trackRow(
        title: String,
        value: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AKSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                }

                Text(title)
                    .font(typography.body.weight(.medium))
                    .foregroundColor(palette.textPrimary)

                Spacer()

                Text(value)
                    .font(typography.footnote)
                    .foregroundColor(palette.textSecondary)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(palette.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, AKSpacing.md)
            .padding(.vertical, AKSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loop & Shuffle Section

    private var loopSection: some View {
        VStack(alignment: .leading, spacing: AKSpacing.sm) {
            Text("PLAYBACK LOOP")
                .font(typography.badgeSmall)
                .foregroundColor(palette.textSecondary.opacity(0.7))
                .padding(.horizontal, AKSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AKSpacing.sm) {
                    loopOptionButton(title: "Off", icon: "arrow.forward", isSelected: coordinator.repeatMode == .off) {
                        coordinator.repeatMode = .off
                    }
                    
                    loopOptionButton(title: "Repeat All", icon: "repeat", isSelected: coordinator.repeatMode == .all) {
                        coordinator.repeatMode = .all
                    }

                    loopOptionButton(title: "Repeat Track", icon: "repeat.1", isSelected: coordinator.repeatMode == .one) {
                        coordinator.repeatMode = .one
                    }
                    
                    loopOptionButton(title: "Shuffle", icon: "shuffle", isSelected: coordinator.isShuffled) {
                        coordinator.toggleShuffle()
                    }
                }
                .padding(.horizontal, AKSpacing.lg)
            }
        }
    }

    private func loopOptionButton(title: String, icon: String, isSelected: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AKSpacing.xs) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
            }
            .font(typography.button)
            .foregroundColor(isSelected ? palette.textPrimary : palette.textSecondary)
            .padding(.horizontal, AKSpacing.md)
            .padding(.vertical, AKSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? palette.accent : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? palette.accent : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Aspect Ratio Section

    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: AKSpacing.sm) {
            Text("ASPECT RATIO")
                .font(typography.badgeSmall)
                .foregroundColor(palette.textSecondary.opacity(0.7))
                .padding(.horizontal, AKSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AKSpacing.xs) {
                    ForEach(AKVideoAspectRatio.allCases) { ratio in
                        let isSelected = coordinator.aspectRatio == ratio
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                coordinator.aspectRatio = ratio
                            }
                        }) {
                            Text(ratio.rawValue)
                                .font(isSelected ? typography.button.weight(.semibold) : typography.button)
                                .foregroundColor(isSelected ? palette.textPrimary : palette.textSecondary)
                                .lineLimit(1)
                                .padding(.horizontal, AKSpacing.md)
                                .padding(.vertical, AKSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(isSelected ? palette.accent : Color.white.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(isSelected ? palette.accent.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AKSpacing.lg)
            }
        }
    }
}

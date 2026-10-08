//
//  AKTrackSelectorSheet.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Interactive sheet enabling users to select audio languages and closed caption / subtitle tracks.
/// Standardized inside AKAuxiliaryContainerView across sheet, drawer, and inline presentation modes.
public struct AKTrackSelectorSheet: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var palette: AKColorPalette
    public var typography: AKTypography
    public var placementMode: AKOverlayPlacementMode
    public var onDismiss: (() -> Void)?

    @State private var selectedTab: Int = 0 // 0 = Audio, 1 = Subtitles

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard,
        placementMode: AKOverlayPlacementMode = .sheet,
        onDismiss: (() -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.palette = palette
        self.typography = typography
        self.placementMode = placementMode
        self.onDismiss = onDismiss
    }

    public var body: some View {
        AKAuxiliaryContainerView(
            badge: "Audio & Subtitles",
            title: coordinator.currentTitle.isEmpty ? "Track Options" : coordinator.currentTitle,
            placementMode: placementMode,
            palette: palette,
            typography: typography,
            onDismiss: onDismiss,
            content: {
                VStack(spacing: AKSpacing.zero) {
                    // Segmented Tab Picker (Audio vs Subtitles)
                    pickerTabs
                        .padding(.horizontal, AKSpacing.lg)
                        .padding(.top, AKSpacing.md)
                        .padding(.bottom, AKSpacing.sm)

                    // Track List
                    if selectedTab == 0 {
                        audioTrackList
                    } else {
                        subtitleTrackList
                    }
                }
            }
        )
    }

    // MARK: - Subviews

    private var pickerTabs: some View {
        HStack(spacing: AKSpacing.zero) {
            Button(action: { withAnimation { selectedTab = 0 } }) {
                Text("Audio Tracks")
                    .font(typography.button)
                    .foregroundColor(selectedTab == 0 ? palette.foregroundPrimary : palette.foregroundTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AKSpacing.xs)
                    .background(selectedTab == 0 ? Color.white.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Button(action: { withAnimation { selectedTab = 1 } }) {
                Text("Subtitles")
                    .font(typography.button)
                    .foregroundColor(selectedTab == 1 ? palette.foregroundPrimary : palette.foregroundTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AKSpacing.xs)
                    .background(selectedTab == 1 ? Color.white.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(AKSpacing.xxs)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var audioTrackList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: AKSpacing.xs) {
                if coordinator.availableAudioTracks.isEmpty {
                    emptyState(title: "No Extra Audio Tracks", subtitle: "Only the default stereo/surround mix is available.")
                } else {
                    ForEach(coordinator.availableAudioTracks) { track in
                        let isSelected = track.id == coordinator.selectedAudioTrack?.id
                        trackRow(track: track, isSelected: isSelected) {
                            coordinator.selectAudioTrack(track)
                        }
                    }
                }
            }
            .padding(.horizontal, AKSpacing.lg)
            .padding(.top, AKSpacing.xs)
            .padding(.bottom, AKSpacing.xxl)
        }
    }

    private var subtitleTrackList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: AKSpacing.xs) {
                // "Off" Option
                let isOff = coordinator.selectedSubtitleTrack == nil || coordinator.selectedSubtitleTrack?.isOff == true
                trackRow(track: AKMediaTrackOption.off, isSelected: isOff) {
                    coordinator.selectSubtitleTrack(AKMediaTrackOption.off)
                }

                ForEach(coordinator.availableSubtitleTracks) { track in
                    let isSelected = track.id == coordinator.selectedSubtitleTrack?.id
                    trackRow(track: track, isSelected: isSelected) {
                        coordinator.selectSubtitleTrack(track)
                    }
                }
            }
            .padding(.horizontal, AKSpacing.lg)
            .padding(.top, AKSpacing.xs)
            .padding(.bottom, AKSpacing.xxl)
        }
    }

    private func trackRow(track: AKMediaTrackOption, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AKSpacing.sm) {
                VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
                    Text(track.title)
                        .font(isSelected ? typography.subheadline.weight(.semibold) : typography.subheadline.weight(.medium))
                        .foregroundColor(isSelected ? palette.foregroundPrimary : palette.foregroundSecondary)

                    if !track.languageCode.isEmpty {
                        Text(track.languageCode.uppercased())
                            .font(typography.badgeSmall)
                            .foregroundColor(palette.foregroundTertiary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(typography.button)
                        .foregroundColor(palette.accent)
                }
            }
            .padding(.horizontal, AKSpacing.md)
            .padding(.vertical, AKSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? palette.accent.opacity(0.15) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? palette.accent.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(spacing: AKSpacing.sm) {
            Spacer(minLength: AKSpacing.xxxl)
            Image(systemName: "waveform.slash")
                .font(.system(size: 40))
                .foregroundColor(palette.foregroundTertiary)
            Text(title)
                .font(typography.subheadline.weight(.semibold))
                .foregroundColor(palette.foregroundSecondary)
            Text(subtitle)
                .font(typography.caption1)
                .foregroundColor(palette.foregroundTertiary)
                .multilineTextAlignment(.center)
            Spacer(minLength: AKSpacing.xxxl)
        }
    }
}

// MARK: - SwiftUI Preview

#Preview("Track Selector Sheet") {
    AKTrackSelectorSheet(coordinator: .previewMock)
        .preferredColorScheme(.dark)
}

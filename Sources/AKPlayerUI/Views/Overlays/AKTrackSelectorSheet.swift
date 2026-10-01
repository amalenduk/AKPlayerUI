//
//  AKTrackSelectorSheet.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Sheet allowing user to select active audio language track and subtitles/closed captions.
/// Driven directly by `AKPlayer`'s `AKMediaTrackOption`.
public struct AKTrackSelectorSheet: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var palette: AKColorPalette
    public var typography: AKTypography

    @State private var selectedTab: Int = 0 // 0 = Audio, 1 = Subtitles

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard
    ) {
        self.coordinator = coordinator
        self.palette = palette
        self.typography = typography
    }

    public var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.85).ignoresSafeArea()
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerBar
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                // Segmented Tab Picker (Audio vs Subtitles)
                pickerTabs
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // Track List
                if selectedTab == 0 {
                    audioTrackList
                } else {
                    subtitleTrackList
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AUDIO & SUBTITLES")
                    .font(typography.badgeSmall)
                    .foregroundColor(palette.accent)
                    .tracking(1.4)

                Text(coordinator.currentTitle)
                    .font(typography.headline)
                    .foregroundColor(palette.foregroundPrimary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: { coordinator.dismissSheet() }) {
                Image(systemName: "xmark")
                    .font(typography.button)
                    .foregroundColor(palette.foregroundSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var pickerTabs: some View {
        HStack(spacing: 0) {
            Button(action: { withAnimation { selectedTab = 0 } }) {
                Text("Audio Tracks")
                    .font(typography.button)
                    .foregroundColor(selectedTab == 0 ? palette.foregroundPrimary : palette.foregroundTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == 0 ? Color.white.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Button(action: { withAnimation { selectedTab = 1 } }) {
                Text("Subtitles")
                    .font(typography.button)
                    .foregroundColor(selectedTab == 1 ? palette.foregroundPrimary : palette.foregroundTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == 1 ? Color.white.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var audioTrackList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 8) {
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
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private var subtitleTrackList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 8) {
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
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private func trackRow(track: AKMediaTrackOption, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
        VStack(spacing: 12) {
            Spacer(minLength: 40)
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
            Spacer(minLength: 40)
        }
    }
}

// MARK: - SwiftUI Preview

#Preview("Track Selector Sheet") {
    AKTrackSelectorSheet(coordinator: .previewMock)
        .preferredColorScheme(.dark)
}

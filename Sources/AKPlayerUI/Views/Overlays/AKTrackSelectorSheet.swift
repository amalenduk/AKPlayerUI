//
//  AKTrackSelectorSheet.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

// MARK: - AKTrackType Presentation Extension

extension AKTrackType {
    public var displayTitle: String {
        switch self {
        case .audio: return "Audio Tracks"
        case .subtitle: return "Subtitles"
        case .closedCaption: return "Closed Captions"
        case .audioDescription: return "Audio Description"
        case .videoAlternative: return "Alternative Angles"
        }
    }
    
    public var iconName: String {
        switch self {
        case .audio: return "speaker.wave.2.fill"
        case .subtitle: return "captions.bubble.fill"
        case .closedCaption: return "captions.bubble"
        case .audioDescription: return "person.wave.2.fill"
        case .videoAlternative: return "video.badge.plus"
        }
    }
    
    public var offSubtitle: String {
        switch self {
        case .subtitle:
            return "Disable subtitles"
        case .closedCaption:
            return "Disable closed captions"
        case .audio:
            return "Mute audio"
        case .audioDescription:
            return "Disable audio description"
        case .videoAlternative:
            return "Default video angle"
        }
    }
}

/// Interactive sheet enabling users to select media track options for a specific AKTrackType
/// (e.g., .audio, .subtitle, .closedCaption).
/// Standardized inside AKAuxiliaryContainerView across sheet, drawer, and inline presentation modes.
public struct AKTrackSelectorSheet: View {
    public let trackType: AKTrackType
    public var coordinator: AKPlayerCoordinator
    public var placementMode: AKOverlayPlacementMode
    
    @Environment(\.akPlayerTheme) private var theme
    
    public init(
        trackType: AKTrackType = .subtitle,
        coordinator: AKPlayerCoordinator = .shared,
        placementMode: AKOverlayPlacementMode = .sheet
    ) {
        self.trackType = trackType
        self.coordinator = coordinator
        self.placementMode = placementMode
    }
    
    private var availableTracks: [AKMediaTrackOption] {
        coordinator.availableTracks(for: trackType)
    }
    
    private var offTrack: AKMediaTrackOption? {
        availableTracks.first(where: { $0.isOff })
    }
    
    private var contentTracks: [AKMediaTrackOption] {
        availableTracks.filter { !$0.isOff }
    }
    
    private var selectedTrack: AKMediaTrackOption? {
        coordinator.selectedTrack(for: trackType)
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: AKSpacing.xs) {
                if availableTracks.isEmpty {
                    emptyState(
                        title: "No Extra \(trackType.displayTitle)",
                        subtitle: "Only the default stream option is available."
                    )
                } else {
                    // 1. Off Row (Distinct control at top if supported)
                    if let off = offTrack {
                        let isOffSelected = selectedTrack == nil || selectedTrack?.isOff == true
                        offRow(track: off, isSelected: isOffSelected) {
                            coordinator.selectTrack(off, for: trackType)
                        }
                        
                        if !contentTracks.isEmpty {
                            sectionDivider(title: "AVAILABLE TRACKS")
                        }
                    }
                    
                    // 2. Available Content / Language Tracks
                    ForEach(contentTracks) { track in
                        let isSelected = track.id == selectedTrack?.id
                        trackRow(track: track, isSelected: isSelected) {
                            coordinator.selectTrack(track, for: trackType)
                        }
                    }
                }
            }
            .padding(.horizontal, AKSpacing.lg)
            .padding(.top, AKSpacing.md)
            .padding(.bottom, AKSpacing.xxl)
        }
    }
    
    private func disabledTrackIcon(isSelected: Bool) -> some View {
        ZStack {
            Image(systemName: trackType.iconName)
                .font(theme.typography.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? theme.palette.accent : theme.palette.foregroundTertiary)

            // Cutout gap for clean contrast across solid glyphs
            Capsule()
                .fill(theme.palette.surfaceElevated)
                .frame(width: 4, height: 20)
                .rotationEffect(.degrees(60))

            // 2-pixel disabled slash line drawn at 60 degrees above the icon
            Capsule()
                .fill(isSelected ? theme.palette.accent : theme.palette.foregroundTertiary)
                .frame(width: 2, height: 18)
                .rotationEffect(.degrees(60))
        }
        .frame(width: 28, height: 28)
        .background(
            Circle()
                .fill(isSelected ? theme.palette.accent.opacity(0.18) : Color.white.opacity(0.05))
        )
    }

    private func offRow(track: AKMediaTrackOption, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AKSpacing.sm) {
                disabledTrackIcon(isSelected: isSelected)
                
                VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
                    Text(track.title)
                        .font(isSelected ? theme.typography.subheadline.weight(.semibold) : theme.typography.subheadline.weight(.medium))
                        .foregroundColor(isSelected ? theme.palette.foregroundPrimary : theme.palette.foregroundSecondary)
                    
                    Text(trackType.offSubtitle)
                        .font(theme.typography.badgeSmall)
                        .foregroundColor(theme.palette.foregroundTertiary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(theme.typography.button)
                        .foregroundColor(theme.palette.accent)
                }
            }
            .padding(.horizontal, AKSpacing.md)
            .padding(.vertical, AKSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? theme.palette.accent.opacity(0.15) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? theme.palette.accent.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func sectionDivider(title: String) -> some View {
        HStack(spacing: AKSpacing.sm) {
            Text(title)
                .font(theme.typography.badgeSmall.weight(.bold))
                .foregroundColor(theme.palette.foregroundTertiary)
                .kerning(1.2)
            
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
        .padding(.top, AKSpacing.sm)
        .padding(.bottom, AKSpacing.xxxs)
    }
    
    private func trackRow(track: AKMediaTrackOption, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AKSpacing.sm) {
                VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
                    Text(track.title)
                        .font(isSelected ? theme.typography.subheadline.weight(.semibold) : theme.typography.subheadline.weight(.medium))
                        .foregroundColor(isSelected ? theme.palette.foregroundPrimary : theme.palette.foregroundSecondary)
                    
                    if !track.languageCode.isEmpty {
                        Text(track.languageCode.uppercased())
                            .font(theme.typography.badgeSmall)
                            .foregroundColor(theme.palette.foregroundTertiary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(theme.typography.button)
                        .foregroundColor(theme.palette.accent)
                }
            }
            .padding(.horizontal, AKSpacing.md)
            .padding(.vertical, AKSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? theme.palette.accent.opacity(0.15) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? theme.palette.accent.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(spacing: AKSpacing.sm) {
            Spacer(minLength: AKSpacing.xxxl)
            Image(systemName: trackType.iconName)
                .font(.system(size: 44))
                .foregroundColor(theme.palette.foregroundTertiary)
            Text(title)
                .font(theme.typography.subheadline.weight(.semibold))
                .foregroundColor(theme.palette.foregroundSecondary)
            Text(subtitle)
                .font(theme.typography.caption1)
                .foregroundColor(theme.palette.foregroundTertiary)
                .multilineTextAlignment(.center)
            Spacer(minLength: AKSpacing.xxxl)
        }
    }
}

// MARK: - SwiftUI Preview

#Preview("Audio Track Selector") {
    AKTrackSelectorSheet(trackType: .audio, coordinator: .previewMock)
        .preferredColorScheme(.dark)
}

#Preview("Subtitle Track Selector") {
    AKTrackSelectorSheet(trackType: .subtitle, coordinator: .previewMock)
        .preferredColorScheme(.dark)
}

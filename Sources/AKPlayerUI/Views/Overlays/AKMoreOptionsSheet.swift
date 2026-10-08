//
//  AKMoreOptionsSheet.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Rich action sheet offering quick access to secondary player features:
/// Audio tracks, subtitles, equalizer, chapters, sleep timer, screen lock, and loop modes.
/// Standardized inside AKAuxiliaryContainerView across sheet, drawer, and inline presentation modes.
public struct AKMoreOptionsSheet: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var palette: AKColorPalette
    public var typography: AKTypography
    public var placementMode: AKOverlayPlacementMode
    public var onSelectAction: ((AKPlayerAuxiliarySheet) -> Void)?
    public var onLockScreen: (() -> Void)?
    public var onDismiss: (() -> Void)?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard,
        placementMode: AKOverlayPlacementMode = .sheet,
        onSelectAction: ((AKPlayerAuxiliarySheet) -> Void)? = nil,
        onLockScreen: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.palette = palette
        self.typography = typography
        self.placementMode = placementMode
        self.onSelectAction = onSelectAction
        self.onLockScreen = onLockScreen
        self.onDismiss = onDismiss
    }

    public var body: some View {
        AKAuxiliaryContainerView(
            badge: "Player Controls",
            title: "More Options",
            placementMode: placementMode,
            palette: palette,
            typography: typography,
            onDismiss: onDismiss,
            content: {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: AKSpacing.xl) {
                        // Quick Action Buttons Grid (4 columns)
                        actionGrid
                            .padding(.horizontal, AKSpacing.md)
                            .padding(.top, AKSpacing.md)

                        // Loop & Shuffle Section
                        loopSection
                            .padding(.horizontal, AKSpacing.lg)

                        // Aspect Ratio Section
                        aspectRatioSection
                            .padding(.horizontal, AKSpacing.lg)

                        Spacer(minLength: AKSpacing.xl)
                    }
                }
            }
        )
    }

    // MARK: - Subviews

    private var actionGrid: some View {
        LazyVGrid(columns: columns, spacing: AKSpacing.lg) {
            // Audio & Subtitles
            gridButton(title: "Tracks", icon: "waveform.badge.magnifyingglass") {
                onSelectAction?(.trackSelection)
            }

            // Equalizer
            gridButton(title: "Equalizer", icon: "slider.vertical.3") {
                onSelectAction?(.equalizer)
            }

            // Chapters
            gridButton(title: "Chapters", icon: "bookmark.fill") {
                onSelectAction?(.chapters)
            }

            // Playback Speed
            gridButton(title: "Speed", icon: "speedometer") {
                onSelectAction?(.playbackSpeed)
            }

            // Lock Screen
            gridButton(title: "Lock Screen", icon: "lock.fill") {
                onLockScreen?()
                onDismiss?()
            }

            // Media Info
            gridButton(title: "Details", icon: "info.circle") {
                onSelectAction?(.details)
            }

            // Up Next / Queue
            gridButton(title: "Up Next", icon: "list.bullet") {
                onSelectAction?(.queue)
            }

            // Lyrics
            gridButton(title: "Lyrics", icon: "quote.bubble") {
                onSelectAction?(.lyrics)
            }
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

    private var loopSection: some View {
        VStack(alignment: .leading, spacing: AKSpacing.sm) {
            Text("PLAYBACK LOOP")
                .font(typography.badgeSmall)
                .foregroundColor(palette.textSecondary.opacity(0.7))

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
        }
    }

    private func loopOptionButton(title: String, icon: String, isSelected: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AKSpacing.xs) {
                Image(systemName: icon)
                Text(title)
            }
            .font(typography.button)
            .foregroundColor(isSelected ? palette.textPrimary : palette.textSecondary)
            .frame(maxWidth: .infinity)
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

    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: AKSpacing.sm) {
            Text("ASPECT RATIO")
                .font(typography.badgeSmall)
                .foregroundColor(palette.textSecondary.opacity(0.7))

            HStack(spacing: AKSpacing.xs) {
                ForEach(AKVideoAspectRatio.allCases) { ratio in
                    let isSelected = coordinator.aspectRatio == ratio
                    Button(action: {
                        coordinator.aspectRatio = ratio
                    }) {
                        Text(ratio.rawValue)
                            .font(typography.button)
                            .foregroundColor(isSelected ? palette.textPrimary : palette.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AKSpacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isSelected ? palette.accent.opacity(0.25) : Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(isSelected ? palette.accent : Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

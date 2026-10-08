//
//  AKChapterSheet.swift
//  AKPlayerUI
//

import SwiftUI
import CoreMedia
import AKPlayer

/// Interactive chapter picker sheet for audiobooks, podcasts, and long-form video.
/// Consumes `AKChapter` directly from the `AKPlayer` core engine.
/// Standardized inside AKAuxiliaryContainerView across sheet, drawer, and inline presentation modes.
public struct AKChapterSheet: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var palette: AKColorPalette
    public var typography: AKTypography
    public var placementMode: AKOverlayPlacementMode
    public var onDismiss: (() -> Void)?

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard,
        placementMode: AKOverlayPlacementMode = .sheet,
        showHeader: Bool = true,
        onDismiss: (() -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.palette = palette
        self.typography = typography
        self.placementMode = placementMode
        self.onDismiss = onDismiss
    }

    private var activeChapterId: Int? {
        coordinator.activeChapter?.id
    }

    public var body: some View {
        AKAuxiliaryContainerView(
            badge: "Chapters (\(coordinator.chapters.count))",
            title: coordinator.currentTitle.isEmpty ? "Media Chapters" : coordinator.currentTitle,
            placementMode: placementMode,
            palette: palette,
            typography: typography,
            onDismiss: onDismiss,
            content: {
                if coordinator.chapters.isEmpty {
                    emptyState
                } else {
                    chapterList
                }
            }
        )
    }

    // MARK: - Subviews

    private var chapterList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: AKSpacing.xs) {
                ForEach(coordinator.chapters) { chapter in
                    let isActive = chapter.id == activeChapterId

                    Button(action: {
                        coordinator.seek(to: chapter.startTime)
                    }) {
                        HStack(spacing: AKSpacing.md) {
                            // Chapter Number Badge
                            ZStack {
                                Circle()
                                    .fill(isActive ? palette.accent : Color.white.opacity(0.1))
                                    .frame(width: 36, height: 36)

                                if isActive {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(chapter.id)")
                                        .font(typography.badge)
                                        .foregroundColor(palette.foregroundSecondary)
                                }
                            }

                            // Title & Duration
                            VStack(alignment: .leading, spacing: AKSpacing.xxs) {
                                Text(chapter.title)
                                    .font(isActive ? typography.subheadline.weight(.bold) : typography.subheadline.weight(.medium))
                                    .foregroundColor(isActive ? palette.foregroundPrimary : palette.foregroundSecondary)
                                    .lineLimit(1)

                                HStack(spacing: AKSpacing.xs) {
                                    Text(formatTimestamp(chapter.startTime))
                                        .font(typography.timecodeSmall)
                                        .foregroundColor(palette.foregroundTertiary)

                                    Text("•")
                                        .foregroundColor(palette.foregroundTertiary)

                                    Text(formatTimestamp(chapter.duration))
                                        .font(typography.caption1)
                                        .foregroundColor(palette.foregroundTertiary)
                                }
                            }

                            Spacer()

                            if isActive {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(palette.accent)
                            }
                        }
                        .padding(.horizontal, AKSpacing.md)
                        .padding(.vertical, AKSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isActive ? palette.accent.opacity(0.15) : Color.white.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isActive ? palette.accent.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AKSpacing.lg)
            .padding(.top, AKSpacing.sm)
            .padding(.bottom, AKSpacing.xl)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AKSpacing.md) {
            Spacer()
            Image(systemName: "list.bullet.indent")
                .font(.system(size: 44))
                .foregroundColor(palette.foregroundTertiary)

            Text("No Chapters Available")
                .font(typography.headline)
                .foregroundColor(palette.foregroundSecondary)

            Text("This media stream does not contain embedded chapter markers.")
                .font(typography.footnote)
                .foregroundColor(palette.foregroundTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AKSpacing.xxl)
            Spacer()
        }
    }

    private func formatTimestamp(_ seconds: Double) -> String {
        guard seconds.isFinite, !seconds.isNaN else { return "0:00" }
        let total = Int(max(0, seconds))
        let m = total / 60
        let s = total % 60
        let h = m / 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m % 60, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }
}

// MARK: - SwiftUI Preview
#Preview("Chapter Sheet") {
    AKChapterSheet(coordinator: .previewChapterMock)
        .preferredColorScheme(.dark)
}

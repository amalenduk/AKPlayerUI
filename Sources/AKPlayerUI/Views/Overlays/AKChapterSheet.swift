//
//  AKChapterSheet.swift
//  AKPlayerUI
//

import SwiftUI
import CoreMedia
import AKPlayer

/// Interactive chapter picker sheet for audiobooks, podcasts, and long-form video.
/// Consumes `AKChapter` directly from the `AKPlayer` core engine.
public struct AKChapterSheet: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var palette: AKColorPalette
    public var typography: AKTypography

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard
    ) {
        self.coordinator = coordinator
        self.palette = palette
        self.typography = typography
    }

    private var activeChapterId: Int? {
        coordinator.activeChapter?.id
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
                    .padding(.bottom, 12)

                // Chapter List
                if coordinator.chapters.isEmpty {
                    emptyState
                } else {
                    chapterList
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("CHAPTERS (\(coordinator.chapters.count))")
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

    private var chapterList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 8) {
                ForEach(coordinator.chapters) { chapter in
                    let isActive = chapter.id == activeChapterId

                    Button(action: {
                        coordinator.seek(to: chapter.startTime)
                        coordinator.dismissSheet()
                    }) {
                        HStack(spacing: 16) {
                            // Chapter Number Badge
                            ZStack {
                                Circle()
                                    .fill(isActive ? palette.accent : Color.white.opacity(0.1))
                                    .frame(width: 36, height: 36)

                                if isActive {
                                    Image(systemName: "play.fill")
                                        .font(typography.badgeSmall)
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(chapter.id)")
                                        .font(typography.badge)
                                        .foregroundColor(palette.foregroundSecondary)
                                }
                            }

                            // Title & Duration
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chapter.title)
                                    .font(isActive ? typography.subheadline.weight(.bold) : typography.subheadline.weight(.medium))
                                    .foregroundColor(isActive ? palette.foregroundPrimary : palette.foregroundSecondary)
                                    .lineLimit(1)

                                HStack(spacing: 8) {
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
                                    .font(typography.button)
                                    .foregroundColor(palette.accent)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
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
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
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
                .padding(.horizontal, 36)
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

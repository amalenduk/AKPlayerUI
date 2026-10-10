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
    public var placementMode: AKOverlayPlacementMode
    @Environment(\.akPlayerTheme) private var theme
    
    public init(
        coordinator: AKPlayerCoordinator = .shared,
        placementMode: AKOverlayPlacementMode = .sheet,
    ) {
        self.coordinator = coordinator
        self.placementMode = placementMode
    }
    
    private var activeChapterId: Int? {
        coordinator.activeChapter?.id
    }
    
    public var body: some View {
        if coordinator.chapters.isEmpty {
            emptyState
        } else {
            chapterList
        }
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
                                    .fill(isActive ? theme.palette.accent : Color.white.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                
                                if isActive {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(chapter.id)")
                                        .font(theme.typography.badge)
                                        .foregroundColor(theme.palette.foregroundSecondary)
                                }
                            }
                            
                            // Title & Duration
                            VStack(alignment: .leading, spacing: AKSpacing.xxs) {
                                Text(chapter.title)
                                    .font(isActive ? theme.typography.subheadline.weight(.bold) : theme.typography.subheadline.weight(.medium))
                                    .foregroundColor(isActive ? theme.palette.foregroundPrimary : theme.palette.foregroundSecondary)
                                    .lineLimit(1)
                                
                                HStack(spacing: AKSpacing.xs) {
                                    Text(formatTimestamp(chapter.startTime))
                                        .font(theme.typography.timecodeSmall)
                                        .foregroundColor(theme.palette.foregroundTertiary)
                                    
                                    Text("•")
                                        .foregroundColor(theme.palette.foregroundTertiary)
                                    
                                    Text(formatTimestamp(chapter.duration))
                                        .font(theme.typography.caption1)
                                        .foregroundColor(theme.palette.foregroundTertiary)
                                }
                            }
                            
                            Spacer()
                            
                            if isActive {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(theme.palette.accent)
                            }
                        }
                        .padding(.horizontal, AKSpacing.md)
                        .padding(.vertical, AKSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isActive ? theme.palette.accent.opacity(0.15) : Color.white.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isActive ? theme.palette.accent.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
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
                .foregroundColor(theme.palette.foregroundTertiary)
            
            Text("No Chapters Available")
                .font(theme.typography.headline)
                .foregroundColor(theme.palette.foregroundSecondary)
            
            Text("This media stream does not contain embedded chapter markers.")
                .font(theme.typography.footnote)
                .foregroundColor(theme.palette.foregroundTertiary)
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

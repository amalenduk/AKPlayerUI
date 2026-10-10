//
//  AKQueueSheet.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Represents an item in the playback queue.
public struct AKQueueItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let title: String
    public let artist: String
    public let duration: TimeInterval
    public let url: URL
    
    public init(id: UUID = UUID(), title: String, artist: String, duration: TimeInterval, url: URL) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.url = url
    }
}

/// Interactive queue management sheet and inline view.
/// Standardized inside AKAuxiliaryContainerView across sheet, drawer, and inline presentation modes.
public struct AKQueueSheet: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var placementMode: AKOverlayPlacementMode
    public var queueItems: [AKQueueItem]
    
    @Environment(\.akPlayerTheme) private var theme
    
    public init(
        coordinator: AKPlayerCoordinator = .shared,
        placementMode: AKOverlayPlacementMode = .sheet,
        showHeader: Bool = true,
        queueItems: [AKQueueItem] = AKQueueSheet.sampleQueue,
    ) {
        self.coordinator = coordinator
        self.placementMode = placementMode
        self.queueItems = queueItems
    }
    
    public var body: some View {
        queueContent
    }
    
    // MARK: - Subviews
    
    private var queueContent: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: AKSpacing.md) {
                // Now Playing Section
                nowPlayingSection
                
                // Up Next Section Header
                HStack {
                    Text("UP NEXT")
                        .font(theme.typography.badgeSmall)
                        .foregroundColor(theme.palette.foregroundTertiary)
                        .tracking(1.2)
                    
                    Spacer()
                    
                    Text("\(queueItems.count) tracks")
                        .font(theme.typography.caption1)
                        .foregroundColor(theme.palette.foregroundTertiary)
                }
                .padding(.top, AKSpacing.xs)
                
                // Up Next Items
                LazyVStack(spacing: AKSpacing.xs) {
                    ForEach(queueItems) { item in
                        queueRow(item: item)
                    }
                }
            }
            .padding(.horizontal, AKSpacing.lg)
            .padding(.top, AKSpacing.xs)
            .padding(.bottom, AKSpacing.xl)
        }
    }
    
    private var nowPlayingSection: some View {
        VStack(alignment: .leading, spacing: AKSpacing.xs) {
            Text("NOW PLAYING")
                .font(theme.typography.badgeSmall)
                .foregroundColor(theme.palette.accent)
                .tracking(1.2)
            
            HStack(spacing: AKSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(theme.palette.accent.opacity(0.8))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
                    Text(coordinator.currentTitle)
                        .font(theme.typography.subheadline.weight(.semibold))
                        .foregroundColor(theme.palette.foregroundPrimary)
                        .lineLimit(1)
                    
                    Text(coordinator.currentSubtitle.isEmpty ? "Playing" : coordinator.currentSubtitle)
                        .font(theme.typography.footnote)
                        .foregroundColor(theme.palette.foregroundSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if coordinator.isPlaying {
                    Image(systemName: "waveform")
                        .font(.system(size: 14))
                        .foregroundColor(theme.palette.accent)
                }
            }
            .padding(AKSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.palette.accent.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(theme.palette.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func queueRow(item: AKQueueItem) -> some View {
        HStack(spacing: AKSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 38, height: 38)
                
                Image(systemName: "music.note")
                    .font(.system(size: 15))
                    .foregroundColor(theme.palette.foregroundSecondary)
            }
            
            VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
                Text(item.title)
                    .font(theme.typography.subheadline.weight(.medium))
                    .foregroundColor(theme.palette.foregroundPrimary)
                    .lineLimit(1)
                
                Text(item.artist)
                    .font(theme.typography.caption1)
                    .foregroundColor(theme.palette.foregroundSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(formatDuration(item.duration))
                .font(theme.typography.timecodeSmall)
                .foregroundColor(theme.palette.foregroundTertiary)
            
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13))
                .foregroundColor(theme.palette.foregroundTertiary)
                .padding(.leading, AKSpacing.xxs)
        }
        .padding(.horizontal, AKSpacing.md)
        .padding(.vertical, AKSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
    
    // MARK: - Sample Queue
    public static let sampleQueue: [AKQueueItem] = [
        AKQueueItem(title: "Save Your Tears", artist: "The Weeknd", duration: 215, url: URL(fileURLWithPath: "/tmp/1.mp3")),
        AKQueueItem(title: "After Hours", artist: "The Weeknd", duration: 361, url: URL(fileURLWithPath: "/tmp/2.mp3")),
        AKQueueItem(title: "In Your Eyes", artist: "The Weeknd", duration: 237, url: URL(fileURLWithPath: "/tmp/3.mp3")),
        AKQueueItem(title: "Heartless", artist: "The Weeknd", duration: 198, url: URL(fileURLWithPath: "/tmp/4.mp3")),
        AKQueueItem(title: "Faith", artist: "The Weeknd", duration: 283, url: URL(fileURLWithPath: "/tmp/5.mp3"))
    ]
}

// MARK: - SwiftUI Preview
#Preview("Queue Sheet") {
    AKQueueSheet(coordinator: .previewAudioMock)
        .preferredColorScheme(.dark)
}

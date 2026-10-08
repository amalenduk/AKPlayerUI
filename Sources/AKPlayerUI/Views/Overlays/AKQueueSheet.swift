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
    public var palette: AKColorPalette
    public var typography: AKTypography
    public var placementMode: AKOverlayPlacementMode
    public var queueItems: [AKQueueItem]
    public var onDismiss: (() -> Void)?

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard,
        placementMode: AKOverlayPlacementMode = .sheet,
        showHeader: Bool = true,
        queueItems: [AKQueueItem] = AKQueueSheet.sampleQueue,
        onDismiss: (() -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.palette = palette
        self.typography = typography
        self.placementMode = placementMode
        self.queueItems = queueItems
        self.onDismiss = onDismiss
    }

    public var body: some View {
        AKAuxiliaryContainerView(
            badge: "Up Next (\(queueItems.count))",
            title: coordinator.currentTitle.isEmpty ? "Playback Queue" : coordinator.currentTitle,
            placementMode: placementMode,
            palette: palette,
            typography: typography,
            onDismiss: onDismiss,
            content: {
                queueContent
            }
        )
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
                        .font(typography.badgeSmall)
                        .foregroundColor(palette.foregroundTertiary)
                        .tracking(1.2)

                    Spacer()

                    Text("\(queueItems.count) tracks")
                        .font(typography.caption1)
                        .foregroundColor(palette.foregroundTertiary)
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
                .font(typography.badgeSmall)
                .foregroundColor(palette.accent)
                .tracking(1.2)

            HStack(spacing: AKSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(palette.accent.opacity(0.8))
                        .frame(width: 44, height: 44)

                    Image(systemName: "music.note")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
                    Text(coordinator.currentTitle)
                        .font(typography.subheadline.weight(.semibold))
                        .foregroundColor(palette.foregroundPrimary)
                        .lineLimit(1)

                    Text(coordinator.currentSubtitle.isEmpty ? "Playing" : coordinator.currentSubtitle)
                        .font(typography.footnote)
                        .foregroundColor(palette.foregroundSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if coordinator.isPlaying {
                    Image(systemName: "waveform")
                        .font(.system(size: 14))
                        .foregroundColor(palette.accent)
                }
            }
            .padding(AKSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.accent.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(palette.accent.opacity(0.3), lineWidth: 1)
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
                    .foregroundColor(palette.foregroundSecondary)
            }

            VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
                Text(item.title)
                    .font(typography.subheadline.weight(.medium))
                    .foregroundColor(palette.foregroundPrimary)
                    .lineLimit(1)

                Text(item.artist)
                    .font(typography.caption1)
                    .foregroundColor(palette.foregroundSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(formatDuration(item.duration))
                .font(typography.timecodeSmall)
                .foregroundColor(palette.foregroundTertiary)

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13))
                .foregroundColor(palette.foregroundTertiary)
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

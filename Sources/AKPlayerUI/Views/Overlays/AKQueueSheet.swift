//
//  AKQueueSheet.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Item representation in playback queue.
public struct AKQueueItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let title: String
    public let artist: String
    public let duration: TimeInterval
    public let url: URL

    public init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        duration: TimeInterval,
        url: URL
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.url = url
    }
}

/// Up Next playback queue sheet with reordering and item removal.
public struct AKQueueSheet: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var palette: AKColorPalette
    public var typography: AKTypography

    @State private var queueItems: [AKQueueItem] = AKQueueSheet.sampleQueue

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

            VStack(spacing: AKSpacing.zero) {
                // Header
                headerBar
                    .padding(.horizontal, AKSpacing.xl)
                    .padding(.top, AKSpacing.lg)
                    .padding(.bottom, AKSpacing.sm)

                // Queue Content
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
                    .padding(.bottom, AKSpacing.xxxl)
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: AKSpacing.xxs) {
                Text("PLAYING QUEUE")
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
                        .frame(width: 48, height: 48)

                    Image(systemName: "music.note")
                        .font(.system(size: 20))
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(palette.accent.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(palette.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func queueRow(item: AKQueueItem) -> some View {
        HStack(spacing: AKSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 42, height: 42)

                Image(systemName: "music.note")
                    .font(.system(size: 16))
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
                .font(.system(size: 14))
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

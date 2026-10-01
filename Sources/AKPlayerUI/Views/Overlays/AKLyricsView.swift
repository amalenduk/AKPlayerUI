//
//  AKLyricsView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Represents an individual time-stamped lyric line for synchronized playback.
public struct AKLyricLine: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let timestamp: TimeInterval
    public let text: String

    public init(id: UUID = UUID(), timestamp: TimeInterval, text: String) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
    }
}

/// Time-synchronized karaoke-style lyrics display sheet.
/// Features dynamic font scaling, smooth autoscrolling, and one-tap seeking by lyric line.
public struct AKLyricsView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var palette: AKColorPalette
    public var typography: AKTypography
    public var lyrics: [AKLyricLine]

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard,
        lyrics: [AKLyricLine] = AKLyricsView.sampleLyrics
    ) {
        self.coordinator = coordinator
        self.palette = palette
        self.typography = typography
        self.lyrics = lyrics
    }

    private var activeIndex: Int? {
        lyrics.lastIndex { $0.timestamp <= coordinator.currentTime }
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

                // Scrollable Synced Lyrics
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: AKSpacing.xxl) {
                            Color.clear.frame(height: AKSpacing.xxxl)

                            ForEach(Array(lyrics.enumerated()), id: \.element.id) { index, line in
                                let isActive = index == (activeIndex ?? 0)

                                Button(action: {
                                    coordinator.seek(to: line.timestamp)
                                }) {
                                    Text(line.text)
                                        .font(isActive ? typography.lyricsActive : typography.lyricsInactive)
                                        .foregroundColor(isActive ? palette.foregroundPrimary : palette.foregroundTertiary)
                                        .opacity(isActive ? 1.0 : 0.45)
                                        .blur(radius: isActive ? 0 : 0.3)
                                        .scaleEffect(isActive ? 1.04 : 1.0, anchor: .leading)
                                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isActive)
                                }
                                .buttonStyle(.plain)
                                .id(line.id)
                            }

                            Color.clear.frame(height: 120)
                        }
                        .padding(.horizontal, AKSpacing.xl)
                    }
                    .onChange(of: activeIndex) { _, newIndex in
                        if let newIndex = newIndex, newIndex < lyrics.count {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                proxy.scrollTo(lyrics[newIndex].id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: AKSpacing.xxs) {
                Text("LYRICS")
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

    // MARK: - Sample Lyrics
    public static let sampleLyrics: [AKLyricLine] = [
        AKLyricLine(timestamp: 0, text: "I'm tryna put you in the worst mood, ah"),
        AKLyricLine(timestamp: 10, text: "P1 cleaner than your church shoes, ah"),
        AKLyricLine(timestamp: 22, text: "Milli point two just to hurt you, ah"),
        AKLyricLine(timestamp: 34, text: "All red Lamb' just to tease you, ah"),
        AKLyricLine(timestamp: 46, text: "None of these toys on lease too, ah"),
        AKLyricLine(timestamp: 58, text: "Made your whole year in a week too, yah"),
        AKLyricLine(timestamp: 70, text: "Look what you've done"),
        AKLyricLine(timestamp: 82, text: "I'm a motherfuckin' starboy"),
        AKLyricLine(timestamp: 95, text: "Every day a nigga try to test me, ah"),
        AKLyricLine(timestamp: 110, text: "Every day a nigga try to end me, ah")
    ]
}

// MARK: - SwiftUI Preview

#Preview("Synced Lyrics") {
    AKLyricsView(coordinator: .previewAudioMock)
        .preferredColorScheme(.dark)
}

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

/// Time-synchronized karaoke-style lyrics display view.
/// Features Apple Music-style gradient edge fading, dynamic active line scaling, and tap-to-seek.
/// Standardized inside AKAuxiliaryContainerView across sheet, drawer, and inline presentation modes.
public struct AKLyricsView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var palette: AKColorPalette
    public var typography: AKTypography
    public var placementMode: AKOverlayPlacementMode
    public var lyrics: [AKLyricLine]
    public var onDismiss: (() -> Void)?

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard,
        placementMode: AKOverlayPlacementMode = .sheet,
        lyrics: [AKLyricLine] = AKLyricsView.sampleLyrics,
        onDismiss: (() -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.palette = palette
        self.typography = typography
        self.placementMode = placementMode
        self.lyrics = lyrics
        self.onDismiss = onDismiss
    }

    private var activeIndex: Int? {
        lyrics.lastIndex { $0.timestamp <= coordinator.currentTime }
    }

    public var body: some View {
        AKAuxiliaryContainerView(
            badge: "Synced Lyrics",
            title: coordinator.currentTitle.isEmpty ? "Lyrics" : coordinator.currentTitle,
            placementMode: placementMode,
            palette: palette,
            typography: typography,
            onDismiss: onDismiss,
            content: {
                lyricsContent
            }
        )
    }

    // MARK: - Karaoke Lyrics Content

    private var lyricsContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: AKSpacing.lg) {
                    Color.clear.frame(height: AKSpacing.sm)

                    ForEach(Array(lyrics.enumerated()), id: \.element.id) { index, line in
                        let isActive = index == (activeIndex ?? 0)

                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                coordinator.seek(to: line.timestamp)
                            }
                        }) {
                            Text(line.text)
                                .font(isActive ? .system(size: 24, weight: .bold, design: .rounded) : .system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(isActive ? .white : .white.opacity(0.35))
                                .scaleEffect(isActive ? 1.03 : 1.0, anchor: .leading)
                                .shadow(color: isActive ? palette.accent.opacity(0.4) : .clear, radius: 8, x: 0, y: 2)
                                .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isActive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .id(line.id)
                    }

                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, AKSpacing.xl)
            }
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 24)
                    Rectangle().fill(.black)
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 48)
                }
            )
            .onChange(of: activeIndex) { _, newIndex in
                if let newIndex = newIndex, newIndex < lyrics.count {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        proxy.scrollTo(lyrics[newIndex].id, anchor: .center)
                    }
                }
            }
            .onAppear {
                if let current = activeIndex, current < lyrics.count {
                    proxy.scrollTo(lyrics[current].id, anchor: .center)
                }
            }
        }
    }

    // MARK: - Sample Lyrics Catalog
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
    ZStack {
        Color.black.ignoresSafeArea()
        AKLyricsView(coordinator: .previewAudioMock)
    }
    .preferredColorScheme(.dark)
}

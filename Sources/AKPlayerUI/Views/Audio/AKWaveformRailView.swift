//
//  AKWaveformRailView.swift
//  AKPlayerUI
//

import SwiftUI

/// Single Responsibility: Displays dynamic audio waveform / spectrum rail with interactive scrubbing.
public struct AKWaveformRailView: View {
    public let currentTime: TimeInterval
    public let duration: TimeInterval
    public let isPlaying: Bool
    public let accentColor: Color
    public let barCount: Int
    public let onSeek: ((TimeInterval) -> Void)?

    @State private var sampleHeights: [CGFloat] = []

    public init(
        currentTime: TimeInterval,
        duration: TimeInterval,
        isPlaying: Bool = false,
        accentColor: Color = Color(red: 0.15, green: 0.58, blue: 1.0),
        barCount: Int = 42,
        onSeek: ((TimeInterval) -> Void)? = nil
    ) {
        self.currentTime = currentTime
        self.duration = duration
        self.isPlaying = isPlaying
        self.accentColor = accentColor
        self.barCount = barCount
        self.onSeek = onSeek
    }

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return max(0, min(1.0, currentTime / duration))
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    let barProgress = Double(index) / Double(barCount)
                    let isPlayed = barProgress <= progress
                    let baseHeight = sampleHeight(for: index)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(isPlayed ? accentColor : Color.white.opacity(0.2))
                        .frame(width: max(2, (w - CGFloat(barCount * 3)) / CGFloat(barCount)))
                        .frame(height: max(4, h * baseHeight))
                        .animation(.easeInOut(duration: 0.2), value: isPlaying)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let ratio = max(0, min(1.0, Double(g.location.x / w)))
                        onSeek?(ratio * duration)
                    }
            )
        }
        .frame(height: 48)
    }

    private func sampleHeight(for index: Int) -> CGFloat {
        // Pseudo-random deterministic waveform profile
        let val = sin(Double(index) * 0.45) * 0.35 + cos(Double(index) * 0.8) * 0.3 + 0.4
        return CGFloat(max(0.15, min(1.0, val)))
    }
}

// MARK: - Previews
#Preview("Waveform Rail") {
    ZStack {
        Color.black.ignoresSafeArea()
        AKWaveformRailView(
            currentTime: 65,
            duration: 210,
            isPlaying: true
        )
        .padding()
    }
}

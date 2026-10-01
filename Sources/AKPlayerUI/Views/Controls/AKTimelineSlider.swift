//
//  AKTimelineSlider.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Single Responsibility: Timeline progress rendering, ad cue markers, and scrubbing interaction.
public struct AKTimelineSlider: View {
    public let currentTime: TimeInterval
    public let duration: TimeInterval
    public let bufferedTime: TimeInterval
    public let cuePoints: [TimeInterval]
    public let isAdActive: Bool
    public let isSeekEnabled: Bool
    public let palette: AKColorPalette
    public let typography: AKTypography

    public let onScrubBegan: (() -> Void)?
    public let onScrubChanged: ((TimeInterval) -> Void)?
    public let onScrubEnded: ((TimeInterval) -> Void)?

    @State private var isDragging: Bool = false
    @State private var dragPosition: Double = 0.0

    public init(
        currentTime: TimeInterval,
        duration: TimeInterval,
        bufferedTime: TimeInterval = 0,
        cuePoints: [TimeInterval] = [],
        isAdActive: Bool = false,
        isSeekEnabled: Bool = true,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard,
        onScrubBegan: (() -> Void)? = nil,
        onScrubChanged: ((TimeInterval) -> Void)? = nil,
        onScrubEnded: ((TimeInterval) -> Void)? = nil
    ) {
        self.currentTime = currentTime
        self.duration = duration
        self.bufferedTime = bufferedTime
        self.cuePoints = cuePoints
        self.isAdActive = isAdActive
        self.isSeekEnabled = isSeekEnabled
        self.palette = palette
        self.typography = typography
        self.onScrubBegan = onScrubBegan
        self.onScrubChanged = onScrubChanged
        self.onScrubEnded = onScrubEnded
    }

    private var activeProgress: Double {
        if isDragging {
            return dragPosition
        }
        guard duration > 0 else { return 0 }
        return max(0, min(1.0, currentTime / duration))
    }

    private var bufferedProgress: Double {
        guard duration > 0 else { return 0 }
        return max(0, min(1.0, bufferedTime / duration))
    }

    private var displayTime: TimeInterval {
        if isDragging {
            return dragPosition * duration
        }
        return currentTime
    }

    public var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                let trackWidth = geometry.size.width

                ZStack(alignment: .leading) {
                    // Background Rail
                    Capsule()
                        .fill(palette.progressRailRemaining)
                        .frame(height: isDragging ? 6 : 4)

                    // Buffered Progress Bar
                    Capsule()
                        .fill(palette.progressRailBuffered)
                        .frame(width: max(0, trackWidth * CGFloat(bufferedProgress)), height: isDragging ? 6 : 4)

                    // Active Played Progress Bar
                    Capsule()
                        .fill(isAdActive ? palette.adActiveProgress : palette.accent)
                        .frame(width: max(0, trackWidth * CGFloat(activeProgress)), height: isDragging ? 6 : 4)

                    // Ad Cue Points
                    if !isAdActive && duration > 0 {
                        ForEach(cuePoints, id: \.self) { cueTime in
                            let ratio = max(0, min(1.0, cueTime / duration))
                            Circle()
                                .fill(palette.adBreakIndicator)
                                .frame(width: 5, height: 5)
                                .offset(x: max(0, trackWidth * CGFloat(ratio) - 2.5))
                        }
                    }

                    // Scrubber Thumb Handle
                    if isSeekEnabled && !isAdActive {
                        Circle()
                            .fill(Color.white)
                            .frame(width: isDragging ? 18 : 12, height: isDragging ? 18 : 12)
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                            .offset(x: max(0, min(trackWidth - (isDragging ? 18 : 12), trackWidth * CGFloat(activeProgress) - (isDragging ? 9 : 6))))
                    }
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    isSeekEnabled && !isAdActive ?
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                onScrubBegan?()
                            }
                            let progress = max(0, min(1.0, Double(gesture.location.x / trackWidth)))
                            dragPosition = progress
                            onScrubChanged?(progress * duration)
                        }
                        .onEnded { gesture in
                            let finalProgress = max(0, min(1.0, Double(gesture.location.x / trackWidth)))
                            isDragging = false
                            onScrubEnded?(finalProgress * duration)
                        }
                    : nil
                )
            }
            .frame(height: 20)

            // Time Labels Row
            HStack {
                Text(formatTime(displayTime))
                    .font(typography.timecodeSmall)
                    .foregroundColor(palette.textSecondary)

                Spacer()

                if isAdActive {
                    Text("Ad Break • Scrubbing Locked")
                        .font(typography.badge)
                        .foregroundColor(palette.adActiveProgress)
                } else if duration > 0 {
                    Text("-\(formatTime(max(0, duration - displayTime)))")
                        .font(typography.timecodeSmall)
                        .foregroundColor(palette.textSecondary)
                }
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard !time.isNaN && !time.isInfinite && time >= 0 else { return "0:00" }
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - SwiftUI Previews
#Preview("Standard Timeline") {
    ZStack {
        Color.black.ignoresSafeArea()
        AKTimelineSlider(
            currentTime: 450,
            duration: 1800,
            bufferedTime: 900,
            cuePoints: [300, 900, 1500]
        )
        .padding()
    }
}

#Preview("Ad Lockdown Timeline") {
    ZStack {
        Color.black.ignoresSafeArea()
        AKTimelineSlider(
            currentTime: 12,
            duration: 15,
            isAdActive: true,
            isSeekEnabled: false
        )
        .padding()
    }
}

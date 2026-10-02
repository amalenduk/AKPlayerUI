//
//  AKTimelineSlider.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Single Responsibility: Timeline progress rendering, ad cue markers, scrubbing interaction,
/// and full Live stream DVR (sliding window / repeat telecast / live edge) handling.
public struct AKTimelineSlider: View {
    public let currentTime: TimeInterval
    public let duration: TimeInterval
    public let bufferedTime: TimeInterval
    public let cuePoints: [TimeInterval]
    public let isAdActive: Bool
    public let isSeekEnabled: Bool
    public let isLive: Bool
    public let isAtLiveEdge: Bool
    public let liveOffset: TimeInterval
    public let palette: AKColorPalette
    public let typography: AKTypography

    public let onJumpToLive: (() -> Void)?
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
        isLive: Bool = false,
        isAtLiveEdge: Bool = true,
        liveOffset: TimeInterval = 0,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard,
        onJumpToLive: (() -> Void)? = nil,
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
        self.isLive = isLive
        self.isAtLiveEdge = isAtLiveEdge
        self.liveOffset = liveOffset
        self.palette = palette
        self.typography = typography
        self.onJumpToLive = onJumpToLive
        self.onScrubBegan = onScrubBegan
        self.onScrubChanged = onScrubChanged
        self.onScrubEnded = onScrubEnded
    }

    private var activeProgress: Double {
        if isDragging {
            return dragPosition
        }
        if isLive {
            // In a Live stream, if the viewer is synced with the broadcast edge,
            // the scrubber thumb sits at the VERY END (1.0 / 100%)!
            if isAtLiveEdge {
                return 1.0
            }
            guard duration > 0 else { return 1.0 }
            return max(0, min(1.0, currentTime / duration))
        }
        guard duration > 0 else { return 0 }
        return max(0, min(1.0, currentTime / duration))
    }

    private var bufferedProgress: Double {
        if isLive {
            return 1.0
        }
        guard duration > 0 else { return 0 }
        return max(0, min(1.0, bufferedTime / duration))
    }

    private var displayTime: TimeInterval {
        if isDragging {
            return dragPosition * duration
        }
        return currentTime
    }

    private var effectiveLiveEdge: Bool {
        if isDragging {
            return dragPosition >= 0.96
        }
        return isAtLiveEdge
    }

    private var currentLiveOffset: TimeInterval {
        if isDragging {
            guard duration > 0 else { return 0 }
            return max(0, (1.0 - dragPosition) * duration)
        }
        return liveOffset
    }

    public var body: some View {
        VStack(spacing: AKSpacing.xxs) {
            if isLive && !isSeekEnabled {
                // Pure Live Stream (No DVR seeking backwards)
                pureLiveRibbon
            } else {
                // Seekable Track (VOD or Live DVR)
                scrubberTrack
            }

            // Labels Row
            labelsRow
        }
    }

    // MARK: - Scrubber Track

    private var scrubberTrack: some View {
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
                    .fill(
                        isAdActive ? palette.adActiveProgress :
                            (isLive ? Color.red : palette.accent)
                    )
                    .frame(width: max(0, trackWidth * CGFloat(activeProgress)), height: isDragging ? 6 : 4)

                // Ad Cue Points
                if !isAdActive && !isLive && duration > 0 {
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
                        .fill(isLive && effectiveLiveEdge ? Color.red : Color.white)
                        .frame(width: isDragging ? 18 : 12, height: isDragging ? 18 : 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: isLive && effectiveLiveEdge ? 2 : 0)
                        )
                        .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 1)
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
                        if isLive {
                            if progress >= 0.96 {
                                onScrubChanged?(duration)
                            } else {
                                onScrubChanged?(progress * duration)
                            }
                        } else {
                            onScrubChanged?(progress * duration)
                        }
                    }
                    .onEnded { gesture in
                        let finalProgress = max(0, min(1.0, Double(gesture.location.x / trackWidth)))
                        isDragging = false
                        if isLive {
                            if finalProgress >= 0.96 {
                                onJumpToLive?()
                            } else {
                                onScrubEnded?(finalProgress * duration)
                            }
                        } else {
                            onScrubEnded?(finalProgress * duration)
                        }
                    }
                : nil
            )
        }
        .frame(height: 20)
    }

    // MARK: - Pure Live Ribbon (No Scrubbing)
    private var pureLiveRibbon: some View {
        HStack(spacing: AKSpacing.xs) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)

            Text("BROADCASTING LIVE")
                .font(typography.badge)
                .foregroundColor(.white)

            Spacer()

            Text("Real-Time Feed")
                .font(typography.caption2)
                .foregroundColor(palette.textSecondary)
        }
        .frame(height: 20)
    }

    // MARK: - Labels Row
    private var labelsRow: some View {
        HStack {
            if isLive {
                if isSeekEnabled {
                    // DVR Live stream: left side shows stream elapsed or current position
                    Text(effectiveLiveEdge ? "LIVE BROADCAST" : "-\(formatOffset(currentLiveOffset))")
                        .font(typography.timecodeSmall)
                        .foregroundColor(effectiveLiveEdge ? palette.textSecondary : palette.accent)

                    Spacer()

                    // Right side shows interactive live badge / Go To Live button
                    AKLiveBadgeView(
                        isAtLiveEdge: effectiveLiveEdge,
                        offsetSeconds: currentLiveOffset,
                        typography: typography,
                        onJumpToLive: {
                            onJumpToLive?()
                        }
                    )
                } else {
                    EmptyView()
                }
            } else {
                // Standard VOD
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

    private func formatOffset(_ seconds: TimeInterval) -> String {
        let absSec = Int(abs(seconds))
        let m = absSec / 60
        let s = absSec % 60
        return String(format: "%d:%02d", m, s)
    }
}

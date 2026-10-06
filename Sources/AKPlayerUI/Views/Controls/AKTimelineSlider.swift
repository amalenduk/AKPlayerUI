//
//  AKTimelineSlider.swift
//  AKPlayerUI
//

import SwiftUI
import CoreMedia
import AKPlayer

/// Single Responsibility: Timeline progress rendering, ad cue markers, scrubbing interaction,
/// and full Live stream DVR (sliding window / repeat telecast / live edge) handling.
public struct AKTimelineSlider: View {
    public let currentTime: TimeInterval
    public let duration: TimeInterval
    public let loadedTimeRanges: [CMTimeRange]
    public let cuePoints: [TimeInterval]
    public let isAdActive: Bool
    public let isSeekEnabled: Bool
    public let isLive: Bool
    public let isAtLiveEdge: Bool
    public let liveOffset: TimeInterval
    
    public let onJumpToLive: (() -> Void)?
    public let onScrubBegan: (() -> Void)?
    public let onScrubChanged: ((TimeInterval) -> Void)?
    public let onScrubEnded: ((TimeInterval) -> Void)?
    
    @State private var isDragging: Bool = false
    @State private var dragPosition: Double = 0.0
    
    
    @Environment(\.akPlayerTheme) private var theme
    
    public init(
        currentTime: TimeInterval,
        duration: TimeInterval,
        loadedTimeRanges: [CMTimeRange] = [],
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
        self.loadedTimeRanges = loadedTimeRanges
        self.cuePoints = cuePoints
        self.isAdActive = isAdActive
        self.isSeekEnabled = isSeekEnabled
        self.isLive = isLive
        self.isAtLiveEdge = isAtLiveEdge
        self.liveOffset = liveOffset
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
            return max(0, min(1.0, 1.0 - (liveOffset / duration)))
        }
        guard duration > 0 else { return 0 }
        return max(0, min(1.0, currentTime / duration))
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
                    .fill(theme.palette.progressRailRemaining)
                    .frame(height: isDragging ? 6 : 4)
                
                // Buffered Progress Bars (YouTube-style segmented ranges)
                if isLive {
                    Capsule()
                        .fill(theme.palette.progressRailBuffered)
                        .frame(width: trackWidth, height: isDragging ? 6 : 4)
                } else if duration > 0 {
                    ForEach(loadedTimeRanges.indices, id: \.self) { index in
                        let range = loadedTimeRanges[index]
                        let startSec = range.start.seconds
                        let endSec = range.start.seconds + range.duration.seconds
                        if startSec.isFinite && endSec.isFinite && endSec > startSec {
                            let startProgress = max(0, min(1.0, startSec / duration))
                            let endProgress = max(0, min(1.0, endSec / duration))
                            let segmentWidth = max(0, trackWidth * CGFloat(endProgress - startProgress))
                            let segmentOffset = trackWidth * CGFloat(startProgress)
                            
                            Capsule()
                                .fill(theme.palette.progressRailBuffered)
                                .frame(width: segmentWidth, height: isDragging ? 6 : 4)
                                .offset(x: segmentOffset)
                        }
                    }
                }
                
                // Active Played Progress Bar
                Capsule()
                    .fill(
                        isAdActive ? theme.palette.adActiveProgress :
                            (isLive ? Color.red : theme.palette.accent)
                    )
                    .frame(width: max(0, trackWidth * CGFloat(activeProgress)), height: isDragging ? 6 : 4)
                
                // Ad Cue Points
                if !isAdActive && !isLive && duration > 0 {
                    ForEach(cuePoints, id: \.self) { cueTime in
                        let ratio = max(0, min(1.0, cueTime / duration))
                        Circle()
                            .fill(theme.palette.adBreakIndicator)
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
                .font(theme.typography.badge)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("Real-Time Feed")
                .font(theme.typography.caption2)
                .foregroundColor(theme.palette.textSecondary)
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
                        .font(theme.typography.timecodeSmall)
                        .foregroundColor(effectiveLiveEdge ? theme.palette.textSecondary : theme.palette.accent)
                    
                    Spacer()
                    
                    // Right side shows interactive live badge / Go To Live button
                    AKLiveBadgeView(
                        isAtLiveEdge: effectiveLiveEdge,
                        liveDrift: currentLiveOffset,
                        onJumpToLive: {
                            onJumpToLive?()
                        }
                    )
                } else {
                    EmptyView()
                }
            } else {
                // Standard VOD
                Text(displayTime.humanReadableClock)
                    .font(theme.typography.timecodeSmall)
                    .foregroundColor(theme.palette.textSecondary)
                
                Spacer()
                
                if isAdActive {
                    Text("Ad Break • Scrubbing Locked")
                        .font(theme.typography.badge)
                        .foregroundColor(theme.palette.adActiveProgress)
                } else if duration > 0 {
                    Text("-\(max(0, duration - displayTime).humanReadableClock)")
                        .font(theme.typography.timecodeSmall)
                        .foregroundColor(theme.palette.textSecondary)
                }
            }
        }
    }

    private func formatOffset(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

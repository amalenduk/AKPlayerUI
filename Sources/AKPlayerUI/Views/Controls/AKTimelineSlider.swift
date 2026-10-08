//
//  AKTimelineSlider.swift
//  AKPlayerUI
//

import SwiftUI
import CoreMedia
import AKPlayer

/// Single Responsibility: Interactive playback timeline slider supporting single-point cue markers,
/// ad duration fill ranges, magnetic snapping, restriction locks (matching AKProgressBar),
/// alongside full Live stream DVR (sliding window, jump to live, live edge indicator).
public struct AKTimelineSlider: View {
    public let currentTime: TimeInterval
    public let duration: TimeInterval
    public let loadedTimeRanges: [CMTimeRange]
    public let bufferProgress: Double
    public let markers: [AKInterstitialMarker]
    public let cuePoints: [TimeInterval]
    public let isAdActive: Bool
    public let isSeekEnabled: Bool
    public let isLive: Bool
    public let isAtLiveEdge: Bool
    public let liveOffset: TimeInterval
    public let enableSnapping: Bool
    public let enforceRestrictions: Bool
    
    public let onJumpToLive: (() -> Void)?
    public let onScrubBegan: (() -> Void)?
    public let onScrubChanged: ((TimeInterval) -> Void)?
    public let onScrubEnded: ((TimeInterval) -> Void)?
    
    @State private var isDragging: Bool = false
    @State private var dragPosition: Double = 0.0
    @State private var hoveredMarker: AKInterstitialMarker?
    @State private var isRestrictedAtMarker: Bool = false
    
    @Environment(\.akPlayerTheme) private var theme
    
    public init(
        currentTime: TimeInterval,
        duration: TimeInterval,
        loadedTimeRanges: [CMTimeRange] = [],
        bufferProgress: Double = 0.0,
        markers: [AKInterstitialMarker] = [],
        cuePoints: [TimeInterval] = [],
        isAdActive: Bool = false,
        isSeekEnabled: Bool = true,
        isLive: Bool = false,
        isAtLiveEdge: Bool = true,
        liveOffset: TimeInterval = 0,
        enableSnapping: Bool = true,
        enforceRestrictions: Bool = true,
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
        self.bufferProgress = bufferProgress
        self.markers = markers
        self.cuePoints = cuePoints
        self.isAdActive = isAdActive
        self.isSeekEnabled = isSeekEnabled
        self.isLive = isLive
        self.isAtLiveEdge = isAtLiveEdge
        self.liveOffset = liveOffset
        self.enableSnapping = enableSnapping
        self.enforceRestrictions = enforceRestrictions
        self.onJumpToLive = onJumpToLive
        self.onScrubBegan = onScrubBegan
        self.onScrubChanged = onScrubChanged
        self.onScrubEnded = onScrubEnded
    }
    
    private var effectiveMarkers: [AKInterstitialMarker] {
        if !markers.isEmpty {
            return markers
        }
        return cuePoints.map {
            AKInterstitialMarker(time: $0, occupancy: .singlePoint)
        }
    }
    
    private var activeProgress: Double {
        if isDragging {
            return dragPosition
        }
        if isLive {
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
            if isLive && !isSeekEnabled && duration <= 0 {
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
            let width = geometry.size.width
            let trackHeight: CGFloat = isDragging ? 6 : 4
            let centerY = geometry.size.height / 2
            let currentFraction = duration > 0 ? max(0, min(1.0, activeProgress)) : (isLive && effectiveLiveEdge ? 1.0 : 0.0)
            let effectiveFraction = isDragging ? dragPosition : currentFraction

            ZStack(alignment: .leading) {
                // 1. Background Rail
                Capsule()
                    .fill(theme.palette.progressRailRemaining)
                    .frame(height: trackHeight)
                    .position(x: width / 2, y: centerY)
                
                // 2. Buffer Track (Supports loadedTimeRanges or bufferProgress or Live)
                bufferTrackView(width: width, height: trackHeight, centerY: centerY)
                
                // 3. Ad Fill Ranges (like AKProgressBar)
                if !isLive && duration > 0 {
                    adFillRangesView(width: width, height: trackHeight, centerY: centerY)
                }
                
                // 4. Progress Track
                let progressWidth = max(0, width * CGFloat(effectiveFraction))
                Capsule()
                    .fill(
                        isLive ? theme.palette.liveBadge : theme.palette.progressRailFill
                    )
                    .frame(width: progressWidth, height: trackHeight)
                    .position(x: progressWidth / 2, y: centerY)
                
                // 5. Ad Cue Point Markers (Single Point, like AKProgressBar)
                if !isLive && duration > 0 {
                    adCueMarkersView(width: width, centerY: centerY)
                }
                
                // 6. Scrubber Thumb Handle
                if isSeekEnabled && !isAdActive {
                    scrubberThumbView(width: width, fraction: effectiveFraction, centerY: centerY)
                }
                
                // 7. Preview Tooltip when Dragging
                if isDragging {
                    previewTooltip(width: width, fraction: effectiveFraction)
                }
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            #if !os(tvOS)
            .gesture(
                isSeekEnabled && !isAdActive ?
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        handleDragChanged(value: gesture, width: width)
                    }
                    .onEnded { _ in
                        handleDragEnded()
                    }
                : nil
            )
            #endif
        }
        .frame(height: 32)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func bufferTrackView(width: CGFloat, height: CGFloat, centerY: CGFloat) -> some View {
        if isLive {
            Capsule()
                .fill(theme.palette.progressRailBuffered)
                .frame(width: width, height: height)
                .position(x: width / 2, y: centerY)
        } else if !loadedTimeRanges.isEmpty && duration > 0 {
            ForEach(loadedTimeRanges.indices, id: \.self) { index in
                let range = loadedTimeRanges[index]
                let startSec = range.start.seconds
                let endSec = range.start.seconds + range.duration.seconds
                if startSec.isFinite && endSec.isFinite && endSec > startSec {
                    let startProgress = max(0, min(1.0, startSec / duration))
                    let endProgress = max(0, min(1.0, endSec / duration))
                    let segmentWidth = max(0, width * CGFloat(endProgress - startProgress))
                    let segmentOffset = width * CGFloat(startProgress)
                    
                    Capsule()
                        .fill(theme.palette.progressRailBuffered)
                        .frame(width: segmentWidth, height: height)
                        .position(x: segmentOffset + segmentWidth / 2, y: centerY)
                }
            }
        } else if bufferProgress > 0 {
            let bufWidth = max(0, width * CGFloat(min(1.0, bufferProgress)))
            Capsule()
                .fill(theme.palette.progressRailBuffered)
                .frame(width: bufWidth, height: height)
                .position(x: bufWidth / 2, y: centerY)
        }
    }
    
    @ViewBuilder
    private func adFillRangesView(width: CGFloat, height: CGFloat, centerY: CGFloat) -> some View {
        ForEach(effectiveMarkers.filter(\.isFill)) { marker in
            let startFraction = max(0, min(1.0, marker.time / duration))
            let segmentDuration = marker.duration ?? 0
            let endFraction = max(startFraction, min(1.0, (marker.time + segmentDuration) / duration))
            let segmentWidth = max(2, width * CGFloat(endFraction - startFraction))
            let offset = width * CGFloat(startFraction)

            let fillColor: Color = Color(red: 0.98, green: 0.76, blue: 0.03).opacity(0.70)

            RoundedRectangle(cornerRadius: height / 2)
                .fill(fillColor)
                .frame(width: segmentWidth, height: height)
                .position(x: offset + segmentWidth / 2, y: centerY)
        }
    }
    
    @ViewBuilder
    private func adCueMarkersView(width: CGFloat, centerY: CGFloat) -> some View {
        ForEach(effectiveMarkers.filter(\.isSinglePoint)) { marker in
            let markerFraction = max(0, min(1.0, marker.time / duration))
            let xPosition = width * CGFloat(markerFraction)
            let markerColor: Color = Color(red: 0.98, green: 0.76, blue: 0.03)

            ZStack {
                Circle()
                    .fill(markerColor)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.2), lineWidth: 0.75)
                    )
                    .frame(
                        width: marker.isCurrent ? 8 : 6,
                        height: marker.isCurrent ? 8 : 6
                    )
                    .shadow(
                        color: markerColor.opacity(0.8),
                        radius: marker.isCurrent ? 4 : 2
                    )
            }
            .position(x: xPosition, y: centerY)
        }
    }
    
    @ViewBuilder
    private func scrubberThumbView(width: CGFloat, fraction: Double, centerY: CGFloat) -> some View {
        let xPosition = width * CGFloat(fraction)
        let thumbDiameter: CGFloat = isDragging ? 18 : 12

        Circle()
            .fill(
                isRestrictedAtMarker ? Color.orange :
                    (isLive && effectiveLiveEdge ? Color.red : Color.white)
            )
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: isLive && effectiveLiveEdge ? 2 : 0)
            )
            .frame(width: thumbDiameter, height: thumbDiameter)
            .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 1)
            .position(x: max(thumbDiameter / 2, min(width - thumbDiameter / 2, xPosition)), y: centerY)
            .animation(.easeInOut(duration: 0.1), value: isDragging)
    }
    
    @ViewBuilder
    private func previewTooltip(width: CGFloat, fraction: Double) -> some View {
        let targetSeconds = isLive ? (duration * fraction) : (fraction * duration)
        let xPosition = max(40, min(width - 40, width * CGFloat(fraction)))

        VStack(spacing: 2) {
            Text(isLive ? (fraction >= 0.96 ? "LIVE" : "-\(formatOffset((1.0 - fraction) * duration))") : formatTime(targetSeconds))
                .font(.caption2.bold())
                .foregroundColor(.white)

            if isRestrictedAtMarker {
                HStack(spacing: 2) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                    Text("Ad Required")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.yellow)
            } else if let marker = hoveredMarker {
                Text(marker.title ?? "Ad Break")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(theme.palette.hudBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(theme.palette.glassBorder, lineWidth: theme.materials.glassBorderWidth)
                )
        )
        .position(x: xPosition, y: -16)
    }
    
    // MARK: - Gesture Handling
    
    #if !os(tvOS)
    private func handleDragChanged(value: DragGesture.Value, width: CGFloat) {
        guard width > 0 else { return }
        if !isDragging {
            isDragging = true
            onScrubBegan?()
        }

        var rawFraction = max(0, min(1.0, Double(value.location.x / width)))
        var restricted = false
        var matchedMarker: AKInterstitialMarker?

        if isLive {
            dragPosition = rawFraction
            if rawFraction >= 0.96 {
                onScrubChanged?(duration)
            } else {
                onScrubChanged?(rawFraction * duration)
            }
            return
        }

        guard duration > 0 else { return }

        // 1. Restriction enforcement: cannot seek past unplayed ad with !marker.canSeek
        if enforceRestrictions {
            let currentSec = currentTime
            let targetSec = rawFraction * duration

            if targetSec > currentSec {
                let blockingMarker = effectiveMarkers.first { marker in
                    !marker.isPlayed &&
                    !marker.isCurrent &&
                    !marker.canSeek &&
                    marker.time > currentSec &&
                    marker.time <= targetSec
                }

                if let blockingMarker {
                    let markerFraction = blockingMarker.time / duration
                    rawFraction = markerFraction
                    restricted = true
                    matchedMarker = blockingMarker
                }
            }
        }

        // 2. Magnetic Snapping to discrete single-point markers within 2% threshold
        if enableSnapping && !restricted {
            let snapThreshold = 0.02
            for marker in effectiveMarkers where marker.isSinglePoint {
                let markerFraction = marker.time / duration
                if abs(rawFraction - markerFraction) <= snapThreshold {
                    rawFraction = markerFraction
                    matchedMarker = marker
                    break
                }
            }
        }

        dragPosition = rawFraction
        hoveredMarker = matchedMarker
        isRestrictedAtMarker = restricted
        onScrubChanged?(rawFraction * duration)
    }

    private func handleDragEnded() {
        let finalProgress = dragPosition
        isDragging = false
        isRestrictedAtMarker = false
        hoveredMarker = nil

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
    #endif
    
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
                        .foregroundColor(effectiveLiveEdge ? theme.palette.textSecondary : theme.palette.liveBadge)
                    
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
                Text(formatTime(displayTime))
                    .font(theme.typography.timecodeSmall)
                    .foregroundColor(theme.palette.textSecondary)
                
                Spacer()
                
                if isAdActive {
                    Text("Ad Break • Scrubbing Locked")
                        .font(theme.typography.badge)
                        .foregroundColor(theme.palette.adActiveProgress)
                } else if duration > 0 {
                    Text("-\(formatTime(max(0, duration - displayTime)))")
                        .font(theme.typography.timecodeSmall)
                        .foregroundColor(theme.palette.textSecondary)
                }
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, !seconds.isNaN, seconds >= 0 else { return "--:--" }
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        if mins >= 60 {
            let hours = mins / 60
            let remMins = mins % 60
            return String(format: "%d:%02d:%02d", hours, remMins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
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

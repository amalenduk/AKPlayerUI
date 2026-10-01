//
//  AKGestureConfiguration.swift
//  AKPlayerUI
//

import Foundation

/// Configuration governing touch and pointer gesture interactions on the player canvas.
public struct AKGestureConfiguration: Sendable, Equatable {
    /// Whether right-edge vertical drag gestures adjust system/player output volume.
    public var isVerticalSwipeVolumeEnabled: Bool

    /// Whether left-edge vertical drag gestures adjust display screen brightness.
    public var isVerticalSwipeBrightnessEnabled: Bool

    /// Whether double-tapping left/right screen zones triggers ±10s seeking ripples.
    public var isDoubleTapToSeekEnabled: Bool

    /// Whether pinch gestures zoom the video canvas between fit, fill, and custom magnification.
    public var isPinchToZoomEnabled: Bool

    /// Multiplier scaling horizontal pan scrub sensitivity (default: 1.0).
    public var horizontalScrubSensitivity: Double

    public init(
        isVerticalSwipeVolumeEnabled: Bool = true,
        isVerticalSwipeBrightnessEnabled: Bool = true,
        isDoubleTapToSeekEnabled: Bool = true,
        isPinchToZoomEnabled: Bool = true,
        horizontalScrubSensitivity: Double = 1.0
    ) {
        self.isVerticalSwipeVolumeEnabled = isVerticalSwipeVolumeEnabled
        self.isVerticalSwipeBrightnessEnabled = isVerticalSwipeBrightnessEnabled
        self.isDoubleTapToSeekEnabled = isDoubleTapToSeekEnabled
        self.isPinchToZoomEnabled = isPinchToZoomEnabled
        self.horizontalScrubSensitivity = horizontalScrubSensitivity
    }
}

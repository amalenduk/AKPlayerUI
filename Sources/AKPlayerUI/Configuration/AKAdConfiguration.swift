//
//  AKAdConfiguration.swift
//  AKPlayerUI
//

import Foundation

/// Policies and presentation rules for native `AKPlayerItem` interstitial ads.
public struct AKAdConfiguration: Sendable, Equatable {
    /// Whether user skip functionality is enabled after the required countdown delay.
    public var allowsAdSkip: Bool

    /// Delay in seconds before the "Skip Ad →" CTA is unlocked (default: 5.0s).
    public var skipCountdownDuration: TimeInterval

    /// Whether the top-left ad pod badge ("Ad 1 of 2 • 0:12") is shown.
    public var showsAdCountdownBadge: Bool

    /// Whether amber ad cue points are plotted along the timeline slider.
    public var showsCuePointsOnTimeline: Bool

    /// Explicit ad break timestamps in seconds (or extracted from media metadata).
    public var cuePoints: [TimeInterval]

    public init(
        allowsAdSkip: Bool = true,
        skipCountdownDuration: TimeInterval = 5.0,
        showsAdCountdownBadge: Bool = true,
        showsCuePointsOnTimeline: Bool = true,
        cuePoints: [TimeInterval] = []
    ) {
        self.allowsAdSkip = allowsAdSkip
        self.skipCountdownDuration = skipCountdownDuration
        self.showsAdCountdownBadge = showsAdCountdownBadge
        self.showsCuePointsOnTimeline = showsCuePointsOnTimeline
        self.cuePoints = cuePoints
    }
}

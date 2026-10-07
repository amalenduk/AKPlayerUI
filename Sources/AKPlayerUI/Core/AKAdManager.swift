//
//  AKAdManager.swift
//  AKPlayerUI
//

import Foundation
import Combine
import AKPlayer

/// Manages runtime state for native interstitial ad playback (`AKPlayerItem` streams).
/// Completely decouples high-frequency 1-second countdown ticks from the main player coordinator.
@MainActor
public final class AKAdManager: ObservableObject, @unchecked Sendable {
    @Published public internal(set) var markers: [AKInterstitialMarker] = []
    @Published public private(set) var isAdActive: Bool = false
    @Published public private(set) var currentAdIndex: Int = 0
    @Published public private(set) var totalAdsInPod: Int = 0
    @Published public private(set) var adDuration: TimeInterval = 0
    @Published public private(set) var adTimeRemaining: TimeInterval = 0
    @Published public private(set) var allowsSkip: Bool = false
    @Published public private(set) var isAdSkippable: Bool = false
    @Published public private(set) var adSkipCountdown: TimeInterval = 0
    @Published public private(set) var skipCountdownDuration: TimeInterval = 5.0
    @Published public private(set) var sponsorName: String?
    @Published public private(set) var sponsorLinkURL: URL?

    public var cuePoints: [TimeInterval] {
        markers.map(\.time)
    }

    public var onSkipRequested: (@MainActor () -> Void)?

    public init() {}

    /// Activates ad overlay state for a native interstitial pod.
    public func startAdPod(
        index: Int = 1,
        total: Int = 1,
        duration: TimeInterval = 0,
        skipDelay: TimeInterval = 5.0,
        allowsSkip: Bool = true,
        sponsor: String? = nil,
        sponsorURL: URL? = nil
    ) {
        self.isAdActive = true
        self.currentAdIndex = index
        self.totalAdsInPod = total
        self.adDuration = duration
        self.adTimeRemaining = duration
        self.skipCountdownDuration = skipDelay
        self.sponsorName = sponsor
        self.sponsorLinkURL = sponsorURL

        // Short ad rule: if duration is known and is <= skipDelay, skip is disabled
        let effectiveAllowsSkip = allowsSkip && (duration <= 0 || duration > skipDelay)
        self.allowsSkip = effectiveAllowsSkip

        if effectiveAllowsSkip && skipDelay > 0 {
            self.isAdSkippable = false
            self.adSkipCountdown = skipDelay
        } else if effectiveAllowsSkip {
            self.isAdSkippable = true
            self.adSkipCountdown = 0
        } else {
            self.isAdSkippable = false
            self.adSkipCountdown = 0
        }
    }

    /// Updates live playback time remaining from AKPlayer interstitial progress.
    public func updateProgress(currentTime: TimeInterval, duration: TimeInterval, timeRemaining: TimeInterval) {
        guard isAdActive else { return }
        self.adTimeRemaining = max(0, timeRemaining)

        if self.adDuration == 0 && duration > 0 {
            self.adDuration = duration
            // Re-evaluate if ad is too short for skipping once live duration is discovered
            if allowsSkip && duration <= skipCountdownDuration {
                self.allowsSkip = false
                self.isAdSkippable = false
                self.adSkipCountdown = 0
            }
        }

        if allowsSkip && adSkipCountdown > 0 {
            adSkipCountdown = max(0, adSkipCountdown - 1.0)
            if adSkipCountdown <= 0 {
                isAdSkippable = true
            }
        }
    }

    /// Triggers user skip request to the player engine.
    public func skipAd() {
        guard isAdSkippable else { return }
        onSkipRequested?()
    }

    /// Ends active ad pod and restores standard media playback HUD.
    public func endAdPod() {
        self.isAdActive = false
        self.currentAdIndex = 0
        self.totalAdsInPod = 0
        self.adDuration = 0
        self.adTimeRemaining = 0
        self.allowsSkip = false
        self.isAdSkippable = false
        self.adSkipCountdown = 0
        self.sponsorName = nil
        self.sponsorLinkURL = nil
    }

    // MARK: - Previews & Mocks
    public static var previewActiveAd: AKAdManager {
        let manager = AKAdManager()
        manager.startAdPod(
            index: 1,
            total: 2,
            duration: 15.0,
            skipDelay: 4.0,
            allowsSkip: true,
            sponsor: "Acme Streaming",
            sponsorURL: URL(string: "https://apple.com")
        )
        return manager
    }

    public static var previewSkippableAd: AKAdManager {
        let manager = AKAdManager()
        manager.startAdPod(
            index: 1,
            total: 1,
            duration: 12.0,
            skipDelay: 0.0,
            allowsSkip: true,
            sponsor: "Pro Audio Gear"
        )
        manager.isAdSkippable = true
        return manager
    }
}

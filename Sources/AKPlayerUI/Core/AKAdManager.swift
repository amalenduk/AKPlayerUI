//
//  AKAdManager.swift
//  AKPlayerUI
//

import Foundation
import Combine

/// Manages runtime state for native interstitial ad playback (`AKPlayerItem` streams).
/// Completely decouples high-frequency 1-second countdown ticks from the main player coordinator.
@MainActor
public final class AKAdManager: ObservableObject, @unchecked Sendable {
    @Published public private(set) var isAdActive: Bool = false
    @Published public private(set) var currentAdIndex: Int = 0
    @Published public private(set) var totalAdsInPod: Int = 0
    @Published public private(set) var adTimeRemaining: TimeInterval = 0
    @Published public private(set) var isAdSkippable: Bool = false
    @Published public private(set) var adSkipCountdown: TimeInterval = 0
    @Published public private(set) var sponsorName: String?
    @Published public private(set) var sponsorLinkURL: URL?

    public var onSkipRequested: (@MainActor () -> Void)?

    public init() {}

    /// Activates ad overlay state for a native interstitial pod.
    public func startAdPod(
        index: Int = 1,
        total: Int = 1,
        duration: TimeInterval = 15.0,
        skipDelay: TimeInterval = 5.0,
        allowsSkip: Bool = true,
        sponsor: String? = nil,
        sponsorURL: URL? = nil
    ) {
        self.isAdActive = true
        self.currentAdIndex = index
        self.totalAdsInPod = total
        self.adTimeRemaining = duration
        self.sponsorName = sponsor
        self.sponsorLinkURL = sponsorURL

        if allowsSkip && skipDelay > 0 {
            self.isAdSkippable = false
            self.adSkipCountdown = skipDelay
        } else if allowsSkip {
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
        if adSkipCountdown > 0 {
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
        self.adTimeRemaining = 0
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

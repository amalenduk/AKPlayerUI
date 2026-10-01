//
//  AKAdOverlayView.swift
//  AKPlayerUI
//

import SwiftUI

/// Single Responsibility: Displays native overlay on top of player canvas during AKPlayerItem interstitial ad playback.
/// Shows countdown badge, sponsor linkout pill, and morphing Skip Ad button.
public struct AKAdOverlayView: View {
    @ObservedObject public var adManager: AKAdManager
    public let palette: AKColorPalette
    public let typography: AKTypography

    public init(
        adManager: AKAdManager,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard
    ) {
        self.adManager = adManager
        self.palette = palette
        self.typography = typography
    }

    public var body: some View {
        if adManager.isAdActive {
            ZStack {
                // Top Row: Pod Indicator Badge
                VStack {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(palette.adBreakIndicator)
                                .frame(width: 8, height: 8)

                            Text("Ad \(adManager.currentAdIndex) of \(max(1, adManager.totalAdsInPod))")
                                .font(typography.badge)
                                .foregroundColor(.white)

                            Text("•")
                                .foregroundColor(.white.opacity(0.5))

                            Text("\(Int(adManager.adTimeRemaining))s remaining")
                                .font(typography.timecodeSmall)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.65))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )

                        Spacer()
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                    Spacer()

                    // Bottom Row: Sponsor Linkout & Morphing Skip Button
                    HStack {
                        if let sponsor = adManager.sponsorName {
                            Link(destination: adManager.sponsorLinkURL ?? URL(string: "https://apple.com")!) {
                                HStack(spacing: 6) {
                                    Text("Sponsored by \(sponsor)")
                                        .font(typography.footnote)
                                    Image(systemName: "arrow.up.right")
                                        .font(typography.badgeSmall)
                                }
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.6))
                                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                                )
                            }
                        }

                        Spacer()

                        // Morphing Skip CTA Button
                        Button(action: {
                            if adManager.isAdSkippable {
                                adManager.skipAd()
                            }
                        }) {
                            HStack(spacing: 6) {
                                if adManager.isAdSkippable {
                                    Text("Skip Ad")
                                        .font(typography.button)
                                    Image(systemName: "forward.end.fill")
                                        .font(typography.caption1.weight(.bold))
                                } else {
                                    Text("Skip in \(Int(adManager.adSkipCountdown))s")
                                        .font(typography.timecodeSmall)
                                    Image(systemName: "hourglass")
                                        .font(typography.caption1)
                                }
                            }
                            .foregroundColor(adManager.isAdSkippable ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(adManager.isAdSkippable ? Color.white : Color.black.opacity(0.65))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!adManager.isAdSkippable)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: adManager.isAdSkippable)
                    }
                    .padding(.bottom, 36)
                    .padding(.horizontal, 24)
                }
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Previews
#Preview("Ad Countdown Active") {
    ZStack {
        Color.gray.opacity(0.4).ignoresSafeArea()
        AKAdOverlayView(adManager: .previewActiveAd)
    }
}

#Preview("Ad Skippable State") {
    ZStack {
        Color.gray.opacity(0.4).ignoresSafeArea()
        AKAdOverlayView(adManager: .previewSkippableAd)
    }
}

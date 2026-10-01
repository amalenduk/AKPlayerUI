//
//  AKEqualizerConfiguration.swift
//  AKPlayerUI
//

import Foundation

/// Policies governing audio equalizer availability and decibel limits.
public struct AKEqualizerConfiguration: Sendable, Equatable {
    /// Whether the 10-band equalizer feature is enabled for the active profile.
    public var isAvailable: Bool

    /// Default starting preset (default: .flat).
    public var defaultPreset: AKEqualizerPreset

    /// Center frequencies for equalized bands.
    public var frequencies: [Double]

    /// Gain adjustment range in decibels (default: -12.0 dB ... +12.0 dB).
    public var minGain: Float
    public var maxGain: Float

    public init(
        isAvailable: Bool = true,
        defaultPreset: AKEqualizerPreset = .flat,
        frequencies: [Double] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000],
        minGain: Float = -12.0,
        maxGain: Float = 12.0
    ) {
        self.isAvailable = isAvailable
        self.defaultPreset = defaultPreset
        self.frequencies = frequencies
        self.minGain = minGain
        self.maxGain = maxGain
    }
}

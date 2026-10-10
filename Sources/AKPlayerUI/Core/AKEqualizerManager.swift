//
//  AKEqualizerManager.swift
//  AKPlayerUI
//

import Foundation
import SwiftUI
import Combine

/// Standard commercial center frequencies for 10-band audio graphic equalizers.
public struct AKEqualizerBand: Identifiable, Sendable, Equatable, Hashable, Codable {
    public let id: Int
    public let frequency: Double
    public let frequencyLabel: String
    public var gain: Float // Gain in decibels: -12.0 dB ... +12.0 dB

    public init(id: Int, frequency: Double, frequencyLabel: String, gain: Float = 0.0) {
        self.id = id
        self.frequency = frequency
        self.frequencyLabel = frequencyLabel
        self.gain = gain
    }

    public static let tenBands: [AKEqualizerBand] = [
        AKEqualizerBand(id: 0, frequency: 32,    frequencyLabel: "32Hz"),
        AKEqualizerBand(id: 1, frequency: 64,    frequencyLabel: "64Hz"),
        AKEqualizerBand(id: 2, frequency: 125,   frequencyLabel: "125Hz"),
        AKEqualizerBand(id: 3, frequency: 250,   frequencyLabel: "250Hz"),
        AKEqualizerBand(id: 4, frequency: 500,   frequencyLabel: "500Hz"),
        AKEqualizerBand(id: 5, frequency: 1000,  frequencyLabel: "1kHz"),
        AKEqualizerBand(id: 6, frequency: 2000,  frequencyLabel: "2kHz"),
        AKEqualizerBand(id: 7, frequency: 4000,  frequencyLabel: "4kHz"),
        AKEqualizerBand(id: 8, frequency: 8000,  frequencyLabel: "8kHz"),
        AKEqualizerBand(id: 9, frequency: 16000, frequencyLabel: "16kHz")
    ]
}

/// Curated DSP Equalizer Presets.
public enum AKEqualizerPreset: String, CaseIterable, Identifiable, Sendable, Codable {
    case flat = "Flat"
    case bassBoost = "Bass Boost"
    case bassReducer = "Bass Reducer"
    case trebleBoost = "Treble Boost"
    case vocalBoost = "Vocal Boost"
    case rock = "Rock"
    case pop = "Pop"
    case jazz = "Jazz"
    case classical = "Classical"
    case electronic = "Electronic"
    case spokenWord = "Spoken Word"
    case custom = "Custom"

    public var id: String { rawValue }

    public var gains: [Float] {
        switch self {
        case .flat:
            return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        case .bassBoost:
            return [6.0, 5.0, 4.0, 2.5, 1.0, 0, 0, 0, 0, 0]
        case .bassReducer:
            return [-6.0, -5.0, -4.0, -2.0, 0, 0, 0, 0, 0, 0]
        case .trebleBoost:
            return [0, 0, 0, 0, 0, 1.0, 2.5, 4.0, 5.5, 6.5]
        case .vocalBoost:
            return [-1.5, -1.0, 0, 2.0, 4.5, 4.5, 3.0, 1.5, 0, -1.0]
        case .rock:
            return [5.0, 3.5, 2.0, 0, -1.0, 0, 2.0, 3.5, 4.5, 5.0]
        case .pop:
            return [-1.5, 1.0, 3.0, 4.0, 3.5, 1.0, -1.0, -1.5, 2.0, 3.0]
        case .jazz:
            return [3.5, 2.5, 1.0, 1.5, -1.5, -1.5, 0, 1.5, 2.5, 3.5]
        case .classical:
            return [4.5, 3.5, 2.5, 2.0, -1.5, -1.5, 0, 2.0, 3.0, 3.5]
        case .electronic:
            return [5.5, 4.5, 1.5, 0, -2.0, 1.5, 0, 2.0, 4.5, 5.5]
        case .spokenWord:
            return [-4.0, -2.0, 0, 1.5, 3.5, 4.0, 3.0, 1.5, 0, -2.0]
        case .custom:
            return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        }
    }
}

/// Standalone Audio Equalizer & DSP Manager with automatic persistent storage.
@MainActor
public final class AKEqualizerManager: ObservableObject, @unchecked Sendable {
    // MARK: - Persistence Keys
    public enum StorageKeys {
        public static let isEnabled = "com.akplayer.equalizer.isEnabled"
        public static let preset = "com.akplayer.equalizer.preset"
        public static let bandGains = "com.akplayer.equalizer.bandGains"
        public static let preampGain = "com.akplayer.equalizer.preampGain"
    }

    private let userDefaults: UserDefaults
    public let isPersistenceEnabled: Bool
    private var isInitializing: Bool = true

    @Published public var isEnabled: Bool = false {
        didSet {
            persistSettings()
        }
    }

    @Published public var activePreset: AKEqualizerPreset = .flat {
        didSet {
            persistSettings()
        }
    }

    @Published public var bands: [AKEqualizerBand] = AKEqualizerBand.tenBands {
        didSet {
            persistSettings()
        }
    }

    @Published public var preampGain: Float = 0.0 { // -6.0 dB ... +6.0 dB
        didSet {
            persistSettings()
        }
    }

    // MARK: - Initializer

    public init(userDefaults: UserDefaults = .standard, persist: Bool = true) {
        self.userDefaults = userDefaults
        self.isPersistenceEnabled = persist

        loadSettings()
        self.isInitializing = false
    }

    // MARK: - Equalizer Operations

    /// Applies a curated preset across all 10 bands and updates storage.
    public func applyPreset(_ preset: AKEqualizerPreset) {
        activePreset = preset
        guard preset != .custom else { return }
        let presetGains = preset.gains
        for i in 0..<min(bands.count, presetGains.count) {
            bands[i].gain = presetGains[i]
        }
        persistSettings()
    }

    /// Sets the gain for an individual frequency band, marks preset as custom, and updates storage.
    public func setGain(_ gain: Float, forBandAt index: Int) {
        guard bands.indices.contains(index) else { return }
        bands[index].gain = max(-12.0, min(12.0, gain))
        activePreset = .custom
        persistSettings()
    }

    /// Resets all equalizer bands and preamp gain to 0.0 dB flat and updates storage.
    public func reset() {
        applyPreset(.flat)
        preampGain = 0.0
        persistSettings()
    }

    /// Restores factory defaults and clears persisted UserDefaults entries.
    public func clearSavedSettings() {
        guard isPersistenceEnabled else { return }
        userDefaults.removeObject(forKey: StorageKeys.isEnabled)
        userDefaults.removeObject(forKey: StorageKeys.preset)
        userDefaults.removeObject(forKey: StorageKeys.bandGains)
        userDefaults.removeObject(forKey: StorageKeys.preampGain)
        reset()
        isEnabled = false
    }

    // MARK: - Storage Lifecycle

    private func persistSettings() {
        guard isPersistenceEnabled && !isInitializing else { return }
        userDefaults.set(isEnabled, forKey: StorageKeys.isEnabled)
        userDefaults.set(activePreset.rawValue, forKey: StorageKeys.preset)
        userDefaults.set(preampGain, forKey: StorageKeys.preampGain)
        let gains = bands.map { $0.gain }
        userDefaults.set(gains, forKey: StorageKeys.bandGains)
    }

    private func loadSettings() {
        guard isPersistenceEnabled else { return }

        if userDefaults.object(forKey: StorageKeys.isEnabled) != nil {
            self.isEnabled = userDefaults.bool(forKey: StorageKeys.isEnabled)
        }

        if let rawPreset = userDefaults.string(forKey: StorageKeys.preset),
           let preset = AKEqualizerPreset(rawValue: rawPreset) {
            self.activePreset = preset
        }

        if userDefaults.object(forKey: StorageKeys.preampGain) != nil {
            self.preampGain = userDefaults.float(forKey: StorageKeys.preampGain)
        }

        if let savedGains = userDefaults.array(forKey: StorageKeys.bandGains) as? [Float],
           savedGains.count == bands.count {
            for i in 0..<bands.count {
                bands[i].gain = savedGains[i]
            }
        } else if let savedNumbers = userDefaults.array(forKey: StorageKeys.bandGains) as? [NSNumber],
                  savedNumbers.count == bands.count {
            for i in 0..<bands.count {
                bands[i].gain = savedNumbers[i].floatValue
            }
        }
    }

    // MARK: - Spline Curves

    /// Generates normalized coordinate points (0...1) for dynamic cubic spline response curves.
    public func normalizedCurvePoints() -> [CGPoint] {
        guard !bands.isEmpty else { return [] }
        let count = bands.count
        return bands.enumerated().map { index, band in
            let x = CGFloat(index) / CGFloat(count - 1)
            // Map -12...+12 dB to 1...0 (0.5 is 0dB center line)
            let clampedGain = max(-12.0, min(12.0, band.gain))
            let normalizedY = CGFloat(1.0 - ((clampedGain + 12.0) / 24.0))
            return CGPoint(x: x, y: normalizedY)
        }
    }
}

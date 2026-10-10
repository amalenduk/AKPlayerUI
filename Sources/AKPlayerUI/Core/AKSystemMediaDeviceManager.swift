//
//  AKSystemMediaDeviceManager.swift
//  AKPlayerUI
//

import Foundation
#if canImport(Combine)
import Observation
import Combine
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(MediaPlayer)
import MediaPlayer
#endif

/// Manages hardware system volume and device display brightness without modifying player-level audio.
@Observable
@MainActor
public final class AKSystemMediaDeviceManager {
    public static let shared = AKSystemMediaDeviceManager()
    
    #if os(iOS)
    private var volumeSlider: UISlider?
    private var volumeView: MPVolumeView?
    private var volumeObservation: NSKeyValueObservation?
    #endif

    private var lastNonZeroVolume: Float = 0.5

    /// Whether the system audio is currently muted (volume is 0).
    public private(set) var isMuted: Bool = false

    /// Current hardware system output volume (0.0 ... 1.0).
    public private(set) var currentVolume: Float = 0.5

    /// Current device screen brightness (0.0 ... 1.0).
    public private(set) var currentBrightness: Float = 0.5

    /// Callback invoked when hardware side buttons or software volume changes (0.0 ... 1.0).
    public var onVolumeChanged: ((Float) -> Void)?

    /// Callback invoked when system mute state changes.
    public var onMuteChanged: ((Bool) -> Void)?
    
    private init() {
        #if os(iOS)
        let initialVolume = AVAudioSession.sharedInstance().outputVolume
        currentVolume = initialVolume
        isMuted = (initialVolume == 0)
        if initialVolume > 0 {
            lastNonZeroVolume = initialVolume
        }
        currentBrightness = readCurrentBrightness()
        setupVolumeControl()
        startVolumeObservation()
        #else
        currentVolume = 0.5
        isMuted = false
        currentBrightness = 0.5
        #endif
    }
    
    #if os(iOS)
    private func setupVolumeControl() {
        if volumeSlider != nil { return }
        
        let view = MPVolumeView(frame: CGRect(x: -2000, y: -2000, width: 1, height: 1))
        view.alpha = 0.0001
        view.clipsToBounds = true
        self.volumeView = view
        
        for subview in view.subviews {
            if let slider = subview as? UISlider {
                self.volumeSlider = slider
                break
            }
        }
        
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first {
            window.addSubview(view)
        }
    }

    private func startVolumeObservation() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        volumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let newVol = change.newValue else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentVolume = newVol
                if newVol > 0 {
                    self.lastNonZeroVolume = newVol
                }
                self.onVolumeChanged?(newVol)

                let isNowMuted = (newVol == 0)
                if isNowMuted != self.isMuted {
                    self.isMuted = isNowMuted
                    self.onMuteChanged?(isNowMuted)
                }
            }
        }
    }
    #endif
    
    /// Sets the hardware system volume directly via MPVolumeView.
    public func setVolume(_ volume: Float) {
        let clamped = max(0.0, min(1.0, volume))
        if clamped > 0 {
            lastNonZeroVolume = clamped
        }
        currentVolume = clamped
        let isNowMuted = (clamped == 0)
        if isNowMuted != isMuted {
            isMuted = isNowMuted
            onMuteChanged?(isNowMuted)
        }
        onVolumeChanged?(clamped)

        #if os(iOS)
        if volumeSlider == nil {
            setupVolumeControl()
        }
        
        guard let slider = volumeSlider else { return }
        slider.setValue(clamped, animated: false)
        slider.sendActions(for: .valueChanged)
        #endif
    }

    /// Flag indicating if a mute/unmute transition is underway, used to prevent floating volume HUD popups.
    public private(set) var isMutingOrUnmuting: Bool = false

    /// Sets the mute status of the system audio.
    public func setMute(_ muted: Bool) {
        isMutingOrUnmuting = true
        if muted {
            if currentVolume > 0 {
                lastNonZeroVolume = currentVolume
            }
            setVolume(0.0)
        } else {
            let restoreVol = lastNonZeroVolume > 0 ? lastNonZeroVolume : 0.5
            setVolume(restoreVol)
        }
        if isMuted != muted {
            isMuted = muted
            onMuteChanged?(muted)
        }
        // Reset flag asynchronously so any immediate volume callbacks can skip HUD presentation
        DispatchQueue.main.async { [weak self] in
            self?.isMutingOrUnmuting = false
        }
    }

    /// Sets the mute status of the system audio (convenience alias for setMute).
    public func setMuted(_ muted: Bool) {
        setMute(muted)
    }

    /// Toggles the mute status of the system audio.
    public func toggleMute() {
        setMute(!isMuted)
    }
    
    private func readCurrentBrightness() -> Float {
        #if os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            return Float(windowScene.screen.brightness)
        }
        return Float(UIScreen.main.brightness)
        #else
        return 0.5
        #endif
    }
    
    /// Sets device screen brightness.
    public func setBrightness(_ brightness: Float) {
        let clamped = CGFloat(max(0.0, min(1.0, brightness)))
        currentBrightness = Float(clamped)
        #if os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            windowScene.screen.brightness = clamped
        } else {
            UIScreen.main.brightness = clamped
        }
        #endif
    }
}

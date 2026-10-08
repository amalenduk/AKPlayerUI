//
//  AKSystemMediaDeviceManager.swift
//  AKPlayerUI
//

import Foundation
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
@MainActor
public final class AKSystemMediaDeviceManager {
    public static let shared = AKSystemMediaDeviceManager()
    
    #if os(iOS)
    private var volumeSlider: UISlider?
    private var volumeView: MPVolumeView?
    private var volumeObservation: NSKeyValueObservation?
    #endif

    /// Callback invoked when hardware side buttons or software volume changes (0.0 ... 1.0).
    public var onVolumeChanged: ((Float) -> Void)?
    
    private init() {
        #if os(iOS)
        setupVolumeControl()
        startVolumeObservation()
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
                self?.onVolumeChanged?(newVol)
            }
        }
    }
    #endif
    
    /// Current hardware system output volume (0.0 ... 1.0).
    public var currentVolume: Float {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        return AVAudioSession.sharedInstance().outputVolume
        #else
        return 0.5
        #endif
    }
    
    /// Sets the hardware system volume directly via MPVolumeView.
    public func setVolume(_ volume: Float) {
        #if os(iOS)
        let clamped = max(0.0, min(1.0, volume))
        if volumeSlider == nil {
            setupVolumeControl()
        }
        
        guard let slider = volumeSlider else { return }
        slider.setValue(clamped, animated: false)
        slider.sendActions(for: .valueChanged)
        #endif
    }
    
    /// Current device screen brightness (0.0 ... 1.0).
    public var currentBrightness: Float {
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
        #if os(iOS)
        let clamped = CGFloat(max(0.0, min(1.0, brightness)))
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

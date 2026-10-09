//
//  AKAirPlayButton.swift
//  AKPlayerUI
//

import SwiftUI
#if canImport(AVKit)
import AVKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Native Route Picker Wrapper

#if os(iOS) || os(tvOS)
public struct AKAirPlayRoutePickerWrapper: UIViewRepresentable {
    public var tintColor: UIColor
    public var activeTintColor: UIColor
    public var prioritizesVideoDevices: Bool

    public init(
        tintColor: UIColor = .white,
        activeTintColor: UIColor = .systemBlue,
        prioritizesVideoDevices: Bool = true
    ) {
        self.tintColor = tintColor
        self.activeTintColor = activeTintColor
        self.prioritizesVideoDevices = prioritizesVideoDevices
    }

    public func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.backgroundColor = .clear
        picker.tintColor = tintColor
        picker.activeTintColor = activeTintColor
        picker.prioritizesVideoDevices = prioritizesVideoDevices
        return picker
    }

    public func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = tintColor
        uiView.activeTintColor = activeTintColor
        uiView.prioritizesVideoDevices = prioritizesVideoDevices
    }
}
#elseif os(macOS)
public struct AKAirPlayRoutePickerWrapper: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        return picker
    }

    public func updateNSView(_ nsView: AVRoutePickerView, context: Context) {}
}
#endif

// MARK: - Themed AirPlay Button

/// A themed button for triggering AirPlay routing in player HUDs and sheets, conforming to AKPlayerTheme aesthetics.
public struct AKAirPlayButton: View {
    public var isAudioOnly: Bool
    public var size: CGFloat
    public var palette: AKColorPalette
    public var isGlassStyle: Bool

    public init(
        isAudioOnly: Bool = false,
        size: CGFloat = 44,
        palette: AKColorPalette = .standard,
        isGlassStyle: Bool = true
    ) {
        self.isAudioOnly = isAudioOnly
        self.size = size
        self.palette = palette
        self.isGlassStyle = isGlassStyle
    }

    public var body: some View {
        ZStack {
            #if os(iOS) || os(tvOS)
            AKAirPlayRoutePickerWrapper(
                tintColor: UIColor(palette.textPrimary),
                activeTintColor: UIColor(palette.accent),
                prioritizesVideoDevices: !isAudioOnly
            )
            .frame(width: size, height: size)
            .opacity(0.001) // Invisible touch layer forwarding touch events directly to AVRoutePickerView
            #elseif os(macOS)
            AKAirPlayRoutePickerWrapper()
                .frame(width: size, height: size)
                .opacity(0.001)
            #endif

            // Themed visual presentation matching the library glassmorphism
            ZStack {
                if isGlassStyle {
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: size, height: size)
                        .overlay(
                            Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }

                Image(systemName: isAudioOnly ? "airplayaudio" : "airplayvideo")
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundColor(palette.textPrimary)
            }
            .allowsHitTesting(false) // Let taps fall through to the native AVRoutePickerView
        }
        .frame(width: size, height: size)
    }
}

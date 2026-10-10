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

// MARK: - AirPlay Launcher Service

/// Global coordinator facilitating programmatic triggering of the native AirPlay route picker
/// across SwiftUI buttons, sheets, and player overlays.
@MainActor
public final class AKAirPlayLauncher: ObservableObject {
    public static let shared = AKAirPlayLauncher()

    #if os(iOS) || os(tvOS)
    public weak var activePicker: AVRoutePickerView?
    #elseif os(macOS)
    public weak var activePicker: AVRoutePickerView?
    #endif

    public func showAirPlayPicker() {
        #if os(iOS) || os(tvOS)
        guard let picker = activePicker else { return }
        if let button = findButton(in: picker) {
            button.sendActions(for: .touchUpInside)
        }
        #elseif os(macOS)
        guard let picker = activePicker else { return }
        if let button = findButton(in: picker) {
            button.performClick(nil)
        }
        #endif
    }

    #if os(iOS) || os(tvOS)
    private func findButton(in view: UIView) -> UIButton? {
        if let button = view as? UIButton { return button }
        for subview in view.subviews {
            if let button = findButton(in: subview) { return button }
        }
        return nil
    }
    #elseif os(macOS)
    private func findButton(in view: NSView) -> NSButton? {
        if let button = view as? NSButton { return button }
        for subview in view.subviews {
            if let button = findButton(in: subview) { return button }
        }
        return nil
    }
    #endif
}

// MARK: - Native Route Picker Wrapper

#if os(iOS) || os(tvOS)
public struct AKAirPlayRoutePickerWrapper: UIViewRepresentable {
    public var tintColor: UIColor
    public var activeTintColor: UIColor
    public var prioritizesVideoDevices: Bool
    public var onPickerCreated: ((AVRoutePickerView) -> Void)?

    public init(
        tintColor: UIColor = .white,
        activeTintColor: UIColor = .systemBlue,
        prioritizesVideoDevices: Bool = true,
        onPickerCreated: ((AVRoutePickerView) -> Void)? = nil
    ) {
        self.tintColor = tintColor
        self.activeTintColor = activeTintColor
        self.prioritizesVideoDevices = prioritizesVideoDevices
        self.onPickerCreated = onPickerCreated
    }

    public func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.backgroundColor = .clear
        picker.tintColor = tintColor
        picker.activeTintColor = activeTintColor
        picker.prioritizesVideoDevices = prioritizesVideoDevices
        onPickerCreated?(picker)
        return picker
    }

    public func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = tintColor
        uiView.activeTintColor = activeTintColor
        uiView.prioritizesVideoDevices = prioritizesVideoDevices
        onPickerCreated?(uiView)
    }
}
#elseif os(macOS)
public struct AKAirPlayRoutePickerWrapper: NSViewRepresentable {
    public var onPickerCreated: ((AVRoutePickerView) -> Void)?

    public init(onPickerCreated: ((AVRoutePickerView) -> Void)? = nil) {
        self.onPickerCreated = onPickerCreated
    }

    public func makeNSView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        onPickerCreated?(picker)
        return picker
    }

    public func updateNSView(_ nsView: AVRoutePickerView, context: Context) {
        onPickerCreated?(nsView)
    }
}
#endif

// MARK: - Themed AirPlay Button

/// A themed button for triggering AirPlay routing in player HUDs and sheets, conforming to AKPlayerTheme aesthetics.
public struct AKAirPlayButton: View {
    public var isAudioOnly: Bool
    public var size: CGFloat
    public var palette: AKColorPalette
    public var action: (() -> Void)?

    @State private var localPickerView: AVRoutePickerView?

    public init(
        isAudioOnly: Bool = false,
        size: CGFloat = 44,
        palette: AKColorPalette = .standard,
        action: (() -> Void)? = nil
    ) {
        self.isAudioOnly = isAudioOnly
        self.size = size
        self.palette = palette
        self.action = action
    }

    public var body: some View {
        Button {
            if let action {
                action()
            } else {
                triggerAirPlay()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: size, height: size)
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )

                Image(systemName: isAudioOnly ? "airplayaudio" : "airplayvideo")
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundColor(palette.textPrimary)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(
            pickerRepresentable
                .frame(width: size, height: size)
                .opacity(0.02)
                .allowsHitTesting(false)
        )
    }

    @ViewBuilder
    private var pickerRepresentable: some View {
        #if os(iOS) || os(tvOS)
        AKAirPlayRoutePickerWrapper(
            tintColor: UIColor(palette.textPrimary),
            activeTintColor: UIColor(palette.accent),
            prioritizesVideoDevices: !isAudioOnly,
            onPickerCreated: { picker in
                self.localPickerView = picker
                AKAirPlayLauncher.shared.activePicker = picker
            }
        )
        #elseif os(macOS)
        AKAirPlayRoutePickerWrapper(
            onPickerCreated: { picker in
                self.localPickerView = picker
                AKAirPlayLauncher.shared.activePicker = picker
            }
        )
        #endif
    }

    public func triggerAirPlay() {
        #if os(iOS) || os(tvOS)
        let picker = localPickerView ?? AKAirPlayLauncher.shared.activePicker
        if let picker, let button = findButton(in: picker) {
            button.sendActions(for: .touchUpInside)
            return
        }
        #elseif os(macOS)
        let picker = localPickerView ?? AKAirPlayLauncher.shared.activePicker
        if let picker, let button = findButton(in: picker) {
            button.performClick(nil)
            return
        }
        #endif
    }

    #if os(iOS) || os(tvOS)
    private func findButton(in view: UIView) -> UIButton? {
        if let button = view as? UIButton { return button }
        for subview in view.subviews {
            if let button = findButton(in: subview) { return button }
        }
        return nil
    }
    #elseif os(macOS)
    private func findButton(in view: NSView) -> NSButton? {
        if let button = view as? NSButton { return button }
        for subview in view.subviews {
            if let button = findButton(in: subview) { return button }
        }
        return nil
    }
    #endif
}

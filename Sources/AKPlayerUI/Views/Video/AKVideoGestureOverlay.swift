//
//  AKVideoGestureOverlay.swift
//  AKPlayerUI
//

import SwiftUI

/// Single Responsibility: Detects edge swipes (volume/brightness), double-tap seeks, and pinch zoom.
public struct AKVideoGestureOverlay: View {
    public let configuration: AKGestureConfiguration
    public let typography: AKTypography
    public let onSingleTap: () -> Void
    public let onDoubleTapSeek: (AKSeekDirection) -> Void
    public let onVolumeChanged: (Float) -> Void
    public let onBrightnessChanged: (Float) -> Void

    @State private var activeRippleDirection: AKSeekDirection?
    @State private var rippleOpacity: Double = 0.0

    @State private var currentVolume: Float = 0.5
    @State private var currentBrightness: Float = 0.5
    @State private var isShowingVolumeHUD: Bool = false
    @State private var isShowingBrightnessHUD: Bool = false

    public init(
        configuration: AKGestureConfiguration = AKGestureConfiguration(),
        typography: AKTypography = .standard,
        onSingleTap: @escaping () -> Void,
        onDoubleTapSeek: @escaping (AKSeekDirection) -> Void,
        onVolumeChanged: @escaping (Float) -> Void = { _ in },
        onBrightnessChanged: @escaping (Float) -> Void = { _ in }
    ) {
        self.configuration = configuration
        self.typography = typography
        self.onSingleTap = onSingleTap
        self.onDoubleTapSeek = onDoubleTapSeek
        self.onVolumeChanged = onVolumeChanged
        self.onBrightnessChanged = onBrightnessChanged
    }

    public var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height

            ZStack {
                // Transparent touch capture background
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { location in
                        guard configuration.isDoubleTapToSeekEnabled else { return }
                        let x = location.x
                        if x < w * 0.35 {
                            triggerSeekRipple(direction: .backward)
                        } else if x > w * 0.65 {
                            triggerSeekRipple(direction: .forward)
                        }
                    }
                    .simultaneousGesture(
                        TapGesture(count: 1)
                            .onEnded {
                                onSingleTap()
                            }
                    )
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                let startX = value.startLocation.x
                                let translationY = value.translation.height
                                let delta = Float(-translationY / (h * 0.7))

                                if configuration.isVerticalSwipeBrightnessEnabled && startX < w * 0.4 {
                                    // Left vertical swipe: Brightness
                                    currentBrightness = max(0.0, min(1.0, currentBrightness + delta * 0.05))
                                    isShowingBrightnessHUD = true
                                    onBrightnessChanged(currentBrightness)
                                } else if configuration.isVerticalSwipeVolumeEnabled && startX > w * 0.6 {
                                    // Right vertical swipe: Volume
                                    currentVolume = max(0.0, min(1.0, currentVolume + delta * 0.05))
                                    isShowingVolumeHUD = true
                                    onVolumeChanged(currentVolume)
                                }
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        isShowingBrightnessHUD = false
                                        isShowingVolumeHUD = false
                                    }
                                }
                            }
                    )

                // Left Ripple (-10s Seek Indicator)
                if activeRippleDirection == .backward {
                    HStack {
                        VStack(spacing: 8) {
                            Image(systemName: "gobackward.10")
                                .font(.system(size: 38, weight: .bold))
                            Text("10 seconds")
                                .font(typography.badge)
                        }
                        .foregroundColor(.white)
                        .padding(24)
                        .background(Circle().fill(Color.black.opacity(0.55)))
                        .opacity(rippleOpacity)
                        .scaleEffect(rippleOpacity > 0 ? 1.0 : 0.8)

                        Spacer()
                    }
                    .padding(.leading, 36)
                }

                // Right Ripple (+15s Seek Indicator)
                if activeRippleDirection == .forward {
                    HStack {
                        Spacer()

                        VStack(spacing: 8) {
                            Image(systemName: "goforward.15")
                                .font(.system(size: 38, weight: .bold))
                            Text("15 seconds")
                                .font(typography.badge)
                        }
                        .foregroundColor(.white)
                        .padding(24)
                        .background(Circle().fill(Color.black.opacity(0.55)))
                        .opacity(rippleOpacity)
                        .scaleEffect(rippleOpacity > 0 ? 1.0 : 0.8)
                    }
                    .padding(.trailing, 36)
                }

                // Vertical Floating HUDs
                if isShowingBrightnessHUD {
                    HStack {
                        AKBrightnessSlider(brightness: currentBrightness, isCompact: true, typography: typography)
                            .padding(.leading, 24)
                        Spacer()
                    }
                    .transition(.opacity)
                }

                if isShowingVolumeHUD {
                    HStack {
                        Spacer()
                        AKVolumeSlider(volume: currentVolume, isCompact: true, typography: typography)
                            .padding(.trailing, 24)
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    private func triggerSeekRipple(direction: AKSeekDirection) {
        activeRippleDirection = direction
        onDoubleTapSeek(direction)

        withAnimation(.easeOut(duration: 0.2)) {
            rippleOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                rippleOpacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                activeRippleDirection = nil
            }
        }
    }
}

// MARK: - Previews
#Preview("Gesture Overlay Preview") {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        AKVideoGestureOverlay(
            onSingleTap: {},
            onDoubleTapSeek: { _ in }
        )
    }
}

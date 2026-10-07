//
//  AKVideoGestureOverlay.swift
//  AKPlayerUI
//

import SwiftUI

/// Single Responsibility: Detects edge swipes (system volume/brightness), double-tap seeks, and pinch zoom.
public struct AKVideoGestureOverlay: View {
    public let configuration: AKGestureConfiguration
    public let canSeek: Bool
    public let typography: AKTypography
    public let onSingleTap: () -> Void
    public let onDoubleTapSeek: (AKSeekDirection) -> Void
    public let onVolumeChanged: (Float) -> Void
    public let onBrightnessChanged: (Float) -> Void

    @State private var activeRippleDirection: AKSeekDirection?
    @State private var rippleOpacity: Double = 0.0

    @State private var currentVolume: Float = 0.5
    @State private var currentBrightness: Float = 0.5
    @State private var dragStartVolume: Float? = nil
    @State private var dragStartBrightness: Float? = nil
    @State private var activeVerticalGesture: VerticalGestureType? = nil

    @State private var isShowingVolumeHUD: Bool = false
    @State private var isShowingBrightnessHUD: Bool = false
    @State private var hudDismissTask: Task<Void, Never>? = nil

    private enum VerticalGestureType {
        case brightness
        case volume
    }

    public init(
        configuration: AKGestureConfiguration = AKGestureConfiguration(),
        canSeek: Bool = true,
        typography: AKTypography = .standard,
        onSingleTap: @escaping () -> Void,
        onDoubleTapSeek: @escaping (AKSeekDirection) -> Void,
        onVolumeChanged: @escaping (Float) -> Void = { _ in },
        onBrightnessChanged: @escaping (Float) -> Void = { _ in }
    ) {
        self.configuration = configuration
        self.canSeek = canSeek
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
                        guard configuration.isDoubleTapToSeekEnabled && canSeek else { return }
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

                                // 1. Determine active gesture type when beginning vertical swipe
                                if activeVerticalGesture == nil {
                                    syncSystemValues()
                                    if configuration.isVerticalSwipeBrightnessEnabled && startX < w * 0.4 {
                                        activeVerticalGesture = .brightness
                                        dragStartBrightness = currentBrightness
                                        isShowingBrightnessHUD = true
                                        isShowingVolumeHUD = false
                                    } else if configuration.isVerticalSwipeVolumeEnabled && startX > w * 0.6 {
                                        activeVerticalGesture = .volume
                                        dragStartVolume = currentVolume
                                        isShowingVolumeHUD = true
                                        isShowingBrightnessHUD = false
                                    }
                                    hudDismissTask?.cancel()
                                }

                                // 2. High-speed 1:1 responsive linear tracking across screen height
                                let dragDistance = Float(-translationY / max(1.0, h * 0.65))

                                switch activeVerticalGesture {
                                case .brightness:
                                    guard let startVal = dragStartBrightness else { return }
                                    let newVal = max(0.0, min(1.0, startVal + dragDistance))
                                    currentBrightness = newVal
                                    AKSystemMediaDeviceManager.shared.setBrightness(newVal)
                                    onBrightnessChanged(newVal)

                                case .volume:
                                    guard let startVal = dragStartVolume else { return }
                                    let newVal = max(0.0, min(1.0, startVal + dragDistance))
                                    currentVolume = newVal
                                    AKSystemMediaDeviceManager.shared.setVolume(newVal)
                                    onVolumeChanged(newVal)

                                case .none:
                                    break
                                }
                            }
                            .onEnded { _ in
                                activeVerticalGesture = nil
                                dragStartBrightness = nil
                                dragStartVolume = nil

                                hudDismissTask?.cancel()
                                hudDismissTask = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                                    guard !Task.isCancelled else { return }
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        isShowingBrightnessHUD = false
                                        isShowingVolumeHUD = false
                                    }
                                }
                            }
                    )

                // Left Ripple (-10s Seek Indicator)
                if activeRippleDirection == .backward {
                    HStack {
                        VStack(spacing: AKSpacing.xs) {
                            Image(systemName: "gobackward.10")
                                .font(.system(size: 38, weight: .bold))
                            Text("10 seconds")
                                .font(typography.badge)
                        }
                        .foregroundColor(.white)
                        .padding(AKSpacing.xl)
                        .background(Circle().fill(Color.black.opacity(0.55)))
                        .opacity(rippleOpacity)
                        .scaleEffect(rippleOpacity > 0 ? 1.0 : 0.8)

                        Spacer()
                    }
                    .padding(.leading, AKSpacing.xxl)
                }

                // Right Ripple (+15s Seek Indicator)
                if activeRippleDirection == .forward {
                    HStack {
                        Spacer()

                        VStack(spacing: AKSpacing.xs) {
                            Image(systemName: "goforward.15")
                                .font(.system(size: 38, weight: .bold))
                            Text("15 seconds")
                                .font(typography.badge)
                        }
                        .foregroundColor(.white)
                        .padding(AKSpacing.xl)
                        .background(Circle().fill(Color.black.opacity(0.55)))
                        .opacity(rippleOpacity)
                        .scaleEffect(rippleOpacity > 0 ? 1.0 : 0.8)
                    }
                    .padding(.trailing, AKSpacing.xxl)
                }

                // Vertical Floating HUDs
                if isShowingBrightnessHUD {
                    AKBrightnessSlider(brightness: currentBrightness, isCompact: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                }

                if isShowingVolumeHUD {
                    AKVolumeSlider(volume: currentVolume, isCompact: true, typography: typography)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            syncSystemValues()
        }
    }

    private func syncSystemValues() {
        currentBrightness = AKSystemMediaDeviceManager.shared.currentBrightness
        currentVolume = AKSystemMediaDeviceManager.shared.currentVolume
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

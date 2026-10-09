//
//  AKVideoGestureOverlay.swift
//  AKPlayerUI
//

import SwiftUI
#if os(iOS)
import UIKit
#endif
import AKPlayer

/// Single Responsibility: Detects edge swipes (system volume/brightness), double-tap seeks, press-and-hold 2x speed, and gestures.
public struct AKVideoGestureOverlay: View {
    public let configuration: AKGestureConfiguration
    public let coordinator: AKPlayerCoordinator
    public let isHUDVisible: Bool
    public let canSeek: Bool
    public let canPlayFastForward: Bool
    public let canPlayFastReverse: Bool
    public let typography: AKTypography
    public let theme: AKPlayerTheme
    public let onSingleTap: () -> Void
    public let onDoubleTapSeek: (AKSeekDirection) -> Void
    public let onDoubleTapCenterPlayPause: (() -> Void)?
    public let onVolumeChanged: (Float) -> Void
    public let onBrightnessChanged: (Float) -> Void
    public let onGestureActiveChanged: (Bool) -> Void
    public let onFastPlaybackBegan: (Float) -> Void
    public let onFastPlaybackEnded: () -> Void

    @State private var activeRippleDirection: AKSeekDirection?
    @State private var rippleOpacity: Double = 0.0
    @State private var activeCenterState: AKPlayerState? = nil
    @State private var centerPlayPauseOpacity: Double = 0.0

    @State private var currentVolume: Float = 0.5
    @State private var currentBrightness: Float = 0.5
    @State private var panStartVolume: Float? = nil
    @State private var panStartBrightness: Float? = nil

    @State private var activeFastPlaybackRate: Float? = nil
    @State private var unsupportToastMessage: String? = nil

    @State private var isShowingVolumeHUD: Bool = false
    @State private var isShowingBrightnessHUD: Bool = false
    @State private var hudDismissTask: Task<Void, Never>? = nil

    public init(
        configuration: AKGestureConfiguration = AKGestureConfiguration(),
        coordinator: AKPlayerCoordinator,
        isHUDVisible: Bool = false,
        canSeek: Bool = true,
        canPlayFastForward: Bool = true,
        canPlayFastReverse: Bool = true,
        typography: AKTypography = .standard,
        theme: AKPlayerTheme = .standard,
        onSingleTap: @escaping () -> Void,
        onDoubleTapSeek: @escaping (AKSeekDirection) -> Void,
        onDoubleTapCenterPlayPause: (() -> Void)? = nil,
        onVolumeChanged: @escaping (Float) -> Void = { _ in },
        onBrightnessChanged: @escaping (Float) -> Void = { _ in },
        onGestureActiveChanged: @escaping (Bool) -> Void = { _ in },
        onFastPlaybackBegan: @escaping (Float) -> Void = { _ in },
        onFastPlaybackEnded: @escaping () -> Void = {}
    ) {
        self.configuration = configuration
        self.coordinator = coordinator
        self.isHUDVisible = isHUDVisible
        self.canSeek = canSeek
        self.canPlayFastForward = canPlayFastForward
        self.canPlayFastReverse = canPlayFastReverse
        self.typography = typography
        self.theme = theme
        self.onSingleTap = onSingleTap
        self.onDoubleTapSeek = onDoubleTapSeek
        self.onDoubleTapCenterPlayPause = onDoubleTapCenterPlayPause
        self.onVolumeChanged = onVolumeChanged
        self.onBrightnessChanged = onBrightnessChanged
        self.onGestureActiveChanged = onGestureActiveChanged
        self.onFastPlaybackBegan = onFastPlaybackBegan
        self.onFastPlaybackEnded = onFastPlaybackEnded
    }

    public var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height

            ZStack {
                // MARK: - Visual Guide Zones (For Testing)
                HStack(spacing: 0) {
                    // Left 40% (Blue)
                    ZStack(alignment: .topLeading) {
                        Color.blue.opacity(0.18)
                            .overlay(
                                Rectangle().strokeBorder(Color.blue.opacity(0.35), lineWidth: 1.5)
                            )
                        Text("⏪ Left: Rewind / Brightness")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(AKSpacing.xs)
                    }
                    .frame(width: w * 0.4, height: h)

                    // Center 20%
                    Color.clear
                        .frame(width: w * 0.2, height: h)

                    // Right 40% (Orange)
                    ZStack(alignment: .topTrailing) {
                        Color.orange.opacity(0.18)
                            .overlay(
                                Rectangle().strokeBorder(Color.orange.opacity(0.35), lineWidth: 1.5)
                            )
                        Text("⏩ Right: Fast Forward / Volume")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(AKSpacing.xs)
                    }
                    .frame(width: w * 0.4, height: h)
                }
                .allowsHitTesting(false)

                // MARK: - Touch Capture Layer (Native UIKit Gesture Pipeline)
                #if os(iOS)
                AKTouchCaptureView(
                    onSingleTap: {
                        dismissFloatingSliders()
                        onSingleTap()
                    },
                    onDoubleTap: { location in
                        dismissFloatingSliders()
                        if location.x < w * 0.4 {
                            guard configuration.isDoubleTapToSeekEnabled && canSeek else { return }
                            triggerSeekRipple(direction: .backward)
                        } else if location.x > w * 0.6 {
                            guard configuration.isDoubleTapToSeekEnabled && canSeek else { return }
                            triggerSeekRipple(direction: .forward)
                        } else {
                            guard configuration.isDoubleTapToPlayPauseEnabled else { return }
                            triggerCenterPlayPause()
                        }
                    },
                    onHoldBegan: { location in
                        dismissFloatingSliders()
                        if location.x > w * 0.6 {
                            // Right side: Fast Forward (2.0x)
                            if canPlayFastForward {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    activeFastPlaybackRate = 2.0
                                }
                                onFastPlaybackBegan(2.0)
                                onGestureActiveChanged(true)
                            } else {
                                showUnsupportedToast("Fast forward not supported")
                            }
                        } else if location.x < w * 0.4 {
                            // Left side: Rewind (-2.0x)
                            if canPlayFastReverse {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    activeFastPlaybackRate = -2.0
                                }
                                onFastPlaybackBegan(-2.0)
                                onGestureActiveChanged(true)
                            } else {
                                showUnsupportedToast("Rewind not supported for this media")
                            }
                        }
                    },
                    onHoldEnded: {
                        // 👈 Guaranteed by UIKit touch system the instant finger lifts
                        withAnimation(.easeOut(duration: 0.2)) {
                            activeFastPlaybackRate = nil
                        }
                        onFastPlaybackEnded()
                        onGestureActiveChanged(false)
                    },
                    onPanChanged: { location, translationY in
                        if location.x > w * 0.6 && configuration.isVerticalSwipeVolumeEnabled {
                            // Right side: Volume
                            if panStartVolume == nil {
                                syncSystemValues()
                                panStartVolume = currentVolume
                                hudDismissTask?.cancel()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isShowingBrightnessHUD = false
                                    isShowingVolumeHUD = true
                                }
                                onGestureActiveChanged(true)
                            }
                            guard let start = panStartVolume else { return }
                            let dragDistance = Float(-translationY / max(1.0, h * 0.65))
                            let newVal = max(0.0, min(1.0, start + dragDistance))
                            currentVolume = newVal
                            AKSystemMediaDeviceManager.shared.setVolume(newVal)
                            onVolumeChanged(newVal)

                        } else if location.x < w * 0.4 && configuration.isVerticalSwipeBrightnessEnabled {
                            // Left side: Brightness
                            if panStartBrightness == nil {
                                syncSystemValues()
                                panStartBrightness = currentBrightness
                                hudDismissTask?.cancel()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isShowingVolumeHUD = false
                                    isShowingBrightnessHUD = true
                                }
                                onGestureActiveChanged(true)
                            }
                            guard let start = panStartBrightness else { return }
                            let dragDistance = Float(-translationY / max(1.0, h * 0.65))
                            let newVal = max(0.0, min(1.0, start + dragDistance))
                            currentBrightness = newVal
                            AKSystemMediaDeviceManager.shared.setBrightness(newVal)
                            onBrightnessChanged(newVal)
                        }
                    },
                    onPanEnded: {
                        panStartVolume = nil
                        panStartBrightness = nil
                        onGestureActiveChanged(false)
                        scheduleSliderDismissal()
                    }
                )
                #endif

                // MARK: - Top Fast Playback Indicator Pill
                if let rate = activeFastPlaybackRate {
                    VStack {
                        HStack(spacing: AKSpacing.xs) {
                            Image(systemName: rate > 0 ? "forward.fill" : "backward.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text(rate > 0 ? "2X Speed" : "2X Rewind")
                                .font(typography.badge)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AKSpacing.md)
                        .padding(.vertical, AKSpacing.xs)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.75))
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, AKSpacing.lg)

                        Spacer()
                    }
                    .allowsHitTesting(false)
                }

                // Unsupported Toast Pill
                if let message = unsupportToastMessage {
                    VStack {
                        Text(message)
                            .font(typography.badge)
                            .foregroundColor(.white)
                            .padding(.horizontal, AKSpacing.md)
                            .padding(.vertical, AKSpacing.xs)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.85))
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, AKSpacing.lg)

                        Spacer()
                    }
                    .allowsHitTesting(false)
                }

                // Left Ripple (-10s Seek Indicator with Wave & Rotation)
                if activeRippleDirection == .backward && (coordinator.currentMedia?.seekingThroughMedia.canSeek(to: .offset(-10)) ?? false) {
                    HStack {
                        AKDoubleTapSeekWaveView(direction: .backward, typography: typography)
                            .opacity(rippleOpacity)
                        Spacer()
                    }
                    .padding(.leading, AKSpacing.lg)
                    .allowsHitTesting(false)
                }

                // Right Ripple (+15s Seek Indicator with Wave & Rotation)
                if activeRippleDirection == .forward && (coordinator.currentMedia?.seekingThroughMedia.canSeek(to: .offset(15)) ?? false) {
                    HStack {
                        Spacer()
                        AKDoubleTapSeekWaveView(direction: .forward, typography: typography)
                            .opacity(rippleOpacity)
                    }
                    .padding(.trailing, AKSpacing.lg)
                    .allowsHitTesting(false)
                }

                // Center Ripple (Double-Tap Play/Pause Indicator Following AKPlayPauseButton Condition)
                if let activeState = activeCenterState {
                    AKDoubleTapPlayPauseWaveView(
                        state: activeState,
                        autoPlay: coordinator.autoPlay,
                        theme: theme
                    )
                    .opacity(centerPlayPauseOpacity)
                    .allowsHitTesting(false)
                }

                // Vertical Floating HUDs with smooth cross-fade animation
                if isShowingBrightnessHUD {
                    AKBrightnessSlider(brightness: currentBrightness, isCompact: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.92)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                        .allowsHitTesting(false)
                }

                if isShowingVolumeHUD {
                    AKVolumeSlider(volume: currentVolume, isCompact: true, typography: typography)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.92)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                        .allowsHitTesting(false)
                }
            }
        }
        .onChange(of: isHUDVisible) { _, isVisible in
            if isVisible {
                dismissFloatingSliders()
            }
        }
        .onAppear {
            syncSystemValues()
            AKSystemMediaDeviceManager.shared.onVolumeChanged = { newVolume in
                currentVolume = newVolume
                onVolumeChanged(newVolume)

                // When hardware side volume buttons are pressed, display custom volume slider
                // (Skip showing floating slider if the change was due to a mute/unmute action)
                if panStartVolume == nil && !AKSystemMediaDeviceManager.shared.isMutingOrUnmuting {
                    hudDismissTask?.cancel()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingBrightnessHUD = false
                        isShowingVolumeHUD = true
                    }
                    scheduleSliderDismissal()
                }
            }
        }
        .onDisappear {
            AKSystemMediaDeviceManager.shared.onVolumeChanged = nil
        }
    }

    private func showUnsupportedToast(_ text: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            unsupportToastMessage = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.25)) {
                unsupportToastMessage = nil
            }
        }
    }

    private func scheduleSliderDismissal() {
        hudDismissTask?.cancel()
        hudDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                isShowingBrightnessHUD = false
                isShowingVolumeHUD = false
            }
        }
    }

    private func dismissFloatingSliders() {
        hudDismissTask?.cancel()
        if isShowingBrightnessHUD || isShowingVolumeHUD {
            withAnimation(.easeOut(duration: 0.2)) {
                isShowingBrightnessHUD = false
                isShowingVolumeHUD = false
            }
        }
    }

    private func syncSystemValues() {
        currentBrightness = AKSystemMediaDeviceManager.shared.currentBrightness
        currentVolume = AKSystemMediaDeviceManager.shared.currentVolume
    }

    private func triggerSeekRipple(direction: AKSeekDirection) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        activeRippleDirection = direction
        onDoubleTapSeek(direction)

        withAnimation(.easeOut(duration: 0.15)) {
            rippleOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(.easeOut(duration: 0.25)) {
                rippleOpacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                activeRippleDirection = nil
            }
        }
    }

    private func triggerCenterPlayPause() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        activeCenterState = coordinator.state

        if let onDoubleTapCenterPlayPause {
            onDoubleTapCenterPlayPause()
        } else {
            coordinator.togglePlayPause()
        }

        withAnimation(.easeOut(duration: 0.15)) {
            centerPlayPauseOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeOut(duration: 0.25)) {
                centerPlayPauseOpacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                activeCenterState = nil
            }
        }
    }
}

// MARK: - Native Touch Capture View using iOS Gesture Pipeline
#if os(iOS)
class AKPlayerGestureView: UIView, UIGestureRecognizerDelegate {
    var onSingleTap: (() -> Void)?
    var onDoubleTap: ((CGPoint) -> Void)?
    var onHoldBegan: ((CGPoint) -> Void)?
    var onHoldEnded: (() -> Void)?
    var onPanChanged: ((CGPoint, CGFloat) -> Void)?
    var onPanEnded: (() -> Void)?

    private var longPress: UILongPressGestureRecognizer!
    private var doubleTap: UITapGestureRecognizer!
    private var singleTap: UITapGestureRecognizer!
    private var pan: UIPanGestureRecognizer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
    }

    private func setupGestures() {
        backgroundColor = .clear

        longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.35
        longPress.allowableMovement = 30
        longPress.delegate = self
        addGestureRecognizer(longPress)

        doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        addGestureRecognizer(doubleTap)

        singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        singleTap.delegate = self
        addGestureRecognizer(singleTap)

        pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    @objc private func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            onHoldBegan?(sender.location(in: self))
        case .ended, .cancelled, .failed:
            onHoldEnded?()
        default:
            break
        }
    }

    @objc private func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        onDoubleTap?(sender.location(in: self))
    }

    @objc private func handleSingleTap(_ sender: UITapGestureRecognizer) {
        onSingleTap?()
    }

    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        let loc = sender.location(in: self)
        let trans = sender.translation(in: self)
        switch sender.state {
        case .changed:
            onPanChanged?(loc, trans.y)
        case .ended, .cancelled, .failed:
            onPanEnded?()
        default:
            break
        }
    }
}

struct AKTouchCaptureView: UIViewRepresentable {
    var onSingleTap: () -> Void
    var onDoubleTap: (CGPoint) -> Void
    var onHoldBegan: (CGPoint) -> Void
    var onHoldEnded: () -> Void
    var onPanChanged: (CGPoint, CGFloat) -> Void
    var onPanEnded: () -> Void

    func makeUIView(context: Context) -> AKPlayerGestureView {
        let view = AKPlayerGestureView()
        updateCallbacks(view)
        return view
    }

    func updateUIView(_ uiView: AKPlayerGestureView, context: Context) {
        updateCallbacks(uiView)
    }

    private func updateCallbacks(_ view: AKPlayerGestureView) {
        view.onSingleTap = onSingleTap
        view.onDoubleTap = onDoubleTap
        view.onHoldBegan = onHoldBegan
        view.onHoldEnded = onHoldEnded
        view.onPanChanged = onPanChanged
        view.onPanEnded = onPanEnded
    }
}
#endif


// MARK: - Dynamic Double-Tap Center Play/Pause Wave Component
/// Follows the exact state condition as AKPlayPauseButton:
/// - .failed -> reload icon
/// - .playing -> pause icon
/// - .loading / .buffering (with autoPlay) -> progress spinner
/// - default (.paused, .idle, .stopped, etc.) -> play icon
struct AKDoubleTapPlayPauseWaveView: View {
    let state: AKPlayerState
    let autoPlay: Bool
    let theme: AKPlayerTheme

    @State private var waveScale1: CGFloat = 0.65
    @State private var waveScale2: CGFloat = 0.65
    @State private var waveOpacity1: Double = 0.65
    @State private var waveOpacity2: Double = 0.40
    @State private var iconScale: CGFloat = 0.55
    @State private var iconOpacity: Double = 0.0

    // MARK: - State Icon Helper (Matching AKPlayPauseButton)

    private func iconName(for state: AKPlayerState) -> String {
        switch state {
        case .failed:
            return theme.icons.reload
        case .playing:
            return theme.icons.pause
        default:
            return theme.icons.play
        }
    }

    private var stateLabel: String {
        switch state {
        case .failed:
            return "Retry"
        case .playing:
            return "Pause"
        case .loaded, .buffering, .waitingForNetwork:
            return autoPlay ? "Pause" : "Play"
        case .loading:
            return autoPlay ? "Pause" : "Play"
        default:
            return "Play"
        }
    }

    var body: some View {
        ZStack {
            // Concentric Expanding Kinetic Shockwaves
            ForEach(0..<2, id: \.self) { i in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: CGFloat(2.5 - Double(i) * 0.7)
                    )
                    .frame(width: 90 + CGFloat(i * 24), height: 90 + CGFloat(i * 24))
                    .scaleEffect(i == 0 ? waveScale1 : waveScale2)
                    .opacity(i == 0 ? waveOpacity1 : waveOpacity2)
            }

            // Glassmorphic Glowing Center Core (84pt)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.85),
                            Color.black.opacity(0.62)
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 42
                    )
                )
                .frame(width: 84, height: 84)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.28), lineWidth: 1.2)
                )
                .shadow(color: Color.white.opacity(0.18), radius: 10, x: 0, y: 0)

            // Play / Pause Icon + State Label (Following AKPlayPauseButton condition)
            VStack(spacing: 4) {
                let name = iconName(for: state)
                    Image(systemName: name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(iconScale)
                        .offset(x: name == theme.icons.play ? 2 : 0) // Optical centering for play triangle

                Text(stateLabel)
                    .font(theme.typography.caption1.weight(.bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .opacity(iconOpacity)
        }
        .onAppear {
            // Spring Recoil
            withAnimation(.spring(response: 0.38, dampingFraction: 0.58, blendDuration: 0)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }

            // Expanding Shockwaves
            withAnimation(.easeOut(duration: 0.65)) {
                waveScale1 = 1.35
                waveOpacity1 = 0.0
            }
            withAnimation(.easeOut(duration: 0.75).delay(0.08)) {
                waveScale2 = 1.45
                waveOpacity2 = 0.0
            }
        }
    }
}

// MARK: - Dynamic Double-Tap Wave & Rotating Icon Component (Compact & Outward Sliding)
struct AKDoubleTapSeekWaveView: View {
    let direction: AKSeekDirection
    let typography: AKTypography

    @State private var waveScale1: CGFloat = 0.6
    @State private var waveScale2: CGFloat = 0.6
    @State private var waveScale3: CGFloat = 0.6
    @State private var waveOpacity1: Double = 0.65
    @State private var waveOpacity2: Double = 0.45
    @State private var waveOpacity3: Double = 0.25
    @State private var iconRotation: Double = 0
    @State private var iconScale: CGFloat = 0.6
    @State private var chevronStep: Int = 0
    @State private var horizontalSlide: CGFloat = 0

    var isForward: Bool { direction == .forward }

    var body: some View {
        ZStack {
            // Concentric Expanding Kinetic Shockwaves (Proportionally Compact)
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: isForward ? .leading : .trailing,
                            endPoint: isForward ? .trailing : .leading
                        ),
                        lineWidth: CGFloat(2.5 - Double(i) * 0.5)
                    )
                    .frame(width: 90 + CGFloat(i * 22), height: 90 + CGFloat(i * 22))
                    .scaleEffect(i == 0 ? waveScale1 : (i == 1 ? waveScale2 : waveScale3))
                    .opacity(i == 0 ? waveOpacity1 : (i == 1 ? waveOpacity2 : waveOpacity3))
            }

            // Glassmorphic Glowing Center Core (Compact: 80pt)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.82),
                            Color.black.opacity(0.60)
                        ],
                        center: .center,
                        startRadius: 6,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.28), lineWidth: 1.2)
                )
                .shadow(color: Color.white.opacity(0.18), radius: 8, x: 0, y: 0)

            // Dynamic Rotating Icon + Cascading Ripple Chevrons + Time Label
            VStack(spacing: 3) {
                Image(systemName: isForward ? "goforward.15" : "gobackward.10")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(iconRotation))
                    .scaleEffect(iconScale)

                // Cascading Kinetic Wave Chevrons (>>> or <<<)
                HStack(spacing: 2) {
                    if isForward {
                        Image(systemName: "chevron.right").opacity(chevronStep >= 1 ? 1.0 : 0.25)
                        Image(systemName: "chevron.right").opacity(chevronStep >= 2 ? 1.0 : 0.25)
                        Image(systemName: "chevron.right").opacity(chevronStep >= 3 ? 1.0 : 0.25)
                    } else {
                        Image(systemName: "chevron.left").opacity(chevronStep >= 3 ? 1.0 : 0.25)
                        Image(systemName: "chevron.left").opacity(chevronStep >= 2 ? 1.0 : 0.25)
                        Image(systemName: "chevron.left").opacity(chevronStep >= 1 ? 1.0 : 0.25)
                    }
                }
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.white.opacity(0.9))

                Text(isForward ? "15s" : "10s")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .offset(x: horizontalSlide)
        .onAppear {
            // 1. Kinetic Rotation & Spring Recoil
            iconRotation = isForward ? -65 : 65
            iconScale = 0.55
            withAnimation(.spring(response: 0.42, dampingFraction: 0.55, blendDuration: 0)) {
                iconRotation = 0
                iconScale = 1.0
            }

            // 2. Slide outward towards the side edge
            horizontalSlide = isForward ? -8 : 8
            withAnimation(.easeOut(duration: 0.55)) {
                horizontalSlide = isForward ? 12 : -12
            }

            // 3. Cascading Staggered Expanding Shockwaves
            withAnimation(.easeOut(duration: 0.65)) {
                waveScale1 = 1.30
                waveOpacity1 = 0.0
            }
            withAnimation(.easeOut(duration: 0.75).delay(0.08)) {
                waveScale2 = 1.40
                waveOpacity2 = 0.0
            }
            withAnimation(.easeOut(duration: 0.85).delay(0.16)) {
                waveScale3 = 1.48
                waveOpacity3 = 0.0
            }

            // 4. Sequential Cascading Chevrons Wave
            withAnimation(.easeInOut(duration: 0.12)) { chevronStep = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.12)) { chevronStep = 2 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                withAnimation(.easeInOut(duration: 0.12)) { chevronStep = 3 }
            }
        }
    }
}

// MARK: - Previews
#Preview("Gesture Overlay Preview") {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        AKVideoGestureOverlay(
            coordinator: AKPlayerCoordinator.previewMiniVideoMock,
            onSingleTap: {},
            onDoubleTapSeek: { _ in }
        )
    }
}

//
//  AKVideoPlayerControlsView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Unified interactive controls overlay for video playback.
/// Combines edge gestures, double-tap seek, fast-forward scrub,
/// screen lock management, and the autohiding glass HUD.
public struct AKVideoPlayerControlsView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    @ObservedObject public var uiState: AKPlayerUIState
    @Binding public var isScreenLocked: Bool
    public let theme: AKPlayerTheme
    
    @State private var isHUDVisible: Bool = true
    @State private var hideHUDTask: Task<Void, Never>?
    
    public init(
        coordinator: AKPlayerCoordinator = .shared,
        uiState: AKPlayerUIState? = nil,
        isScreenLocked: Binding<Bool>,
        theme: AKPlayerTheme = .standard
    ) {
        self.coordinator = coordinator
        self.uiState = uiState ?? coordinator.uiState
        self._isScreenLocked = isScreenLocked
        self.theme = theme
    }
    
    public var body: some View {
        ZStack {
            // 1. Gesture Surface or Screen Locked Tap Surface
            if !isScreenLocked {
                AKVideoGestureOverlay(
                    configuration: coordinator.configuration.gestures,
                    coordinator: coordinator,
                    isHUDVisible: isHUDVisible,
                    canSeek: coordinator.capabilities.canSeek,
                    canPlayFastForward: (coordinator.capabilities.canPlayFastForward || (coordinator.currentMedia?.canPlay(at: .custom(2.0)) ?? false) || coordinator.capabilities.canSeek) && !coordinator.adManager.isAdActive,
                    canPlayFastReverse: (coordinator.capabilities.canPlayFastReverse || (coordinator.currentMedia?.canPlay(at: .custom(-2.0)) ?? false)) && !coordinator.adManager.isAdActive,
                    typography: theme.typography,
                    theme: theme,
                    onSingleTap: {
                        toggleHUD()
                    },
                    onDoubleTapSeek: { direction in
                        guard coordinator.capabilities.canSeek else { return }
                        hideHUDTask?.cancel()
                        withAnimation(.easeOut(duration: 0.2)) {
                            isHUDVisible = false
                        }
                        if direction == .backward {
                            coordinator.skipBackward()
                        } else {
                            coordinator.skipForward()
                        }
                    },
                    onDoubleTapCenterPlayPause: {
                        hideHUDTask?.cancel()
                        coordinator.togglePlayPause()
                    },
                    onVolumeChanged: { _ in
                        resetHUDTimer()
                    },
                    onBrightnessChanged: { _ in
                        resetHUDTimer()
                    },
                    onGestureActiveChanged: { isActive in
                        if isActive {
                            hideHUDTask?.cancel()
                            withAnimation(.easeOut(duration: 0.2)) {
                                isHUDVisible = false
                            }
                        }
                    },
                    onFastPlaybackBegan: { targetRate in
                        coordinator.setPlaybackRate(AKPlaybackRate(rate: targetRate))
                    },
                    onFastPlaybackEnded: {
                        coordinator.setPlaybackRate(.normal)
                    }
                )
            } else {
                // Screen is locked: Tap anywhere reveals unlock button
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isHUDVisible.toggle()
                        }
                        if isHUDVisible {
                            resetHUDTimer()
                        }
                    }
            }
            
            // 2. Autohiding Glass HUD Overlays
            if isHUDVisible {
                AKVideoPlayerHUDView(
                    coordinator: coordinator,
                    uiState: uiState,
                    isScreenLocked: $isScreenLocked,
                    theme: theme,
                    onResetHUDTimer: {
                        resetHUDTimer()
                    },
                    onScrubBegan: {
                        hideHUDTask?.cancel()
                    },
                    onScrubChanged: { _ in
                        hideHUDTask?.cancel()
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isScreenLocked)
        .onAppear {
            resetHUDTimer()
        }
    }
    
    // MARK: - HUD Autohide Timer
    
    private func toggleHUD() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isHUDVisible.toggle()
        }
        if isHUDVisible {
            resetHUDTimer()
        } else {
            hideHUDTask?.cancel()
        }
    }
    
    private func resetHUDTimer() {
        hideHUDTask?.cancel()
        hideHUDTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if coordinator.isPlaying && uiState.activeSheet == nil && uiState.activeInlineOverlay == nil {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isHUDVisible = false
                    }
                }
            }
        }
    }
}

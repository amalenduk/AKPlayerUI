//
//  AKVideoPlayerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Flagship Fullscreen Video Player View.
/// Orchestrates the underlying video surface, interactive gestures & autohiding HUD controls,
/// native ad overlays, and auxiliary sheet/drawer presentations.
public struct AKVideoPlayerView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    @ObservedObject public var uiState: AKPlayerUIState
    public let theme: AKPlayerTheme
    
    @State private var isScreenLocked: Bool = false
    
    public init(
        coordinator: AKPlayerCoordinator = .shared,
        uiState: AKPlayerUIState? = nil,
        theme: AKPlayerTheme = .standard
    ) {
        self.coordinator = coordinator
        self.uiState = uiState ?? coordinator.uiState
        self.theme = theme
    }
    
    public var body: some View {
        ZStack {
            // Background Canvas
            Color.black.ignoresSafeArea()
            
            // 1. Video Surface Pipeline
            AKVideoSurfaceView(
                player: coordinator.player,
                aspectRatio: coordinator.aspectRatio
            )
            .ignoresSafeArea()
            
            // 2. Interactive Controls Layer (Edge Gestures + Autohiding Glass HUD + Lock State)
            AKVideoPlayerControlsView(
                coordinator: coordinator,
                uiState: uiState,
                isScreenLocked: $isScreenLocked,
                theme: theme
            )
            
            // 3. Native Interstitial Ad Overlay
            AKAdOverlayView(
                adManager: coordinator.adManager,
                palette: theme.palette
            )
        }
        .akAuxiliaryHost(
            coordinator: coordinator,
            uiState: uiState,
            theme: theme,
            onLockScreen: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isScreenLocked = true
                }
            }
        )
        .environment(\.akPlayerTheme, theme)
    }
}

// MARK: - Previews
#Preview("Fullscreen Video Player") {
    AKVideoPlayerView(coordinator: .previewMock)
}

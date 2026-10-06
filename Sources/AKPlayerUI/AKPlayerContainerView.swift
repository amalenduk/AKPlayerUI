//
//  AKPlayerContainerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Master Presentation Container hosting fluid transitions between `.hidden`, `.miniPlayer`, and `.fullScreen`.
/// Automatically routes between Video and Audio UI layouts based on the active media characteristics.
public struct AKPlayerContainerView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    
    public init(coordinator: AKPlayerCoordinator = .shared) {
        self.coordinator = coordinator
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Fullscreen Player Overlay
            if coordinator.presentationMode == .fullScreen {
                if coordinator.isAudioOnly {
                    AKAudioPlayerView(
                        coordinator: coordinator,
                        theme: coordinator.theme
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity.combined(with: .scale(scale: 0.94))
                    ))
                    .zIndex(2)
                } else {
                    AKVideoPlayerView(
                        coordinator: coordinator,
                        theme: coordinator.theme
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity.combined(with: .scale(scale: 0.94))
                    ))
                    .zIndex(2)
                }
            }
            
            // Docked Mini Player Bar
            if coordinator.presentationMode == .miniPlayer {
                if coordinator.isAudioOnly {
                    AKAudioMiniPlayerView(
                        coordinator: coordinator,
                        theme: coordinator.theme
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, AKSpacing.xs)
                    .zIndex(1)
                } else {
                    AKVideoMiniPlayerView(
                        coordinator: coordinator,
                        onExpand: { coordinator.expand() },
                        onDismiss: { coordinator.dismiss() }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, AKSpacing.xs)
                    .zIndex(1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: coordinator.presentationMode)
    }
}

// MARK: - Previews
#Preview("Container Preview (FullScreen Video)") {
    AKPlayerContainerView(coordinator: .previewMock)
}

#Preview("Container Preview (FullScreen Audio)") {
    AKPlayerContainerView(coordinator: .previewAudioMock)
}

#Preview("Container Preview (MiniPlayer Video)") {
    AKPlayerContainerView(coordinator: .previewMiniVideoMock)
}

#Preview("Container Preview (MiniPlayer Audio)") {
    AKPlayerContainerView(coordinator: .previewMiniAudioMock)
}

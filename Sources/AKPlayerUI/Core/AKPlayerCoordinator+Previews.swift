//
//  AKPlayerCoordinator+Previews.swift
//  AKPlayerUI
//

import SwiftUI
import CoreMedia
import AKPlayer

// MARK: - SwiftUI Preview Helper
extension AKPlayerCoordinator {
    /// Provides a fully populated mock coordinator for SwiftUI Previews.
    public static var previewMock: AKPlayerCoordinator {
        let coordinator = AKPlayerCoordinator()
        coordinator.metadata.title = "Interstellar: Beyond the Horizon"
        coordinator.metadata.artist = "Christopher Nolan • 2024"
        coordinator.currentTime = 1420
        coordinator.duration = 7240
        coordinator.loadedTimeRanges = [CMTimeRange(start: .zero, duration: CMTime(seconds: 2800, preferredTimescale: 600))]
        coordinator.state = .playing
        coordinator.presentationMode = .fullScreen
        coordinator.capabilities = .fullVideo
        coordinator.adManager.markers = [
            AKInterstitialMarker(time: 300, duration: 15, title: "Ad 1"),
            AKInterstitialMarker(time: 1800, duration: 30, title: "Ad 2"),
            AKInterstitialMarker(time: 3600, duration: 15, title: "Ad 3")
        ]
        return coordinator
    }
    
    /// Provides a mock coordinator in active ad lockdown for testing ad overlays.
    public static var previewAdMock: AKPlayerCoordinator {
        let coordinator = previewMock
        coordinator.adManager.startAdPod(
            index: 1,
            total: 2,
            duration: 15,
            skipDelay: 4,
            allowsSkip: true,
            sponsor: "Acme Streaming Service"
        )
        return coordinator
    }
}

extension AKPlayerCoordinator {
    /// Provides a mock coordinator configured for audio playback previews.
    public static var previewAudioMock: AKPlayerCoordinator {
        let coordinator = AKPlayerCoordinator()
        coordinator.isAudioOnly = true
        coordinator.metadata.title = "Starboy (feat. Daft Punk)"
        coordinator.metadata.artist = "The Weeknd • Starboy"
        coordinator.currentTime = 115
        coordinator.duration = 230
        coordinator.loadedTimeRanges = [CMTimeRange(start: .zero, duration: CMTime(seconds: 180, preferredTimescale: 600))]
        coordinator.state = .playing
        coordinator.presentationMode = .fullScreen
        coordinator.capabilities = AKMediaCapabilities(
            canSeek: true,
            canStepForward: false,
            canStepBackward: false,
            canPause: true,
            canPlayFastForward: true,
            canPlayFastReverse: false
        )
        return coordinator
    }
    
    /// Provides a mock coordinator configured with chapter markers.
    public static var previewChapterMock: AKPlayerCoordinator {
        let coordinator = previewMock
        coordinator.chapters = [
            AKChapter(
                id: 1,
                index: 0,
                title: "1. The Dust Bowl & The Secret Base",
                timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 900, preferredTimescale: 600))
            ),
            AKChapter(
                id: 2,
                index: 1,
                title: "2. Launch of the Endurance",
                timeRange: CMTimeRange(start: CMTime(seconds: 900, preferredTimescale: 600), duration: CMTime(seconds: 1200, preferredTimescale: 600))
            ),
            AKChapter(
                id: 3,
                index: 2,
                title: "3. Miller's Water Planet & Massive Wave",
                timeRange: CMTimeRange(start: CMTime(seconds: 2100, preferredTimescale: 600), duration: CMTime(seconds: 1500, preferredTimescale: 600))
            ),
            AKChapter(
                id: 4,
                index: 3,
                title: "4. Gargantua & The Tesseract",
                timeRange: CMTimeRange(start: CMTime(seconds: 3600, preferredTimescale: 600), duration: CMTime(seconds: 3640, preferredTimescale: 600))
            )
        ]
        coordinator.currentTime = 1420
        coordinator.activeChapter = coordinator.chapters[1]
        return coordinator
    }
}

extension AKPlayerCoordinator {
    public static var previewMiniVideoMock: AKPlayerCoordinator {
        let coordinator = previewMock
        coordinator.presentationMode = .miniPlayer
        return coordinator
    }
    
    public static var previewMiniAudioMock: AKPlayerCoordinator {
        let coordinator = previewAudioMock
        coordinator.presentationMode = .miniPlayer
        return coordinator
    }
}

// MARK: - Image + AKPlatformImage Convenience
public extension Image {
    init(platformImage: AKPlatformImage) {
#if os(macOS)
        self.init(nsImage: platformImage)
#else
        self.init(uiImage: platformImage)
#endif
    }
}

//
//  AKPlayerUITests.swift
//  AKPlayerUITests
//

import Testing
import SwiftUI
@testable import AKPlayerUI

struct AKPlayerUITests {
    @Test func testConfigurationDefaults() async throws {
        let config = AKPlayerUIConfiguration.automatic
        #expect(config.playback.defaultPlaybackSpeed == 1.0)
        #expect(config.playback.openDirectlyInFullScreen == true)
        #expect(config.gestures.isDoubleTapToSeekEnabled == true)
        #expect(config.overlayPlacement == .sheet)
        #expect(config.landscapeOverlayPlacement == .sideDrawer)
    }

    @Test @MainActor func testAuxiliaryPresentationAndDismiss() async throws {
        let uiState = AKPlayerUIState()
        uiState.presentSheet(.moreOptions)
        #expect(uiState.activeSheet == .moreOptions)

        // Switch to another sheet directly
        uiState.presentSheet(.playbackSpeed)
        #expect(uiState.activeSheet == .playbackSpeed)

        // Dismiss
        uiState.dismissAuxiliary()
        #expect(uiState.activeSheet == nil)
    }

    @Test @MainActor func testLandscapePlacementRouting() async throws {
        let uiState = AKPlayerUIState(placement: .sheet, landscapePlacement: .sideDrawer)
        #expect(uiState.effectivePlacement() == .sheet)
        #expect(!uiState.isDrawerActive)

        // Switch to landscape
        uiState.updateOrientation(isLandscape: true)
        #expect(uiState.effectivePlacement() == .sideDrawer)

        // Open sheet in landscape -> should activate drawer
        uiState.presentSheet(.moreOptions)
        #expect(uiState.isDrawerActive)
        #expect(uiState.activeInlineOverlay == .moreOptions)
        #expect(uiState.activeSheet == nil)

        // Rotate back to portrait -> should migrate to native sheet
        uiState.updateOrientation(isLandscape: false)
        #expect(uiState.effectivePlacement() == .sheet)
        #expect(!uiState.isDrawerActive)
        #expect(uiState.activeSheet == .moreOptions)
        #expect(uiState.activeInlineOverlay == nil)
    }

    @Test func testEqualizerManagerPresets() async throws {
        let eq = await AKEqualizerManager()
        await eq.applyPreset(.bassBoost)
        let isCustom = await eq.activePreset == .custom
        #expect(!isCustom)
    }

    @Test func testColorPalettePresetsAndBuilder() async throws {
        // Standard
        let standard = AKColorPalette.standard
        #expect(standard.accent == Color(red: 0.15, green: 0.58, blue: 1.0))
        #expect(standard.foregroundPrimary == standard.textPrimary)

        // Apple Music
        let appleMusic = AKColorPalette.appleMusic
        #expect(appleMusic.accent == Color(red: 0.98, green: 0.14, blue: 0.35))
        #expect(appleMusic.progressRailFill == Color.white)
        #expect(appleMusic.playerActionButtons == Color.white)

        // Fluent Builder with overrides
        let customized = standard.with(
            accent: .green,
            surface: .purple
        )
        #expect(customized.accent == .green)
        #expect(customized.surface == .purple)
        #expect(customized.textPrimary == standard.textPrimary)
    }

    @Test func testMaterialTokensPresetsAndGlassMaterials() async throws {
        let standard = AKMaterialTokens.standard
        #expect(standard.blurStyle == .ultraThin)
        #expect(standard.materialStyle == .ultraThin)
        #expect(standard.materialStyle.material != nil)

        let appleMusic = AKMaterialTokens.appleMusic
        #expect(appleMusic.glassBorderWidth == 0.75)
        #expect(appleMusic.ambientBlurRadius == 64.0)
        #expect(appleMusic.shadowRadius == 16.0)

        let flat = AKMaterialTokens.flat
        #expect(flat.materialStyle == .none)
        #expect(flat.materialStyle.material == nil)

        // Builder
        let modified = standard.with(ambientBlurRadius: 90, glassBorderWidth: 2.0)
        #expect(modified.ambientBlurRadius == 90)
        #expect(modified.glassBorderWidth == 2.0)
    }

    @Test func testThemePresetsAndEnvironmentIntegration() async throws {
        let standard = AKPlayerTheme.standard
        #expect(standard.buttonStyle == .glass)

        let appleMusic = AKPlayerTheme.appleMusic
        #expect(appleMusic.palette == AKColorPalette.appleMusic)
        #expect(appleMusic.materials == AKMaterialTokens.appleMusic)
        #expect(appleMusic.buttonStyle == .glass)

        let midnight = AKPlayerTheme.midnight
        #expect(midnight.buttonStyle == .glass)

        let custom = standard.with(buttonStyle: .monochrome)
        #expect(custom.buttonStyle == .monochrome)
    }

    @Test @MainActor func testTransportActionButtonsUnifiedCallbacks() async throws {
        var triggeredAction: String?

        let seekBtn = AKSeekButton(direction: .forward, stepSeconds: 15) {
            triggeredAction = "seek"
        }
        seekBtn.onAction()
        #expect(triggeredAction == "seek")

        let stepBtn = AKFrameStepButton(direction: .backward) {
            triggeredAction = "step"
        }
        stepBtn.onAction()
        #expect(triggeredAction == "step")

        let nextBtn = AKNextTrackButton {
            triggeredAction = "next"
        }
        nextBtn.onAction()
        #expect(triggeredAction == "next")

        let prevBtn = AKPreviousTrackButton {
            triggeredAction = "prev"
        }
        prevBtn.onAction()
        #expect(triggeredAction == "prev")

        let transportBtn = AKTransportButton(action: .custom(icon: "star")) {
            triggeredAction = "custom"
        }
        transportBtn.onAction()
        #expect(triggeredAction == "custom")

        let playPauseBtn = AKPlayPauseButton(state: .playing) {
            triggeredAction = "toggle"
        }
        playPauseBtn.onAction()
        #expect(triggeredAction == "toggle")
    }

    @Test
    @MainActor
    func testSystemMediaDeviceManagerMuteAndCallback() {
        let manager = AKSystemMediaDeviceManager.shared
        var receivedMuted: Bool?
        manager.onMuteChanged = { muted in
            receivedMuted = muted
        }

        manager.setMute(true)
        #expect(manager.isMuted == true)
        #expect(receivedMuted == true)

        manager.setMute(false)
        #expect(manager.isMuted == false)
        #expect(receivedMuted == false)

        manager.setMuted(true)
        #expect(manager.isMuted == true)
        #expect(receivedMuted == true)

        manager.toggleMute()
        #expect(manager.isMuted == false)
        #expect(receivedMuted == false)

        manager.onMuteChanged = nil
    }

    @Test
    @MainActor
    func testEqualizerPersistence() throws {
        let suiteName = "test.equalizer.persistence.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let eq1 = AKEqualizerManager(userDefaults: defaults, persist: true)
        eq1.isEnabled = true
        eq1.applyPreset(.bassBoost)
        eq1.setGain(4.5, forBandAt: 2)
        eq1.preampGain = 3.0

        let eq2 = AKEqualizerManager(userDefaults: defaults, persist: true)
        #expect(eq2.isEnabled == true)
        #expect(eq2.activePreset == .custom)
        #expect(eq2.bands[2].gain == 4.5)
        #expect(eq2.preampGain == 3.0)

        eq2.clearSavedSettings()
        let eq3 = AKEqualizerManager(userDefaults: defaults, persist: true)
        #expect(eq3.isEnabled == false)
        #expect(eq3.activePreset == .flat)
        #expect(eq3.bands[2].gain == 0.0)

        defaults.removePersistentDomain(forName: suiteName)
    }
}

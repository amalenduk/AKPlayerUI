//
//  AKPlayerUITests.swift
//  AKPlayerUITests
//

import Testing
@testable import AKPlayerUI

struct AKPlayerUITests {
    @Test func testConfigurationDefaults() async throws {
        let config = AKPlayerUIConfiguration.automatic
        #expect(config.playback.defaultPlaybackSpeed == 1.0)
        #expect(config.playback.openDirectlyInFullScreen == true)
        #expect(config.gestures.isDoubleTapToSeekEnabled == true)
    }

    @Test func testEqualizerManagerPresets() async throws {
        let eq = await AKEqualizerManager()
        await eq.applyPreset(.bassBoost)
        let isCustom = await eq.activePreset == .custom
        #expect(!isCustom)
    }
}

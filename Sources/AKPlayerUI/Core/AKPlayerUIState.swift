//
//  AKPlayerUIState.swift
//  AKPlayerUI
//

import SwiftUI
import Observation

/// Dedicated UI Presentation State Manager for AKPlayerUI.
///
/// Encapsulates view presentation, modal sheets, and landscape side drawer routing.
@Observable
@MainActor
public final class AKPlayerUIState {
    /// Active placement mode for auxiliary surfaces in portrait orientation (default: .sheet).
    public var overlayPlacement: AKOverlayPlacementMode

    /// Active placement mode for auxiliary surfaces in landscape orientation (default: .sideDrawer).
    public var landscapeOverlayPlacement: AKOverlayPlacementMode

    /// Observed orientation state (true if UI is in landscape).
    public var isLandscape: Bool = false

    /// Currently active modal sheet.
    public var activeSheet: AKPlayerAuxiliarySheet? = nil

    /// Currently active side drawer overlay in landscape.
    public var activeInlineOverlay: AKPlayerAuxiliarySheet? = nil

    public init(
        placement: AKOverlayPlacementMode = .sheet,
        landscapePlacement: AKOverlayPlacementMode = .sideDrawer
    ) {
        self.overlayPlacement = placement
        self.landscapeOverlayPlacement = landscapePlacement
    }

    // MARK: - Presentation State Queries

    /// The effective placement mode based on orientation and media type.
    public func effectivePlacement(isAudioOnly: Bool = false) -> AKOverlayPlacementMode {
        let mode = isLandscape ? landscapeOverlayPlacement : overlayPlacement
        if !isAudioOnly && mode == .inline {
            return .sheet
        }
        return mode
    }

    /// Indicates whether the side drawer panel should be presented.
    public var isDrawerActive: Bool {
        effectivePlacement() == .sideDrawer && activeInlineOverlay != nil
    }

    /// Indicates whether the inline auxiliary split layout should be active (supported for audio).
    public func isInlineActive(isAudioOnly: Bool = false) -> Bool {
        isAudioOnly && effectivePlacement(isAudioOnly: true) == .inline && activeInlineOverlay != nil
    }

    // MARK: - Orientation Lifecycle

    /// Updates the observed orientation state and migrates active surface between sheet and drawer.
    public func updateOrientation(isLandscape: Bool) {
        guard self.isLandscape != isLandscape else { return }
        self.isLandscape = isLandscape

        let targetPlacement = effectivePlacement()
        if let sheet = activeSheet, targetPlacement == .sideDrawer {
            activeSheet = nil
            activeInlineOverlay = sheet
        } else if let drawer = activeInlineOverlay, targetPlacement == .sheet {
            activeInlineOverlay = nil
            activeSheet = drawer
        }
    }

    // MARK: - Navigation & Presentation Actions

    /// Toggles an auxiliary sheet or side drawer.
    public func toggle(_ sheet: AKPlayerAuxiliarySheet, isAudioOnly: Bool = false) {
        if effectivePlacement() == .sideDrawer {
            activeSheet = nil
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                activeInlineOverlay = (activeInlineOverlay == sheet) ? nil : sheet
            }
        } else {
            activeInlineOverlay = nil
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                activeSheet = (activeSheet == sheet) ? nil : sheet
            }
        }
    }

    /// Presents an auxiliary interface (as a sheet or drawer according to current orientation).
    public func presentSheet(_ sheet: AKPlayerAuxiliarySheet, isAudioOnly: Bool = false) {
        toggle(sheet)
    }

    /// Dismisses any active auxiliary sheet or drawer.
    public func dismissAuxiliary() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            activeInlineOverlay = nil
            activeSheet = nil
        }
    }

    /// Dismisses any active sheet.
    public func dismissSheet() {
        dismissAuxiliary()
    }
}

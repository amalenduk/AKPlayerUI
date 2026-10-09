//
//  AKPlayerUIState.swift
//  AKPlayerUI
//

import SwiftUI
import Combine

/// Dedicated UI Presentation State Manager for AKPlayerUI.
///
/// Encapsulates all view navigation, modal sheet presentations, side drawer overlays,
/// and placement routing. Completely decouples UI presentation concerns from the
/// playback coordination engine (`AKPlayerCoordinator`).
@MainActor
public final class AKPlayerUIState: ObservableObject {
    /// Active placement mode for auxiliary surfaces in portrait orientation (default: .sheet).
    @Published public var overlayPlacement: AKOverlayPlacementMode

    /// Active placement mode for auxiliary surfaces in landscape orientation (default: .sideDrawer).
    @Published public var landscapeOverlayPlacement: AKOverlayPlacementMode

    /// Observed orientation state (true if UI is in landscape).
    @Published public var isLandscape: Bool = false

    /// Currently active Apple-style modal sheet.
    @Published public var activeSheet: AKPlayerAuxiliarySheet? = nil

    /// Currently active in-player overlay (inline content canvas or side drawer panel).
    @Published public var activeInlineOverlay: AKPlayerAuxiliarySheet? = nil

    public init(
        placement: AKOverlayPlacementMode = .sheet,
        landscapePlacement: AKOverlayPlacementMode = .sideDrawer
    ) {
        self.overlayPlacement = placement
        self.landscapeOverlayPlacement = landscapePlacement
    }

    // MARK: - Presentation State Queries

    /// The effective placement mode based on orientation (portrait vs landscape) and media type.
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

    /// Indicates whether the inline auxiliary split layout should be active.
    /// Note: Inline layout is only supported for audio playback (since video fills the display).
    public func isInlineActive(isAudioOnly: Bool) -> Bool {
        isAudioOnly && effectivePlacement(isAudioOnly: true) == .inline && activeInlineOverlay != nil
    }

    // MARK: - Orientation Lifecycle

    /// Updates the observed orientation state and smoothly migrates any active overlay if needed.
    public func updateOrientation(isLandscape: Bool) {
        guard self.isLandscape != isLandscape else { return }
        self.isLandscape = isLandscape

        // Smoothly migrate presentation mode if a sheet or drawer is currently displayed
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

    /// Toggles an auxiliary interface (Equalizer, Chapters, Lyrics, Queue, Track Selection)
    /// respecting the currently active presentation mode, orientation, and media type.
    public func toggle(_ sheet: AKPlayerAuxiliarySheet, isAudioOnly: Bool = true) {
        let placement = effectivePlacement(isAudioOnly: isAudioOnly)

        switch placement {
        case .inline:
            activeSheet = nil
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                if self.activeInlineOverlay == sheet {
                    self.activeInlineOverlay = nil
                } else {
                    self.activeInlineOverlay = sheet
                }
            }
        case .sheet:
            activeInlineOverlay = nil
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                if self.activeSheet == sheet {
                    self.activeSheet = nil
                } else {
                    self.activeSheet = sheet
                }
            }
        case .sideDrawer:
            activeSheet = nil
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                if self.activeInlineOverlay == sheet {
                    self.activeInlineOverlay = nil
                } else {
                    self.activeInlineOverlay = sheet
                }
            }
        }
    }

    /// Presents an auxiliary interface as a sheet, or activates drawer/inline according to mode.
    public func presentSheet(_ sheet: AKPlayerAuxiliarySheet, isAudioOnly: Bool = true) {
        toggle(sheet, isAudioOnly: isAudioOnly)
    }

    /// Dismisses any active auxiliary sheet, drawer, or inline overlay.
    public func dismissAuxiliary() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            self.activeInlineOverlay = nil
            self.activeSheet = nil
        }
    }

    /// Dismisses any active sheet.
    public func dismissSheet() {
        dismissAuxiliary()
    }
}

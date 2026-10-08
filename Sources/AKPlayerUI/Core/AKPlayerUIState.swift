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
    /// Active placement mode for auxiliary surfaces (Inline, Sheet, Side Drawer).
    @Published public var overlayPlacement: AKOverlayPlacementMode

    /// Currently active Apple-style modal sheet.
    @Published public var activeSheet: AKPlayerAuxiliarySheet? = nil

    /// Currently active in-player overlay (inline content canvas or side drawer panel).
    @Published public var activeInlineOverlay: AKPlayerAuxiliarySheet? = nil

    public init(placement: AKOverlayPlacementMode = .sideDrawer) {
        self.overlayPlacement = placement
    }

    // MARK: - Presentation State Queries

    /// Indicates whether the side drawer panel should be presented.
    public var isDrawerActive: Bool {
        overlayPlacement == .sideDrawer && activeInlineOverlay != nil
    }

    /// Indicates whether the inline auxiliary split layout should be active.
    /// Note: Inline layout is only supported for audio playback (since video fills the display).
    public func isInlineActive(isAudioOnly: Bool) -> Bool {
        isAudioOnly && overlayPlacement == .inline && activeInlineOverlay != nil
    }

    // MARK: - Navigation & Presentation Actions

    /// Toggles an auxiliary interface (Equalizer, Chapters, Lyrics, Queue, Track Selection)
    /// respecting the currently active presentation mode and media type.
    public func toggle(_ sheet: AKPlayerAuxiliarySheet, isAudioOnly: Bool = true) {
        // Video player does not have an inline split layout; fallback .inline to .sheet
        let effectivePlacement: AKOverlayPlacementMode = (!isAudioOnly && overlayPlacement == .inline) ? .sheet : overlayPlacement

        switch effectivePlacement {
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

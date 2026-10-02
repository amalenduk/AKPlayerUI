//
//  AKOverlayPlacementMode.swift
//  AKPlayerUI
//

import Foundation

/// Defines how auxiliary player interfaces (Lyrics, Chapters, Queue, Equalizer)
/// are presented relative to the active playback surface.
public enum AKOverlayPlacementMode: String, CaseIterable, Identifiable, Sendable {
    /// In-player split: The hero view smoothly scrolls/collapses up into a sticky top
    /// playback control bar, and the auxiliary content fills the lower player canvas.
    case inline = "Inline"

    /// Bottom sheet: Presents an Apple-style interactive modal sheet with medium and large detents.
    case sheet = "Sheet"

    /// Side drawer: Slides in an elevated frosted glass panel over the playback canvas.
    case sideDrawer = "Side Drawer"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .inline:     return "rectangle.split.1x2"
        case .sheet:      return "rectangle.portrait.and.arrow.forward"
        case .sideDrawer: return "sidebar.trailing"
        }
    }

    public var description: String {
        switch self {
        case .inline:     return "Embedded in-player split view with top playback bar"
        case .sheet:      return "Modal bottom sheet with custom detents"
        case .sideDrawer: return "Slide-in frosted side drawer panel"
        }
    }
}

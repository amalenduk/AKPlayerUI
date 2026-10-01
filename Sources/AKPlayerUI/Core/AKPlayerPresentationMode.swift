//
//  AKPlayerPresentationMode.swift
//  AKPlayerUI
//

import Foundation

/// Defines how the player UI is presented in the host application.
public enum AKPlayerPresentationMode: String, CaseIterable, Sendable {
    /// The player is hidden and inactive.
    case hidden

    /// The player is collapsed into a docked/floating mini player bar.
    case miniPlayer

    /// The player occupies the full screen surface with rich glass HUD controls.
    case fullScreen

    public var isPresented: Bool {
        self != .hidden
    }

    public var isFullScreen: Bool {
        self == .fullScreen
    }

    public var isMiniPlayer: Bool {
        self == .miniPlayer
    }
}

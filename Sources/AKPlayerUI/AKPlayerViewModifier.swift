//
//  AKPlayerViewModifier.swift
//  AKPlayerUI
//

import SwiftUI

public struct AKPlayerOverlayModifier: ViewModifier {
    @ObservedObject public var coordinator: AKPlayerCoordinator

    public init(coordinator: AKPlayerCoordinator = .shared) {
        self.coordinator = coordinator
    }

    public func body(content: Content) -> some View {
        ZStack {
            content

            AKPlayerContainerView(coordinator: coordinator)
        }
    }
}

public extension View {
    /// Attaches the AKPlayer presentation container to the root view hierarchy.
    /// Calling `AKPlayerUI.load(...)` from anywhere in the application will automatically
    /// present the player over this view without requiring navigation boilerplate.
    func akPlayer(coordinator: AKPlayerCoordinator = .shared) -> some View {
        modifier(AKPlayerOverlayModifier(coordinator: coordinator))
    }
}

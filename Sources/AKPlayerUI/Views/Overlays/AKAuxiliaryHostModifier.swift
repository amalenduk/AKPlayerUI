//
//  AKAuxiliaryHostModifier.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// ViewModifier hosting auxiliary surfaces (modal sheets and side-drawer overlays).
public struct AKAuxiliaryHostModifier: ViewModifier {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    @ObservedObject public var uiState: AKPlayerUIState
    public let theme: AKPlayerTheme
    public var onLockScreen: (() -> Void)?

    public init(
        coordinator: AKPlayerCoordinator,
        uiState: AKPlayerUIState,
        theme: AKPlayerTheme,
        onLockScreen: (() -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.uiState = uiState
        self.theme = theme
        self.onLockScreen = onLockScreen
    }

    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    let isLandscape = geo.size.width > geo.size.height
                    Color.clear
                        .task(id: isLandscape) {
                            uiState.updateOrientation(isLandscape: isLandscape)
                        }
                }
            )
            // 1. Side Drawer Mode (Landscape)
            .overlay {
                if uiState.isDrawerActive, let activeOverlay = uiState.activeInlineOverlay {
                    GeometryReader { geo in
                        let isLandscape = geo.size.width > geo.size.height
                        ZStack(alignment: .trailing) {
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    coordinator.dismissAuxiliary()
                                }
                                .transition(.opacity)

                            HStack(spacing: 0) {
                                Spacer()

                                sheetView(for: activeOverlay, placement: .sideDrawer)
                                    .environment(\.akPlayerTheme, theme)
                                    .frame(width: min(geo.size.width * 0.88, isLandscape ? 400 : 380))
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .ignoresSafeArea(edges: isLandscape ? .all : [])
                    }
                    .transition(.move(edge: .trailing))
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: uiState.activeInlineOverlay)
            // 2. Native Sheet Presentation (Portrait)
            .sheet(item: $uiState.activeSheet) { sheet in
                sheetView(for: sheet, placement: .sheet)
                    .environment(\.akPlayerTheme, theme)
                    .presentationDetents(presentationDetents(for: sheet))
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color(red: 0.11, green: 0.11, blue: 0.15).opacity(0.96))
            }
    }

    // MARK: - Standardized Auxiliary Container
    @ViewBuilder
    private func sheetView(
        for sheet: AKPlayerAuxiliarySheet,
        placement: AKOverlayPlacementMode = .sheet
    ) -> some View {
        AKAuxiliaryContainerView(
            title: sheet.title,
            placementMode: placement,
            onDismiss: { uiState.dismissAuxiliary() },
            content: {
                sheetContent(for: sheet, placement: placement)
            }
        )
    }

    @ViewBuilder
    private func sheetContent(for sheet: AKPlayerAuxiliarySheet, placement: AKOverlayPlacementMode) -> some View {
        switch sheet {
        case .playbackSpeed:
            AKPlaybackSpeedSheet(coordinator: coordinator)
        case .moreOptions:
            AKMoreOptionsSheet(
                coordinator: coordinator,
                onSelectAction: { targetSheet in
                    uiState.presentSheet(targetSheet)
                },
                onLockScreen: onLockScreen
            )
        case .equalizer:
            AKEqualizerView(equalizer: coordinator.equalizer)
        case .chapters:
            AKChapterSheet(coordinator: coordinator)
        case .lyrics:
            AKLyricsView(coordinator: coordinator)
        case .queue:
            AKQueueSheet(coordinator: coordinator)
        case .audioTracks:
            AKTrackSelectorSheet(trackType: .audio, coordinator: coordinator)
        case .subtitleTracks, .trackSelection:
            AKTrackSelectorSheet(trackType: .subtitle, coordinator: coordinator)
        case .details:
            AKMediaDetailsView(coordinator: coordinator)
        }
    }

    // MARK: - Presentation Detents
    private func presentationDetents(for sheet: AKPlayerAuxiliarySheet) -> Set<PresentationDetent> {
        switch sheet {
        case .playbackSpeed:
            return [.height(310)]
        case .moreOptions:
            return [.medium, .large]
        case .audioTracks, .subtitleTracks, .trackSelection, .equalizer, .chapters, .queue, .lyrics, .details:
            return [.fraction(0.68), .large]
        }
    }
}

public extension View {
    /// Hosts auxiliary sheets and side-drawer overlays for AKPlayerUI.
    func akAuxiliaryHost(
        coordinator: AKPlayerCoordinator,
        uiState: AKPlayerUIState,
        theme: AKPlayerTheme,
        onLockScreen: (() -> Void)? = nil
    ) -> some View {
        modifier(AKAuxiliaryHostModifier(
            coordinator: coordinator,
            uiState: uiState,
            theme: theme,
            onLockScreen: onLockScreen
        ))
    }
}

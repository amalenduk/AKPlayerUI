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
            // 1. Side Drawer Mode: Slide-in Floating Frosted Glass Panel
            .overlay {
                if uiState.isDrawerActive, let activeOverlay = uiState.activeInlineOverlay {
                    GeometryReader { geo in
                        let isLandscape = geo.size.width > geo.size.height
                        ZStack(alignment: .trailing) {
                            // Dimmed Backdrop
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    coordinator.dismissAuxiliary()
                                }
                                .transition(.opacity)

                            // Trailing Drawer Panel (Ignores safe area ONLY in landscape)
                            HStack(spacing: 0) {
                                Spacer()

                                sheetView(for: activeOverlay, placement: .sideDrawer)
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
            // 2. Native Sheet Presentation
            .sheet(item: $uiState.activeSheet) { sheet in
                sheetView(for: sheet, placement: .sheet)
                    .presentationDetents(presentationDetents(for: sheet))
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color(red: 0.11, green: 0.11, blue: 0.15).opacity(0.96))
            }
    }

    // MARK: - Auxiliary Sheet Builder
    @ViewBuilder
    private func sheetView(for sheet: AKPlayerAuxiliarySheet, placement: AKOverlayPlacementMode = .sheet) -> some View {
        switch sheet {
        case .playbackSpeed:
            AKPlaybackSpeedSheet(
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .moreOptions:
            AKMoreOptionsSheet(
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onSelectAction: { targetSheet in
                    uiState.presentSheet(targetSheet, isAudioOnly: coordinator.isAudioOnly)
                },
                onLockScreen: {
                    onLockScreen?()
                },
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .equalizer:
            AKEqualizerView(
                equalizer: coordinator.equalizer,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                title: "10-Band Graphic Equalizer",
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .chapters:
            AKChapterSheet(
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .lyrics:
            AKLyricsView(
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .queue:
            AKQueueSheet(
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .audioTracks:
            AKTrackSelectorSheet(
                trackType: .audio,
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .subtitleTracks, .trackSelection:
            AKTrackSelectorSheet(
                trackType: .subtitle,
                coordinator: coordinator,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                onDismiss: { uiState.dismissAuxiliary() }
            )
        case .details:
            AKEqualizerView(
                equalizer: coordinator.equalizer,
                palette: theme.palette,
                typography: theme.typography,
                placementMode: placement,
                title: "Media Details",
                onDismiss: { uiState.dismissAuxiliary() }
            )
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

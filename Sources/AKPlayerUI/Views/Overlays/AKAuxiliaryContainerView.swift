//
//  AKAuxiliaryContainerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Unified base container providing consistent aesthetics, typography, padding,
/// and header controls across all auxiliary surfaces (Equalizer, Lyrics, Chapters, Queue, Track Selection).
/// Guarantees:
/// - Exactly ONE header across all presentation modes.
/// - Exactly ONE title text in the header.
/// - Exactly ONE close button (or none in inline mode).
/// - ZERO duplicate drag handles (native sheet indicator handles it for sheets, none in drawers).
/// - Edge-to-edge safe area handling for `.sideDrawer`.
public struct AKAuxiliaryContainerView<Content: View>: View {
    public let title: String
    public let placementMode: AKOverlayPlacementMode
    public let onDismiss: (() -> Void)?
    public let content: Content
    
    @Environment(\.akPlayerTheme) private var theme
    
    public init(
        badge: String = "",
        title: String,
        placementMode: AKOverlayPlacementMode = .sheet,
        onBack: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.placementMode = placementMode
        self.onDismiss = onDismiss
        self.content = content()
    }
    
    public var body: some View {
        switch placementMode {
        case .sheet:
            sheetLayout
        case .sideDrawer:
            drawerLayout
        case .inline:
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Sheet Layout
    private var sheetLayout: some View {
        VStack(spacing: AKSpacing.zero) {
            headerBar(isDrawer: false)
                .padding(.horizontal, AKSpacing.lg)
                .padding(.top, AKSpacing.lg)
                .padding(.bottom, AKSpacing.sm)
            
            Divider()
                .background(theme.palette.glassBorder.opacity(0.4))
            
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(theme.palette.surface)
    }
    
    // MARK: - Side Drawer Layout
    private var drawerLayout: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            VStack(spacing: AKSpacing.zero) {
                headerBar(isDrawer: true)
                    .padding(.horizontal, AKSpacing.lg)
                    .padding(.top, AKSpacing.md)
                    .padding(.bottom, AKSpacing.sm)
                    .safeAreaPadding(isLandscape ? [.top, .trailing] : [])
                
                Divider()
                    .background(theme.palette.glassBorder.opacity(0.4))
                
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaPadding(isLandscape ? [.bottom, .trailing] : [])
                    .padding(.bottom, AKSpacing.md)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.palette.surface)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 24,
                    bottomTrailingRadius: isLandscape ? 0 : 24,
                    topTrailingRadius: isLandscape ? 0 : 24,
                    style: .continuous
                )
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 24,
                    bottomTrailingRadius: isLandscape ? 0 : 24,
                    topTrailingRadius: isLandscape ? 0 : 24,
                    style: .continuous
                )
                .stroke(theme.palette.glassBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.55), radius: 28, x: -10, y: 0)
        }
    }
    
    // MARK: - Standardized Header Bar
    private func headerBar(isDrawer: Bool) -> some View {
        HStack(alignment: .center, spacing: AKSpacing.sm) {
            Text(title)
                .font(theme.typography.headline)
                .foregroundColor(theme.palette.foregroundPrimary)
                .lineLimit(1)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(theme.palette.foregroundPrimary.opacity(0.85))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

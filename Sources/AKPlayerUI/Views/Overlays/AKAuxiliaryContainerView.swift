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
/// - Exactly ONE close button (or none in inline mode).
/// - ZERO duplicate drag handles (native sheet indicator handles it for sheets, none in drawers/inline).
/// - Edge-to-edge safe area handling for `.sideDrawer` (completely eliminating the top/bottom gap).
public struct AKAuxiliaryContainerView<HeaderTrailing: View, Content: View>: View {
    public let badge: String
    public let title: String
    public let subtitle: String?
    public let placementMode: AKOverlayPlacementMode
    public let palette: AKColorPalette
    public let typography: AKTypography
    public let onDismiss: (() -> Void)?
    public let headerTrailing: HeaderTrailing
    public let content: Content

    public init(
        badge: String,
        title: String,
        subtitle: String? = nil,
        placementMode: AKOverlayPlacementMode = .sheet,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder headerTrailing: () -> HeaderTrailing = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.badge = badge
        self.title = title
        self.subtitle = subtitle
        self.placementMode = placementMode
        self.palette = palette
        self.typography = typography
        self.onDismiss = onDismiss
        self.headerTrailing = headerTrailing()
        self.content = content()
    }

    public var body: some View {
        switch placementMode {
        case .sheet:
            sheetLayout
        case .sideDrawer:
            drawerLayout
        case .inline:
            inlineLayout
        }
    }

    // MARK: - Sheet Layout
    // Native SwiftUI .presentationDragIndicator(.visible) is active,
    // so we give comfortable top clearance without drawing redundant capsules.
    private var sheetLayout: some View {
        VStack(spacing: AKSpacing.zero) {
            headerBar(isDrawer: false)
                .padding(.horizontal, AKSpacing.lg)
                .padding(.top, AKSpacing.lg)
                .padding(.bottom, AKSpacing.sm)

            Divider()
                .background(Color.white.opacity(0.08))

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            Color(red: 0.11, green: 0.11, blue: 0.15).opacity(0.98)
        )
    }

    // MARK: - Side Drawer Layout
    // Floating elevated panel restricted to safe area height (non-full-height card)
    private var drawerLayout: some View {
        VStack(spacing: AKSpacing.zero) {
            headerBar(isDrawer: true)
                .padding(.horizontal, AKSpacing.lg)
                .padding(.top, AKSpacing.md)
                .padding(.bottom, AKSpacing.sm)

            Divider()
                .background(Color.white.opacity(0.08))

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, AKSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(red: 0.11, green: 0.11, blue: 0.15).opacity(0.97)
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.55), radius: 28, x: -10, y: 0)
    }

    // MARK: - Inline Layout
    // Displayed below the sticky top playback bar. No redundant header or close button.
    private var inlineLayout: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Standardized Header Bar
    private func headerBar(isDrawer: Bool) -> some View {
        HStack(alignment: .center, spacing: AKSpacing.sm) {
            VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
                Text(badge.uppercased())
                    .font(typography.badgeSmall)
                    .foregroundColor(palette.accent)
                    .tracking(1.4)

                Text(title)
                    .font(typography.headline)
                    .foregroundColor(palette.foregroundPrimary)
                    .lineLimit(1)

                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(typography.caption1)
                        .foregroundColor(palette.foregroundSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            headerTrailing

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.foregroundPrimary.opacity(0.85))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

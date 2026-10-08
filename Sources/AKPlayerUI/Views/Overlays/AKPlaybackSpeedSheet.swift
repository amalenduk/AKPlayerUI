//
//  AKPlaybackSpeedSheet.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Interactive sheet enabling fine-grained playback speed adjustment via slider, steppers, and preset pills.
/// Standardized inside AKAuxiliaryContainerView across sheet, drawer, and inline presentation modes.
public struct AKPlaybackSpeedSheet: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public var palette: AKColorPalette
    public var typography: AKTypography
    public var placementMode: AKOverlayPlacementMode
    public var onDismiss: (() -> Void)?

    @State private var currentRate: Float = 1.0

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard,
        placementMode: AKOverlayPlacementMode = .sheet,
        onDismiss: (() -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.palette = palette
        self.typography = typography
        self.placementMode = placementMode
        self.onDismiss = onDismiss
        _currentRate = State(initialValue: coordinator.playbackRate)
    }

    public var body: some View {
        AKAuxiliaryContainerView(
            badge: "Speed Control",
            title: "Playback Speed",
            placementMode: placementMode,
            palette: palette,
            typography: typography,
            onDismiss: onDismiss,
            content: {
                VStack(spacing: AKSpacing.lg) {
                    // Large Rate Display
                    VStack(spacing: AKSpacing.xxxs) {
                        Text(Self.format(rate: currentRate))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(palette.textPrimary)
                        
                        Text(rateLabel(for: currentRate))
                            .font(typography.caption1)
                            .foregroundColor(palette.textSecondary)
                    }
                    .padding(.top, AKSpacing.xs)

                    // Continuous Slider with Steppers
                    HStack(spacing: AKSpacing.md) {
                        // Decrement Button (-)
                        Button(action: {
                            adjustRate(by: -0.05)
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                                .frame(width: 38, height: 38)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        // Slider Track
                        Slider(
                            value: Binding(
                                get: { Double(currentRate) },
                                set: { newValue in
                                    let rounded = round(Float(newValue) * 100) / 100
                                    currentRate = rounded
                                    applyRate(rounded)
                                }
                            ),
                            in: 0.25...2.0,
                            step: 0.05
                        )
                        .tint(palette.accent)

                        // Increment Button (+)
                        Button(action: {
                            adjustRate(by: 0.05)
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                                .frame(width: 38, height: 38)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AKSpacing.lg)

                    // Quick Preset Pills (using AKPlaybackRate.allCases)
                    VStack(alignment: .leading, spacing: AKSpacing.xs) {
                        Text("PRESETS")
                            .font(typography.badgeSmall)
                            .foregroundColor(palette.textSecondary.opacity(0.7))
                            .padding(.horizontal, AKSpacing.lg)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AKSpacing.xs) {
                                ForEach(AKPlaybackRate.allCases, id: \.self) { rateCase in
                                    let rateValue = rateCase.rate
                                    let isSelected = abs(currentRate - rateValue) < 0.01
                                    Button(action: {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                            currentRate = rateValue
                                            applyRate(rateValue)
                                        }
                                    }) {
                                        Text(Self.format(rate: rateValue))
                                            .font(typography.button)
                                            .foregroundColor(isSelected ? palette.textPrimary : palette.textSecondary)
                                            .padding(.horizontal, AKSpacing.md)
                                            .padding(.vertical, AKSpacing.sm)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(isSelected ? palette.accent : Color.white.opacity(0.08))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, AKSpacing.lg)
                        }
                    }
                    .padding(.bottom, AKSpacing.lg)
                }
            }
        )
        .onAppear {
            currentRate = coordinator.playbackRate
        }
    }

    // MARK: - Helpers

    public static func format(rate: Float) -> String {
        let safeRate = rate > 0 ? rate : 1.0
        if safeRate.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(safeRate))x"
        } else if (safeRate * 10).truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.1fx", safeRate)
        } else {
            return String(format: "%.2fx", safeRate)
        }
    }

    private func adjustRate(by delta: Float) {
        let updated = min(max(round((currentRate + delta) * 100) / 100, 0.25), 2.0)
        currentRate = updated
        applyRate(updated)
    }

    private func applyRate(_ rate: Float) {
        let akRate = AKPlaybackRate(rate: rate)
        coordinator.setPlaybackRate(akRate)
    }

    private func rateLabel(for rate: Float) -> String {
        if abs(rate - 1.0) < 0.01 {
            return "Normal Speed"
        } else if rate < 1.0 {
            return "Slower"
        } else {
            return "Faster"
        }
    }
}

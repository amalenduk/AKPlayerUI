//
//  AKBrightnessSlider.swift
//  AKPlayerUI
//

import SwiftUI

/// Single Responsibility: Displays tactile vertical brightness slider or floating HUD pill.
public struct AKBrightnessSlider: View {
    public let brightness: Float // 0.0 ... 1.0
    public let isCompact: Bool
    public let typography: AKTypography
    public let onBrightnessChanged: ((Float) -> Void)?

    public init(
        brightness: Float,
        isCompact: Bool = false,
        typography: AKTypography = .standard,
        onBrightnessChanged: ((Float) -> Void)? = nil
    ) {
        self.brightness = max(0.0, min(1.0, brightness))
        self.isCompact = isCompact
        self.typography = typography
        self.onBrightnessChanged = onBrightnessChanged
    }

    private var brightnessIcon: String {
        if brightness < 0.35 {
            return "sun.min.fill"
        } else {
            return "sun.max.fill"
        }
    }

    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: brightnessIcon)
                .font(.system(size: isCompact ? 14 : 18, weight: .semibold))
                .foregroundColor(.yellow)

            GeometryReader { geo in
                let h = geo.size.height
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: isCompact ? 6 : 8)

                    Capsule()
                        .fill(Color.yellow)
                        .frame(width: isCompact ? 6 : 8, height: max(0, h * CGFloat(brightness)))
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: isCompact ? 100 : 140)

            Text("\(Int(brightness * 100))%")
                .font(typography.badgeSmall)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, isCompact ? 8 : 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Previews
#Preview("Brightness Slider") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 30) {
            AKBrightnessSlider(brightness: 0.2)
            AKBrightnessSlider(brightness: 0.6)
            AKBrightnessSlider(brightness: 1.0)
        }
    }
}

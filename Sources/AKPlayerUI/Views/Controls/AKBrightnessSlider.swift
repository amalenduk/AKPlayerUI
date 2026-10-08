//
//  AKBrightnessSlider.swift
//  AKPlayerUI
//

import SwiftUI

/// Single Responsibility: Displays tactile vertical brightness slider or floating HUD pill.
public struct AKBrightnessSlider: View {
    public let brightness: Float // 0.0 ... 1.0
    public let isCompact: Bool
    public let onBrightnessChanged: ((Float) -> Void)?
    
    @Environment(\.akPlayerTheme) private var theme
    
    public init(
        brightness: Float,
        isCompact: Bool = false,
        onBrightnessChanged: ((Float) -> Void)? = nil
    ) {
        self.brightness = max(0.0, min(1.0, brightness))
        self.isCompact = isCompact
        self.onBrightnessChanged = onBrightnessChanged
    }
    
    private var brightnessIcon: String {
        if brightness < 0.35 {
            return theme.icons.brightnessMin
        } else {
            return theme.icons.brightnessMax
        }
    }
    
    public var body: some View {
        VStack(spacing: AKSpacing.xs) {
            Image(systemName: brightnessIcon)
                .font(.system(size: isCompact ? 14 : 18, weight: .semibold))
                .foregroundColor(theme.palette.accent)
            
            GeometryReader { geo in
                let h = geo.size.height
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: isCompact ? 6 : 8)
                    
                    Capsule()
                        .fill(theme.palette.accent)
                        .frame(width: isCompact ? 6 : 8, height: max(0, h * CGFloat(brightness)))
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: isCompact ? 100 : 140)
            
            Text("\(Int(brightness * 100))%")
                .font(theme.typography.badgeSmall)
                .foregroundColor(theme.palette.accent.opacity(0.8))
        }
        .frame(width: isCompact ? 100 : 140)
        .padding(.vertical, AKSpacing.sm)
        .padding(.horizontal, isCompact ? AKSpacing.xs : AKSpacing.sm)
        .background(
            ZStack {
                if let mat = theme.materials.materialStyle.material {
                    RoundedRectangle(cornerRadius: theme.materials.controlCornerRadius)
                        .fill(mat)
                }
                RoundedRectangle(cornerRadius: theme.materials.controlCornerRadius)
                    .fill(theme.palette.hudBackground)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.materials.controlCornerRadius)
                .stroke(
                    theme.palette.glassBorder.opacity(theme.materials.glassBorderOpacity),
                    lineWidth: theme.materials.glassBorderWidth
                )
        )
        .shadow(
            color: Color.black.opacity(theme.materials.shadowOpacity),
            radius: theme.materials.shadowRadius,
            x: 0,
            y: theme.materials.shadowY
        )
    }
}

// MARK: - Previews
#Preview("Brightness Slider") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: AKSpacing.xxl) {
            AKBrightnessSlider(brightness: 0.2)
            AKBrightnessSlider(brightness: 0.6)
            AKBrightnessSlider(brightness: 1.0, isCompact: true)
        }
    }
}

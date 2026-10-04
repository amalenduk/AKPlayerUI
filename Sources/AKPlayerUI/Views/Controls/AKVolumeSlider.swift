//
//  AKVolumeSlider.swift
//  AKPlayerUI
//

import SwiftUI

/// Single Responsibility: Displays tactile vertical volume slider or floating HUD pill.
public struct AKVolumeSlider: View {
    public let volume: Float // 0.0 ... 1.0
    public let isCompact: Bool
    public let onVolumeChanged: ((Float) -> Void)?
    
    @Environment(\.akPlayerTheme) private var theme
    
    public init(
        volume: Float,
        isCompact: Bool = false,
        typography: AKTypography = .standard,
        onVolumeChanged: ((Float) -> Void)? = nil
    ) {
        self.volume = max(0.0, min(1.0, volume))
        self.isCompact = isCompact
        self.onVolumeChanged = onVolumeChanged
    }
    
    private var volumeIcon: String {
        if volume <= 0.01 {
            return theme.icons.volumeMute
        } else if volume < 0.35 {
            return theme.icons.volumeLow
        } else if volume < 0.7 {
            return theme.icons.volumeMid
        } else {
            return theme.icons.volumeHigh
        }
    }
    
    public var body: some View {
        VStack(spacing: AKSpacing.xs) {
            Image(systemName: volumeIcon)
                .font(.system(size: isCompact ? 14 : 18, weight: .semibold))
                .foregroundColor(theme.palette.accent)
            
            GeometryReader { geo in
                let h = geo.size.height
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: isCompact ? 6 : 8)
                    
                    Capsule()
                        .fill(theme.palette.playerActionButtons)
                        .frame(width: isCompact ? 6 : 8, height: max(0, h * CGFloat(volume)))
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: isCompact ? 100 : 140)
            
            Text("\(Int(volume * 100))%")
                .font(theme.typography.badgeSmall)
                .foregroundColor(theme.palette.playerActionButtons.opacity(0.8))
        }
        .frame(width: isCompact ? 100 : 140)
        .padding(.vertical, AKSpacing.sm)
        .padding(.horizontal, isCompact ? AKSpacing.xs : AKSpacing.sm)
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
#Preview("Volume Slider") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: AKSpacing.xxl) {
            AKVolumeSlider(volume: 0.0)
            AKVolumeSlider(volume: 0.45)
            AKVolumeSlider(volume: 0.9, isCompact: true)
        }
    }
}

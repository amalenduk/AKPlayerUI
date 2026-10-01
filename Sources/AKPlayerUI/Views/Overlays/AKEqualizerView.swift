//
//  AKEqualizerView.swift
//  AKPlayerUI
//

import SwiftUI

/// 10-Band Graphic Equalizer Sheet with real-time dynamic response curve, presets, and preamp attenuation.
public struct AKEqualizerView: View {
    @ObservedObject public var equalizer: AKEqualizerManager
    public let palette: AKColorPalette
    public let typography: AKTypography
    public let onDismiss: (() -> Void)?

    public init(
        equalizer: AKEqualizerManager,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard,
        onDismiss: (() -> Void)? = nil
    ) {
        self.equalizer = equalizer
        self.palette = palette
        self.typography = typography
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: AKSpacing.lg) {
            // Header Row
            HStack {
                VStack(alignment: .leading, spacing: AKSpacing.xxs) {
                    Text("10-Band Graphic Equalizer")
                        .font(typography.title2.weight(.bold))
                        .foregroundColor(.white)
                    Text("Digital Signal Processing • 32Hz – 16kHz")
                        .font(typography.footnote)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Master EQ Bypass Toggle
                Toggle("", isOn: $equalizer.isEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: palette.accent))

                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, AKSpacing.sm)
                }
            }
            .padding(.horizontal, AKSpacing.md)
            .padding(.top, AKSpacing.md)

            // Dynamic Cubic Spline Frequency Response Curve
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )

                // 0dB Center Reference Line
                GeometryReader { geo in
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: geo.size.height * 0.5))
                        p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.5))
                    }
                    .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    // Spline Curve
                    splinePath(in: geo.size)
                        .stroke(
                            equalizer.isEnabled ? palette.accent : Color.gray.opacity(0.5),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                }
            }
            .frame(height: 120)
            .padding(.horizontal, AKSpacing.md)

            // Preset Pills Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AKSpacing.xs) {
                    ForEach(AKEqualizerPreset.allCases) { preset in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                equalizer.applyPreset(preset)
                            }
                        }) {
                            Text(preset.rawValue)
                                .font(typography.caption1.weight(.semibold))
                                .foregroundColor(equalizer.activePreset == preset ? .black : .white)
                                .padding(.horizontal, AKSpacing.md)
                                .padding(.vertical, AKSpacing.xs)
                                .background(
                                    Capsule()
                                        .fill(equalizer.activePreset == preset ? Color.white : Color.white.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AKSpacing.md)
            }

            // 10-Band Logarithmic Sliders
            HStack(spacing: AKSpacing.xs) {
                ForEach(0..<equalizer.bands.count, id: \.self) { index in
                    VStack(spacing: AKSpacing.xs) {
                        Text(String(format: "%+.1f", equalizer.bands[index].gain))
                            .font(typography.badgeSmall)
                            .foregroundColor(equalizer.bands[index].gain == 0 ? .white.opacity(0.4) : palette.accent)

                        // Vertical Fader
                        GeometryReader { faderGeo in
                            let h = faderGeo.size.height
                            let gain = equalizer.bands[index].gain
                            let normalized = Double((gain + 12.0) / 24.0)

                            ZStack(alignment: .bottom) {
                                // Background Track
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 4)

                                // 0dB Center Marker
                                Rectangle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 12, height: 1)
                                    .position(x: faderGeo.size.width * 0.5, y: h * 0.5)

                                // Fader Thumb
                                Circle()
                                    .fill(equalizer.isEnabled ? palette.accent : Color.gray)
                                    .frame(width: 18, height: 18)
                                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                                    .position(x: faderGeo.size.width * 0.5, y: h * (1.0 - CGFloat(normalized)))
                            }
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { g in
                                        let ratio = 1.0 - (g.location.y / h)
                                        let newGain = Float(max(0.0, min(1.0, ratio)) * 24.0 - 12.0)
                                        equalizer.setGain(newGain, forBandAt: index)
                                    }
                            )
                        }
                        .frame(maxHeight: .infinity)

                        Text(equalizer.bands[index].frequencyLabel)
                            .font(typography.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(height: 180)
            .padding(.horizontal, AKSpacing.md)
            .disabled(!equalizer.isEnabled)
            .opacity(equalizer.isEnabled ? 1.0 : 0.5)

            // Preamp Gain Slider
            HStack(spacing: AKSpacing.md) {
                Text("Preamp")
                    .font(typography.footnote.weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))

                Slider(value: $equalizer.preampGain, in: -6.0...6.0, step: 0.5)
                    .tint(palette.accent)

                Text(String(format: "%+.1f dB", equalizer.preampGain))
                    .font(typography.timecodeSmall)
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, AKSpacing.md)
            .padding(.bottom, AKSpacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.13))
                .ignoresSafeArea()
        )
    }

    private func splinePath(in size: CGSize) -> Path {
        let points = equalizer.normalizedCurvePoints().map {
            CGPoint(x: $0.x * size.width, y: $0.y * size.height)
        }
        guard points.count > 1 else { return Path() }

        var path = Path()
        path.move(to: points[0])

        for i in 0..<points.count - 1 {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i < points.count - 2 ? points[i + 2] : p2

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6,
                y: p1.y + (p2.y - p0.y) / 6
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6,
                y: p2.y - (p3.y - p1.y) / 6
            )
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        return path
    }
}

// MARK: - Previews
#Preview("10-Band Equalizer") {
    let eq = AKEqualizerManager()
    eq.isEnabled = true
    eq.applyPreset(.bassBoost)
    return AKEqualizerView(equalizer: eq)
}

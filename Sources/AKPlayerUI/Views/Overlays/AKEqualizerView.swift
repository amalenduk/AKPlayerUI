//
//  AKEqualizerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// 10-Band Graphic Equalizer View.
/// Displays dynamic cubic spline frequency curves, quick presets, individual band sliders, and preamp gain.
/// Standardized inside AKAuxiliaryContainerView to eliminate duplicate headers, duplicate drag handles, and duplicate close buttons.
public struct AKEqualizerView: View {
    @ObservedObject public var equalizer: AKEqualizerManager
    public var palette: AKColorPalette
    public var typography: AKTypography
    public var placementMode: AKOverlayPlacementMode
    public var title: String
    public var subtitle: String?
    public var onDismiss: (() -> Void)?

    public init(
        equalizer: AKEqualizerManager,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard,
        placementMode: AKOverlayPlacementMode = .sheet,
        title: String = "Graphic Equalizer",
        subtitle: String? = "10-Band DSP Audio Equalizer • 32Hz – 16kHz",
        onDismiss: (() -> Void)? = nil
    ) {
        self.equalizer = equalizer
        self.palette = palette
        self.typography = typography
        self.placementMode = placementMode
        self.title = title
        self.subtitle = subtitle
        self.onDismiss = onDismiss
    }

    public var body: some View {
        AKAuxiliaryContainerView(
            badge: "DSP Equalizer",
            title: title,
            subtitle: subtitle,
            placementMode: placementMode,
            palette: palette,
            typography: typography,
            onDismiss: onDismiss,
            headerTrailing: {
                Toggle("", isOn: $equalizer.isEnabled)
                    .labelsHidden()
                    .tint(palette.accent)
            },
            content: {
                GeometryReader { contentGeo in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: AKSpacing.md) {
                            // Dynamic Cubic Spline Frequency Response Curve
                            frequencyResponseCurve

                            // Quick Preset Selection Pills
                            presetPillsRow

                            // 10-Band Logarithmic Sliders (Flexibly grows when sheet expands to full height)
                            fadersRow
                                .frame(minHeight: 145, maxHeight: .infinity)

                            // Preamp Gain Slider
                            preampSlider
                        }
                        .frame(minWidth: contentGeo.size.width, minHeight: contentGeo.size.height)
                        .padding(.top, AKSpacing.xs)
                    }
                }
            }
        )
    }

    // MARK: - Subviews

    private var frequencyResponseCurve: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            // 0dB Center Reference Line
            GeometryReader { geo in
                Path { p in
                    p.move(to: CGPoint(x: 0, y: geo.size.height * 0.5))
                    p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.5))
                }
                .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                // Spline Curve
                splinePath(in: geo.size)
                    .stroke(
                        equalizer.isEnabled ? palette.accent : Color.gray.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )
            }
        }
        .frame(height: 105)
        .padding(.horizontal, AKSpacing.md)
    }

    private var presetPillsRow: some View {
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
    }

    private var fadersRow: some View {
        HStack(spacing: AKSpacing.xxs) {
            ForEach(0..<equalizer.bands.count, id: \.self) { index in
                VStack(spacing: AKSpacing.xxs) {
                    Text(String(format: "%+.1f", equalizer.bands[index].gain))
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(equalizer.bands[index].gain == 0 ? .white.opacity(0.4) : palette.accent)

                    // Vertical Fader with Adaptive Travel Track
                    GeometryReader { faderGeo in
                        let h = faderGeo.size.height
                        let thumbSize: CGFloat = 16
                        let halfThumb: CGFloat = thumbSize * 0.5
                        let trackHeight = max(1.0, h - thumbSize)
                        let gain = equalizer.bands[index].gain
                        let normalized = Double((gain + 12.0) / 24.0)
                        let thumbY = halfThumb + trackHeight * (1.0 - CGFloat(normalized))

                        ZStack(alignment: .bottom) {
                            // Background Track
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 4, height: h)

                            // 0dB Center Marker
                            Rectangle()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: 10, height: 1)
                                .position(x: faderGeo.size.width * 0.5, y: halfThumb + trackHeight * 0.5)

                            // Fader Thumb
                            Circle()
                                .fill(equalizer.isEnabled ? palette.accent : Color.gray)
                                .frame(width: thumbSize, height: thumbSize)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .position(x: faderGeo.size.width * 0.5, y: thumbY)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { g in
                                    let ratio = 1.0 - ((g.location.y - halfThumb) / trackHeight)
                                    let newGain = Float(max(0.0, min(1.0, ratio)) * 24.0 - 12.0)
                                    equalizer.setGain(newGain, forBandAt: index)
                                }
                        )
                    }
                    .frame(maxHeight: .infinity)

                    Text(equalizer.bands[index].frequencyLabel)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .frame(minHeight: 145, maxHeight: .infinity)
        .padding(.horizontal, AKSpacing.sm)
        .disabled(!equalizer.isEnabled)
        .opacity(equalizer.isEnabled ? 1.0 : 0.45)
    }

    private var preampSlider: some View {
        HStack(spacing: AKSpacing.sm) {
            Text("Preamp")
                .font(typography.footnote.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))

            Slider(value: $equalizer.preampGain, in: -6.0...6.0, step: 0.5)
                .tint(palette.accent)

            Text(String(format: "%+.1f dB", equalizer.preampGain))
                .font(typography.timecodeSmall)
                .foregroundColor(.white)
                .frame(width: 58, alignment: .trailing)
        }
        .padding(.horizontal, AKSpacing.md)
        .padding(.bottom, AKSpacing.md)
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

//
//  AKVideoMiniPlayerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Floating / Docked Video Mini Player Bar that docks above the host tab bar.
/// Standardized height (~58pt), comfortable touch targets, continuous corner clipping, and live stream awareness.
public struct AKVideoMiniPlayerView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public let palette: AKColorPalette
    public let typography: AKTypography

    public init(
        coordinator: AKPlayerCoordinator = .shared,
        palette: AKColorPalette = .standard,
        typography: AKTypography = .standard
    ) {
        self.coordinator = coordinator
        self.palette = palette
        self.typography = typography
    }

    private var progress: Double {
        if coordinator.capabilities.isLive {
            return 1.0
        }
        guard coordinator.duration > 0 else { return 0 }
        return max(0, min(1.0, coordinator.currentTime / coordinator.duration))
    }

    public var body: some View {
        VStack(spacing: AKSpacing.zero) {
            HStack(spacing: AKSpacing.sm) {
                // Miniature Video Surface
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black)

                    AKVideoSurfaceView(
                        player: coordinator.player,
                        aspectRatio: .fill
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(width: 58, height: 38)
                .contentShape(Rectangle())
                .onTapGesture {
                    coordinator.expand()
                }

                // Title & Subtitle Info (Tapping expands into fullscreen)
                VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
                    Text(coordinator.currentTitle.isEmpty ? "Media Title" : coordinator.currentTitle)
                        .font(typography.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: AKSpacing.xs) {
                        if coordinator.capabilities.isLive {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text("LIVE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }

                        if !coordinator.currentSubtitle.isEmpty {
                            Text(coordinator.currentSubtitle)
                                .font(typography.caption2)
                                .foregroundColor(.white.opacity(0.65))
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    coordinator.expand()
                }

                // Quick Play/Pause Action
                Button(action: {
                    coordinator.togglePlayPause()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: coordinator.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: coordinator.isPlaying ? 0 : 1)
                    }
                }
                .buttonStyle(.plain)

                // Dismiss / Close Button
                Button(action: {
                    coordinator.dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 30, height: 30)

                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AKSpacing.md)
            .padding(.vertical, AKSpacing.xs)

            // Bottom Progress Line (Cleanly clipped inside card shape)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 2.5)

                    Rectangle()
                        .fill(
                            coordinator.adManager.isAdActive ? palette.adActiveProgress :
                                (coordinator.capabilities.isLive ? Color.red : palette.accent)
                        )
                        .frame(width: geo.size.width * CGFloat(progress), height: 2.5)
                        .animation(.linear(duration: 0.25), value: progress)
                }
            }
            .frame(height: 2.5)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.16).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 4)
        )
        // CRITICAL: Clip entire card so progress bar cannot bleed outside rounded corners
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, AKSpacing.sm)
    }
}

// MARK: - Previews
#Preview("Mini Player Bar") {
    ZStack(alignment: .bottom) {
        Color.gray.opacity(0.3).ignoresSafeArea()
        AKVideoMiniPlayerView(coordinator: .previewMock)
            .padding(.bottom, AKSpacing.lg)
    }
}

//
//  AKVideoMiniPlayerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Floating / Docked Mini Player Bar that attaches above the host tab bar.
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
        guard coordinator.duration > 0 else { return 0 }
        return max(0, min(1.0, coordinator.currentTime / coordinator.duration))
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Miniature Video Surface
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black)

                    AKVideoSurfaceView(
                        player: coordinator.player,
                        aspectRatio: .fill
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(width: 68, height: 42)

                // Title & Subtitle Info (Tapping expands into fullscreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text(coordinator.currentTitle.isEmpty ? "Media Title" : coordinator.currentTitle)
                        .font(typography.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if !coordinator.currentSubtitle.isEmpty {
                        Text(coordinator.currentSubtitle)
                            .font(typography.caption2)
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)
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
                    Image(systemName: coordinator.isPlaying ? "pause.fill" : "play.fill")
                        .font(typography.headline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                // Dismiss / Close Button
                Button(action: {
                    coordinator.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(typography.footnote.weight(.bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            // Bottom Progress Line
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 2)

                    Rectangle()
                        .fill(coordinator.adManager.isAdActive ? palette.adActiveProgress : palette.accent)
                        .frame(width: geo.size.width * CGFloat(progress), height: 2)
                }
            }
            .frame(height: 2)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 12)
    }
}

// MARK: - Previews
#Preview("Mini Player Bar") {
    ZStack(alignment: .bottom) {
        Color.gray.opacity(0.3).ignoresSafeArea()
        AKVideoMiniPlayerView(coordinator: .previewMock)
            .padding(.bottom, 20)
    }
}

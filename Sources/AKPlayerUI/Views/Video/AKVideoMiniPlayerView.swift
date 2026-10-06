//
//  AKVideoMiniPlayerView.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Floating / Docked Video Mini Player Bar that docks above the host tab bar.
/// Standardized height (~58pt), comfortable touch targets, continuous corner clipping, and live stream awareness.
/// Driven directly by `AKPlayer` with an expand callback for host navigation.
public struct AKVideoMiniPlayerView: View {
    @ObservedObject public var coordinator: AKPlayerCoordinator
    public let player: AKPlayer
    public let onExpand: () -> Void
    public var onDismiss: (() -> Void)?
    
    @State private var currentMedia: (any AKPlayable)?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isLive: Bool = false
    
    @Environment(\.akPlayerTheme) private var theme
    
    public init(
        coordinator: AKPlayerCoordinator,
        onExpand: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.player = coordinator.player
        self.onExpand = onExpand
        self.onDismiss = onDismiss
        self._currentMedia = State(initialValue: player.currentMedia)
        let cur = player.currentTime.seconds
        self._currentTime = State(initialValue: cur.isFinite ? cur : 0)
        let dur = player.currentItemDuration.seconds
        self._duration = State(initialValue: dur.isFinite ? dur : 0)
        self._isLive = State(initialValue: player.isLive || (player.currentMedia?.isLive() == true))
    }
    
    private var progress: Double {
        if isLive {
            return 1.0
        }
        guard duration > 0 else { return 0 }
        return max(0, min(1.0, currentTime / duration))
    }
    
    private var titleText: String {
        if let title = currentMedia?.staticMetadata?.title, !title.isEmpty {
            return title
        }
        return "Media Video"
    }
    
    private var subtitleText: String? {
        if let artist = currentMedia?.staticMetadata?.artist, !artist.isEmpty {
            return artist
        }
        if let album = currentMedia?.staticMetadata?.albumTitle, !album.isEmpty {
            return album
        }
        return nil
    }
    
    public var body: some View {
        VStack(spacing: AKSpacing.zero) {
            HStack(spacing: AKSpacing.sm) {
                // Miniature Video Surface (Tapping expands into full view)
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black)
                    
                    AKVideoSurfaceView(
                        player: player,
                        aspectRatio: .fill
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(width: 58, height: 38)
                .contentShape(Rectangle())
                .onTapGesture {
                    onExpand()
                }
                
                // Title & Subtitle Info (Tapping expands into full view)
                VStack(alignment: .leading, spacing: AKSpacing.xxxs) {
                    Text(titleText)
                        .font(theme.typography.subheadline.weight(.semibold))
                        .foregroundColor(theme.palette.foregroundPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: AKSpacing.xs) {
                        if isLive {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text("LIVE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        } else if let subtitleText {
                            Text(subtitleText)
                                .font(theme.typography.caption2)
                                .foregroundColor(theme.palette.foregroundSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onExpand()
                }
                
                // Quick Play/Pause Action
                AKPlayPauseButton(state: player.state, autoPlay: player.autoPlay, size: 36) {
                    player.togglePlayPause()
                }
                
                // Dismiss / Close Button
                if let onDismiss {
                    Button(action: onDismiss) {
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
                        .fill(isLive ? Color.red : theme.palette.accent)
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
                        .stroke(theme.palette.glassBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 4)
        )
        // CRITICAL: Clip entire card so progress bar cannot bleed outside rounded corners
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, AKSpacing.sm)
        .task {
            currentMedia = player.currentMedia
            isLive = player.isLive || (player.currentMedia?.isLive() == true)
            let cur = player.currentTime.seconds
            currentTime = cur.isFinite ? cur : 0
            let dur = player.currentItemDuration.seconds
            duration = dur.isFinite ? dur : 0
            
            for await event in player.events {
                switch event {
                case .stateDidChange:
                    let d = player.currentItemDuration.seconds
                    if d.isFinite && d > 0 { duration = d }
                case .mediaDidChange(let newMedia):
                    currentMedia = newMedia
                    isLive = player.isLive || newMedia.isLive()
                    let d = player.currentItemDuration.seconds
                    duration = d.isFinite ? d : 0
                case .timeDidChange(let time):
                    let c = time.seconds
                    currentTime = c.isFinite ? c : 0
                    let d = player.currentItemDuration.seconds
                    if d.isFinite && d > 0 { duration = d }
                case .didReachEnd:
                    currentTime = duration
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Mini Player Bar") {
    ZStack(alignment: .bottom) {
        Color.gray.opacity(0.3).ignoresSafeArea()
        AKVideoMiniPlayerView(
            coordinator: AKPlayerCoordinator(),
            onExpand: {},
            onDismiss: {}
        )
        .padding(.bottom, AKSpacing.lg)
    }
}

//
//  AKPlayPauseButton.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Single Responsibility: Displays play/pause state or buffering spinner, toggling playback on tap.
/// Driven directly by the core `AKPlayer` engine with tactile spring feedback and fluid transitions.
public struct AKPlayPauseButton: View {
    public let player: AKPlayer?
    public var size: CGFloat
    
    @State private var state: AKPlayerState
    @State private var autoPlay: Bool
    
    @Environment(\.akPlayerTheme) private var theme
    
    // MARK: - Public Initializer (Library API)
    
    public init(
        player: AKPlayer,
        size: CGFloat = 64
    ) {
        self.player = player
        self.size = size
        self._state = State(initialValue: player.state)
        self._autoPlay = State(initialValue: player.autoPlay)
    }
    
    // MARK: - Preview Initializer (Internal / Testing Only)
    
    fileprivate init(
        previewState: AKPlayerState,
        previewAutoPlay: Bool = false,
        size: CGFloat = 64
    ) {
        self.player = nil
        self.size = size
        self._state = State(initialValue: previewState)
        self._autoPlay = State(initialValue: previewAutoPlay)
    }
    
    // MARK: - View Body
    
    public var body: some View {
        Button(action: { player?.togglePlayPause() }) {
            ZStack {
                Circle()
                    .fill(theme.palette.playerActionBackgroundButtons)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle().stroke(theme.palette.glassBorder, lineWidth: 1)
                    )
                
                Group {
                    switch state {
                    case .idle:
                        iconImage(for: state)
                    case .loading:
                        progressView()
                    case .loaded:
                        if autoPlay {
                            progressView()
                        } else {
                            iconImage(for: .paused)
                        }
                    case .buffering:
                        if autoPlay {
                            progressView()
                        } else {
                            iconImage(for: .paused)
                        }
                    case .paused:
                        iconImage(for: .paused)
                    case .playing:
                        iconImage(for: .playing)
                    case .stopped:
                        iconImage(for: .paused)
                    case .waitingForNetwork:
                        if autoPlay {
                            progressView()
                        } else {
                            iconImage(for: .paused)
                        }
                    case .failed:
                        iconImage(for: .paused)
                    }
                }
            }
        }
        .buttonStyle(AKPlayPauseButtonStyle())
        .animation(.spring(response: 0.32, dampingFraction: 0.75), value: state)
        .animation(.spring(response: 0.32, dampingFraction: 0.75), value: autoPlay)
        .task {
            // In preview mode (player == nil), do not overwrite the preview state
            guard let player = player else { return }
            state = player.state
            autoPlay = player.autoPlay
            for await event in player.events {
                if case .stateDidChange(let newState) = event {
                    state = newState
                    autoPlay = player.autoPlay
                }
            }
        }
    }
    
    // MARK: - State Icon Helper
    
    @ViewBuilder
    private func iconImage(for state: AKPlayerState) -> some View {
        let isPlaying = state.isPlaying
        let iconName = isPlaying ? theme.icons.pause : theme.icons.play
        
        Group {
            if #available(iOS 17.0, *) {
                Image(systemName: iconName)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundColor(theme.palette.playerActionButtons)
                    .offset(x: isPlaying ? 0 : 2)
                    .contentTransition(.symbolEffect(.replace))
            } else {
                Image(systemName: iconName)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundColor(theme.palette.playerActionButtons)
                    .offset(x: isPlaying ? 0 : 2)
            }
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
    
    @ViewBuilder
    private func progressView() -> some View {
        ProgressView()
            .tint(theme.palette.playerActionButtons)
            .scaleEffect(size / 40.0)
            .transition(.scale(scale: 0.7).combined(with: .opacity))
    }
}

// MARK: - Tactile Spring Button Style

private struct AKPlayPauseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Buffering State") {
    ZStack {
        Color.black.ignoresSafeArea()
        AKPlayPauseButton(previewState: .buffering, previewAutoPlay: true)
            .environment(\.akPlayerTheme, .standard)
    }
}

#Preview("Playing State") {
    ZStack {
        Color.black.ignoresSafeArea()
        AKPlayPauseButton(previewState: .playing)
            .environment(\.akPlayerTheme, .vibrant)
    }
}

#Preview("Paused State") {
    ZStack {
        Color.black.ignoresSafeArea()
        AKPlayPauseButton(previewState: .paused)
            .environment(\.akPlayerTheme, .highContrast)
    }
}

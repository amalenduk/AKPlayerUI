//
//  AKPlayPauseButton.swift
//  AKPlayerUI
//

import SwiftUI
import AKPlayer

/// Single Responsibility: Displays play/pause state or buffering spinner, toggling playback on tap.
/// Driven directly by the core `AKPlayer` engine with tactile spring feedback, dynamic theming, and fluid transitions.
public struct AKPlayPauseButton: View {
    public let state: AKPlayerState
    public let autoPlay: Bool
    public let size: CGFloat
    public let onToggle: () -> Void
    
    @Environment(\.akPlayerTheme) private var theme
    
    // MARK: - Public Initializer (Library API)
    
    public init(
        state: AKPlayerState,
        autoPlay: Bool = false,
        size: CGFloat = 64,
        onToggle: @escaping () -> Void
    ) {
        self.state = state
        self.autoPlay = autoPlay
        self.size = size
        self.onToggle = onToggle
    }
    
    // MARK: - View Body
    
    public var body: some View {
        // 3. Use the dynamic onToggle closure which handles both real player and manual actions
        Button(action: { onToggle() }) {
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
        .buttonStyle(AKControlButtonStyle(size: size))
        .animation(.spring(response: 0.32, dampingFraction: 0.75), value: state)
        .animation(.spring(response: 0.32, dampingFraction: 0.75), value: autoPlay)
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
                    .offset(x: isPlaying ? 0 : 2)
                    .contentTransition(.symbolEffect(.replace))
            } else {
                Image(systemName: iconName)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .offset(x: isPlaying ? 0 : 2)
            }
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
    
    @ViewBuilder
    private func progressView() -> some View {
        ProgressView()
            .scaleEffect(size / 40.0)
            .transition(.scale(scale: 0.7).combined(with: .opacity))
    }
}


// MARK: - Previews

#Preview("Standard Filled Theme") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 24) {
            AKPlayPauseButton(state: .playing, size: 64, onToggle: { })
            AKPlayPauseButton(state: .paused, size: 64, onToggle: { })
            AKPlayPauseButton(state: .buffering, autoPlay: true, size: 64, onToggle: { })
        }
        .environment(\.akPlayerTheme, .standard)
    }
}

#Preview("Tinted Theme") {
    var tintedTheme = AKPlayerTheme.standard
    tintedTheme.buttonStyle = .tinted
    return ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 24) {
            AKPlayPauseButton(state: .playing, size: 64, onToggle: { })
            AKPlayPauseButton(state: .paused, size: 64, onToggle: { })
        }
        .environment(\.akPlayerTheme, tintedTheme)
    }
}

#Preview("Outlined Theme") {
    var tintedTheme = AKPlayerTheme.standard
    tintedTheme.buttonStyle = .outlined
    return ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 24) {
            AKPlayPauseButton(state: .playing, size: 64, onToggle: { })
            AKPlayPauseButton(state: .paused, size: 64, onToggle: { })
        }
        .environment(\.akPlayerTheme, tintedTheme)
    }
}

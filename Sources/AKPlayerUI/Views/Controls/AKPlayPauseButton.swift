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
    public let isEnabled: Bool
    public let size: CGFloat
    public let style: AKButtonStyle?
    public let onAction: () -> Void
    
    @Environment(\.akPlayerTheme) private var theme
    
    public init(
        state: AKPlayerState,
        autoPlay: Bool = false,
        isEnabled: Bool = true,
        size: CGFloat = 64,
        style: AKButtonStyle? = nil,
        onAction: @escaping () -> Void
    ) {
        self.state = state
        self.autoPlay = autoPlay
        self.isEnabled = isEnabled
        self.size = size
        self.style = style
        self.onAction = onAction
    }
    
    public var body: some View {
        Button(action: { onAction() }) {
            Group {
                switch state {
                case .idle, .paused, .playing, .stopped, .failed:
                    iconImage(for: state)
                case .loaded, .buffering, .waitingForNetwork:
                    if autoPlay {
                        progressView()
                    } else {
                        iconImage(for: .paused)
                    }
                case .loading:
                    progressView()
                }
            }
        }
        .buttonStyle(AKControlButtonStyle(size: size, style: style))
        .disabled(!isEnabled)
        .animation(.spring(response: 0.32, dampingFraction: 0.75), value: state)
        .animation(.spring(response: 0.32, dampingFraction: 0.75), value: autoPlay)
    }
    
    // MARK: - State Icon Helper

    private func iconName(for state: AKPlayerState) -> String {
        switch state {
        case .failed:
            return theme.icons.reload
        case .playing:
            return theme.icons.pause
        default:
            return theme.icons.play
        }
    }
    
    @ViewBuilder
    private func iconImage(for state: AKPlayerState) -> some View {
        let name = iconName(for: state)
        
        Group {
            if #available(iOS 17.0, *) {
                Image(systemName: name)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
            } else {
                Image(systemName: name)
                    .font(.system(size: size * 0.42, weight: .bold))
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
            AKPlayPauseButton(state: .playing, size: 64, onAction: { })
            AKPlayPauseButton(state: .paused, size: 64, onAction: { })
            AKPlayPauseButton(state: .buffering, autoPlay: true, size: 64, onAction: { })
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
            AKPlayPauseButton(state: .playing, size: 64, onAction: { })
            AKPlayPauseButton(state: .paused, size: 64, style: AKButtonStyle.filled, onAction: { })
        }
        .environment(\.akPlayerTheme, tintedTheme)
    }
}

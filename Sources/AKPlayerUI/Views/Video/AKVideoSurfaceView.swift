//
//  AKVideoSurfaceView.swift
//  AKPlayerUI
//

import SwiftUI
import AVFoundation
import AKPlayer

#if canImport(UIKit)
import UIKit

/// Single Responsibility: Hosts the AVPlayerLayer / AKPlayerView rendering pipeline for iOS & tvOS.
public struct AKVideoSurfaceView: UIViewRepresentable {
    public let player: AKPlayer
    public let aspectRatio: AKVideoAspectRatio
    
    public init(player: AKPlayer, aspectRatio: AKVideoAspectRatio = .fit) {
        self.player = player
        self.aspectRatio = aspectRatio
    }
    
    public func makeUIView(context: Context) -> AKPlayerView {
        let view = AKPlayerView()
        view.player = player.player
        view.backgroundColor = .black
        view.setVideoFillMode(aspectRatio.videoGravity.rawValue)
        return view
    }
    
    public func updateUIView(_ uiView: AKPlayerView, context: Context) {
        if uiView.player !== player.player {
            uiView.player = player.player
        }
        uiView.setVideoFillMode(aspectRatio.videoGravity.rawValue)
    }
}

#elseif canImport(AppKit)
import AppKit

/// Single Responsibility: Hosts the AVPlayerLayer / AKPlayerView rendering pipeline for macOS.
public struct AKVideoSurfaceView: NSViewRepresentable {
    public let player: AKPlayer
    public let aspectRatio: AKVideoAspectRatio
    
    public init(player: AKPlayer, aspectRatio: AKVideoAspectRatio = .fit) {
        self.player = player
        self.aspectRatio = aspectRatio
    }
    
    public func makeNSView(context: Context) -> AKPlayerView {
        let view = AKPlayerView(frame: .zero)
        view.player = player.player
        view.setVideoFillMode(aspectRatio.videoGravity.rawValue)
        return view
    }
    
    public func updateNSView(_ nsView: AKPlayerView, context: Context) {
        if nsView.player !== player.player {
            nsView.player = player.player
        }
        nsView.setVideoFillMode(aspectRatio.videoGravity.rawValue)
    }
}
#endif

// MARK: - Previews
#Preview("Video Surface Mock") {
    ZStack {
        Color.black.ignoresSafeArea()
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
            .overlay(
                Image(systemName: "film")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.3))
            )
            .padding(AKSpacing.md)
    }
}

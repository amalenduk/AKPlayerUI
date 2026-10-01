//
//  AKMediaCapabilities.swift
//  AKPlayerUI
//

import Foundation

/// Intrinsic playback capabilities reported by the media asset or player engine.
/// UI controls dynamically observe these properties to enable, disable, or adjust controls.
public struct AKMediaCapabilities: Sendable, Equatable {
    public var canSeek: Bool
    public var canStepForward: Bool
    public var canStepBackward: Bool
    public var canPause: Bool
    public var canPlayFastForward: Bool
    public var canPlayFastReverse: Bool
    public var isLive: Bool

    public init(
        canSeek: Bool = false,
        canStepForward: Bool = false,
        canStepBackward: Bool = false,
        canPause: Bool = true,
        canPlayFastForward: Bool = true,
        canPlayFastReverse: Bool = false,
        isLive: Bool = false
    ) {
        self.canSeek = canSeek
        self.canStepForward = canStepForward
        self.canStepBackward = canStepBackward
        self.canPause = canPause
        self.canPlayFastForward = canPlayFastForward
        self.canPlayFastReverse = canPlayFastReverse
        self.isLive = isLive
    }

    public static let empty = AKMediaCapabilities()

    public static let fullVideo = AKMediaCapabilities(
        canSeek: true,
        canStepForward: true,
        canStepBackward: true,
        canPause: true,
        canPlayFastForward: true,
        canPlayFastReverse: true,
        isLive: false
    )

    public static let liveStreamDVR = AKMediaCapabilities(
        canSeek: true,
        canStepForward: false,
        canStepBackward: false,
        canPause: true,
        canPlayFastForward: false,
        canPlayFastReverse: false,
        isLive: true
    )
}

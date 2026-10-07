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
    public var canPlayReverse: Bool
    public var canPlayFastForward: Bool
    public var canPlayFastReverse: Bool
    public var canPlaySlowForward: Bool
    public var canPlaySlowReverse: Bool

    public init(
        canSeek: Bool = false,
        canStepForward: Bool = false,
        canStepBackward: Bool = false,
        canPause: Bool = true,
        canPlayReverse: Bool = false,
        canPlayFastForward: Bool = true,
        canPlayFastReverse: Bool = false,
        canPlaySlowForward: Bool = false,
        canPlaySlowReverse: Bool = false
    ) {
        self.canSeek = canSeek
        self.canStepForward = canStepForward
        self.canStepBackward = canStepBackward
        self.canPause = canPause
        self.canPlayReverse = canPlayReverse
        self.canPlayFastForward = canPlayFastForward
        self.canPlayFastReverse = canPlayFastReverse
        self.canPlaySlowForward = canPlaySlowForward
        self.canPlaySlowReverse = canPlaySlowReverse
    }

    public static let empty = AKMediaCapabilities()

    public static let fullVideo = AKMediaCapabilities(
        canSeek: true,
        canStepForward: true,
        canStepBackward: true,
        canPause: true,
        canPlayReverse: true,
        canPlayFastForward: true,
        canPlayFastReverse: true,
        canPlaySlowForward: true,
        canPlaySlowReverse: true
    )

    public static let liveStreamDVR = AKMediaCapabilities(
        canSeek: true,
        canStepForward: false,
        canStepBackward: false,
        canPause: true,
        canPlayReverse: false,
        canPlayFastForward: false,
        canPlayFastReverse: false,
        canPlaySlowForward: false,
        canPlaySlowReverse: false
    )
}

//
//  AKIconProvider.swift
//  AKPlayerUI
//

import Foundation

/// Icon registry mapping system actions to SF Symbol names.
public struct AKIconProvider: Sendable, Equatable {
    public var play: String
    public var pause: String
    public var skipBackward: String
    public var skipForward: String
    public var stepBackward: String
    public var stepForward: String
    public var speed: String
    public var airPlay: String
    public var pictureInPicture: String
    public var subtitles: String
    public var audioTracks: String
    public var equalizer: String
    public var chapters: String
    public var sleepTimer: String
    public var volumeMute: String
    public var volumeLow: String
    public var volumeMid: String
    public var volumeHigh: String
    public var brightness: String
    public var expand: String
    public var collapse: String
    public var dismiss: String
    public var brightnessMin: String
    public var brightnessMax: String
    
    public init(
        play: String = "play.fill",
        pause: String = "pause.fill",
        skipBackward: String = "gobackward",
        skipForward: String = "goforward",
        stepBackward: String = "backward.frame.fill",
        stepForward: String = "forward.frame.fill",
        speed: String = "gauge.with.needle",
        airPlay: String = "airplayvideo",
        pictureInPicture: String = "pip.enter",
        subtitles: String = "captions.bubble.fill",
        audioTracks: String = "waveform.badge.magnifyingglass",
        equalizer: String = "slider.vertical.3",
        chapters: String = "list.bullet.indent",
        sleepTimer: String = "timer",
        volumeMute: String = "speaker.slash.fill",
        volumeLow: String = "speaker.wave.1.fill",
        volumeMid: String = "speaker.wave.2.fill",
        volumeHigh: String = "speaker.wave.3.fill",
        brightness: String = "sun.max.fill",
        expand: String = "arrow.up.left.and.arrow.down.right",
        collapse: String = "chevron.down",
        dismiss: String = "xmark",
        brightnessMin: String = "sun.min.fill",
        brightnessMax: String = "sun.max.fill"
    ) {
        self.play = play
        self.pause = pause
        self.skipBackward = skipBackward
        self.skipForward = skipForward
        self.stepBackward = stepBackward
        self.stepForward = stepForward
        self.speed = speed
        self.airPlay = airPlay
        self.pictureInPicture = pictureInPicture
        self.subtitles = subtitles
        self.audioTracks = audioTracks
        self.equalizer = equalizer
        self.chapters = chapters
        self.sleepTimer = sleepTimer
        self.volumeMute = volumeMute
        self.volumeLow = volumeLow
        self.volumeMid = volumeMid
        self.volumeHigh = volumeHigh
        self.brightness = brightness
        self.expand = expand
        self.collapse = collapse
        self.dismiss = dismiss
        self.brightnessMin = brightnessMin
        self.brightnessMax = brightnessMax
    }
    
    public static let standard = AKIconProvider()
}

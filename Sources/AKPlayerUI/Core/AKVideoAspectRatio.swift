//
//  AKVideoAspectRatio.swift
//  AKPlayerUI
//

import AVFoundation
import SwiftUI

/// Supported video presentation aspect ratio and scaling modes.
public enum AKVideoAspectRatio: String, CaseIterable, Identifiable, Sendable {
    case fit            = "Fit"
    case fill           = "Fill"
    case stretch        = "Stretch"
    case sixteenByNine  = "16:9"
    case fourByThree    = "4:3"
    case twentyOneByNine = "21:9"

    public var id: String { rawValue }

    public var videoGravity: AVLayerVideoGravity {
        switch self {
        case .fit, .sixteenByNine, .fourByThree, .twentyOneByNine:
            return .resizeAspect
        case .fill:
            return .resizeAspectFill
        case .stretch:
            return .resize
        }
    }

    public var aspectRatioValue: CGFloat? {
        switch self {
        case .sixteenByNine:   return 16.0 / 9.0
        case .fourByThree:     return 4.0 / 3.0
        case .twentyOneByNine: return 21.0 / 9.0
        default:               return nil
        }
    }
}

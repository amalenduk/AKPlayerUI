//
//  AKSpacing.swift
//  AKPlayerUI
//

import CoreGraphics
import SwiftUI

/// Layout spacing and padding design tokens used consistently across the player interface.
public struct AKSpacing: Sendable {
    /// 0pt no spacing.
    public static let zero: CGFloat = 0

    /// 2pt micro spacing.
    public static let xxxs: CGFloat = 2

    /// 4pt ultra-tight spacing.
    public static let xxs: CGFloat  = 4

    /// 8pt tight spacing.
    public static let xs: CGFloat   = 8

    /// 12pt compact spacing.
    public static let sm: CGFloat   = 12

    /// 16pt standard content spacing.
    public static let md: CGFloat   = 16

    /// 20pt generous spacing.
    public static let lg: CGFloat   = 20

    /// 24pt spacious section spacing.
    public static let xl: CGFloat   = 24

    /// 32pt large container padding.
    public static let xxl: CGFloat  = 32

    /// 40pt major layout gap.
    public static let xxxl: CGFloat = 40

    /// 48pt hero spacing.
    public static let huge: CGFloat = 48
}

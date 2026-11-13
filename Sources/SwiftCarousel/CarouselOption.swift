//
//  CarouselOption.swift
//  SwiftCarousel
//
//  Ported from iCarousel 1.8.3 by Nick Lockwood.
//  https://github.com/nicklockwood/iCarousel — zlib license.
//

import CoreGraphics

/// Layout tunables that can be overridden through ``CarouselDelegate/carousel(_:valueForOption:withDefault:)``.
///
/// Raw values match the original `iCarouselOption` enum.
public enum CarouselOption: Int, CaseIterable, Sendable {
    case wrap
    case showBackfaces
    case offsetMultiplier
    case visibleItems
    case count
    case arc
    case angle
    case radius
    case tilt
    case spacing
    case fadeMin
    case fadeMax
    case fadeRange
    case fadeMinAlpha
}

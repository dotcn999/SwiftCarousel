//
//  CarouselType.swift
//  SwiftCarousel
//
//  Ported from iCarousel 1.8.3 by Nick Lockwood.
//  https://github.com/nicklockwood/iCarousel — zlib license.
//

import CoreGraphics

/// The built-in carousel layouts.
///
/// Raw values match the original `iCarouselType` enum.
public enum CarouselType: Int, CaseIterable, Sendable {
    case linear = 0
    case rotary
    case invertedRotary
    case cylinder
    case invertedCylinder
    case wheel
    case invertedWheel
    case coverFlow
    case coverFlow2
    case timeMachine
    case invertedTimeMachine
    case custom

    /// Circular layouts wrap by default.
    public var isCircular: Bool {
        switch self {
        case .rotary, .invertedRotary, .cylinder, .invertedCylinder, .wheel, .invertedWheel:
            return true
        case .linear, .coverFlow, .coverFlow2, .timeMachine, .invertedTimeMachine, .custom:
            return false
        }
    }

    var defaultOffsetMultiplier: CGFloat {
        switch self {
        case .coverFlow, .coverFlow2: return 2
        default: return 1
        }
    }

    public var displayName: String {
        switch self {
        case .linear: return "Linear"
        case .rotary: return "Rotary"
        case .invertedRotary: return "Inverted Rotary"
        case .cylinder: return "Cylinder"
        case .invertedCylinder: return "Inverted Cylinder"
        case .wheel: return "Wheel"
        case .invertedWheel: return "Inverted Wheel"
        case .coverFlow: return "Cover Flow"
        case .coverFlow2: return "Cover Flow 2"
        case .timeMachine: return "Time Machine"
        case .invertedTimeMachine: return "Inverted Time Machine"
        case .custom: return "Custom"
        }
    }
}

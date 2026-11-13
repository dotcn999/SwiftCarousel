//
//  CarouselDelegate.swift
//  SwiftCarousel
//
//  Ported from iCarousel 1.8.3 by Nick Lockwood.
//  https://github.com/nicklockwood/iCarousel — zlib license.
//

import UIKit

/// Receives scroll, selection and layout callbacks from ``CarouselView``.
///
/// All methods are optional.
@MainActor
public protocol CarouselDelegate: AnyObject {
    func carouselWillBeginScrollingAnimation(_ carousel: CarouselView)
    func carouselDidEndScrollingAnimation(_ carousel: CarouselView)
    func carouselDidScroll(_ carousel: CarouselView)
    func carouselCurrentItemIndexDidChange(_ carousel: CarouselView)
    func carouselWillBeginDragging(_ carousel: CarouselView)
    func carousel(_ carousel: CarouselView, didEndDragging willDecelerate: Bool)
    func carouselWillBeginDecelerating(_ carousel: CarouselView)
    func carouselDidEndDecelerating(_ carousel: CarouselView)

    func carousel(_ carousel: CarouselView, shouldSelectItemAt index: Int) -> Bool
    func carousel(_ carousel: CarouselView, didSelectItemAt index: Int)

    func carouselItemWidth(_ carousel: CarouselView) -> CGFloat

    func carousel(
        _ carousel: CarouselView,
        itemTransformForOffset offset: CGFloat,
        baseTransform transform: CATransform3D
    ) -> CATransform3D

    func carousel(_ carousel: CarouselView, valueForOption option: CarouselOption, withDefault value: CGFloat) -> CGFloat
}

public extension CarouselDelegate {
    func carouselWillBeginScrollingAnimation(_ carousel: CarouselView) {}
    func carouselDidEndScrollingAnimation(_ carousel: CarouselView) {}
    func carouselDidScroll(_ carousel: CarouselView) {}
    func carouselCurrentItemIndexDidChange(_ carousel: CarouselView) {}
    func carouselWillBeginDragging(_ carousel: CarouselView) {}
    func carousel(_ carousel: CarouselView, didEndDragging willDecelerate: Bool) {}
    func carouselWillBeginDecelerating(_ carousel: CarouselView) {}
    func carouselDidEndDecelerating(_ carousel: CarouselView) {}

    func carousel(_ carousel: CarouselView, shouldSelectItemAt index: Int) -> Bool { true }
    func carousel(_ carousel: CarouselView, didSelectItemAt index: Int) {}

    func carouselItemWidth(_ carousel: CarouselView) -> CGFloat { 0 }

    func carousel(
        _ carousel: CarouselView,
        itemTransformForOffset offset: CGFloat,
        baseTransform transform: CATransform3D
    ) -> CATransform3D {
        transform
    }

    func carousel(_ carousel: CarouselView, valueForOption option: CarouselOption, withDefault value: CGFloat) -> CGFloat {
        value
    }
}

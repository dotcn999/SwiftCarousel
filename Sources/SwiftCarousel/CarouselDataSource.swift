//
//  CarouselDataSource.swift
//  SwiftCarousel
//
//  Ported from iCarousel 1.8.3 by Nick Lockwood.
//  https://github.com/nicklockwood/iCarousel — zlib license.
//

import UIKit

/// Supplies the views displayed by ``CarouselView``.
///
/// Only `numberOfItems(in:)` and `carousel(_:viewForItemAt:reusing:)` are required.
@MainActor
public protocol CarouselDataSource: AnyObject {
    func numberOfItems(in carousel: CarouselView) -> Int

    /// Returns a view for the given index.
    ///
    /// - Parameter reusing: A view previously returned to the reuse pool, or `nil`.
    func carousel(_ carousel: CarouselView, viewForItemAt index: Int, reusing view: UIView?) -> UIView

    func numberOfPlaceholders(in carousel: CarouselView) -> Int

    func carousel(_ carousel: CarouselView, placeholderViewAt index: Int, reusing view: UIView?) -> UIView
}

public extension CarouselDataSource {
    func numberOfPlaceholders(in carousel: CarouselView) -> Int { 0 }

    func carousel(_ carousel: CarouselView, placeholderViewAt index: Int, reusing view: UIView?) -> UIView {
        view ?? UIView()
    }
}

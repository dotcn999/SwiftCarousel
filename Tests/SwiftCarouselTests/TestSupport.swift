import UIKit
import XCTest

@testable import SwiftCarousel

@MainActor
final class StubDataSource: CarouselDataSource {
    var itemCount = 5
    var placeholderCount = 0
    var itemSize = CGSize(width: 100, height: 150)

    func numberOfItems(in carousel: CarouselView) -> Int {
        itemCount
    }

    func carousel(_ carousel: CarouselView, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        let itemView = view ?? UIView()
        itemView.frame = CGRect(origin: .zero, size: itemSize)
        return itemView
    }

    func numberOfPlaceholders(in carousel: CarouselView) -> Int {
        placeholderCount
    }

    func carousel(_ carousel: CarouselView, placeholderViewAt index: Int, reusing view: UIView?) -> UIView {
        let placeholder = view ?? UIView()
        placeholder.frame = CGRect(origin: .zero, size: itemSize)
        return placeholder
    }
}

@MainActor
final class StubDelegate: CarouselDelegate {
    var optionValues: [CarouselOption: CGFloat] = [:]
    var customTransform: ((CGFloat, CATransform3D) -> CATransform3D)?
    var itemWidth: CGFloat = 0
    var allowsSelection = true
    var selectedIndex: Int?
    var events: [String] = []

    func carouselItemWidth(_ carousel: CarouselView) -> CGFloat {
        itemWidth
    }

    func carouselWillBeginScrollingAnimation(_ carousel: CarouselView) {
        events.append("willBeginScrollingAnimation")
    }

    func carouselDidEndScrollingAnimation(_ carousel: CarouselView) {
        events.append("didEndScrollingAnimation")
    }

    func carouselDidScroll(_ carousel: CarouselView) {
        events.append("didScroll")
    }

    func carouselCurrentItemIndexDidChange(_ carousel: CarouselView) {
        events.append("indexDidChange")
    }

    func carouselWillBeginDragging(_ carousel: CarouselView) {
        events.append("willBeginDragging")
    }

    func carousel(_ carousel: CarouselView, didEndDragging willDecelerate: Bool) {
        events.append("didEndDragging:\(willDecelerate)")
    }

    func carouselWillBeginDecelerating(_ carousel: CarouselView) {
        events.append("willBeginDecelerating")
    }

    func carouselDidEndDecelerating(_ carousel: CarouselView) {
        events.append("didEndDecelerating")
    }

    func carousel(_ carousel: CarouselView, shouldSelectItemAt index: Int) -> Bool {
        allowsSelection
    }

    func carousel(_ carousel: CarouselView, didSelectItemAt index: Int) {
        selectedIndex = index
        events.append("select:\(index)")
    }

    func carousel(
        _ carousel: CarouselView,
        itemTransformForOffset offset: CGFloat,
        baseTransform transform: CATransform3D
    ) -> CATransform3D {
        customTransform?(offset, transform) ?? transform
    }

    func carousel(_ carousel: CarouselView, valueForOption option: CarouselOption, withDefault value: CGFloat) -> CGFloat {
        optionValues[option] ?? value
    }
}

@MainActor
final class CarouselHarness {
    let carousel: CarouselView
    let dataSource = StubDataSource()
    let delegate = StubDelegate()

    init(
        items: Int = 12,
        type: CarouselType = .linear,
        placeholders: Int = 0,
        frame: CGRect = CGRect(x: 0, y: 0, width: 320, height: 480)
    ) {
        dataSource.itemCount = items
        dataSource.placeholderCount = placeholders

        carousel = CarouselView(frame: frame)
        carousel.bounces = false
        carousel.dataSource = dataSource
        carousel.delegate = delegate
        carousel.type = type
        carousel.layoutIfNeeded()
    }

    var itemCenter: CGPoint {
        CGPoint(x: carousel.bounds.midX, y: carousel.bounds.midY)
    }

    func transform(at index: Int) -> CATransform3D? {
        carousel.itemView(at: index)?.superview?.layer.transform
    }

    func opacity(at index: Int) -> Float? {
        carousel.itemView(at: index)?.superview?.layer.opacity
    }

    /// Finishes the Cover Flow 2 toggle animation without waiting for a display link.
    func settleToggle() {
        carousel.toggle = 0
        carousel.transformItemViews()
    }

    func stop() {
        carousel.stopAnimation()
    }
}

@MainActor
final class StubPanGestureRecognizer: UIPanGestureRecognizer {
    var stubbedState: UIGestureRecognizer.State = .possible
    var stubbedTranslation: CGPoint = .zero
    var stubbedVelocity: CGPoint = .zero

    override var state: UIGestureRecognizer.State {
        get { stubbedState }
        set { stubbedState = newValue }
    }

    override func translation(in view: UIView?) -> CGPoint {
        stubbedTranslation
    }

    override func velocity(in view: UIView?) -> CGPoint {
        stubbedVelocity
    }
}

@MainActor
final class StubTapGestureRecognizer: UITapGestureRecognizer {
    var stubbedLocation: CGPoint = .zero

    override func location(in view: UIView?) -> CGPoint {
        stubbedLocation
    }
}

func XCTAssertTransformIsFinite(
    _ transform: CATransform3D,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let values = [
        transform.m11, transform.m12, transform.m13, transform.m14,
        transform.m21, transform.m22, transform.m23, transform.m24,
        transform.m31, transform.m32, transform.m33, transform.m34,
        transform.m41, transform.m42, transform.m43, transform.m44
    ]
    XCTAssertTrue(values.allSatisfy(\.isFinite), "Transform contains a non-finite component", file: file, line: line)
}

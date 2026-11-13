import QuartzCore
import UIKit
import XCTest

@testable import SwiftCarousel

@MainActor
final class CarouselInteractionTests: XCTestCase {

    private func makePan(
        state: UIGestureRecognizer.State = .changed,
        translation: CGPoint = .zero,
        velocity: CGPoint = .zero
    ) -> StubPanGestureRecognizer {
        let pan = StubPanGestureRecognizer(target: nil, action: nil)
        pan.stubbedState = state
        pan.stubbedTranslation = translation
        pan.stubbedVelocity = velocity
        return pan
    }

    func testDragUpdatesOffsetAndReportsDelegateCallbacks() {
        let harness = CarouselHarness(items: 5, type: .linear)
        defer { harness.stop() }

        let pan = makePan(state: .began)
        harness.carousel.handlePan(pan)

        XCTAssertTrue(harness.carousel.isDragging)
        XCTAssertTrue(harness.delegate.events.contains("willBeginDragging"))

        pan.stubbedState = .changed
        pan.stubbedTranslation = CGPoint(x: -120, y: 0)
        pan.stubbedVelocity = CGPoint(x: -600, y: 0)
        harness.carousel.handlePan(pan)

        XCTAssertEqual(harness.carousel.scrollOffset, 1.2, accuracy: 0.001)
        XCTAssertEqual(harness.carousel.currentItemIndex, 1)
        XCTAssertTrue(harness.delegate.events.contains("didScroll"))
        XCTAssertTrue(harness.delegate.events.contains("indexDidChange"))

        pan.stubbedState = .ended
        harness.carousel.handlePan(pan)

        XCTAssertFalse(harness.carousel.isDragging)
        XCTAssertTrue(harness.carousel.isDecelerating)
        XCTAssertTrue(harness.delegate.events.contains("didEndDragging:true"))
        XCTAssertTrue(harness.delegate.events.contains("willBeginDecelerating"))
    }

    func testVerticalDragUsesYTranslation() {
        let harness = CarouselHarness(items: 5, type: .linear)
        defer { harness.stop() }

        harness.carousel.isVertical = true

        let pan = makePan(state: .began)
        harness.carousel.handlePan(pan)

        pan.stubbedState = .changed
        pan.stubbedTranslation = CGPoint(x: -500, y: -100)
        harness.carousel.handlePan(pan)

        XCTAssertEqual(harness.carousel.scrollOffset, 1, accuracy: 0.001)
    }

    func testDragBeyondEndUsesBounceDistance() {
        let harness = CarouselHarness(items: 5, type: .linear)
        defer { harness.stop() }

        harness.carousel.bounces = true
        harness.carousel.bounceDistance = 1

        let pan = makePan(state: .began)
        harness.carousel.handlePan(pan)

        pan.stubbedState = .changed
        pan.stubbedTranslation = CGPoint(x: -1000, y: 0)
        harness.carousel.handlePan(pan)

        XCTAssertEqual(harness.carousel.scrollOffset, 5, accuracy: 0.001)
    }

    func testDecelerationDistanceAndBoundaryClamping() {
        let harness = CarouselHarness(items: 5, type: .linear)
        defer { harness.stop() }

        harness.carousel.scrollOffset = 0
        harness.carousel.startVelocity = 10
        XCTAssertTrue(harness.carousel.shouldDecelerate)
        XCTAssertGreaterThan(harness.carousel.decelerationDistance, 0)

        harness.carousel.startDecelerating()
        XCTAssertTrue(harness.carousel.isDecelerating)
        XCTAssertEqual(harness.carousel.endOffset, 4, accuracy: 0.001)

        harness.carousel.stopAnimation()
        harness.carousel.startTime = CACurrentMediaTime() - 10
        harness.carousel.step()

        XCTAssertFalse(harness.carousel.isDecelerating)
        XCTAssertEqual(harness.carousel.currentItemIndex, 4)
        XCTAssertTrue(harness.delegate.events.contains("didEndDecelerating"))
    }

    func testLowVelocityDoesNotDecelerate() {
        let harness = CarouselHarness(items: 5, type: .linear)
        defer { harness.stop() }

        harness.carousel.startVelocity = 1

        XCTAssertFalse(harness.carousel.shouldDecelerate)
        XCTAssertFalse(harness.carousel.shouldScroll)
    }

    func testGestureRecognizerRejectsPerpendicularSwipes() {
        let harness = CarouselHarness(items: 5, type: .linear)
        defer { harness.stop() }

        let horizontalData = makePan(translation: CGPoint(x: 40, y: 5))
        let verticalData = makePan(translation: CGPoint(x: 5, y: 40))

        XCTAssertTrue(harness.carousel.gestureRecognizerShouldBegin(horizontalData))
        XCTAssertFalse(harness.carousel.gestureRecognizerShouldBegin(verticalData))

        harness.carousel.isVertical = true

        XCTAssertFalse(harness.carousel.gestureRecognizerShouldBegin(horizontalData))
        XCTAssertTrue(harness.carousel.gestureRecognizerShouldBegin(verticalData))
    }

    func testTapSelectsTappedItem() {
        let harness = CarouselHarness(items: 5, type: .linear)
        defer { harness.stop() }

        let tap = StubTapGestureRecognizer(target: nil, action: nil)
        tap.stubbedLocation = CGPoint(x: harness.itemCenter.x + 100, y: harness.itemCenter.y)
        harness.carousel.handleTap(tap)

        XCTAssertEqual(harness.delegate.selectedIndex, 1)
        XCTAssertTrue(harness.delegate.events.contains("select:1"))
    }

    func testTapSelectionCanBeDeclined() {
        let harness = CarouselHarness(items: 5, type: .linear)
        defer { harness.stop() }

        harness.delegate.allowsSelection = false

        let tap = StubTapGestureRecognizer(target: nil, action: nil)
        tap.stubbedLocation = harness.itemCenter
        harness.carousel.handleTap(tap)

        XCTAssertNil(harness.delegate.selectedIndex)
    }

    func testAccessibilityIncrementAndDecrementAnimateToAdjacentItems() {
        let harness = CarouselHarness(items: 5, type: .linear)
        defer { harness.stop() }

        harness.carousel.accessibilityIncrement()
        XCTAssertTrue(harness.carousel.isScrolling)
        XCTAssertEqual(harness.carousel.endOffset, 1, accuracy: 0.001)

        harness.carousel.startTime = CACurrentMediaTime() - 1
        harness.carousel.step()

        XCTAssertEqual(harness.carousel.currentItemIndex, 1)
        XCTAssertFalse(harness.carousel.isScrolling)
        XCTAssertTrue(harness.delegate.events.contains("didEndScrollingAnimation"))

        harness.carousel.accessibilityDecrement()
        harness.carousel.startTime = CACurrentMediaTime() - 1
        harness.carousel.step()

        XCTAssertEqual(harness.carousel.currentItemIndex, 0)
    }

    func testAutoscrollMovesOffsetAtConfiguredSpeed() {
        let harness = CarouselHarness(items: 5, type: .linear)
        defer { harness.stop() }

        harness.carousel.scrollOffset = 2
        harness.carousel.autoscroll = 1
        harness.carousel.lastTime = CACurrentMediaTime() - 0.5
        harness.carousel.step()

        XCTAssertEqual(harness.carousel.scrollOffset, 1.5, accuracy: 0.05)
    }

    func testScrollAnimationCompletesAtRequestedItem() {
        let harness = CarouselHarness(items: 5, type: .linear)
        defer { harness.stop() }

        harness.carousel.scrollToItem(at: 3, duration: 0.2)
        XCTAssertTrue(harness.carousel.isScrolling)

        harness.carousel.startTime = CACurrentMediaTime() - 1
        harness.carousel.step()

        XCTAssertEqual(harness.carousel.currentItemIndex, 3)
        XCTAssertEqual(harness.carousel.scrollOffset, 3, accuracy: 0.001)
        XCTAssertFalse(harness.carousel.isScrolling)
        XCTAssertTrue(harness.delegate.events.contains("didEndScrollingAnimation"))
    }
}

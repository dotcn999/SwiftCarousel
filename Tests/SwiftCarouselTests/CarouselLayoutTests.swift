import QuartzCore
import UIKit
import XCTest

@testable import SwiftCarousel

@MainActor
final class CarouselLayoutTests: XCTestCase {

    private func makeHarness(type: CarouselType, items: Int = 12) -> CarouselHarness {
        CarouselHarness(items: items, type: type)
    }

    func testAllBuiltInLayoutsProduceFiniteTransforms() {
        for type in CarouselType.allCases where type != .custom {
            let harness = makeHarness(type: type)
            defer { harness.stop() }

            harness.carousel.scrollOffset = 1
            harness.carousel.layoutIfNeeded()
            harness.settleToggle()

            XCTAssertGreaterThan(harness.carousel.numberOfVisibleItems, 0, "\(type) has no visible items")
            XCTAssertFalse(harness.carousel.indexesForVisibleItems.isEmpty, "\(type) loaded no views")

            for index in harness.carousel.indexesForVisibleItems {
                guard let transform = harness.transform(at: index) else {
                    XCTFail("\(type) did not load item \(index)")
                    continue
                }
                XCTAssertTransformIsFinite(transform)
            }
        }
    }

    func testLinearTransformPositionsItemsAlongXAxis() {
        let harness = makeHarness(type: .linear)
        defer { harness.stop() }

        harness.carousel.scrollOffset = 1
        harness.carousel.layoutIfNeeded()
        harness.settleToggle()

        let transform = try! XCTUnwrap(harness.transform(at: 2))
        XCTAssertEqual(transform.m41, 100, accuracy: 0.001)
        XCTAssertEqual(transform.m42, 0, accuracy: 0.001)
        XCTAssertEqual(transform.m11, 1, accuracy: 0.001)
    }

    func testVerticalLinearTransformUsesYAxis() {
        let harness = makeHarness(type: .linear)
        defer { harness.stop() }

        harness.carousel.isVertical = true
        harness.carousel.scrollOffset = 1
        harness.carousel.layoutIfNeeded()
        harness.settleToggle()

        let transform = try! XCTUnwrap(harness.transform(at: 2))
        XCTAssertEqual(transform.m41, 0, accuracy: 0.001)
        XCTAssertEqual(transform.m42, 100, accuracy: 0.001)
    }

    func testSpacingOptionStretchesLinearLayout() {
        let harness = makeHarness(type: .linear)
        defer { harness.stop() }

        harness.delegate.optionValues[.spacing] = 2
        harness.carousel.reloadData()
        harness.carousel.scrollOffset = 1
        harness.carousel.layoutIfNeeded()
        harness.settleToggle()

        let transform = try! XCTUnwrap(harness.transform(at: 2))
        XCTAssertEqual(transform.m41, 200, accuracy: 0.001)
    }

    func testRotaryTransformCurvesItemsAwayFromViewer() {
        let harness = makeHarness(type: .rotary)
        defer { harness.stop() }

        harness.carousel.scrollOffset = 1
        harness.carousel.layoutIfNeeded()

        let transform = try! XCTUnwrap(harness.transform(at: 2))
        XCTAssertGreaterThan(transform.m41, 0)
        XCTAssertLessThan(transform.m43, 0)
        XCTAssertEqual(transform.m11, 1, accuracy: 0.001)
    }

    func testInvertedRotaryTransformCurvesItemsTowardsViewer() {
        let harness = makeHarness(type: .invertedRotary)
        defer { harness.stop() }

        harness.carousel.scrollOffset = 1
        harness.carousel.layoutIfNeeded()

        let transform = try! XCTUnwrap(harness.transform(at: 2))
        XCTAssertGreaterThan(transform.m41, 0)
        XCTAssertGreaterThan(transform.m43, 0)
    }

    func testCylinderTransformRotatesAroundItsAxis() {
        let harness = makeHarness(type: .cylinder)
        defer { harness.stop() }

        harness.carousel.scrollOffset = 1
        harness.carousel.layoutIfNeeded()
        harness.settleToggle()

        let transform = try! XCTUnwrap(harness.transform(at: 2))
        XCTAssertLessThan(abs(transform.m11), 0.95)
        XCTAssertGreaterThan(abs(transform.m13), 0.1)
        XCTAssertLessThan(transform.m43, 0)
    }

    func testInvertedCylinderMirrorsRotationDirection() {
        let normal = makeHarness(type: .cylinder)
        let inverted = makeHarness(type: .invertedCylinder)
        defer {
            normal.stop()
            inverted.stop()
        }

        normal.carousel.scrollOffset = 1
        inverted.carousel.scrollOffset = 1
        normal.carousel.layoutIfNeeded()
        inverted.carousel.layoutIfNeeded()
        normal.settleToggle()
        inverted.settleToggle()

        let normalTransform = try! XCTUnwrap(normal.transform(at: 2))
        let invertedTransform = try! XCTUnwrap(inverted.transform(at: 2))

        XCTAssertEqual(normalTransform.m11, invertedTransform.m11, accuracy: 0.001)
        XCTAssertLessThan(normalTransform.m13 * invertedTransform.m13, 0)
    }

    func testWheelTransformPlacesItemsOnCircle() {
        let harness = makeHarness(type: .wheel)
        defer { harness.stop() }

        harness.carousel.scrollOffset = 1
        harness.carousel.layoutIfNeeded()
        harness.settleToggle()

        let transform = try! XCTUnwrap(harness.transform(at: 2))
        XCTAssertGreaterThan(transform.m41, 0)
        XCTAssertGreaterThan(transform.m42, 0)
        XCTAssertEqual(transform.m43, 0.01, accuracy: 0.0001)
    }

    func testInvertedWheelMirrorsItemPosition() {
        let normal = makeHarness(type: .wheel)
        let inverted = makeHarness(type: .invertedWheel)
        defer {
            normal.stop()
            inverted.stop()
        }

        normal.carousel.scrollOffset = 1
        inverted.carousel.scrollOffset = 1
        normal.carousel.layoutIfNeeded()
        inverted.carousel.layoutIfNeeded()
        normal.settleToggle()
        inverted.settleToggle()

        let normalTransform = try! XCTUnwrap(normal.transform(at: 2))
        let invertedTransform = try! XCTUnwrap(inverted.transform(at: 2))

        XCTAssertGreaterThan(normalTransform.m41, 0)
        XCTAssertGreaterThan(invertedTransform.m41, 0)
        XCTAssertGreaterThan(normalTransform.m42, 0)
        XCTAssertLessThan(invertedTransform.m42, 0)
    }

    func testCoverFlowTransformTiltsAndRecedesSideItems() {
        let harness = makeHarness(type: .coverFlow)
        defer { harness.stop() }

        harness.carousel.scrollOffset = 1
        harness.carousel.layoutIfNeeded()
        harness.settleToggle()

        let transform = try! XCTUnwrap(harness.transform(at: 2))
        XCTAssertLessThan(transform.m11, 0.3)
        XCTAssertGreaterThan(abs(transform.m13), 0.5)
        XCTAssertLessThan(transform.m43, 0)
        XCTAssertGreaterThan(transform.m41, 50)
    }

    func testTimeMachineTransformRecedesSideItems() {
        let harness = makeHarness(type: .timeMachine)
        defer { harness.stop() }

        harness.carousel.scrollOffset = 1
        harness.carousel.layoutIfNeeded()
        harness.settleToggle()

        let transform = try! XCTUnwrap(harness.transform(at: 0))
        XCTAssertEqual(transform.m41, -30, accuracy: 0.001)
        XCTAssertEqual(transform.m43, -100, accuracy: 0.001)
        XCTAssertEqual(transform.m11, 1, accuracy: 0.001)
    }

    func testInvertedTimeMachineMirrorsSideItemTransform() {
        let harness = makeHarness(type: .invertedTimeMachine)
        defer { harness.stop() }

        harness.carousel.scrollOffset = 1
        harness.carousel.layoutIfNeeded()
        harness.settleToggle()

        let transform = try! XCTUnwrap(harness.transform(at: 2))
        XCTAssertEqual(transform.m41, 30, accuracy: 0.001)
        XCTAssertEqual(transform.m43, -100, accuracy: 0.001)
    }

    func testCustomLayoutUsesDelegateTransform() {
        let harness = makeHarness(type: .custom)
        defer { harness.stop() }

        harness.delegate.customTransform = { offset, base in
            CATransform3DTranslate(base, offset * 42, 0, 0)
        }
        harness.carousel.reloadData()
        harness.carousel.scrollOffset = 1
        harness.carousel.layoutIfNeeded()
        harness.settleToggle()

        let transform = try! XCTUnwrap(harness.transform(at: 2))
        XCTAssertEqual(transform.m41, 42, accuracy: 0.001)
    }

    func testTimeMachineFadesItemsBehindViewer() {
        let harness = makeHarness(type: .timeMachine)
        defer { harness.stop() }

        harness.carousel.scrollOffset = 1
        harness.carousel.layoutIfNeeded()

        XCTAssertEqual(harness.carousel.alphaForItem(withOffset: 1), 0, accuracy: 0.001)
    }

    func testWrapOptionDisablesWrappingForCircularLayout() {
        let harness = makeHarness(type: .cylinder)
        defer { harness.stop() }

        XCTAssertTrue(harness.carousel.isWrapEnabled)

        harness.delegate.optionValues[.wrap] = 0
        harness.carousel.reloadData()

        XCTAssertFalse(harness.carousel.isWrapEnabled)
    }

    func testVisibleItemsOptionOverridesComputedCount() {
        let harness = makeHarness(type: .linear)
        defer { harness.stop() }

        harness.delegate.optionValues[.visibleItems] = 3
        harness.carousel.reloadData()

        XCTAssertEqual(harness.carousel.numberOfVisibleItems, 3)
    }

    func testCenterItemUsesIdentityTranslation() {
        for type in CarouselType.allCases where type != .custom {
            let harness = makeHarness(type: type)
            defer { harness.stop() }

            harness.carousel.scrollOffset = 1
            harness.carousel.layoutIfNeeded()
            harness.settleToggle()

            let transform = try! XCTUnwrap(harness.transform(at: 1))
            XCTAssertEqual(transform.m41, 0, accuracy: 0.01, "\(type) center item is offset on x")
            XCTAssertEqual(transform.m42, 0, accuracy: 0.01, "\(type) center item is offset on y")
        }
    }
}

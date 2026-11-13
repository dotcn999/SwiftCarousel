import UIKit
import XCTest

@testable import SwiftCarousel

@MainActor
final class CarouselViewTests: XCTestCase {
    @MainActor
    final class StubDataSource: CarouselDataSource {
        var itemCount = 5
        var placeholderCount = 0

        func numberOfItems(in carousel: CarouselView) -> Int {
            itemCount
        }

        func carousel(_ carousel: CarouselView, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
            let itemView = view ?? UIView()
            itemView.frame = CGRect(x: 0, y: 0, width: 100, height: 150)
            return itemView
        }

        func numberOfPlaceholders(in carousel: CarouselView) -> Int {
            placeholderCount
        }

        func carousel(_ carousel: CarouselView, placeholderViewAt index: Int, reusing view: UIView?) -> UIView {
            let placeholder = view ?? UIView()
            placeholder.frame = CGRect(x: 0, y: 0, width: 100, height: 150)
            return placeholder
        }
    }

    private var retainedDataSources: [StubDataSource] = []

    private func makeCarousel(
        items: Int = 5,
        type: CarouselType = .linear,
        placeholders: Int = 0
    ) -> (carousel: CarouselView, dataSource: StubDataSource) {
        let dataSource = StubDataSource()
        dataSource.itemCount = items
        dataSource.placeholderCount = placeholders
        retainedDataSources.append(dataSource)

        let carousel = CarouselView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        carousel.bounces = false
        carousel.dataSource = dataSource
        carousel.type = type
        carousel.layoutIfNeeded()

        return (carousel, dataSource)
    }

    func testLinearLayoutLoadsItems() {
        let (carousel, _) = makeCarousel(items: 5)

        XCTAssertEqual(carousel.numberOfItems, 5)
        XCTAssertEqual(carousel.itemWidth, 100)
        XCTAssertFalse(carousel.isWrapEnabled)
        XCTAssertGreaterThan(carousel.numberOfVisibleItems, 0)
        XCTAssertNotNil(carousel.itemView(at: 0))
        XCTAssertEqual(carousel.currentItemIndex, 0)
    }

    func testCircularTypesWrapByDefault() {
        let (carousel, _) = makeCarousel(items: 5, type: .cylinder)
        XCTAssertTrue(carousel.isWrapEnabled)

        carousel.type = .linear
        XCTAssertFalse(carousel.isWrapEnabled)
    }

    func testWrappedOffsetsUseShortestDistance() {
        let (carousel, _) = makeCarousel(items: 5, type: .cylinder)

        XCTAssertEqual(carousel.offsetForItem(at: 0), 0, accuracy: 0.000001)
        XCTAssertEqual(carousel.offsetForItem(at: 2), 2, accuracy: 0.000001)
        XCTAssertEqual(carousel.offsetForItem(at: 4), -1, accuracy: 0.000001)

        carousel.scrollOffset = 2

        XCTAssertEqual(carousel.offsetForItem(at: 2), 0, accuracy: 0.000001)
        XCTAssertEqual(carousel.offsetForItem(at: 0), -2, accuracy: 0.000001)
        XCTAssertEqual(carousel.offsetForItem(at: 4), 2, accuracy: 0.000001)
    }

    func testNonWrappedOffsetsClampWithoutBounce() {
        let (carousel, _) = makeCarousel(items: 5, type: .linear)

        carousel.scrollOffset = 10
        XCTAssertEqual(carousel.scrollOffset, 4, accuracy: 0.000001)
        XCTAssertEqual(carousel.currentItemIndex, 4)

        carousel.scrollOffset = -3
        XCTAssertEqual(carousel.scrollOffset, 0, accuracy: 0.000001)
        XCTAssertEqual(carousel.currentItemIndex, 0)
    }

    func testInsertAndRemoveUpdateItemCount() {
        let (carousel, _) = makeCarousel(items: 5, type: .linear)

        carousel.insertItem(at: 2, animated: false)
        XCTAssertEqual(carousel.numberOfItems, 6)

        carousel.removeItem(at: 2, animated: false)
        XCTAssertEqual(carousel.numberOfItems, 5)
    }

    func testPlaceholdersAreLoadedForNonWrappedCarousel() {
        let (carousel, _) = makeCarousel(items: 5, type: .linear, placeholders: 2)

        XCTAssertEqual(carousel.numberOfPlaceholders, 2)
        XCTAssertTrue(carousel.indexesForVisibleItems.contains(-1))
    }

    func testReloadDataReflectsNewItemCount() {
        let (carousel, dataSource) = makeCarousel(items: 5, type: .linear)

        dataSource.itemCount = 3
        carousel.reloadData()

        XCTAssertEqual(carousel.numberOfItems, 3)
        XCTAssertNotNil(carousel.itemView(at: 0))
    }
}

import XCTest

@MainActor
final class SwiftCarouselDemoUITests: XCTestCase {
    func testSwipeChangesCurrentIndex() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoType", "0", "-demoIndex", "3"]
        app.launch()

        let indexLabel = app.staticTexts["currentIndexLabel"]
        XCTAssertTrue(indexLabel.waitForExistence(timeout: 10))
        let initialIndex = indexLabel.label

        let carousel = app.otherElements["carouselView"]
        XCTAssertTrue(carousel.waitForExistence(timeout: 5))
        carousel.swipeLeft()

        let changed = NSPredicate { object, _ in
            (object as? XCUIElement)?.label != initialIndex
        }
        expectation(for: changed, evaluatedWith: indexLabel)
        waitForExpectations(timeout: 6)
    }

    func testLaunchAllCarouselTypes() {
        for rawValue in 0...10 {
            let app = XCUIApplication()
            app.launchArguments = ["-demoType", "\(rawValue)", "-demoIndex", "4"]
            app.launch()

            XCTAssertTrue(app.staticTexts["currentIndexLabel"].waitForExistence(timeout: 10))
            XCTAssertTrue(app.otherElements["carouselView"].waitForExistence(timeout: 5))

            app.terminate()
        }
    }
}

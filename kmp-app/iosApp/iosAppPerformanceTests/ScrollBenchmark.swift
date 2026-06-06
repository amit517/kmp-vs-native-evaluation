import XCTest

final class ScrollBenchmark: BasePerformanceTest {

    override func setUp() {
        super.setUp()
        app.launch()
        waitForArticleListLoaded()
    }

    func testScrollPerformance() throws {
        let scrollable = findScrollableElement()
        XCTAssertTrue(scrollable.exists, "Scrollable article list should exist")

        let options = XCTMeasureOptions()
        options.iterationCount = 50

        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric], options: options) {
            scrollable.swipeUp(velocity: .default)
        }
    }

    func testFastScrollStress() throws {
        let scrollable = findScrollableElement()
        XCTAssertTrue(scrollable.exists, "Scrollable article list should exist")

        let options = XCTMeasureOptions()
        options.iterationCount = 30

        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric], options: options) {
            scrollable.swipeUp(velocity: .fast)
            scrollable.swipeUp(velocity: .fast)
            scrollable.swipeUp(velocity: .fast)
            scrollable.swipeDown(velocity: .fast)
            scrollable.swipeDown(velocity: .fast)
            scrollable.swipeDown(velocity: .fast)
        }
    }
}

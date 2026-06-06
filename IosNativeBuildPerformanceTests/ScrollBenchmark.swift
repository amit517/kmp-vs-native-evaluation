import XCTest

final class ScrollBenchmark: BasePerformanceTest {

    override func setUp() {
        super.setUp()
        app.launch()
        waitForArticleListLoaded()
    }

    func testScrollPerformance() throws {
        let scrollView = app.scrollViews[TestConstants.Identifiers.newsListScrollView]
        XCTAssertTrue(scrollView.exists)

        let options = XCTMeasureOptions()
        options.iterationCount = 50

        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric], options: options) {
            scrollView.swipeUp(velocity: .default)
        }
    }

    func testFastScrollStress() throws {
        let scrollView = app.scrollViews[TestConstants.Identifiers.newsListScrollView]
        XCTAssertTrue(scrollView.exists)

        let options = XCTMeasureOptions()
        options.iterationCount = 30

        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric], options: options) {
            scrollView.swipeUp(velocity: .fast)
            scrollView.swipeUp(velocity: .fast)
            scrollView.swipeUp(velocity: .fast)
            scrollView.swipeDown(velocity: .fast)
            scrollView.swipeDown(velocity: .fast)
            scrollView.swipeDown(velocity: .fast)
        }
    }
}

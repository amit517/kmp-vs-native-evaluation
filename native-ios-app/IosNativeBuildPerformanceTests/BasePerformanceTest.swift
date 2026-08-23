import XCTest

class BasePerformanceTest: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["BENCHMARK_MODE"]
        app.launchEnvironment["BENCHMARK_MODE"] = "1"
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    /// Metric set for scroll benchmarks. Kept byte-identical to the KMP harness
    /// so the two suites stay comparable.
    ///
    /// XCTHitchMetric measures frame hitches in the target process, so it reports
    /// on Compose/Skia and UIKit alike — unlike scrollingAndDecelerationMetric,
    /// which needs a UIScrollView signpost Compose never emits.
    func scrollMetrics() -> [XCTMetric] {
        var metrics: [XCTMetric] = [XCTClockMetric()]
        if #available(iOS 26.0, *) {
            metrics.append(XCTHitchMetric(application: app))
        }
        return metrics
    }

    func waitForArticleListLoaded() {
        let scrollView = app.scrollViews[TestConstants.Identifiers.newsListScrollView]
        let exists = scrollView.waitForExistence(timeout: TestConstants.contentLoadTimeout)
        XCTAssertTrue(exists, "Article list scroll view should appear")
        sleep(1)
    }
}

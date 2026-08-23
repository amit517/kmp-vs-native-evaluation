import XCTest

final class NetworkDatabaseBenchmark: BasePerformanceTest {

    func testInitialDataLoad() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 30

        measure(metrics: [XCTClockMetric()], options: options) {
            app.launch()
            let scrollView = app.scrollViews[TestConstants.Identifiers.newsListScrollView]
            let appeared = scrollView.waitForExistence(timeout: TestConstants.contentLoadTimeout)
            XCTAssertTrue(appeared)
            app.terminate()
        }
    }

    // Settle time sits outside startMeasuring/stopMeasuring so it is not part of
    // the metric. Structure kept identical to the KMP suite.
    func testCategoryFilterPerformance() throws {
        app.launch()
        waitForArticleListLoaded()

        let techChip = app.buttons[TestConstants.Identifiers.categoryChip("TECHNOLOGY")]
        let allChip = app.buttons[TestConstants.Identifiers.categoryChip("ALL")]
        XCTAssertTrue(techChip.waitForExistence(timeout: TestConstants.defaultTimeout))
        XCTAssertTrue(allChip.exists)

        let options = XCTMeasureOptions()
        options.iterationCount = 50
        options.invocationOptions = [.manuallyStart, .manuallyStop]

        measure(metrics: [XCTClockMetric()], options: options) {
            startMeasuring()
            techChip.tap()
            _ = app.scrollViews[TestConstants.Identifiers.newsListScrollView]
                .waitForExistence(timeout: TestConstants.defaultTimeout)
            stopMeasuring()

            // Reset to the unfiltered list for the next iteration, unmeasured.
            allChip.tap()
            sleep(1)
        }
    }

    func testSearchPerformance() throws {
        app.launch()
        waitForArticleListLoaded()

        let searchButton = app.buttons[TestConstants.Identifiers.searchButton]
        XCTAssertTrue(searchButton.waitForExistence(timeout: TestConstants.defaultTimeout))
        searchButton.tap()

        let searchField = app.textFields[TestConstants.Identifiers.searchTextField]
        XCTAssertTrue(searchField.waitForExistence(timeout: TestConstants.defaultTimeout))

        let query = "Technology"
        let options = XCTMeasureOptions()
        options.iterationCount = 50
        options.invocationOptions = [.manuallyStart, .manuallyStop]

        measure(metrics: [XCTClockMetric()], options: options) {
            startMeasuring()
            searchField.tap()
            searchField.typeText(query)
            _ = app.scrollViews[TestConstants.Identifiers.newsListScrollView]
                .waitForExistence(timeout: TestConstants.defaultTimeout)
            stopMeasuring()

            // Every iteration must search the same query, so assert the field
            // holds exactly it — a dropped keystroke would otherwise vary the
            // workload silently from one iteration to the next.
            XCTAssertEqual(searchField.value as? String, query,
                           "search field drifted; iterations would not be comparable")

            // Verified clear, outside the measured interval.
            searchField.clearText()
        }
    }

    // Android's imageLoading metric is a frame count, so pair the clock with
    // frame-hitch data rather than timing a hardcoded sleep.
    func testImageLoadingPerformance() throws {
        app.launch()
        waitForArticleListLoaded()

        let scrollView = app.scrollViews[TestConstants.Identifiers.newsListScrollView]

        let options = XCTMeasureOptions()
        options.iterationCount = 30
        options.invocationOptions = [.manuallyStart, .manuallyStop]

        measure(metrics: scrollMetrics(), options: options) {
            startMeasuring()
            scrollView.swipeUp(velocity: .slow)
            scrollView.swipeDown(velocity: .slow)
            stopMeasuring()

            // Let images settle before the next iteration, unmeasured.
            sleep(2)
        }
    }
}

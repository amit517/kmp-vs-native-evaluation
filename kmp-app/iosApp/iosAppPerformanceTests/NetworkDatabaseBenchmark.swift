import XCTest

final class NetworkDatabaseBenchmark: BasePerformanceTest {

    // Measures launch -> article list visible -> terminate. With the single
    // direct otherElements lookup this is real load time; the previous 23.3 s
    // (CV 0.26 %) was the 3-tier lookup's fixed 22 s of timeout.
    func testInitialDataLoad() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 30

        measure(metrics: [XCTClockMetric()], options: options) {
            app.launch()
            let appeared = waitForElement(identifier: TestConstants.Identifiers.articleList,
                                          timeout: TestConstants.contentLoadTimeout)
            XCTAssertTrue(appeared)
            app.terminate()
        }
    }

    // Identifier lookups, not hardcoded coordinates: testTag maps to
    // accessibilityIdentifier and surfaces via otherElements. Settle time sits
    // outside startMeasuring/stopMeasuring so it is not part of the metric.
    func testCategoryFilterPerformance() throws {
        app.launch()
        waitForArticleListLoaded()

        let techChip = button(TestConstants.Identifiers.technologyCategoryChip)
        let allChip = button(TestConstants.Identifiers.allCategoryChip)
        XCTAssertTrue(techChip.waitForExistence(timeout: TestConstants.defaultTimeout))
        XCTAssertTrue(allChip.exists)

        let options = XCTMeasureOptions()
        options.iterationCount = 50
        options.invocationOptions = [.manuallyStart, .manuallyStop]

        measure(metrics: [XCTClockMetric()], options: options) {
            startMeasuring()
            techChip.tap()
            _ = element(TestConstants.Identifiers.articleList)
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

        // The field lives inside `if (showSearchBar)`, so open the search bar
        // first. The toolbar icon has only contentDescription = "Search", no
        // testTag, so it is addressed by label.
        let searchIcon = app.buttons["Search"]
        XCTAssertTrue(searchIcon.waitForExistence(timeout: TestConstants.defaultTimeout))
        searchIcon.tap()

        let searchField = textView(TestConstants.Identifiers.searchField)
        XCTAssertTrue(searchField.waitForExistence(timeout: TestConstants.defaultTimeout),
                      "Compose search field should be addressable by testTag")

        let query = "Technology"
        let options = XCTMeasureOptions()
        options.iterationCount = 50
        options.invocationOptions = [.manuallyStart, .manuallyStop]

        measure(metrics: [XCTClockMetric()], options: options) {
            startMeasuring()
            searchField.tap()
            searchField.typeText(query)
            _ = element(TestConstants.Identifiers.articleList)
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

        let scrollable = findScrollableElement()

        let options = XCTMeasureOptions()
        options.iterationCount = 30
        options.invocationOptions = [.manuallyStart, .manuallyStop]

        measure(metrics: scrollMetrics(), options: options) {
            startMeasuring()
            scrollable.swipeUp(velocity: .slow)
            scrollable.swipeDown(velocity: .slow)
            stopMeasuring()

            // Let images settle before the next iteration, unmeasured.
            sleep(2)
        }
    }
}

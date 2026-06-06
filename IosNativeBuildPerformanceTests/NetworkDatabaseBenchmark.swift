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

    func testCategoryFilterPerformance() throws {
        app.launch()
        waitForArticleListLoaded()

        let options = XCTMeasureOptions()
        options.iterationCount = 50

        measure(metrics: [XCTClockMetric()], options: options) {
            let techChip = app.buttons[TestConstants.Identifiers.categoryChip("TECHNOLOGY")]
            if techChip.waitForExistence(timeout: 5) {
                techChip.tap()
                sleep(1)
            }
            let allChip = app.buttons[TestConstants.Identifiers.categoryChip("ALL")]
            if allChip.waitForExistence(timeout: 5) {
                allChip.tap()
                sleep(1)
            }
        }
    }

    func testSearchPerformance() throws {
        app.launch()
        waitForArticleListLoaded()

        let searchButton = app.buttons[TestConstants.Identifiers.searchButton]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 5))
        searchButton.tap()
        sleep(1)

        let searchField = app.textFields[TestConstants.Identifiers.searchTextField]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        let options = XCTMeasureOptions()
        options.iterationCount = 50

        measure(metrics: [XCTClockMetric()], options: options) {
            searchField.tap()
            searchField.typeText("Technology")
            sleep(1)
            searchField.clearText()
            sleep(1)
        }
    }

    func testImageLoadingPerformance() throws {
        app.launch()
        waitForArticleListLoaded()

        let scrollView = app.scrollViews[TestConstants.Identifiers.newsListScrollView]

        let options = XCTMeasureOptions()
        options.iterationCount = 30

        measure(metrics: [XCTClockMetric()], options: options) {
            scrollView.swipeUp(velocity: .slow)
            sleep(2)
            scrollView.swipeDown(velocity: .slow)
            sleep(1)
        }
    }
}

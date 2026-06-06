import XCTest

final class NetworkDatabaseBenchmark: BasePerformanceTest {

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

    func testCategoryFilterPerformance() throws {
        app.launch()
        waitForArticleListLoaded()

        let options = XCTMeasureOptions()
        options.iterationCount = 50

        measure(metrics: [XCTClockMetric()], options: options) {
            let techChipCoord = CGPoint(x: 120, y: 110)
            app.coordinate(withNormalizedOffset: CGVector(dx: techChipCoord.x / app.frame.width,
                                                          dy: techChipCoord.y / app.frame.height)).tap()
            sleep(1)

            let allChipCoord = CGPoint(x: 50, y: 110)
            app.coordinate(withNormalizedOffset: CGVector(dx: allChipCoord.x / app.frame.width,
                                                          dy: allChipCoord.y / app.frame.height)).tap()
            sleep(1)
        }
    }

    func testSearchPerformance() throws {
        app.launch()
        waitForArticleListLoaded()

        let searchIconCoord = CGPoint(x: app.frame.width - 50, y: 44)
        app.coordinate(withNormalizedOffset: CGVector(dx: searchIconCoord.x / app.frame.width,
                                                      dy: searchIconCoord.y / app.frame.height)).tap()
        sleep(1)

        let options = XCTMeasureOptions()
        options.iterationCount = 50

        measure(metrics: [XCTClockMetric()], options: options) {
            let searchFieldCoord = CGPoint(x: app.frame.width / 2, y: 90)
            
            app.coordinate(withNormalizedOffset: CGVector(dx: searchFieldCoord.x / app.frame.width,
                                                          dy: searchFieldCoord.y / app.frame.height)).tap()
            usleep(500_000)
            
            app.typeText("Technology")
            sleep(1)
            
            app.typeText(XCUIKeyboardKey.selectAll.rawValue)
            usleep(200_000)
            app.typeText(XCUIKeyboardKey.delete.rawValue)
            sleep(1)
        }
    }

    func testImageLoadingPerformance() throws {
        app.launch()
        waitForArticleListLoaded()

        let scrollable = findScrollableElement()

        let options = XCTMeasureOptions()
        options.iterationCount = 30

        measure(metrics: [XCTClockMetric()], options: options) {
            scrollable.swipeUp(velocity: .slow)
            sleep(2)
            scrollable.swipeDown(velocity: .slow)
            sleep(1)
        }
    }
}

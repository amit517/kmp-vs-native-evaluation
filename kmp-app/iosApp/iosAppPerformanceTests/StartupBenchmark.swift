import XCTest

final class StartupBenchmark: BasePerformanceTest {

    func testColdStartup() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 30

        measure(metrics: [XCTOSSignpostMetric.applicationLaunch], options: options) {
            app.launch()
            _ = waitForElement(identifier: TestConstants.Identifiers.articleList,
                               timeout: TestConstants.contentLoadTimeout)
            app.terminate()
        }
    }

    func testWarmStartup() throws {
        app.launch()
        waitForArticleListLoaded()

        let options = XCTMeasureOptions()
        options.iterationCount = 50

        measure(metrics: [XCTOSSignpostMetric.applicationLaunch], options: options) {
            XCUIDevice.shared.press(.home)
            sleep(1)
            app.activate()
            _ = waitForElement(identifier: TestConstants.Identifiers.articleList,
                               timeout: TestConstants.defaultTimeout)
        }
    }

    func testHotStartup() throws {
        app.launch()
        waitForArticleListLoaded()

        let options = XCTMeasureOptions()
        options.iterationCount = 50

        measure(metrics: [XCTOSSignpostMetric.applicationLaunch], options: options) {
            XCUIDevice.shared.press(.home)
            usleep(500_000)
            app.activate()
            _ = waitForElement(identifier: TestConstants.Identifiers.articleList,
                               timeout: TestConstants.defaultTimeout)
        }
    }
}

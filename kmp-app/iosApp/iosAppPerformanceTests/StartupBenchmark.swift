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

    // applicationLaunch needs a real process launch; activate() never emits that
    // signpost. Clock-measure activate() -> content visible instead.
    func testWarmStartup() throws {
        app.launch()
        waitForArticleListLoaded()

        let options = XCTMeasureOptions()
        options.iterationCount = 50
        options.invocationOptions = [.manuallyStart, .manuallyStop]

        measure(metrics: [XCTClockMetric()], options: options) {
            XCUIDevice.shared.press(.home)
            sleep(1)
            startMeasuring()
            app.activate()
            _ = waitForElement(identifier: TestConstants.Identifiers.articleList,
                               timeout: TestConstants.defaultTimeout)
            stopMeasuring()
        }
    }

    func testHotStartup() throws {
        app.launch()
        waitForArticleListLoaded()

        let options = XCTMeasureOptions()
        options.iterationCount = 50
        options.invocationOptions = [.manuallyStart, .manuallyStop]

        measure(metrics: [XCTClockMetric()], options: options) {
            XCUIDevice.shared.press(.home)
            usleep(500_000)
            startMeasuring()
            app.activate()
            _ = waitForElement(identifier: TestConstants.Identifiers.articleList,
                               timeout: TestConstants.defaultTimeout)
            stopMeasuring()
        }
    }
}

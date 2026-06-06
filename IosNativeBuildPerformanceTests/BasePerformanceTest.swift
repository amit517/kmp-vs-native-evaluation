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

    func waitForArticleListLoaded() {
        let scrollView = app.scrollViews[TestConstants.Identifiers.newsListScrollView]
        let exists = scrollView.waitForExistence(timeout: TestConstants.contentLoadTimeout)
        XCTAssertTrue(exists, "Article list scroll view should appear")
        sleep(1)
    }
}

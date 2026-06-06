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

    /// Waits for the article list to appear in the Compose Multiplatform UI.
    /// Compose testTag("article_list") maps to an accessibility identifier.
    /// Tries multiple XCTest element types since Compose renders via UIKit.
    func waitForArticleListLoaded() {
        let appeared = waitForElement(identifier: TestConstants.Identifiers.articleList,
                                      timeout: TestConstants.contentLoadTimeout)
        XCTAssertTrue(appeared, "Article list should appear within \(TestConstants.contentLoadTimeout)s")
        sleep(1)
    }

    /// Finds a Compose element by its testTag accessibility identifier.
    /// Compose Multiplatform on iOS renders into UIKit views, so the element type
    /// varies — try scrollViews, otherElements, and generic descendants.
    func findElement(identifier: String) -> XCUIElement {
        // Try scrollViews first (LazyColumn renders as scrollable)
        let scrollView = app.scrollViews[identifier]
        if scrollView.exists { return scrollView }

        // Try other element types
        let other = app.otherElements[identifier]
        if other.exists { return other }

        // Fallback: search all descendants
        let descendant = app.descendants(matching: .any)[identifier]
        return descendant
    }

    /// Waits for a Compose element to appear, trying multiple element types.
    func waitForElement(identifier: String, timeout: TimeInterval) -> Bool {
        // Try scrollViews first
        let scrollView = app.scrollViews[identifier]
        if scrollView.waitForExistence(timeout: timeout) { return true }

        // Try other elements with remaining time
        let other = app.otherElements[identifier]
        if other.waitForExistence(timeout: 2) { return true }

        // Last resort: any descendant
        let descendant = app.descendants(matching: .any)[identifier]
        return descendant.waitForExistence(timeout: 2)
    }

    /// Returns a scrollable element for swipe gestures.
    /// For Compose Multiplatform, the LazyColumn with testTag should be scrollable.
    func findScrollableElement() -> XCUIElement {
        let byId = app.scrollViews[TestConstants.Identifiers.articleList]
        if byId.exists { return byId }

        // Compose may render the scrollable content as a generic element
        let other = app.otherElements[TestConstants.Identifiers.articleList]
        if other.exists { return other }

        // Fallback: first scrollable view in the hierarchy
        let firstScroll = app.scrollViews.firstMatch
        if firstScroll.exists { return firstScroll }

        return app.descendants(matching: .any)[TestConstants.Identifiers.articleList]
    }
}

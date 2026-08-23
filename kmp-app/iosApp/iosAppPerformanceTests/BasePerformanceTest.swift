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

    /// Metric set for scroll benchmarks. Kept byte-identical to the native harness
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

    /// Waits for the article list to appear in the Compose Multiplatform UI.
    /// Compose testTag("article_list") maps to an accessibility identifier.
    /// Tries multiple XCTest element types since Compose renders via UIKit.
    func waitForArticleListLoaded() {
        let appeared = waitForElement(identifier: TestConstants.Identifiers.articleList,
                                      timeout: TestConstants.contentLoadTimeout)
        XCTAssertTrue(appeared, "Article list should appear within \(TestConstants.contentLoadTimeout)s")
        sleep(1)
    }

    /// Single direct lookup, mirroring the native harness.
    ///
    /// Compose Multiplatform does map testTag -> accessibilityIdentifier, but a
    /// tagged LazyColumn surfaces as `otherElements`, never `scrollViews`
    /// (verified on device: scrollViews[article_list].exists == false, while
    /// otherElements[article_list].exists == true). The old 3-tier fallback
    /// queried scrollViews first, so it burned its full 20 s timeout every
    /// iteration before falling through — that, not data loading, is what the
    /// 23.3 s initialDataLoad figure measured.
    /// Verified on device via AccessibilityDump — Compose testTags surface as:
    ///   LazyColumn      -> otherElements   (never scrollViews)
    ///   FilterChip/Card -> buttons         (semantics merged with the role)
    ///   OutlinedTextField -> textViews     (not textFields)
    func element(_ identifier: String) -> XCUIElement {
        app.otherElements[identifier]
    }

    func button(_ identifier: String) -> XCUIElement {
        app.buttons[identifier]
    }

    func textView(_ identifier: String) -> XCUIElement {
        app.textViews[identifier]
    }

    func waitForElement(identifier: String, timeout: TimeInterval) -> Bool {
        element(identifier).waitForExistence(timeout: timeout)
    }

    /// The tagged list region is itself swipeable; no hierarchy walk needed.
    /// The old `descendants(matching: .any)` fallback is what made
    /// scroll_performance take 4 h 57 m for 50 swipes.
    func findScrollableElement() -> XCUIElement {
        element(TestConstants.Identifiers.articleList)
    }
}

import XCTest

/// Diagnostic only — not a benchmark.
///
/// KMP measured 0.53 s per swipe against native's 2.59 s. XCUITest derives swipe
/// distance from the target element's bounds, and the two harnesses swipe
/// different element types (KMP: otherElements[article_list] at 393x631;
/// native: scrollViews[news_list_scroll_view]). If the native element is much
/// taller, the gap is swipe geometry, not framework performance.
final class ScrollGeometryDiagnostic: BasePerformanceTest {

    func testReportScrollGeometry() throws {
        app.launch()
        waitForArticleListLoaded()

        let scrollView = app.scrollViews[TestConstants.Identifiers.newsListScrollView]
        XCTAssertTrue(scrollView.waitForExistence(timeout: TestConstants.defaultTimeout))
        print("=== NATIVE scrollViews['\(TestConstants.Identifiers.newsListScrollView)'] frame = \(scrollView.frame) ===")
        print("=== app.frame = \(app.frame) ===")

        // Time a single swipe on the same element the benchmark uses.
        for i in 1...3 {
            let t0 = Date()
            scrollView.swipeUp(velocity: .default)
            print("=== swipe \(i) on scrollView took \(Date().timeIntervalSince(t0)) s ===")
        }

        // Same gesture on a region matching KMP's element height, to separate
        // gesture geometry from rendering cost.
        for i in 1...3 {
            let t0 = Date()
            app.otherElements.firstMatch.swipeUp(velocity: .default)
            print("=== swipe \(i) on otherElements.firstMatch took \(Date().timeIntervalSince(t0)) s ===")
        }
    }
}

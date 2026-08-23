import XCTest

/// Diagnostic only — not a benchmark.
///
/// The search field accumulated residue across iterations ("TeTeTeTechnology"),
/// which meant the search benchmark was measuring a query that grew every
/// iteration. This observes what `value` actually reports at each stage so the
/// clear step can be made deterministic instead of assumed.
final class SearchFieldDiagnostic: BasePerformanceTest {

    private func show(_ stage: String, _ field: XCUIElement) {
        let v = field.value as? String
        print("    [\(stage)] value=\(v.map { "'\($0)'" } ?? "nil") label='\(field.label)'")
    }

    func testSearchFieldClearBehaviour() throws {
        app.launch()
        waitForArticleListLoaded()

        let searchIcon = app.buttons["Search"]
        XCTAssertTrue(searchIcon.waitForExistence(timeout: TestConstants.defaultTimeout))
        searchIcon.tap()

        let field = textView(TestConstants.Identifiers.searchField)
        XCTAssertTrue(field.waitForExistence(timeout: TestConstants.defaultTimeout))

        let query = "Technology"
        show("empty", field)

        for round in 1...3 {
            print("=== ROUND \(round) ===")
            field.tap()
            field.typeText(query)
            sleep(1)
            show("after type", field)

            // The current one-shot clear, so its failure mode is visible.
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue,
                                  count: query.count))
            sleep(1)
            show("after \(query.count) deletes", field)
        }

        print("=== NOW TRY VERIFIED CLEAR ===")
        for attempt in 1...12 {
            guard let v = field.value as? String, !v.isEmpty, v != "Search articles..." else {
                print("    cleared after \(attempt - 1) extra deletes")
                break
            }
            field.typeText(XCUIKeyboardKey.delete.rawValue)
            usleep(150_000)
        }
        show("final", field)
    }
}

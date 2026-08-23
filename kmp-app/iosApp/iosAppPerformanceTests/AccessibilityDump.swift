import XCTest

/// Diagnostic only — not a benchmark.
///
/// Compose Multiplatform has no iOS equivalent of Android's
/// `testTagsAsResourceId`, so what `testTag(...)` actually surfaces as to
/// XCUITest has to be observed rather than assumed.
final class AccessibilityDump: BasePerformanceTest {

    private func probe(_ label: String, _ identifier: String) {
        let queries: [(String, XCUIElementQuery)] = [
            ("otherElements", app.otherElements),
            ("buttons", app.buttons),
            ("textFields", app.textFields),
            ("staticTexts", app.staticTexts),
            ("scrollViews", app.scrollViews),
        ]
        var hits: [String] = []
        for (name, q) in queries where q[identifier].exists {
            hits.append(name)
        }
        print("=== PROBE \(label) '\(identifier)' -> \(hits.isEmpty ? "NOWHERE" : hits.joined(separator: ",")) ===")
    }

    func testDumpHierarchy() throws {
        app.launch()
        _ = app.descendants(matching: .any)[TestConstants.Identifiers.articleList]
            .waitForExistence(timeout: TestConstants.contentLoadTimeout)

        probe("articleList", TestConstants.Identifiers.articleList)
        probe("chipAll", TestConstants.Identifiers.allCategoryChip)
        probe("chipTech", TestConstants.Identifiers.technologyCategoryChip)

        // The search field is inside `if (showSearchBar)`, so it does not exist
        // until the toolbar search icon is tapped. That icon carries only
        // contentDescription = "Search", no testTag.
        print("=== BUTTON LABELS ===")
        for i in 0..<app.buttons.count {
            let b = app.buttons.element(boundBy: i)
            print("  button[\(i)] id='\(b.identifier)' label='\(b.label)'")
        }

        let searchIcon = app.buttons["Search"]
        print("=== buttons['Search'].exists = \(searchIcon.exists) ===")
        if searchIcon.exists {
            searchIcon.tap()
            sleep(1)
            probe("searchField(after open)", TestConstants.Identifiers.searchField)
        }

        print("=== FULL HIERARCHY BEGIN ===")
        print(app.debugDescription)
        print("=== FULL HIERARCHY END ===")
    }
}

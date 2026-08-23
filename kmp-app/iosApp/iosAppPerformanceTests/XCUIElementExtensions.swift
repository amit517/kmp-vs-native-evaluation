import XCTest

extension XCUIElement {
    /// Deletes one character at a time, re-reading `value` until the field is
    /// empty.
    ///
    /// A single burst of deletes is unreliable on a text field whose
    /// onValueChange runs a search per keystroke. Measured on device: sending 10
    /// deletes after typing "Technology" left "Tec" — only 7 landed. The residue
    /// then accumulated across iterations ("TecTechnology", "TecTTechnology"),
    /// so each iteration searched a longer query and the benchmark measured a
    /// growing workload instead of a fixed one.
    ///
    /// An empty field reads back as nil; the placeholder is exposed as `label`,
    /// not `value`, so it does not need special-casing.
    func clearText(maxDeletes: Int = 80) {
        tap()
        var deletes = 0
        while deletes < maxDeletes {
            guard let current = value as? String, !current.isEmpty else { return }
            typeText(XCUIKeyboardKey.delete.rawValue)
            deletes += 1
            usleep(120_000)
        }
        XCTFail("Could not clear text field after \(maxDeletes) deletes; " +
                "value still '\((value as? String) ?? "nil")'")
    }
}

import Foundation

enum TestConstants {
    static let appBundleIdentifier = "com.example.thesisproject.Thesisproject"
    static let signpostSubsystem = "com.example.thesisproject.Thesisproject"
    static let defaultTimeout: TimeInterval = 15.0
    static let contentLoadTimeout: TimeInterval = 20.0

    enum Identifiers {
        // Compose Multiplatform testTag identifiers
        static let articleList = "article_list"
        static let searchField = "search_field"
        // Category chips use dynamic testTag("category_chip_<name>")
        // Article cards use dynamic testTag("article_card_<id>")

        static func articleCard(_ id: String) -> String { "article_card_\(id)" }
        static func categoryChip(_ rawValue: String) -> String { "category_chip_\(rawValue)" }
    }
}

import Foundation

enum TestConstants {
    static let appBundleIdentifier = "com.amit.IosNativeBuild"
    static let signpostSubsystem = "com.amit.IosNativeBuild"
    static let defaultTimeout: TimeInterval = 15.0
    static let contentLoadTimeout: TimeInterval = 20.0

    enum Identifiers {
        static let newsListScrollView = "news_list_scroll_view"
        static let searchTextField = "search_text_field"
        static let searchButton = "search_button"
        static let favoritesButton = "favorites_button"
        static let categoryChipsScroll = "category_chips_scroll"
        static let loadingView = "loading_view"
        static let errorView = "error_state_view"
        static let retryButton = "retry_button"
        static let articleDetailScroll = "article_detail_scroll"
        static let articleDetailTitle = "article_detail_title"
        static let favoritesScrollView = "favorites_scroll_view"

        static func articleCard(_ id: String) -> String { "article_card_\(id)" }
        static func articleTitle(_ id: String) -> String { "article_title_\(id)" }
        static func categoryChip(_ rawValue: String) -> String { "category_chip_\(rawValue)" }
    }
}

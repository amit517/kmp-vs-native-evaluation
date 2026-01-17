package com.amit.newsreader.navigation

/**
 * Sealed class representing app navigation destinations
 */
sealed class Screen(val route: String) {
    data object NewsList : Screen("news_list")
    data object ArticleDetail : Screen("article_detail/{articleId}") {
        fun createRoute(articleId: String) = "article_detail/$articleId"
    }
    data object Favorites : Screen("favorites")
}
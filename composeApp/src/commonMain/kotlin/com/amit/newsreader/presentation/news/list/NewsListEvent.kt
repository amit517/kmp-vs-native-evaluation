package com.amit.newsreader.presentation.news.list

import com.amit.newsreader.domain.model.ArticleCategory

/**
 * Events for News List Screen
 * User interactions and system events
 */
sealed interface NewsListEvent {
    data object LoadArticles : NewsListEvent
    data object RefreshArticles : NewsListEvent
    data class SelectCategory(val category: ArticleCategory?) : NewsListEvent
    data class SearchArticles(val query: String) : NewsListEvent
    data class ToggleFavorite(val articleId: String) : NewsListEvent
    data class NavigateToDetail(val articleId: String) : NewsListEvent
    data object ClearError : NewsListEvent
}
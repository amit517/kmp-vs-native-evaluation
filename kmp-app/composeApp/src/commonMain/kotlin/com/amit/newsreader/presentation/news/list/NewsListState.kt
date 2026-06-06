package com.amit.newsreader.presentation.news.list

import com.amit.newsreader.domain.model.Article
import com.amit.newsreader.domain.model.ArticleCategory

/**
 * UI State for News List Screen
 * Follows MVI pattern
 */
data class NewsListState(
    val articles: List<Article> = emptyList(),
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val isLoadingMore: Boolean = false,
    val error: String? = null,
    val selectedCategory: ArticleCategory? = null,
    val searchQuery: String = "",
    val isSearching: Boolean = false,
    val showFavoritesOnly: Boolean = false,
    val currentPage: Int = 1,
    val hasMorePages: Boolean = true
)

package com.amit.newsreader.presentation.news.detail

import com.amit.newsreader.domain.model.Article

/**
 * UI State for Article Detail Screen
 */
data class ArticleDetailState(
    val article: Article? = null,
    val isLoading: Boolean = false,
    val error: String? = null
)
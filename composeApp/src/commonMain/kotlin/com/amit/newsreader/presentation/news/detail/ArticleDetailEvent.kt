package com.amit.newsreader.presentation.news.detail

/**
 * Events for Article Detail Screen
 */
sealed interface ArticleDetailEvent {
    data class LoadArticle(val articleId: String) : ArticleDetailEvent
    data object ToggleFavorite : ArticleDetailEvent
    data object NavigateBack : ArticleDetailEvent
    data object ShareArticle : ArticleDetailEvent
}
package com.amit.newsreader.navigation

import kotlinx.serialization.Serializable

/**
 * Type-safe navigation destinations using Kotlin Serialization
 */
sealed interface Screen {
    
    @Serializable
    data object NewsList : Screen
    
    @Serializable
    data class ArticleDetail(val articleId: String) : Screen
    
    @Serializable
    data object Favorites : Screen
}

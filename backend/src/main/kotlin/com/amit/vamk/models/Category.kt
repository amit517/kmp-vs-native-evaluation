package com.amit.vamk.models

import kotlinx.serialization.Serializable

/**
 * Category data model
 * Represents an article category
 */
@Serializable
data class Category(
    val id: String,
    val name: String,
    val description: String,
    val articleCount: Int = 0
)

/**
 * Response model for category articles endpoint
 * Returns category info with paginated articles
 */
@Serializable
data class CategoryArticlesResponse(
    val category: Category,
    val articles: List<Article>,
    val page: Int,
    val pageSize: Int,
    val totalPages: Int,
    val totalArticles: Int
)

package com.amit.vamk.models

import kotlinx.serialization.Serializable

/**
 * Article data model
 * Represents a news article with all its properties
 */
@Serializable
data class Article(
    val id: String,
    val title: String,
    val content: String,
    val summary: String,
    val imageUrl: String? = null,
    val author: String,
    val publishedAt: Long, // Unix timestamp in milliseconds
    val category: String,
    val readTimeMinutes: Int,
    val tags: List<String> = emptyList()
)

/**
 * Request model for creating a new article
 */
@Serializable
data class CreateArticleRequest(
    val title: String,
    val content: String,
    val summary: String,
    val author: String,
    val category: String,
    val readTimeMinutes: Int,
    val tags: List<String> = emptyList()
)

/**
 * Request model for updating an existing article
 */
@Serializable
data class UpdateArticleRequest(
    val title: String? = null,
    val content: String? = null,
    val summary: String? = null,
    val author: String? = null,
    val category: String? = null,
    val readTimeMinutes: Int? = null,
    val tags: List<String>? = null
)

/**
 * Response model for paginated article list
 */
@Serializable
data class ArticlesResponse(
    val articles: List<Article>,
    val page: Int,
    val pageSize: Int,
    val totalPages: Int,
    val totalArticles: Int
)

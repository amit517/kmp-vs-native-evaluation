package com.amit.newsreader.domain.model

import kotlinx.datetime.Instant

/**
 * Domain model for Article
 * Clean architecture: This is the core business entity
 */
data class Article(
    val id: String,
    val title: String,
    val content: String,
    val summary: String,
    val imageUrl: String?,
    val author: String,
    val publishedAt: Instant,
    val category: ArticleCategory,
    val readTimeMinutes: Int,
    val tags: List<String>,
    val isFavorite: Boolean = false
)

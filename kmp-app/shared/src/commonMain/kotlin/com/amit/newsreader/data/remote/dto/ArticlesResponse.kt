package com.amit.newsreader.data.remote.dto

import kotlinx.serialization.Serializable

/**
 * Response wrapper for paginated articles from backend
 * GET /api/articles?page=1&limit=20
 */
@Serializable
data class ArticlesResponse(
    val articles: List<ArticleDto>,
    val page: Int,
    val pageSize: Int,
    val totalPages: Int,
    val totalArticles: Int
)

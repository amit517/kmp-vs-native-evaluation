package com.amit.newsreader.domain.repository

import com.amit.newsreader.domain.model.Article
import com.amit.newsreader.domain.model.ArticleCategory
import com.amit.newsreader.util.Result
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for news articles
 * Clean Architecture: Domain layer defines the contract
 */
interface NewsRepository {

    /**
     * Get articles with pagination and optional filters
     * Returns cached data and emits updates via Flow
     */
    fun getArticles(
        page: Int = 1,
        limit: Int = 20,
        category: ArticleCategory? = null,
        forceRefresh: Boolean = false
    ): Flow<Result<List<Article>>>

    /**
     * Get single article by ID
     */
    fun getArticleById(id: String): Flow<Result<Article>>

    /**
     * Search articles by query
     */
    fun searchArticles(query: String): Flow<Result<List<Article>>>

    /**
     * Get favorite articles
     */
    fun getFavoriteArticles(): Flow<Result<List<Article>>>

    /**
     * Toggle favorite status of an article
     */
    suspend fun toggleFavorite(articleId: String): Result<Unit>

    /**
     * Refresh articles from network
     */
    suspend fun refreshArticles(
        page: Int = 1,
        limit: Int = 20,
        category: ArticleCategory? = null
    ): Result<Unit>

    /**
     * Clear local cache
     */
    suspend fun clearCache(): Result<Unit>
}

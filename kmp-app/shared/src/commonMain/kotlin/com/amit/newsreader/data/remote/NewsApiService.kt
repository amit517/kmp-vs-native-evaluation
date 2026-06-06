package com.amit.newsreader.data.remote

import com.amit.newsreader.data.remote.dto.ArticleDto
import com.amit.newsreader.data.remote.dto.ArticlesResponse
import com.amit.newsreader.data.remote.dto.CategoryDto
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.request.*

/**
 * API service for News Reader backend
 * Base URLs:
 * - Android emulator: http://10.0.2.2:8080
 * - iOS simulator: http://localhost:8080
 */
class NewsApiService(
    private val httpClient: HttpClient,
    private val baseUrl: String
) {
    /**
     * Get paginated articles with optional filters
     * GET /api/articles?page=1&limit=20&category=TECHNOLOGY&search=kotlin
     */
    suspend fun getArticles(
        page: Int = 1,
        limit: Int = 20,
        category: String? = null,
        search: String? = null
    ): ArticlesResponse {
        return httpClient.get("$baseUrl/api/articles") {
            parameter("page", page)
            parameter("limit", limit)
            category?.let { parameter("category", it) }
            search?.let { parameter("search", it) }
        }.body()
    }

    /**
     * Get single article by ID
     * GET /api/articles/{id}
     */
    suspend fun getArticleById(id: String): ArticleDto {
        return httpClient.get("$baseUrl/api/articles/$id").body()
    }

    /**
     * Get all available categories
     * GET /api/categories
     */
    suspend fun getCategories(): List<CategoryDto> {
        return httpClient.get("$baseUrl/api/categories").body()
    }
}

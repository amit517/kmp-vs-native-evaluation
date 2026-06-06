package com.amit.newsreader.data.remote.dto

import kotlinx.serialization.Serializable

/**
 * Data Transfer Object for Article from backend API
 * Matches backend article model exactly
 */
@Serializable
data class ArticleDto(
    val id: String,
    val title: String,
    val content: String,
    val summary: String,
    val imageUrl: String? = null,
    val author: String,
    val publishedAt: Long, // Backend sends timestamp (Long), not ISO string
    val category: String,
    val readTimeMinutes: Int,
    val tags: List<String> = emptyList()
)

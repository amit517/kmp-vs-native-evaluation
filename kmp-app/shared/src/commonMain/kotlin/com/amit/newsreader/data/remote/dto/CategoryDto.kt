package com.amit.newsreader.data.remote.dto

import kotlinx.serialization.Serializable

/**
 * Data Transfer Object for Category from backend API
 * GET /api/categories
 */
@Serializable
data class CategoryDto(
    val id: String,
    val name: String,
    val displayName: String
)

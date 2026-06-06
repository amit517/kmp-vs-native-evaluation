package com.amit.newsreader.data.local

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "ArticleEntity",
    indices = [
        Index("category"),
        Index("isFavorite"),
        Index(value = ["publishedAt"])
    ]
)
data class ArticleEntity(
    @PrimaryKey val id: String,
    val title: String,
    val content: String,
    val summary: String,
    val imageUrl: String?,
    val author: String,
    val publishedAt: Long,
    val category: String,
    val readTimeMinutes: Int,
    val tags: String,
    val isFavorite: Boolean = false,
    val cachedAt: Long
)

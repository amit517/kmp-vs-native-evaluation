@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.amit.newsreader.data.mapper

import com.amit.newsreader.data.remote.dto.ArticleDto
import com.amit.newsreader.database.ArticleEntity
import com.amit.newsreader.domain.model.Article
import com.amit.newsreader.domain.model.ArticleCategory
import kotlin.time.Clock
import kotlin.time.Instant

/**
 * Mapper for converting between different article representations
 * DTO (Network) <-> Entity (Database) <-> Domain Model
 */

// DTO to Domain
fun ArticleDto.toDomain(): Article {
    return Article(
        id = id,
        title = title,
        content = content,
        summary = summary,
        imageUrl = imageUrl,
        author = author,
        publishedAt = Instant.fromEpochMilliseconds(publishedAt),
        category = ArticleCategory.fromString(category),
        readTimeMinutes = readTimeMinutes,
        tags = tags,
        isFavorite = false
    )
}

// DTO to Entity
fun ArticleDto.toEntity(isFavorite: Boolean = false): ArticleEntity {
    return ArticleEntity(
        id = id,
        title = title,
        content = content,
        summary = summary,
        imageUrl = imageUrl,
        author = author,
        publishedAt = publishedAt,
        category = category,
        readTimeMinutes = readTimeMinutes.toLong(),
        tags = tags.joinToString(","),
        isFavorite = isFavorite,
        cachedAt = Clock.System.now().toEpochMilliseconds().toLong()
    )
}

// Entity to Domain
fun ArticleEntity.toDomain(): Article {
    return Article(
        id = id,
        title = title,
        content = content,
        summary = summary,
        imageUrl = imageUrl,
        author = author,
        publishedAt = Instant.fromEpochMilliseconds(publishedAt),
        category = ArticleCategory.fromString(category),
        readTimeMinutes = readTimeMinutes.toInt(),
        tags = if (tags.isNotEmpty()) tags.split(",") else emptyList(),
        isFavorite = isFavorite
    )
}

// Domain to Entity
fun Article.toEntity(): ArticleEntity {
    return ArticleEntity(
        id = id,
        title = title,
        content = content,
        summary = summary,
        imageUrl = imageUrl,
        author = author,
        publishedAt = publishedAt.toEpochMilliseconds(),
        category = category.name,
        readTimeMinutes = readTimeMinutes.toLong(),
        tags = tags.joinToString(","),
        isFavorite = isFavorite,
        cachedAt = Clock.System.now().toEpochMilliseconds()
    )
}

// List extensions
fun List<ArticleDto>.toDomainList(): List<Article> = map { it.toDomain() }
fun List<ArticleDto>.toEntityList(): List<ArticleEntity> = map { it.toEntity() }
fun List<ArticleEntity>.entityToDomainList(): List<Article> = map { it.toDomain() }
fun List<Article>.domainToEntityList(): List<ArticleEntity> = map { it.toEntity() }

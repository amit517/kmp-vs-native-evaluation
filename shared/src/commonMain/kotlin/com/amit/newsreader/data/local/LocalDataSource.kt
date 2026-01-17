package com.amit.newsreader.data.local

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToList
import app.cash.sqldelight.coroutines.mapToOne
import app.cash.sqldelight.coroutines.mapToOneOrNull
import com.amit.newsreader.database.ArticleEntity
import com.amit.newsreader.database.NewsReaderDatabase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.Flow

/**
 * Local data source for article database operations
 */
class LocalDataSource(
    databaseDriverFactory: DatabaseDriverFactory
) {
    private val database = NewsReaderDatabase(databaseDriverFactory.createDriver())
    private val queries = database.newsReaderQueries

    // Flow-based queries for reactive updates
    fun getAllArticles(): Flow<List<ArticleEntity>> {
        return queries.selectAll()
            .asFlow()
            .mapToList(Dispatchers.IO)
    }

    fun getArticlesByCategory(category: String): Flow<List<ArticleEntity>> {
        return queries.selectByCategory(category)
            .asFlow()
            .mapToList(Dispatchers.IO)
    }

    fun getArticleById(id: String): Flow<ArticleEntity?> {
        return queries.selectById(id)
            .asFlow()
            .mapToOneOrNull(Dispatchers.IO)
    }

    fun searchArticles(query: String): Flow<List<ArticleEntity>> {
        return queries.searchArticles(query, query, query, query)
            .asFlow()
            .mapToList(Dispatchers.IO)
    }

    fun getFavoriteArticles(): Flow<List<ArticleEntity>> {
        return queries.selectFavorites()
            .asFlow()
            .mapToList(Dispatchers.IO)
    }

    // Synchronous operations for repository layer
    suspend fun insertArticle(article: ArticleEntity) {
        queries.insertArticle(
            id = article.id,
            title = article.title,
            content = article.content,
            summary = article.summary,
            imageUrl = article.imageUrl,
            author = article.author,
            publishedAt = article.publishedAt,
            category = article.category,
            readTimeMinutes = article.readTimeMinutes,
            tags = article.tags,
            isFavorite = article.isFavorite,
            cachedAt = article.cachedAt
        )
    }

    suspend fun insertArticles(articles: List<ArticleEntity>) {
        queries.transaction {
            articles.forEach { article ->
                queries.insertArticle(
                    id = article.id,
                    title = article.title,
                    content = article.content,
                    summary = article.summary,
                    imageUrl = article.imageUrl,
                    author = article.author,
                    publishedAt = article.publishedAt,
                    category = article.category,
                    readTimeMinutes = article.readTimeMinutes,
                    tags = article.tags,
                    isFavorite = article.isFavorite,
                    cachedAt = article.cachedAt
                )
            }
        }
    }

    suspend fun updateFavoriteStatus(id: String, isFavorite: Boolean) {
        queries.updateFavoriteStatus(isFavorite, id)
    }

    suspend fun deleteAllArticles() {
        queries.deleteAll()
    }

    suspend fun deleteArticleById(id: String) {
        queries.deleteById(id)
    }

    suspend fun getArticleByIdSync(id: String): ArticleEntity? {
        return queries.selectById(id).executeAsOneOrNull()
    }

    suspend fun countArticles(): Long {
        return queries.countAll().executeAsOne()
    }
}

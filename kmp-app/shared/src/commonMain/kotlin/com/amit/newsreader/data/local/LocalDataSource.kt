package com.amit.newsreader.data.local

import kotlinx.coroutines.flow.Flow

/**
 * Local data source for article database operations
 */
class LocalDataSource(
    database: NewsReaderDatabase
) {
    private val dao = database.articleDao()

    // Flow-based queries for reactive updates
    fun getAllArticles(): Flow<List<ArticleEntity>> {
        return dao.selectAll()
    }

    fun getArticlesByCategory(category: String): Flow<List<ArticleEntity>> {
        return dao.selectByCategory(category)
    }

    fun getArticleById(id: String): Flow<ArticleEntity?> {
        return dao.selectById(id)
    }

    fun searchArticles(query: String): Flow<List<ArticleEntity>> {
        return dao.searchArticles(query)
    }

    fun getFavoriteArticles(): Flow<List<ArticleEntity>> {
        return dao.selectFavorites()
    }

    // Suspend operations
    suspend fun insertArticle(article: ArticleEntity) {
        dao.insertArticle(article)
    }

    suspend fun insertArticles(articles: List<ArticleEntity>) {
        dao.insertArticles(articles)
    }

    suspend fun updateFavoriteStatus(id: String, isFavorite: Boolean) {
        dao.updateFavoriteStatus(id, isFavorite)
    }

    suspend fun deleteAllArticles() {
        dao.deleteAll()
    }

    suspend fun deleteArticleById(id: String) {
        dao.deleteById(id)
    }

    suspend fun getArticleByIdSync(id: String): ArticleEntity? {
        return dao.selectByIdSync(id)
    }

    suspend fun countArticles(): Long {
        return dao.countAll()
    }

    suspend fun upsertArticlesPreservingFavorites(articles: List<ArticleEntity>) {
        articles.forEach { article ->
            val existing = dao.selectByIdSync(article.id)
            dao.insertArticle(
                article.copy(isFavorite = existing?.isFavorite ?: false)
            )
        }
    }
}

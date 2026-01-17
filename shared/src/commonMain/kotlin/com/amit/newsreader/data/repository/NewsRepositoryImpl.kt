package com.amit.newsreader.data.repository

import com.amit.newsreader.data.local.LocalDataSource
import com.amit.newsreader.data.mapper.entityToDomainList
import com.amit.newsreader.data.mapper.toDomain
import com.amit.newsreader.data.mapper.toDomainList
import com.amit.newsreader.data.mapper.toEntity
import com.amit.newsreader.data.mapper.toEntityList
import com.amit.newsreader.data.remote.NewsApiService
import com.amit.newsreader.domain.model.Article
import com.amit.newsreader.domain.model.ArticleCategory
import com.amit.newsreader.domain.repository.NewsRepository
import com.amit.newsreader.util.Result
import com.amit.newsreader.util.safeCall
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map

/**
 * Repository implementation with offline-first architecture
 * Strategy: Return cached data immediately, then fetch from network
 */
class NewsRepositoryImpl(
    private val apiService: NewsApiService,
    private val localDataSource: LocalDataSource
) : NewsRepository {

    override fun getArticles(
        page: Int,
        limit: Int,
        category: ArticleCategory?,
        forceRefresh: Boolean
    ): Flow<Result<List<Article>>> = flow {
        emit(Result.Loading)

        // If not forcing refresh, emit cached data first
        if (!forceRefresh) {
            val cachedArticles = if (category != null) {
                localDataSource.getArticlesByCategory(category.name)
            } else {
                localDataSource.getAllArticles()
            }

            cachedArticles.collect { entities ->
                if (entities.isNotEmpty()) {
                    emit(Result.Success(entities.entityToDomainList()))
                }
            }
        }

        // Fetch fresh data from network
        val networkResult = safeCall {
            val response = apiService.getArticles(
                page = page,
                limit = limit,
                category = category?.name
            )
            response.articles
        }

        when (networkResult) {
            is Result.Success -> {
                // Cache the network response
                val entities = networkResult.data.toEntityList()
                localDataSource.insertArticles(entities)

                // Emit the fresh data
                emit(Result.Success(networkResult.data.toDomainList()))
            }
            is Result.Error -> {
                // If we have cached data, we already emitted it
                // Only emit error if we don't have cached data
                val cachedCount = localDataSource.countArticles()
                if (cachedCount == 0L || forceRefresh) {
                    emit(networkResult)
                }
            }
            is Result.Loading -> {
                // Should not happen, but handle it anyway
            }
        }
    }.catch { e ->
        emit(Result.Error(e as? Exception ?: Exception(e.message), e.message))
    }

    override fun getArticleById(id: String): Flow<Result<Article>> = flow {
        emit(Result.Loading)

        // First, try to get from cache
        localDataSource.getArticleById(id).collect { entity ->
            if (entity != null) {
                emit(Result.Success(entity.toDomain()))
            }
        }

        // Then fetch from network for latest data
        val networkResult = safeCall {
            apiService.getArticleById(id)
        }

        when (networkResult) {
            is Result.Success -> {
                val entity = networkResult.data.toEntity()
                localDataSource.insertArticle(entity)
                emit(Result.Success(networkResult.data.toDomain()))
            }
            is Result.Error -> {
                // If we have cached data, we already emitted it
                val cached = localDataSource.getArticleByIdSync(id)
                if (cached == null) {
                    emit(networkResult)
                }
            }
            is Result.Loading -> {}
        }
    }.catch { e ->
        emit(Result.Error(e as? Exception ?: Exception(e.message), e.message))
    }

    override fun searchArticles(query: String): Flow<Result<List<Article>>> = flow {
        emit(Result.Loading)

        // Search in local database
        localDataSource.searchArticles(query)
            .map { entities -> entities.entityToDomainList() }
            .collect { articles ->
                emit(Result.Success(articles))
            }
    }.catch { e ->
        emit(Result.Error(e as? Exception ?: Exception(e.message), e.message))
    }

    override fun getFavoriteArticles(): Flow<Result<List<Article>>> = flow {
        emit(Result.Loading)

        localDataSource.getFavoriteArticles()
            .map { entities -> entities.entityToDomainList() }
            .collect { articles ->
                emit(Result.Success(articles))
            }
    }.catch { e ->
        emit(Result.Error(e as? Exception ?: Exception(e.message), e.message))
    }

    override suspend fun toggleFavorite(articleId: String): Result<Unit> {
        return safeCall {
            val article = localDataSource.getArticleByIdSync(articleId)
            if (article != null) {
                localDataSource.updateFavoriteStatus(articleId, !article.isFavorite)
            }
        }
    }

    override suspend fun refreshArticles(
        page: Int,
        limit: Int,
        category: ArticleCategory?
    ): Result<Unit> {
        return safeCall {
            val response = apiService.getArticles(
                page = page,
                limit = limit,
                category = category?.name
            )

            // Cache the articles
            val entities = response.articles.toEntityList()
            localDataSource.insertArticles(entities)
        }
    }

    override suspend fun clearCache(): Result<Unit> {
        return safeCall {
            localDataSource.deleteAllArticles()
        }
    }
}

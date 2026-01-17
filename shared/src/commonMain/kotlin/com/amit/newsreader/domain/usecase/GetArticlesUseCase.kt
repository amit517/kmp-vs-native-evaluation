package com.amit.newsreader.domain.usecase

import com.amit.newsreader.domain.model.Article
import com.amit.newsreader.domain.model.ArticleCategory
import com.amit.newsreader.domain.repository.NewsRepository
import com.amit.newsreader.util.Result
import kotlinx.coroutines.flow.Flow

/**
 * Use case for getting articles with pagination and filtering
 * Encapsulates business logic for article retrieval
 */
class GetArticlesUseCase(
    private val repository: NewsRepository
) {
    operator fun invoke(
        page: Int = 1,
        limit: Int = 20,
        category: ArticleCategory? = null,
        forceRefresh: Boolean = false
    ): Flow<Result<List<Article>>> {
        return repository.getArticles(
            page = page,
            limit = limit,
            category = category,
            forceRefresh = forceRefresh
        )
    }
}

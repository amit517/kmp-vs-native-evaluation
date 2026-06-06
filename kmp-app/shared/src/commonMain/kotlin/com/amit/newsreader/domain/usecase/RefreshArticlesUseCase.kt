package com.amit.newsreader.domain.usecase

import com.amit.newsreader.domain.model.ArticleCategory
import com.amit.newsreader.domain.repository.NewsRepository
import com.amit.newsreader.util.Result

/**
 * Use case for refreshing articles from network
 */
class RefreshArticlesUseCase(
    private val repository: NewsRepository
) {
    suspend operator fun invoke(
        page: Int = 1,
        limit: Int = 20,
        category: ArticleCategory? = null
    ): Result<Unit> {
        return repository.refreshArticles(page, limit, category)
    }
}

package com.amit.newsreader.domain.usecase

import com.amit.newsreader.domain.model.Article
import com.amit.newsreader.domain.repository.NewsRepository
import com.amit.newsreader.util.Result
import kotlinx.coroutines.flow.Flow

/**
 * Use case for getting article details by ID
 */
class GetArticleDetailUseCase(
    private val repository: NewsRepository
) {
    operator fun invoke(articleId: String): Flow<Result<Article>> {
        return repository.getArticleById(articleId)
    }
}

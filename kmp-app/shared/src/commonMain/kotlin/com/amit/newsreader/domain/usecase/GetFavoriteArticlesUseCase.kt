package com.amit.newsreader.domain.usecase

import com.amit.newsreader.domain.model.Article
import com.amit.newsreader.domain.repository.NewsRepository
import com.amit.newsreader.util.Result
import kotlinx.coroutines.flow.Flow

/**
 * Use case for getting favorite articles
 */
class GetFavoriteArticlesUseCase(
    private val repository: NewsRepository
) {
    operator fun invoke(): Flow<Result<List<Article>>> {
        return repository.getFavoriteArticles()
    }
}

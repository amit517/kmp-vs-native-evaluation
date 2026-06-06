package com.amit.newsreader.domain.usecase

import com.amit.newsreader.domain.repository.NewsRepository
import com.amit.newsreader.util.Result

/**
 * Use case for toggling article favorite status
 */
class ToggleFavoriteUseCase(
    private val repository: NewsRepository
) {
    suspend operator fun invoke(articleId: String): Result<Unit> {
        return repository.toggleFavorite(articleId)
    }
}

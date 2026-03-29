package com.amit.newsreader.presentation.news.detail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.amit.newsreader.domain.usecase.GetArticleDetailUseCase
import com.amit.newsreader.domain.usecase.ToggleFavoriteUseCase
import com.amit.newsreader.util.Result
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlin.time.ExperimentalTime

/**
 * ViewModel for Article Detail Screen
 */
class ArticleDetailViewModel(
    private val getArticleDetailUseCase: GetArticleDetailUseCase,
    private val toggleFavoriteUseCase: ToggleFavoriteUseCase
) : ViewModel() {

    private val _state = MutableStateFlow(ArticleDetailState())
    val state: StateFlow<ArticleDetailState> = _state.asStateFlow()

    fun onEvent(event: ArticleDetailEvent) {
        when (event) {
            is ArticleDetailEvent.LoadArticle -> loadArticle(event.articleId)
            is ArticleDetailEvent.ToggleFavorite -> toggleFavorite()
            is ArticleDetailEvent.NavigateBack -> {
                // Handled by UI
            }
            is ArticleDetailEvent.ShareArticle -> {
                // Handled by UI with platform-specific sharing
            }
        }
    }

    private fun loadArticle(articleId: String) {
        viewModelScope.launch {
            getArticleDetailUseCase(articleId)
                .catch { e ->
                    _state.update {
                        it.copy(
                            isLoading = false,
                            error = e.message ?: "Failed to load article"
                        )
                    }
                }
                .collect { result ->
                    when (result) {
                        is Result.Loading -> {
                            _state.update { it.copy(isLoading = true, error = null) }
                        }
                        is Result.Success -> {
                            _state.update {
                                it.copy(
                                    article = result.data,
                                    isLoading = false,
                                    error = null
                                )
                            }
                        }
                        is Result.Error -> {
                            _state.update {
                                it.copy(
                                    isLoading = false,
                                    error = result.message ?: "An error occurred"
                                )
                            }
                        }
                    }
                }
        }
    }

    @OptIn(ExperimentalTime::class)
    private fun toggleFavorite() {
        val article = _state.value.article ?: return

        viewModelScope.launch {
            toggleFavoriteUseCase(article.id)
            _state.update { currentState ->
                currentState.copy(
                    article = currentState.article?.copy(isFavorite = !article.isFavorite)
                )
            }
        }
    }
}

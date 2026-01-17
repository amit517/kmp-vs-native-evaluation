package com.amit.newsreader.presentation.news.list

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.amit.newsreader.domain.model.ArticleCategory
import com.amit.newsreader.domain.usecase.GetArticlesUseCase
import com.amit.newsreader.domain.usecase.RefreshArticlesUseCase
import com.amit.newsreader.domain.usecase.SearchArticlesUseCase
import com.amit.newsreader.domain.usecase.ToggleFavoriteUseCase
import com.amit.newsreader.util.Result
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * ViewModel for News List Screen
 * Handles business logic and state management
 */
class NewsListViewModel(
    private val getArticlesUseCase: GetArticlesUseCase,
    private val refreshArticlesUseCase: RefreshArticlesUseCase,
    private val searchArticlesUseCase: SearchArticlesUseCase,
    private val toggleFavoriteUseCase: ToggleFavoriteUseCase
) : ViewModel() {

    private val _state = MutableStateFlow(NewsListState())
    val state: StateFlow<NewsListState> = _state.asStateFlow()

    private var searchJob: Job? = null
    private var loadJob: Job? = null

    init {
        loadArticles()
    }

    fun onEvent(event: NewsListEvent) {
        when (event) {
            is NewsListEvent.LoadArticles -> loadArticles()
            is NewsListEvent.RefreshArticles -> refreshArticles()
            is NewsListEvent.SelectCategory -> selectCategory(event.category)
            is NewsListEvent.SearchArticles -> searchArticles(event.query)
            is NewsListEvent.ToggleFavorite -> toggleFavorite(event.articleId)
            is NewsListEvent.NavigateToDetail -> {
                // Navigation handled by UI
            }
            is NewsListEvent.ClearError -> clearError()
        }
    }

    private fun loadArticles() {
        loadJob?.cancel()
        loadJob = viewModelScope.launch {
            getArticlesUseCase(
                category = _state.value.selectedCategory,
                forceRefresh = false
            )
                .catch { e ->
                    _state.update {
                        it.copy(
                            isLoading = false,
                            error = e.message ?: "Failed to load articles"
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
                                    articles = result.data,
                                    isLoading = false,
                                    isRefreshing = false,
                                    error = null
                                )
                            }
                        }
                        is Result.Error -> {
                            _state.update {
                                it.copy(
                                    isLoading = false,
                                    isRefreshing = false,
                                    error = result.message ?: "An error occurred"
                                )
                            }
                        }
                    }
                }
        }
    }

    private fun refreshArticles() {
        viewModelScope.launch {
            _state.update { it.copy(isRefreshing = true, error = null) }

            val result = refreshArticlesUseCase(
                category = _state.value.selectedCategory
            )

            when (result) {
                is Result.Success -> {
                    // Load articles will be triggered by the flow
                    loadArticles()
                }
                is Result.Error -> {
                    _state.update {
                        it.copy(
                            isRefreshing = false,
                            error = result.message ?: "Failed to refresh"
                        )
                    }
                }
                is Result.Loading -> {
                    // Already set isRefreshing
                }
            }
        }
    }

    private fun selectCategory(category: ArticleCategory?) {
        _state.update {
            it.copy(
                selectedCategory = category,
                searchQuery = "",
                isSearching = false
            )
        }
        loadArticles()
    }

    private fun searchArticles(query: String) {
        _state.update { it.copy(searchQuery = query) }

        if (query.isBlank()) {
            _state.update { it.copy(isSearching = false) }
            loadArticles()
            return
        }

        searchJob?.cancel()
        searchJob = viewModelScope.launch {
            _state.update { it.copy(isSearching = true, error = null) }

            searchArticlesUseCase(query)
                .catch { e ->
                    _state.update {
                        it.copy(
                            isSearching = false,
                            error = e.message ?: "Search failed"
                        )
                    }
                }
                .collect { result ->
                    when (result) {
                        is Result.Success -> {
                            _state.update {
                                it.copy(
                                    articles = result.data,
                                    isSearching = false,
                                    error = null
                                )
                            }
                        }
                        is Result.Error -> {
                            _state.update {
                                it.copy(
                                    isSearching = false,
                                    error = result.message ?: "Search failed"
                                )
                            }
                        }
                        is Result.Loading -> {
                            // Already set isSearching
                        }
                    }
                }
        }
    }

    private fun toggleFavorite(articleId: String) {
        viewModelScope.launch {
            toggleFavoriteUseCase(articleId)
            // The flow will automatically update the UI
        }
    }

    private fun clearError() {
        _state.update { it.copy(error = null) }
    }

    override fun onCleared() {
        super.onCleared()
        searchJob?.cancel()
        loadJob?.cancel()
    }
}

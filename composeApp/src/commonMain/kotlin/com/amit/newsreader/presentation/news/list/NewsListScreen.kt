package com.amit.newsreader.presentation.news.list

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.amit.newsreader.presentation.components.*
import org.koin.compose.viewmodel.koinViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewsListScreen(
    onArticleClick: (String) -> Unit,
    onFavoritesClick: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: NewsListViewModel = koinViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    var showSearchBar by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            Column {
                TopAppBar(
                    title = { Text("News Reader") },
                    actions = {
                        IconButton(onClick = { showSearchBar = !showSearchBar }) {
                            Icon(
                                imageVector = Icons.Default.Search,
                                contentDescription = "Search"
                            )
                        }
                        IconButton(onClick = onFavoritesClick) {
                            Icon(
                                imageVector = Icons.Default.Favorite,
                                contentDescription = "Favorites"
                            )
                        }
                    }
                )

                if (showSearchBar) {
                    SearchBar(
                        query = state.searchQuery,
                        onQueryChange = { viewModel.onEvent(NewsListEvent.SearchArticles(it)) },
                        onSearch = { viewModel.onEvent(NewsListEvent.SearchArticles(it)) },
                        active = false,
                        onActiveChange = {},
                        placeholder = { Text("Search articles...") },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    ) {}
                }

                CategoryChips(
                    selectedCategory = state.selectedCategory,
                    onCategorySelected = { viewModel.onEvent(NewsListEvent.SelectCategory(it)) }
                )
            }
        },
        modifier = modifier
    ) { paddingValues ->
        NewsListContent(
            state = state,
            onEvent = viewModel::onEvent,
            onArticleClick = onArticleClick,
            modifier = Modifier.padding(paddingValues)
        )
    }
}

@Composable
private fun NewsListContent(
    state: NewsListState,
    onEvent: (NewsListEvent) -> Unit,
    onArticleClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        when {
            state.isLoading && state.articles.isEmpty() -> {
                LoadingIndicator(message = "Loading articles...")
            }

            state.error != null && state.articles.isEmpty() -> {
                ErrorView(
                    message = state.error,
                    onRetry = { onEvent(NewsListEvent.LoadArticles) }
                )
            }

            state.articles.isEmpty() -> {
                EmptyState(
                    message = if (state.searchQuery.isNotEmpty()) {
                        "No articles found for '${state.searchQuery}'"
                    } else {
                        "No articles available"
                    }
                )
            }

            else -> {
                ArticleList(
                    articles = state.articles,
                    isRefreshing = state.isRefreshing,
                    isLoadingMore = state.isLoadingMore,
                    hasMorePages = state.hasMorePages,
                    onLoadMore = { onEvent(NewsListEvent.LoadMoreArticles) },
                    onArticleClick = onArticleClick,
                    onFavoriteClick = { articleId ->
                        onEvent(NewsListEvent.ToggleFavorite(articleId))
                    }
                )
            }
        }

        // Show error snackbar if there's an error but we have cached data
        state.error?.let { error ->
            if (state.articles.isNotEmpty()) {
                Snackbar(
                    modifier = Modifier.padding(16.dp),
                    action = {
                        TextButton(onClick = { onEvent(NewsListEvent.ClearError) }) {
                            Text("Dismiss")
                        }
                    }
                ) {
                    Text(error)
                }
            }
        }
    }
}

@Composable
private fun ArticleList(
    articles: List<com.amit.newsreader.domain.model.Article>,
    isRefreshing: Boolean,
    isLoadingMore: Boolean,
    hasMorePages: Boolean,
    onLoadMore: () -> Unit,
    onArticleClick: (String) -> Unit,
    onFavoriteClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Show loading indicator at top when refreshing
        if (isRefreshing) {
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    contentAlignment = androidx.compose.ui.Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
        }
        
        items(
            items = articles,
            key = { it.id }
        ) { article ->
            ArticleCard(
                article = article,
                onClick = { onArticleClick(article.id) },
                onFavoriteClick = { onFavoriteClick(article.id) }
            )
            
            // Trigger load more when reaching near the end
            if (articles.indexOf(article) >= articles.size - 3 && hasMorePages && !isLoadingMore) {
                LaunchedEffect(article.id) {
                    onLoadMore()
                }
            }
        }
        
        // Show loading indicator at bottom when loading more
        if (isLoadingMore) {
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    contentAlignment = androidx.compose.ui.Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
        }
    }
}

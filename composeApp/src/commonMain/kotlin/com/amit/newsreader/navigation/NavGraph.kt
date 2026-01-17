package com.amit.newsreader.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute
import com.amit.newsreader.presentation.news.detail.ArticleDetailScreen
import com.amit.newsreader.presentation.news.list.NewsListEvent
import com.amit.newsreader.presentation.news.list.NewsListScreen
import org.koin.compose.viewmodel.koinViewModel

/**
 * Main navigation graph for the app with type-safe navigation
 */
@Composable
fun NavGraph(
    modifier: Modifier = Modifier,
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = Screen.NewsList,
        modifier = modifier
    ) {
        // News List Screen
        composable<Screen.NewsList> {
            NewsListScreen(
                onArticleClick = { articleId ->
                    navController.navigate(Screen.ArticleDetail(articleId))
                },
                onFavoritesClick = {
                    navController.navigate(Screen.Favorites)
                }
            )
        }

        // Article Detail Screen - Type-safe with automatic parameter extraction
        composable<Screen.ArticleDetail> { backStackEntry ->
            val articleDetail: Screen.ArticleDetail = backStackEntry.toRoute()

            ArticleDetailScreen(
                articleId = articleDetail.articleId,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onShareClick = {
                    // Platform-specific sharing will be handled here
                    // For now, we'll just log or show a message
                }
            )
        }

        // Favorites Screen (reuses NewsListScreen with favorites filter)
        composable<Screen.Favorites> {
            FavoritesScreen(
                onArticleClick = { articleId ->
                    navController.navigate(Screen.ArticleDetail(articleId))
                },
                onBackClick = {
                    navController.popBackStack()
                }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FavoritesScreen(
    onArticleClick: (String) -> Unit,
    onBackClick: () -> Unit,
    viewModel: com.amit.newsreader.presentation.news.list.NewsListViewModel = koinViewModel()
) {
    LaunchedEffect(Unit) {
        viewModel.onEvent(NewsListEvent.LoadFavorites)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Favorites") },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        NewsListScreen(
            onArticleClick = onArticleClick,
            onFavoritesClick = onBackClick,
            modifier = Modifier.padding(paddingValues),
            viewModel = viewModel
        )
    }
}

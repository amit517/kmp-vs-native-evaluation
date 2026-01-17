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
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.amit.newsreader.presentation.news.detail.ArticleDetailScreen
import com.amit.newsreader.presentation.news.list.NewsListEvent
import com.amit.newsreader.presentation.news.list.NewsListScreen
import org.koin.compose.viewmodel.koinViewModel

/**
 * Main navigation graph for the app
 */
@Composable
fun NavGraph(
    modifier: Modifier = Modifier,
    navController: NavHostController = rememberNavController(),
    startDestination: String = Screen.NewsList.route
) {
    NavHost(
        navController = navController,
        startDestination = startDestination,
        modifier = modifier
    ) {
        // News List Screen
        composable(route = Screen.NewsList.route) {
            NewsListScreen(
                onArticleClick = { articleId ->
                    navController.navigate(Screen.ArticleDetail.createRoute(articleId))
                },
                onFavoritesClick = {
                    navController.navigate(Screen.Favorites.route)
                }
            )
        }

        // Article Detail Screen
        composable(
            route = Screen.ArticleDetail.route,
            arguments = listOf(
                navArgument("articleId") {
                    type = NavType.StringType
                }
            )
        ) { backStackEntry ->
            val articleId = backStackEntry.arguments?.getString("articleId") ?: return@composable

            ArticleDetailScreen(
                articleId = articleId,
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
        composable(route = Screen.Favorites.route) {
            FavoritesScreen(
                onArticleClick = { articleId ->
                    navController.navigate(Screen.ArticleDetail.createRoute(articleId))
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

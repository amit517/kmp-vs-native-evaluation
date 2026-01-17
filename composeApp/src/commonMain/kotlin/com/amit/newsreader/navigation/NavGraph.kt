package com.amit.newsreader.navigation

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.amit.newsreader.presentation.news.detail.ArticleDetailScreen
import com.amit.newsreader.presentation.news.list.NewsListScreen

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
            // We can create a separate FavoritesScreen or reuse NewsListScreen
            // For now, using a simple implementation
            NewsListScreen(
                onArticleClick = { articleId ->
                    navController.navigate(Screen.ArticleDetail.createRoute(articleId))
                },
                onFavoritesClick = {
                    navController.popBackStack()
                }
            )
        }
    }
}
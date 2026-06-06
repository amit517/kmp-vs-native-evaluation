package com.amit.newsreader

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.amit.newsreader.navigation.NavGraph
import com.amit.newsreader.theme.NewsReaderTheme
import org.koin.compose.KoinContext

/**
 * Main app entry point for Compose Multiplatform
 * Shared between Android and iOS
 */
@Composable
fun App(modifier: Modifier = Modifier) {
    NewsReaderTheme {
        NavGraph(modifier = modifier)
    }
}

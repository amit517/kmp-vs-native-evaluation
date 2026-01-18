@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.amit.newsreader.presentation.news.detail

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.*
import androidx.compose.material3.HorizontalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.amit.newsreader.domain.model.Article
import coil3.compose.AsyncImage
import com.amit.newsreader.presentation.components.ErrorView
import com.amit.newsreader.presentation.components.LoadingIndicator
import com.amit.newsreader.theme.*
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import org.koin.compose.viewmodel.koinViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ArticleDetailScreen(
    articleId: String,
    onNavigateBack: () -> Unit,
    onShareClick: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: ArticleDetailViewModel = koinViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    LaunchedEffect(articleId) {
        viewModel.onEvent(ArticleDetailEvent.LoadArticle(articleId))
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Article Details") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    state.article?.let { article ->
                        IconButton(onClick = { viewModel.onEvent(ArticleDetailEvent.ToggleFavorite) }) {
                            Icon(
                                imageVector = if (article.isFavorite) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                                contentDescription = if (article.isFavorite) "Remove from favorites" else "Add to favorites",
                                tint = if (article.isFavorite) androidx.compose.ui.graphics.Color.Red else MaterialTheme.colorScheme.onSurface
                            )
                        }
                        IconButton(onClick = onShareClick) {
                            Icon(
                                imageVector = Icons.Default.Share,
                                contentDescription = "Share"
                            )
                        }
                    }
                }
            )
        },
        modifier = modifier
    ) { paddingValues ->
        Box(modifier = Modifier.padding(paddingValues)) {
            when {
                state.isLoading -> {
                    LoadingIndicator(message = "Loading article...")
                }

                state.error != null -> {
                    ErrorView(
                        message = state.error ?: "Failed to load article",
                        onRetry = { viewModel.onEvent(ArticleDetailEvent.LoadArticle(articleId)) }
                    )
                }

                state.article != null -> {
                    ArticleDetailContent(article = state.article!!)
                }
            }
        }
    }
}

@Composable
private fun ArticleDetailContent(
    article: Article,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
    ) {
        // Article Image
        article.imageUrl?.let { imageUrl ->
            AsyncImage(
                model = imageUrl,
                contentDescription = article.title,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(300.dp),
                contentScale = ContentScale.Crop
            )
        }

        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Category Badge
            CategoryBadge(category = article.category)

            // Title
            Text(
                text = article.title,
                style = MaterialTheme.typography.headlineSmall
            )

            // Author and metadata
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "By ${article.author}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = formatPublishedDate(article.publishedAt.toLocalDateTime(TimeZone.currentSystemDefault())),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Text(
                    text = "${article.readTimeMinutes} min read",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            HorizontalDivider()

            // Summary
            Text(
                text = article.summary,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            HorizontalDivider()

            // Content
            Text(
                text = article.content,
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Justify
            )

            // Tags
            if (article.tags.isNotEmpty()) {
                HorizontalDivider()
                Text(
                    text = "Tags",
                    style = MaterialTheme.typography.titleSmall
                )
                TagsRow(tags = article.tags)
            }
        }
    }
}

@Composable
private fun CategoryBadge(category: com.amit.newsreader.domain.model.ArticleCategory) {
    val color = when (category) {
        com.amit.newsreader.domain.model.ArticleCategory.TECHNOLOGY -> TechnologyColor
        com.amit.newsreader.domain.model.ArticleCategory.BUSINESS -> BusinessColor
        com.amit.newsreader.domain.model.ArticleCategory.ENTERTAINMENT -> EntertainmentColor
        com.amit.newsreader.domain.model.ArticleCategory.SPORTS -> SportsColor
        com.amit.newsreader.domain.model.ArticleCategory.SCIENCE -> ScienceColor
        com.amit.newsreader.domain.model.ArticleCategory.HEALTH -> HealthColor
    }

    Surface(
        color = color.copy(alpha = 0.2f),
        shape = MaterialTheme.shapes.small
    ) {
        Text(
            text = category.displayName,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            style = MaterialTheme.typography.labelMedium,
            color = color
        )
    }
}

@Composable
private fun TagsRow(tags: List<String>) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        tags.forEach { tag ->
            AssistChip(
                onClick = { },
                label = { Text(tag) }
            )
        }
    }
}

private fun formatPublishedDate(date: kotlinx.datetime.LocalDateTime): String {
    return "${date.date.day} ${date.month.name.lowercase().replaceFirstChar { it.uppercase() }} ${date.year}"
}

//
//  FavoritesView.swift
//  IosNativeBuild
//
//  Favorites Screen - matches KMP FavoritesScreen in NavGraph.kt
//

import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = NewsListViewModel(autoLoad: false)

    let onArticleClick: (String) -> Void
    let onBackClick: () -> Void

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.articles.isEmpty {
                LoadingView(message: "Loading favorites...")
            } else if let errorMessage = viewModel.error, viewModel.articles.isEmpty {
                ErrorStateView(
                    message: errorMessage,
                    onRetry: {
                        viewModel.loadFavorites()
                    }
                )
            } else if viewModel.articles.isEmpty {
                EmptyStateView(message: "No favorites yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.articles) { article in
                            ArticleCard(
                                article: article,
                                onClick: {
                                    onArticleClick(article.id)
                                },
                                onFavoriteClick: {
                                    viewModel.toggleFavorite(article.id)
                                }
                            )
                        }
                    }
                    .padding(16)
                }
                .accessibilityIdentifier("favorites_scroll_view")
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBackClick) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppTheme.onSurface)
                }
            }
        }
        .onAppear {
            viewModel.loadFavorites()
        }
    }
}

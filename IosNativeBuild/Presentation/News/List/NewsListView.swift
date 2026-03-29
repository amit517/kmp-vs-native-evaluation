//
//  NewsListView.swift
//  IosNativeBuild
//
//  Main News List Screen with Category Filtering
//

import SwiftUI

struct NewsListView: View {
    @StateObject private var viewModel = NewsListViewModel()
    @State private var showSearchBar = false

    let onArticleClick: (String) -> Void
    let onFavoritesClick: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Collapsible Search Bar
            if showSearchBar {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search articles...", text: $viewModel.searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Category Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // "All" chip
                    CategoryChip(
                        category: nil,
                        isSelected: viewModel.selectedCategory == nil
                    ) {
                        viewModel.selectCategory(nil)
                    }

                    // Category chips
                    ForEach(ArticleCategory.allCases) { category in
                        CategoryChip(
                            category: category,
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            viewModel.selectCategory(category)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // Content
            ZStack {
                if viewModel.isLoading && viewModel.articles.isEmpty {
                    LoadingView(message: "Loading articles...")
                } else if let errorMessage = viewModel.error, viewModel.articles.isEmpty {
                    ErrorStateView(
                        message: errorMessage,
                        onRetry: {
                            Task { await viewModel.loadArticles() }
                        }
                    )
                } else if !viewModel.isLoading && viewModel.articles.isEmpty {
                    if viewModel.searchQuery.isEmpty {
                        EmptyStateView(message: "No articles available")
                    } else {
                        EmptyStateView(message: "No articles found for '\(viewModel.searchQuery)'")
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(viewModel.articles.enumerated()), id: \.element.id) { index, article in
                                ArticleCard(
                                    article: article,
                                    onClick: {
                                        onArticleClick(article.id)
                                    },
                                    onFavoriteClick: {
                                        viewModel.toggleFavorite(article.id)
                                    }
                                )
                                .onAppear {
                                    // Pagination: load more when within 3 items of end
                                    if index >= viewModel.articles.count - 3 {
                                        Task { await viewModel.loadMoreArticles() }
                                    }
                                }
                            }

                            // Loading more indicator
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding(16)
                    }
                    .refreshable {
                        await viewModel.refreshArticles()
                    }
                }

                // Snackbar error overlay (when articles exist but fetch failed)
                if viewModel.error != nil && !viewModel.articles.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Text(viewModel.error ?? "")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .lineLimit(2)

                            Spacer()

                            Button("Dismiss") {
                                viewModel.clearError()
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color(.darkGray))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: viewModel.error)
                }
            }
        }
        .navigationTitle("News Reader")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        withAnimation {
                            showSearchBar.toggle()
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }

                    Button {
                        onFavoritesClick()
                    } label: {
                        Image(systemName: "heart")
                    }
                }
            }
        }
    }
}

//
//  NewsListView.swift
//  IosNativeBuild
//
//  Main News List Screen with Category Filtering
//

import SwiftUI

struct NewsListView: View {
    @StateObject private var viewModel = NewsListViewModel()
    @State private var selectedArticle: Article?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search articles...", text: $viewModel.searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)

                // Category Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
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
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }

                // Article List
                if viewModel.isLoading && viewModel.articles.isEmpty {
                    Spacer()
                    ProgressView("Loading articles...")
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage, viewModel.articles.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(AppTheme.error)

                        Text("Error")
                            .font(.headline)

                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Retry") {
                            Task {
                                await viewModel.loadArticles()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                } else {
                    List(viewModel.filteredArticles) { article in
                        ArticleCard(
                            article: article,
                            onFavoriteClick: {
                                viewModel.toggleFavorite(article.id)
                            }
                        )
                        .onTapGesture {
                            selectedArticle = article
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.refreshArticles()
                    }
                }
            }
            .navigationTitle("News Reader")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
        }
    }
}

#Preview {
    NewsListView()
}
//
//  ArticleDetailView.swift
//  IosNativeBuild
//
//  Article Detail Screen
//

import SwiftUI

struct ArticleDetailView: View {
    let articleId: String
    let onNavigateBack: () -> Void

    @StateObject private var viewModel = ArticleDetailViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading || (viewModel.article == nil && viewModel.error == nil) {
                LoadingView(message: "Loading article...")
            } else if let errorMessage = viewModel.error, viewModel.article == nil {
                ErrorStateView(
                    message: errorMessage,
                    onRetry: {
                        Task { await viewModel.loadArticle(id: articleId) }
                    }
                )
            } else if let article = viewModel.article {
                ArticleDetailContent(article: article)
            }
        }
        .navigationTitle("Article Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onNavigateBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppTheme.onSurface)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if let article = viewModel.article {
                    Button {
                        viewModel.toggleFavorite()
                    } label: {
                        Image(systemName: article.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(article.isFavorite ? .red : AppTheme.onSurface)
                    }
                }
            }
        }
        .task {
            await viewModel.loadArticle(id: articleId)
        }
    }
}

private struct ArticleDetailContent: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Article Image
                if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .background(Color.gray.opacity(0.1))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .clipped()
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .foregroundColor(.gray)
                                .background(Color.gray.opacity(0.1))
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Category Badge
                    DetailCategoryBadge(category: article.category)

                    // Title
                    Text(article.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.onSurface)
                        .accessibilityIdentifier("article_detail_title")

                    // Author and metadata
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("By \(article.author)")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.primary)

                            Text(formatDate(article.publishedAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("\(article.readTimeMinutes) min read")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Summary
                    Text(article.summary)
                        .font(.body)
                        .foregroundColor(.secondary)

                    Divider()

                    // Content
                    Text(article.content)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.onSurface)
                        .lineSpacing(6)
                        .multilineTextAlignment(.leading)

                    // Tags
                    if !article.tags.isEmpty {
                        Divider()

                        Text("Tags")
                            .font(.headline)
                            .padding(.bottom, 4)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(article.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .accessibilityIdentifier("article_detail_scroll")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}

private struct DetailCategoryBadge: View {
    let category: ArticleCategory

    var body: some View {
        let color = AppTheme.categoryColor(for: category)
        Text(category.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.2))
            .cornerRadius(4)
    }
}

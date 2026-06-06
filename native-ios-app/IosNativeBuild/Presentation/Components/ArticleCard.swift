//
//  ArticleCard.swift
//  IosNativeBuild
//
//  Reusable Article Card Component
//

import SwiftUI

struct ArticleCard: View {
    let article: Article
    let onClick: () -> Void
    let onFavoriteClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            VStack(alignment: .leading, spacing: 0) {
                // Article Image
                if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color.gray.opacity(0.1))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .foregroundColor(.gray)
                                .background(Color.gray.opacity(0.1))
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 0) {
                    // Category Badge
                    CategoryBadge(category: article.category)

                    Spacer().frame(height: 8)

                    // Title
                    Text(article.title)
                        .font(.headline)
                        .foregroundColor(AppTheme.onSurface)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer().frame(height: 4)

                    // Summary
                    Text(article.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    Spacer().frame(height: 12)

                    // Bottom Row: Author, Time, Favorite
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(article.author)
                                .font(.caption)
                                .foregroundColor(AppTheme.primary)

                            Text("\(article.readTimeMinutes) min read")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: onFavoriteClick) {
                            Image(systemName: article.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(article.isFavorite ? .red : .secondary)
                                .imageScale(.large)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

private struct CategoryBadge: View {
    let category: ArticleCategory

    var body: some View {
        let color = AppTheme.categoryColor(for: category)
        Text(category.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .cornerRadius(4)
    }
}

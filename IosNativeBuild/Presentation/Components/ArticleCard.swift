//
//  ArticleCard.swift
//  IosNativeBuild
//
//  Reusable Article Card Component
//

import SwiftUI

struct ArticleCard: View {
    let article: Article
    let onFavoriteClick: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Article Image
            AsyncImage(url: URL(string: article.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 80)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .cornerRadius(8)

            // Article Content
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(AppTheme.onSurface)

                Text(article.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(article.category.displayName)
                        .font(.caption)
                        .foregroundColor(AppTheme.categoryColor(for: article.category))

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatDate(article.publishedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Favorite Button
            Button(action: onFavoriteClick) {
                Image(systemName: article.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(article.isFavorite ? .red : .gray)
                    .imageScale(.large)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
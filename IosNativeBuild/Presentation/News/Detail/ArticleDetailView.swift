//
//  ArticleDetailView.swift
//  IosNativeBuild
//
//  Article Detail Screen
//

import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Article Image
                    if let imageUrl = article.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 250)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 250)
                                    .clipped()
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 250)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        // Category Badge
                        Text(article.category.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.categoryColor(for: article.category))
                            .cornerRadius(12)

                        // Title
                        Text(article.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.onSurface)

                        // Meta Information
                        HStack(spacing: 12) {
                            Label(article.author, systemImage: "person.circle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("•")
                                .foregroundColor(.secondary)

                            Label(formatDate(article.publishedAt), systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("•")
                                .foregroundColor(.secondary)

                            Label("\(article.readTimeMinutes) min", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Divider()
                            .padding(.vertical, 4)

                        // Summary
                        Text(article.summary)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)

                        // Content
                        Text(article.content)
                            .font(.body)
                            .foregroundColor(AppTheme.onSurface)
                            .lineSpacing(6)

                        // Tags
                        if !article.tags.isEmpty {
                            Divider()
                                .padding(.vertical, 8)

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
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(AppTheme.onSurface)
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
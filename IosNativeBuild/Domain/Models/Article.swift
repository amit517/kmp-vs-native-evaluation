//
//  Article.swift
//  IosNativeBuild
//
//  Domain Model for Article
//

import Foundation

struct Article: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let content: String
    let summary: String
    let imageUrl: String?
    let author: String
    let publishedAt: Date
    let category: ArticleCategory
    let readTimeMinutes: Int
    let tags: [String]
    var isFavorite: Bool

    init(
        id: String,
        title: String,
        content: String,
        summary: String,
        imageUrl: String?,
        author: String,
        publishedAt: Date,
        category: ArticleCategory,
        readTimeMinutes: Int,
        tags: [String],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.summary = summary
        self.imageUrl = imageUrl
        self.author = author
        self.publishedAt = publishedAt
        self.category = category
        self.readTimeMinutes = readTimeMinutes
        self.tags = tags
        self.isFavorite = isFavorite
    }

    static func == (lhs: Article, rhs: Article) -> Bool {
        lhs.id == rhs.id
    }
}
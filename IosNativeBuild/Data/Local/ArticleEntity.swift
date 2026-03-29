//
//  ArticleEntity.swift
//  IosNativeBuild
//
//  SwiftData entity matching KMP Room ArticleEntity
//

import Foundation
import SwiftData

@Model
final class ArticleEntity {
    @Attribute(.unique) var id: String
    var title: String
    var content: String
    var summary: String
    var imageUrl: String?
    var author: String
    var publishedAt: Double     // epoch milliseconds
    var category: String
    var readTimeMinutes: Int
    var tags: String            // comma-separated
    var isFavorite: Bool
    var cachedAt: Double        // epoch milliseconds

    init(
        id: String,
        title: String,
        content: String,
        summary: String,
        imageUrl: String?,
        author: String,
        publishedAt: Double,
        category: String,
        readTimeMinutes: Int,
        tags: String,
        isFavorite: Bool = false,
        cachedAt: Double = Date().timeIntervalSince1970 * 1000
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
        self.cachedAt = cachedAt
    }
}

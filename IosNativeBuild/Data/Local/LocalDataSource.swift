//
//  LocalDataSource.swift
//  IosNativeBuild
//
//  Actor wrapping SwiftData operations (combines KMP DAO + LocalDataSource)
//

import Foundation
import SwiftData

actor LocalDataSource {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Query Operations

    func getAllArticles() throws -> [ArticleEntity] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ArticleEntity>(
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func getArticlesByCategory(_ category: String) throws -> [ArticleEntity] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ArticleEntity>(
            predicate: #Predicate { $0.category == category },
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func getArticleById(_ id: String) throws -> ArticleEntity? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ArticleEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func searchArticles(query: String) throws -> [ArticleEntity] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ArticleEntity>(
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
        )
        let all = try context.fetch(descriptor)
        let lowercased = query.lowercased()
        return all.filter { entity in
            entity.title.lowercased().contains(lowercased) ||
            entity.content.lowercased().contains(lowercased) ||
            entity.author.lowercased().contains(lowercased) ||
            entity.tags.lowercased().contains(lowercased)
        }
    }

    func getFavoriteArticles() throws -> [ArticleEntity] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ArticleEntity>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func countArticles() throws -> Int {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ArticleEntity>()
        return try context.fetchCount(descriptor)
    }

    // MARK: - Write Operations

    func updateFavoriteStatus(id: String, isFavorite: Bool) throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ArticleEntity>(
            predicate: #Predicate { $0.id == id }
        )
        if let entity = try context.fetch(descriptor).first {
            entity.isFavorite = isFavorite
            try context.save()
        }
    }

    func upsertArticlesPreservingFavorites(_ entities: [ArticleEntity]) throws {
        let context = ModelContext(modelContainer)
        for entity in entities {
            let entityId = entity.id
            let descriptor = FetchDescriptor<ArticleEntity>(
                predicate: #Predicate { $0.id == entityId }
            )
            let existing = try context.fetch(descriptor).first
            let preservedFavorite = existing?.isFavorite ?? false

            if let existing = existing {
                existing.title = entity.title
                existing.content = entity.content
                existing.summary = entity.summary
                existing.imageUrl = entity.imageUrl
                existing.author = entity.author
                existing.publishedAt = entity.publishedAt
                existing.category = entity.category
                existing.readTimeMinutes = entity.readTimeMinutes
                existing.tags = entity.tags
                existing.isFavorite = preservedFavorite
                existing.cachedAt = entity.cachedAt
            } else {
                entity.isFavorite = preservedFavorite
                context.insert(entity)
            }
        }
        try context.save()
    }
}

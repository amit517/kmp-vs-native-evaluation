//
//  NewsRepository.swift
//  IosNativeBuild
//
//  Repository for managing article data
//

import Foundation

protocol NewsRepository {
    func getArticles(page: Int, pageSize: Int) async throws -> [Article]
    func getArticlesByCategory(_ category: ArticleCategory, page: Int, pageSize: Int) async throws -> [Article]
    func searchArticles(query: String) async throws -> [Article]
    func getArticleById(id: String) async throws -> Article
    func toggleFavorite(articleId: String) async
    func getFavoriteArticles() -> [Article]
}

class NewsRepositoryImpl: NewsRepository {
    private let apiService: NewsAPIService
    private var cachedArticles: [Article] = []
    private var favoriteIds: Set<String> = []

    init(apiService: NewsAPIService = .shared) {
        self.apiService = apiService
        loadFavorites()
    }

    func getArticles(page: Int = 1, pageSize: Int = 20) async throws -> [Article] {
        let response = try await apiService.getArticles(page: page, pageSize: pageSize)
        var articles = ArticleMapper.toDomainList(response.articles)

        // Apply favorite status
        articles = articles.map { article in
            var updatedArticle = article
            updatedArticle.isFavorite = favoriteIds.contains(article.id)
            return updatedArticle
        }

        if page == 1 {
            cachedArticles = articles
        } else {
            // Append for pagination, avoiding duplicates
            let existingIds = Set(cachedArticles.map { $0.id })
            let newArticles = articles.filter { !existingIds.contains($0.id) }
            cachedArticles.append(contentsOf: newArticles)
        }
        return articles
    }

    func getArticlesByCategory(_ category: ArticleCategory, page: Int = 1, pageSize: Int = 20) async throws -> [Article] {
        let response = try await apiService.getArticlesByCategory(category: category, page: page, pageSize: pageSize)
        var articles = ArticleMapper.toDomainList(response.articles)

        // Apply favorite status
        articles = articles.map { article in
            var updatedArticle = article
            updatedArticle.isFavorite = favoriteIds.contains(article.id)
            return updatedArticle
        }

        return articles
    }

    func searchArticles(query: String) async throws -> [Article] {
        // Search locally through cached articles (matches KMP behavior)
        let lowercased = query.lowercased()
        return cachedArticles.filter { article in
            article.title.lowercased().contains(lowercased) ||
            article.content.lowercased().contains(lowercased) ||
            article.author.lowercased().contains(lowercased) ||
            article.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }

    func getArticleById(id: String) async throws -> Article {
        do {
            let dto = try await apiService.getArticleById(id: id)
            var article = ArticleMapper.toDomain(dto)
            article.isFavorite = favoriteIds.contains(article.id)
            return article
        } catch {
            // Fallback to cached article
            if let cached = cachedArticles.first(where: { $0.id == id }) {
                return cached
            }
            throw error
        }
    }

    func toggleFavorite(articleId: String) async {
        if favoriteIds.contains(articleId) {
            favoriteIds.remove(articleId)
        } else {
            favoriteIds.insert(articleId)
        }
        saveFavorites()

        // Update cached articles
        cachedArticles = cachedArticles.map { article in
            var updatedArticle = article
            if updatedArticle.id == articleId {
                updatedArticle.isFavorite = favoriteIds.contains(articleId)
            }
            return updatedArticle
        }
    }

    func getFavoriteArticles() -> [Article] {
        return cachedArticles.filter { favoriteIds.contains($0.id) }
    }

    // MARK: - Persistence

    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "favoriteArticles"),
           let favorites = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteIds = favorites
        }
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteIds) {
            UserDefaults.standard.set(data, forKey: "favoriteArticles")
        }
    }
}
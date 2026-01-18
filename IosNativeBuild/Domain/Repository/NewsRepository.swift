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

        cachedArticles = articles
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
        let response = try await apiService.searchArticles(query: query)
        var articles = ArticleMapper.toDomainList(response.articles)

        // Apply favorite status
        articles = articles.map { article in
            var updatedArticle = article
            updatedArticle.isFavorite = favoriteIds.contains(article.id)
            return updatedArticle
        }

        return articles
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
//
//  NewsRepository.swift
//  IosNativeBuild
//
//  Repository protocol for managing article data
//  All methods return AppResult<T> matching KMP pattern
//

import Foundation

protocol NewsRepository {
    func getArticles(
        page: Int,
        limit: Int,
        category: ArticleCategory?,
        forceRefresh: Bool
    ) async -> AppResult<[Article]>

    func getArticleById(id: String) async -> AppResult<Article>

    func searchArticles(query: String) async -> AppResult<[Article]>

    func getFavoriteArticles() async -> AppResult<[Article]>

    func toggleFavorite(articleId: String) async -> AppResult<Void>

    func refreshArticles(
        page: Int,
        limit: Int,
        category: ArticleCategory?
    ) async -> AppResult<Void>
}

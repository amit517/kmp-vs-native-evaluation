//
//  NewsRepositoryImpl.swift
//  IosNativeBuild
//
//  Offline-first repository matching KMP NewsRepositoryImpl
//

import Foundation

class NewsRepositoryImpl: NewsRepository {
    private let apiService: NewsAPIService
    private let localDataSource: LocalDataSource

    init(apiService: NewsAPIService, localDataSource: LocalDataSource) {
        self.apiService = apiService
        self.localDataSource = localDataSource
    }

    func getArticles(
        page: Int = 1,
        limit: Int = 20,
        category: ArticleCategory? = nil,
        forceRefresh: Bool = false
    ) async -> AppResult<[Article]> {
        // Try network first
        let networkResult: AppResult<[ArticleDTO]> = await safeCall {
            if let category = category {
                let response = try await self.apiService.getArticlesByCategory(
                    category: category, page: page, pageSize: limit
                )
                return response.articles
            } else {
                let response = try await self.apiService.getArticles(
                    page: page, pageSize: limit
                )
                return response.articles
            }
        }

        switch networkResult {
        case .success(let dtos):
            // Cache to DB preserving favorites (only for unfiltered queries)
            if category == nil {
                let entities = ArticleMapper.toEntityList(dtos)
                do {
                    try await localDataSource.upsertArticlesPreservingFavorites(entities)
                    let dbEntities = try await localDataSource.getAllArticles()
                    return .success(ArticleMapper.entityToDomainList(dbEntities))
                } catch {
                    // DB write failed, return network data directly
                    return .success(ArticleMapper.toDomainList(dtos))
                }
            } else {
                return .success(ArticleMapper.toDomainList(dtos))
            }

        case .error(let error, let message):
            // Fallback to cache
            if !forceRefresh {
                do {
                    let count = try await localDataSource.countArticles()
                    if count > 0 {
                        let cached: [ArticleEntity]
                        if let category = category {
                            cached = try await localDataSource.getArticlesByCategory(category.displayName)
                        } else {
                            cached = try await localDataSource.getAllArticles()
                        }
                        return .success(ArticleMapper.entityToDomainList(cached))
                    }
                } catch {
                    // DB read also failed
                }
            }
            return .error(error, message)

        case .loading:
            return .loading
        }
    }

    func getArticleById(id: String) async -> AppResult<Article> {
        // Check existing favorite status
        let existingFavorite: Bool
        do {
            existingFavorite = try await localDataSource.getArticleById(id)?.isFavorite ?? false
        } catch {
            existingFavorite = false
        }

        // Try network
        let networkResult: AppResult<ArticleDTO> = await safeCall {
            try await self.apiService.getArticleById(id: id)
        }

        switch networkResult {
        case .success(let dto):
            var article = ArticleMapper.toDomain(dto)
            article.isFavorite = existingFavorite

            // Cache the article
            let entity = ArticleMapper.toEntity(dto, isFavorite: existingFavorite)
            do {
                try await localDataSource.upsertArticlesPreservingFavorites([entity])
            } catch {
                // Cache failed, still return the article
            }
            return .success(article)

        case .error(let error, let message):
            // Fallback to cache
            do {
                if let cached = try await localDataSource.getArticleById(id) {
                    return .success(ArticleMapper.toDomain(cached))
                }
            } catch {
                // DB read failed
            }
            return .error(error, message)

        case .loading:
            return .loading
        }
    }

    func searchArticles(query: String) async -> AppResult<[Article]> {
        // Local DB search only (matching KMP behavior)
        do {
            let entities = try await localDataSource.searchArticles(query: query)
            return .success(ArticleMapper.entityToDomainList(entities))
        } catch {
            return .error(error, error.localizedDescription)
        }
    }

    func getFavoriteArticles() async -> AppResult<[Article]> {
        do {
            let entities = try await localDataSource.getFavoriteArticles()
            return .success(ArticleMapper.entityToDomainList(entities))
        } catch {
            return .error(error, error.localizedDescription)
        }
    }

    func toggleFavorite(articleId: String) async -> AppResult<Void> {
        do {
            let existing = try await localDataSource.getArticleById(articleId)
            let newStatus = !(existing?.isFavorite ?? false)
            try await localDataSource.updateFavoriteStatus(id: articleId, isFavorite: newStatus)
            return .success(())
        } catch {
            return .error(error, error.localizedDescription)
        }
    }

    func refreshArticles(
        page: Int = 1,
        limit: Int = 20,
        category: ArticleCategory? = nil
    ) async -> AppResult<Void> {
        let networkResult: AppResult<[ArticleDTO]> = await safeCall {
            if let category = category {
                let response = try await self.apiService.getArticlesByCategory(
                    category: category, page: page, pageSize: limit
                )
                return response.articles
            } else {
                let response = try await self.apiService.getArticles(
                    page: page, pageSize: limit
                )
                return response.articles
            }
        }

        switch networkResult {
        case .success(let dtos):
            let entities = ArticleMapper.toEntityList(dtos)
            do {
                try await localDataSource.upsertArticlesPreservingFavorites(entities)
            } catch {
                return .error(error, error.localizedDescription)
            }
            return .success(())
        case .error(let error, let message):
            return .error(error, message)
        case .loading:
            return .loading
        }
    }
}

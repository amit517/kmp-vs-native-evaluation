//
//  DependencyContainer.swift
//  IosNativeBuild
//
//  Centralized DI container matching KMP Koin module
//

import Foundation
import SwiftData

final class DependencyContainer {
    static let shared = DependencyContainer()

    // MARK: - Core Infrastructure

    lazy var modelContainer: ModelContainer = {
        let schema = Schema([ArticleEntity.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    // MARK: - Data Layer

    lazy var localDataSource: LocalDataSource = {
        LocalDataSource(modelContainer: modelContainer)
    }()

    lazy var apiService: NewsAPIService = {
        NewsAPIService()
    }()

    // MARK: - Repository

    lazy var newsRepository: NewsRepository = {
        NewsRepositoryImpl(
            apiService: apiService,
            localDataSource: localDataSource
        )
    }()

    // MARK: - Use Cases

    lazy var getArticlesUseCase: GetArticlesUseCase = {
        GetArticlesUseCase(repository: newsRepository)
    }()

    lazy var getArticleDetailUseCase: GetArticleDetailUseCase = {
        GetArticleDetailUseCase(repository: newsRepository)
    }()

    lazy var searchArticlesUseCase: SearchArticlesUseCase = {
        SearchArticlesUseCase(repository: newsRepository)
    }()

    lazy var getFavoriteArticlesUseCase: GetFavoriteArticlesUseCase = {
        GetFavoriteArticlesUseCase(repository: newsRepository)
    }()

    lazy var toggleFavoriteUseCase: ToggleFavoriteUseCase = {
        ToggleFavoriteUseCase(repository: newsRepository)
    }()

    lazy var refreshArticlesUseCase: RefreshArticlesUseCase = {
        RefreshArticlesUseCase(repository: newsRepository)
    }()
}

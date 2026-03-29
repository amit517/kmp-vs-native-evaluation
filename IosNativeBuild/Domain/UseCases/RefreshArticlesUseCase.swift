//
//  RefreshArticlesUseCase.swift
//  IosNativeBuild
//

import Foundation

class RefreshArticlesUseCase {
    private let repository: NewsRepository

    init(repository: NewsRepository) {
        self.repository = repository
    }

    func execute(
        page: Int = 1,
        limit: Int = 20,
        category: ArticleCategory? = nil
    ) async -> AppResult<Void> {
        return await repository.refreshArticles(
            page: page, limit: limit, category: category
        )
    }
}

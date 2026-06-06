//
//  GetArticlesUseCase.swift
//  IosNativeBuild
//

import Foundation

class GetArticlesUseCase {
    private let repository: NewsRepository

    init(repository: NewsRepository) {
        self.repository = repository
    }

    func execute(
        page: Int = 1,
        limit: Int = 20,
        category: ArticleCategory? = nil,
        forceRefresh: Bool = false
    ) async -> AppResult<[Article]> {
        return await repository.getArticles(
            page: page, limit: limit, category: category, forceRefresh: forceRefresh
        )
    }
}

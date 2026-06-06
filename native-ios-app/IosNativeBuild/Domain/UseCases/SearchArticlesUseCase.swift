//
//  SearchArticlesUseCase.swift
//  IosNativeBuild
//

import Foundation

class SearchArticlesUseCase {
    private let repository: NewsRepository

    init(repository: NewsRepository) {
        self.repository = repository
    }

    func execute(query: String) async -> AppResult<[Article]> {
        return await repository.searchArticles(query: query)
    }
}

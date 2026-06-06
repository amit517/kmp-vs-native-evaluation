//
//  GetFavoriteArticlesUseCase.swift
//  IosNativeBuild
//

import Foundation

class GetFavoriteArticlesUseCase {
    private let repository: NewsRepository

    init(repository: NewsRepository) {
        self.repository = repository
    }

    func execute() async -> AppResult<[Article]> {
        return await repository.getFavoriteArticles()
    }
}

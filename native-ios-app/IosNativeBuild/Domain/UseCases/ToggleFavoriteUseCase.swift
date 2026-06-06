//
//  ToggleFavoriteUseCase.swift
//  IosNativeBuild
//

import Foundation

class ToggleFavoriteUseCase {
    private let repository: NewsRepository

    init(repository: NewsRepository) {
        self.repository = repository
    }

    func execute(articleId: String) async -> AppResult<Void> {
        return await repository.toggleFavorite(articleId: articleId)
    }
}

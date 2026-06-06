//
//  GetArticleDetailUseCase.swift
//  IosNativeBuild
//

import Foundation

class GetArticleDetailUseCase {
    private let repository: NewsRepository

    init(repository: NewsRepository) {
        self.repository = repository
    }

    func execute(articleId: String) async -> AppResult<Article> {
        return await repository.getArticleById(id: articleId)
    }
}

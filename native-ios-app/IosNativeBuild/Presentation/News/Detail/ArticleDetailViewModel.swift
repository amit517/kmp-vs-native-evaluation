//
//  ArticleDetailViewModel.swift
//  IosNativeBuild
//
//  ViewModel for Article Detail Screen — uses Use Cases + AppResult
//

import Foundation
import Combine

@MainActor
class ArticleDetailViewModel: ObservableObject {
    @Published var article: Article? = nil
    @Published var isLoading = false
    @Published var error: String? = nil

    private let getArticleDetailUseCase: GetArticleDetailUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase

    init(
        getArticleDetailUseCase: GetArticleDetailUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase
    ) {
        self.getArticleDetailUseCase = getArticleDetailUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
    }

    // Convenience init using DI container (keeps Views unchanged)
    convenience init() {
        let container = DependencyContainer.shared
        self.init(
            getArticleDetailUseCase: container.getArticleDetailUseCase,
            toggleFavoriteUseCase: container.toggleFavoriteUseCase
        )
    }

    func loadArticle(id: String) async {
        isLoading = true
        error = nil

        let result = await getArticleDetailUseCase.execute(articleId: id)

        switch result {
        case .success(let fetched):
            article = fetched
        case .error(_, let message):
            self.error = message ?? "Failed to load article"
        case .loading:
            break
        }

        isLoading = false
    }

    func toggleFavorite() {
        guard var current = article else { return }
        // Optimistic update
        current.isFavorite.toggle()
        article = current

        Task {
            _ = await toggleFavoriteUseCase.execute(articleId: current.id)
        }
    }
}

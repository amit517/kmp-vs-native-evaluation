//
//  ArticleDetailViewModel.swift
//  IosNativeBuild
//
//  ViewModel for Article Detail Screen
//

import Foundation
import Combine

@MainActor
class ArticleDetailViewModel: ObservableObject {
    @Published var article: Article? = nil
    @Published var isLoading = false
    @Published var error: String? = nil

    private let repository: NewsRepository

    nonisolated init(repository: NewsRepository = NewsRepositoryImpl()) {
        self.repository = repository
    }

    func loadArticle(id: String) async {
        isLoading = true
        error = nil

        do {
            let fetched = try await repository.getArticleById(id: id)
            article = fetched
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func toggleFavorite() {
        guard var current = article else { return }
        // Optimistic update
        current.isFavorite.toggle()
        article = current

        Task {
            await repository.toggleFavorite(articleId: current.id)
        }
    }
}

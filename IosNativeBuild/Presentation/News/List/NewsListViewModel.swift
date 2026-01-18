//
//  NewsListViewModel.swift
//  IosNativeBuild
//
//  ViewModel for News List Screen
//

import Foundation
import Combine

@MainActor
class NewsListViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var filteredArticles: [Article] = []
    @Published var selectedCategory: ArticleCategory?
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String?

    private let repository: NewsRepository
    private var cancellables = Set<AnyCancellable>()

    init(repository: NewsRepository = NewsRepositoryImpl()) {
        self.repository = repository

        // Setup search debouncing
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.filterArticles(query: query)
            }
            .store(in: &cancellables)

        // Load initial articles
        Task {
            await loadArticles()
        }
    }

    func loadArticles() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedArticles = try await repository.getArticles(page: 1, pageSize: 100)
            articles = fetchedArticles
            filteredArticles = fetchedArticles
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func refreshArticles() async {
        isRefreshing = true
        errorMessage = nil

        do {
            let fetchedArticles = try await repository.getArticles(page: 1, pageSize: 100)
            articles = fetchedArticles
            filterArticles()
            isRefreshing = false
        } catch {
            errorMessage = error.localizedDescription
            isRefreshing = false
        }
    }

    func selectCategory(_ category: ArticleCategory?) {
        selectedCategory = category
        filterArticles()
    }

    func toggleFavorite(_ articleId: String) {
        Task {
            await repository.toggleFavorite(articleId: articleId)

            // Update UI
            if let index = articles.firstIndex(where: { $0.id == articleId }) {
                articles[index].isFavorite.toggle()
            }
            if let index = filteredArticles.firstIndex(where: { $0.id == articleId }) {
                filteredArticles[index].isFavorite.toggle()
            }
        }
    }

    private func filterArticles(query: String? = nil) {
        let searchText = query ?? searchQuery

        var result = articles

        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Filter by search query
        if !searchText.isEmpty {
            result = result.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.summary.localizedCaseInsensitiveContains(searchText) ||
                article.author.localizedCaseInsensitiveContains(searchText)
            }
        }

        filteredArticles = result
    }
}
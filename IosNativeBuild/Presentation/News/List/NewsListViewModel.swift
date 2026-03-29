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
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var isLoadingMore = false
    @Published var error: String? = nil
    @Published var selectedCategory: ArticleCategory? = nil
    @Published var searchQuery = ""
    @Published var isSearching = false
    @Published var showFavoritesOnly = false
    @Published var currentPage = 1
    @Published var hasMorePages = true

    private let repository: NewsRepository
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    private let pageSize = 20

    init(repository: NewsRepository = NewsRepositoryImpl(), autoLoad: Bool = true) {
        self.repository = repository

        // Setup search debouncing
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                Task {
                    await self.performSearch(query)
                }
            }
            .store(in: &cancellables)

        // Load initial articles (skip for favorites-only usage)
        if autoLoad {
            Task {
                await loadArticles()
            }
        }
    }

    func loadArticles() async {
        isLoading = true
        error = nil
        currentPage = 1
        hasMorePages = true
        showFavoritesOnly = false

        do {
            let fetched: [Article]
            if let category = selectedCategory {
                fetched = try await repository.getArticlesByCategory(category, page: 1, pageSize: pageSize)
            } else {
                fetched = try await repository.getArticles(page: 1, pageSize: pageSize)
            }
            articles = fetched
            hasMorePages = fetched.count >= pageSize
        } catch {
            if articles.isEmpty {
                self.error = error.localizedDescription
            } else {
                // Keep existing articles, show snackbar error
                self.error = error.localizedDescription
            }
        }

        isLoading = false
    }

    func loadMoreArticles() async {
        guard !isLoadingMore && hasMorePages && !showFavoritesOnly else { return }

        isLoadingMore = true
        let nextPage = currentPage + 1

        do {
            let fetched: [Article]
            if let category = selectedCategory {
                fetched = try await repository.getArticlesByCategory(category, page: nextPage, pageSize: pageSize)
            } else {
                fetched = try await repository.getArticles(page: nextPage, pageSize: pageSize)
            }
            articles.append(contentsOf: fetched)
            currentPage = nextPage
            hasMorePages = fetched.count >= pageSize
        } catch {
            // Silently fail for load-more; user can scroll again
        }

        isLoadingMore = false
    }

    func refreshArticles() async {
        isRefreshing = true
        error = nil
        currentPage = 1
        hasMorePages = true

        do {
            let fetched: [Article]
            if let category = selectedCategory {
                fetched = try await repository.getArticlesByCategory(category, page: 1, pageSize: pageSize)
            } else {
                fetched = try await repository.getArticles(page: 1, pageSize: pageSize)
            }
            articles = fetched
            hasMorePages = fetched.count >= pageSize
        } catch {
            self.error = error.localizedDescription
        }

        isRefreshing = false
    }

    func selectCategory(_ category: ArticleCategory?) {
        selectedCategory = category
        searchQuery = ""
        isSearching = false
        searchTask?.cancel()
        Task {
            await loadArticles()
        }
    }

    private func performSearch(_ query: String) async {
        searchTask?.cancel()

        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            isSearching = false
            if showFavoritesOnly { return }
            await loadArticles()
            return
        }

        isSearching = true
        selectedCategory = nil

        searchTask = Task {
            do {
                let results = try await repository.searchArticles(query: query)
                if !Task.isCancelled {
                    articles = results
                    hasMorePages = false
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                }
            }
            if !Task.isCancelled {
                isSearching = false
            }
        }
    }

    func toggleFavorite(_ articleId: String) {
        // Optimistic update
        if let index = articles.firstIndex(where: { $0.id == articleId }) {
            articles[index].isFavorite.toggle()
        }
        Task {
            await repository.toggleFavorite(articleId: articleId)
        }
    }

    func loadFavorites() {
        showFavoritesOnly = true
        searchQuery = ""
        selectedCategory = nil
        hasMorePages = false
        isSearching = false

        let favorites = repository.getFavoriteArticles()
        articles = favorites
    }

    func clearError() {
        error = nil
    }
}

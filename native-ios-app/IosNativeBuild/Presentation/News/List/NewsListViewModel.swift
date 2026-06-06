//
//  NewsListViewModel.swift
//  IosNativeBuild
//
//  ViewModel for News List Screen — uses Use Cases + AppResult
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

    private let getArticlesUseCase: GetArticlesUseCase
    private let searchArticlesUseCase: SearchArticlesUseCase
    private let getFavoriteArticlesUseCase: GetFavoriteArticlesUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let refreshArticlesUseCase: RefreshArticlesUseCase

    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    private let pageSize = 20

    init(
        getArticlesUseCase: GetArticlesUseCase,
        searchArticlesUseCase: SearchArticlesUseCase,
        getFavoriteArticlesUseCase: GetFavoriteArticlesUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        refreshArticlesUseCase: RefreshArticlesUseCase,
        autoLoad: Bool = true
    ) {
        self.getArticlesUseCase = getArticlesUseCase
        self.searchArticlesUseCase = searchArticlesUseCase
        self.getFavoriteArticlesUseCase = getFavoriteArticlesUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.refreshArticlesUseCase = refreshArticlesUseCase

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

        if autoLoad {
            Task { await loadArticles() }
        }
    }

    // Convenience init using DI container (keeps Views unchanged)
    convenience init(autoLoad: Bool = true) {
        let container = DependencyContainer.shared
        self.init(
            getArticlesUseCase: container.getArticlesUseCase,
            searchArticlesUseCase: container.searchArticlesUseCase,
            getFavoriteArticlesUseCase: container.getFavoriteArticlesUseCase,
            toggleFavoriteUseCase: container.toggleFavoriteUseCase,
            refreshArticlesUseCase: container.refreshArticlesUseCase,
            autoLoad: autoLoad
        )
    }

    func loadArticles() async {
        isLoading = true
        error = nil
        currentPage = 1
        hasMorePages = true
        showFavoritesOnly = false

        let result = await getArticlesUseCase.execute(
            page: 1, limit: pageSize, category: selectedCategory, forceRefresh: false
        )

        switch result {
        case .success(let fetched):
            articles = fetched
            hasMorePages = fetched.count >= pageSize
        case .error(_, let message):
            if articles.isEmpty {
                self.error = message ?? "Failed to load articles"
            } else {
                self.error = message ?? "Failed to load articles"
            }
        case .loading:
            break
        }

        isLoading = false
    }

    func loadMoreArticles() async {
        guard !isLoadingMore && hasMorePages && !showFavoritesOnly else { return }

        isLoadingMore = true
        let nextPage = currentPage + 1

        let result = await getArticlesUseCase.execute(
            page: nextPage, limit: pageSize, category: selectedCategory, forceRefresh: false
        )

        switch result {
        case .success(let fetched):
            articles.append(contentsOf: fetched)
            currentPage = nextPage
            hasMorePages = fetched.count >= pageSize
        case .error:
            break
        case .loading:
            break
        }

        isLoadingMore = false
    }

    func refreshArticles() async {
        isRefreshing = true
        error = nil
        currentPage = 1
        hasMorePages = true

        let result = await getArticlesUseCase.execute(
            page: 1, limit: pageSize, category: selectedCategory, forceRefresh: true
        )

        switch result {
        case .success(let fetched):
            articles = fetched
            hasMorePages = fetched.count >= pageSize
        case .error(_, let message):
            self.error = message ?? "Failed to refresh"
        case .loading:
            break
        }

        isRefreshing = false
    }

    func selectCategory(_ category: ArticleCategory?) {
        selectedCategory = category
        searchQuery = ""
        isSearching = false
        searchTask?.cancel()
        Task { await loadArticles() }
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
            let result = await searchArticlesUseCase.execute(query: query)

            if !Task.isCancelled {
                switch result {
                case .success(let results):
                    articles = results
                    hasMorePages = false
                case .error(_, let message):
                    self.error = message ?? "Search failed"
                case .loading:
                    break
                }
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
            _ = await toggleFavoriteUseCase.execute(articleId: articleId)
        }
    }

    func loadFavorites() {
        showFavoritesOnly = true
        searchQuery = ""
        selectedCategory = nil
        hasMorePages = false
        isSearching = false

        Task {
            isLoading = true
            let result = await getFavoriteArticlesUseCase.execute()
            switch result {
            case .success(let favorites):
                articles = favorites
            case .error(_, let message):
                self.error = message ?? "Failed to load favorites"
            case .loading:
                break
            }
            isLoading = false
        }
    }

    func syncFavorites() {
        Task {
            let result = await getFavoriteArticlesUseCase.execute()
            if case .success(let favorites) = result {
                let favoriteIds = Set(favorites.map { $0.id })
                for i in articles.indices {
                    articles[i].isFavorite = favoriteIds.contains(articles[i].id)
                }
            }
        }
    }

    func clearError() {
        error = nil
    }
}

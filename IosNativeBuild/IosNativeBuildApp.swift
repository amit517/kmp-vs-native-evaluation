//
//  IosNativeBuildApp.swift
//  IosNativeBuild
//
//  Native iOS News Reader App
//

import SwiftUI

enum AppRoute: Hashable {
    case articleDetail(articleId: String)
    case favorites
}

@main
struct IosNativeBuildApp: App {
    @State private var path = NavigationPath()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                NewsListView(
                    onArticleClick: { articleId in
                        path.append(AppRoute.articleDetail(articleId: articleId))
                    },
                    onFavoritesClick: {
                        path.append(AppRoute.favorites)
                    }
                )
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .articleDetail(let articleId):
                        ArticleDetailView(
                            articleId: articleId,
                            onNavigateBack: {
                                path.removeLast()
                            }
                        )
                    case .favorites:
                        FavoritesView(
                            onArticleClick: { articleId in
                                path.append(AppRoute.articleDetail(articleId: articleId))
                            },
                            onBackClick: {
                                path.removeLast()
                            }
                        )
                    }
                }
            }
        }
    }
}

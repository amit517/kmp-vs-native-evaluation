package com.amit.newsreader.di

import com.amit.newsreader.config.ApiConfig
import com.amit.newsreader.data.local.DatabaseDriverFactory
import com.amit.newsreader.data.local.LocalDataSource
import com.amit.newsreader.data.remote.HttpClientFactory
import com.amit.newsreader.data.remote.NewsApiService
import com.amit.newsreader.data.repository.NewsRepositoryImpl
import com.amit.newsreader.domain.repository.NewsRepository
import com.amit.newsreader.domain.usecase.*
import org.koin.core.module.Module
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module

/**
 * Shared Koin module for dependency injection
 * Contains all common dependencies for both Android and iOS
 */

// Platform-specific module for providing platform dependencies
expect val platformModule: Module

// Common shared module
val sharedModule = module {
    // Network
    single { HttpClientFactory.create() }
    single { NewsApiService(get(), ApiConfig.BASE_URL) }

    // Database
    singleOf(::LocalDataSource)

    // Repository
    single<NewsRepository> { NewsRepositoryImpl(get(), get()) }

    // Use Cases
    singleOf(::GetArticlesUseCase)
    singleOf(::RefreshArticlesUseCase)
    singleOf(::ToggleFavoriteUseCase)
    singleOf(::SearchArticlesUseCase)
    singleOf(::GetArticleDetailUseCase)
    singleOf(::GetFavoriteArticlesUseCase)
}

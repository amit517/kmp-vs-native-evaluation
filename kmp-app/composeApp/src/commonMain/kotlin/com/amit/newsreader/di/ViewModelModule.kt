package com.amit.newsreader.di

import com.amit.newsreader.presentation.news.detail.ArticleDetailViewModel
import com.amit.newsreader.presentation.news.list.NewsListViewModel
import org.koin.core.module.dsl.viewModelOf
import org.koin.dsl.module

/**
 * Koin module for ViewModels
 * Available in composeApp module
 */
val viewModelModule = module {
    viewModelOf(::NewsListViewModel)
    viewModelOf(::ArticleDetailViewModel)
}
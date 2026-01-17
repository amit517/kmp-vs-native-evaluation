package com.amit.newsreader.di

import com.amit.newsreader.data.local.DatabaseDriverFactory
import org.koin.core.module.Module
import org.koin.dsl.module

/**
 * Android-specific Koin module
 * Provides Android Context and DatabaseDriverFactory
 */
actual val platformModule: Module = module {
    single { DatabaseDriverFactory(get()) }
}

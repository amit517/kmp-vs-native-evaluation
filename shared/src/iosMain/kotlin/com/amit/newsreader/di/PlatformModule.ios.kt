package com.amit.newsreader.di

import com.amit.newsreader.data.local.DatabaseDriverFactory
import org.koin.core.module.Module
import org.koin.dsl.module

/**
 * iOS-specific Koin module
 * Provides DatabaseDriverFactory for iOS
 */
actual val platformModule: Module = module {
    single { DatabaseDriverFactory() }
}

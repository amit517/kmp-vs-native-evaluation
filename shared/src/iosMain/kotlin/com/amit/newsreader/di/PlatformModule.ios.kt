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

/**
 * Base URL for iOS simulator
 * localhost works directly on iOS simulator
 */
actual fun getBaseUrl(): String = "http://localhost:8080"

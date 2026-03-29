package com.amit.newsreader.di

import com.amit.newsreader.data.local.DatabaseBuilder
import org.koin.core.module.Module
import org.koin.dsl.module

/**
 * iOS-specific Koin module
 * Provides DatabaseBuilder for iOS
 */
actual val platformModule: Module = module {
    single { DatabaseBuilder() }
}

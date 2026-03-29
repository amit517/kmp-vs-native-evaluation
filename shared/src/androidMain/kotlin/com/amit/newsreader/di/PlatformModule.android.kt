package com.amit.newsreader.di

import com.amit.newsreader.data.local.DatabaseBuilder
import org.koin.core.module.Module
import org.koin.dsl.module

/**
 * Android-specific Koin module
 * Provides Android Context and DatabaseBuilder
 */
actual val platformModule: Module = module {
    single { DatabaseBuilder(get()) }
}

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

/**
 * Base URL for Android emulator
 * 10.0.2.2 is the special IP for accessing localhost from Android emulator
 */
actual fun getBaseUrl(): String = "http://10.0.2.2:8080"

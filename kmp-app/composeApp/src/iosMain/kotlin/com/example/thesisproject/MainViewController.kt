package com.example.thesisproject

import androidx.compose.ui.window.ComposeUIViewController
import com.amit.newsreader.App
import com.amit.newsreader.di.initKoin
import com.amit.newsreader.di.viewModelModule

/**
 * Lazy initialization of Koin - initialized once on first access
 * This is thread-safe and idiomatic Kotlin
 */
private val koinInitializer by lazy {
    initKoin {
        modules(viewModelModule)
    }
}

/**
 * Entry point for iOS application
 * Returns a UIViewController that hosts the Compose UI
 */
fun MainViewController() = ComposeUIViewController {
    // Trigger lazy initialization of Koin
    koinInitializer
    App()
}

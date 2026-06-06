package com.amit.newsreader

import android.app.Application
import com.amit.newsreader.di.initKoin
import com.amit.newsreader.di.viewModelModule
import org.koin.android.ext.koin.androidContext
import org.koin.android.ext.koin.androidLogger
import org.koin.core.logger.Level

/**
 * Application class for initializing Koin dependency injection
 */
class NewsReaderApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        initKoin {
            androidLogger(Level.ERROR)
            androidContext(this@NewsReaderApplication)
            modules(viewModelModule)
        }
    }
}

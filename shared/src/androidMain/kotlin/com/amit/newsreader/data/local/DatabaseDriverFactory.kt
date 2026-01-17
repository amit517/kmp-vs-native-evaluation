package com.amit.newsreader.data.local

import android.content.Context
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.android.AndroidSqliteDriver
import com.amit.newsreader.database.NewsReaderDatabase

/**
 * Android implementation of DatabaseDriverFactory
 */
actual class DatabaseDriverFactory(private val context: Context) {
    actual fun createDriver(): SqlDriver {
        return AndroidSqliteDriver(
            schema = NewsReaderDatabase.Schema,
            context = context,
            name = "newsreader.db"
        )
    }
}

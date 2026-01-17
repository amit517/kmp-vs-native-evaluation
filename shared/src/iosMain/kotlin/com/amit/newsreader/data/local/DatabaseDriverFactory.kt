package com.amit.newsreader.data.local

import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.native.NativeSqliteDriver
import com.amit.newsreader.database.NewsReaderDatabase

/**
 * iOS implementation of DatabaseDriverFactory
 */
actual class DatabaseDriverFactory {
    actual fun createDriver(): SqlDriver {
        return NativeSqliteDriver(
            schema = NewsReaderDatabase.Schema,
            name = "newsreader.db"
        )
    }
}

package com.amit.newsreader.data.local

import android.content.Context
import androidx.room.Room
import androidx.sqlite.driver.bundled.BundledSQLiteDriver
import kotlinx.coroutines.Dispatchers

actual class DatabaseBuilder(private val context: Context) {
    actual fun build(): NewsReaderDatabase {
        val dbFile = context.applicationContext.getDatabasePath("newsreader.db")
        return Room.databaseBuilder<NewsReaderDatabase>(
            context = context.applicationContext,
            name = dbFile.absolutePath
        )
            .setDriver(BundledSQLiteDriver())
            .setQueryCoroutineContext(Dispatchers.IO)
            .build()
    }
}

package com.amit.newsreader.data.local

import androidx.room.ConstructedBy
import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.RoomDatabaseConstructor

@Database(entities = [ArticleEntity::class], version = 1)
@ConstructedBy(NewsReaderDatabaseConstructor::class)
abstract class NewsReaderDatabase : RoomDatabase() {
    abstract fun articleDao(): ArticleDao
}

@Suppress("NO_ACTUAL_FOR_EXPECT")
expect object NewsReaderDatabaseConstructor : RoomDatabaseConstructor<NewsReaderDatabase> {
    override fun initialize(): NewsReaderDatabase
}

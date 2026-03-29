package com.amit.newsreader.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface ArticleDao {

    @Query("SELECT * FROM ArticleEntity ORDER BY publishedAt DESC")
    fun selectAll(): Flow<List<ArticleEntity>>

    @Query("SELECT * FROM ArticleEntity WHERE category = :category ORDER BY publishedAt DESC")
    fun selectByCategory(category: String): Flow<List<ArticleEntity>>

    @Query("SELECT * FROM ArticleEntity WHERE id = :id")
    fun selectById(id: String): Flow<ArticleEntity?>

    @Query("SELECT * FROM ArticleEntity WHERE id = :id")
    suspend fun selectByIdSync(id: String): ArticleEntity?

    @Query(
        """SELECT * FROM ArticleEntity
        WHERE title LIKE '%' || :query || '%'
        OR content LIKE '%' || :query || '%'
        OR author LIKE '%' || :query || '%'
        OR tags LIKE '%' || :query || '%'
        ORDER BY publishedAt DESC"""
    )
    fun searchArticles(query: String): Flow<List<ArticleEntity>>

    @Query("SELECT * FROM ArticleEntity WHERE isFavorite = 1 ORDER BY publishedAt DESC")
    fun selectFavorites(): Flow<List<ArticleEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertArticle(article: ArticleEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertArticles(articles: List<ArticleEntity>)

    @Query("UPDATE ArticleEntity SET isFavorite = :isFavorite WHERE id = :id")
    suspend fun updateFavoriteStatus(id: String, isFavorite: Boolean)

    @Query("DELETE FROM ArticleEntity")
    suspend fun deleteAll()

    @Query("DELETE FROM ArticleEntity WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("SELECT COUNT(*) FROM ArticleEntity")
    suspend fun countAll(): Long
}

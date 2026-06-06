package com.amit.vamk.routes

import com.amit.vamk.data.ArticleRepository
import com.amit.vamk.models.ArticlesResponse
import com.amit.vamk.models.CreateArticleRequest
import com.amit.vamk.models.UpdateArticleRequest
import io.ktor.http.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.coroutines.delay
import kotlin.math.ceil

/**
 * Configure article routes
 */
fun Route.articleRoutes() {
    route("/articles") {
        
        // GET /api/articles - List articles with pagination
        get {
            // Simulate network delay for realistic testing
            delay(50L)
            
            // Parse query parameters
            val page = call.request.queryParameters["page"]?.toIntOrNull() ?: 1
            val pageSize = call.request.queryParameters["limit"]?.toIntOrNull()?.coerceIn(1, 100) ?: 20
            val category = call.request.queryParameters["category"]
            val search = call.request.queryParameters["search"]
            
            // Validate page number
            if (page < 1) {
                throw IllegalArgumentException("Page number must be greater than 0")
            }
            
            // Get articles based on search or category filter
            val articles = when {
                !search.isNullOrBlank() -> ArticleRepository.searchArticles(search, page, pageSize)
                else -> ArticleRepository.getArticles(page, pageSize, category)
            }
            
            // Calculate pagination metadata
            val totalArticles = ArticleRepository.getTotalArticles(category)
            val totalPages = ceil(totalArticles.toDouble() / pageSize).toInt()
            
            // Return paginated response
            call.respond(
                HttpStatusCode.OK,
                ArticlesResponse(
                    articles = articles,
                    page = page,
                    pageSize = pageSize,
                    totalPages = totalPages,
                    totalArticles = totalArticles
                )
            )
        }
        
        // GET /api/articles/{id} - Get single article
        get("{id}") {
            // Simulate network delay
            delay(30L)
            
            val id = call.parameters["id"] 
                ?: throw IllegalArgumentException("Article ID is required")
            
            val article = ArticleRepository.getArticleById(id)
                ?: throw NoSuchElementException("Article with ID '$id' not found")
            
            call.respond(HttpStatusCode.OK, article)
        }
        
        // POST /api/articles - Create new article
        post {
            // Simulate processing delay
            delay(100L)
            
            val request = call.receive<CreateArticleRequest>()
            
            // Validate request
            if (request.title.isBlank()) {
                throw IllegalArgumentException("Article title cannot be empty")
            }
            if (request.content.isBlank()) {
                throw IllegalArgumentException("Article content cannot be empty")
            }
            if (request.summary.isBlank()) {
                throw IllegalArgumentException("Article summary cannot be empty")
            }
            
            // Verify category exists
            val category = ArticleRepository.getCategoryByName(request.category)
                ?: throw IllegalArgumentException("Category '${request.category}' does not exist")
            
            // Create article
            val article = ArticleRepository.createArticle(request)
            
            call.respond(HttpStatusCode.Created, article)
        }
        
        // PUT /api/articles/{id} - Update article
        put("{id}") {
            delay(80L)
            
            val id = call.parameters["id"]
                ?: throw IllegalArgumentException("Article ID is required")
            
            val request = call.receive<UpdateArticleRequest>()
            
            // Validate category if provided
            if (request.category != null) {
                ArticleRepository.getCategoryByName(request.category)
                    ?: throw IllegalArgumentException("Category '${request.category}' does not exist")
            }
            
            val updated = ArticleRepository.updateArticle(id, request)
                ?: throw NoSuchElementException("Article with ID '$id' not found")
            
            call.respond(HttpStatusCode.OK, updated)
        }
        
        // DELETE /api/articles/{id} - Delete article
        delete("{id}") {
            delay(50L)
            
            val id = call.parameters["id"]
                ?: throw IllegalArgumentException("Article ID is required")
            
            val deleted = ArticleRepository.deleteArticle(id)
            
            if (!deleted) {
                throw NoSuchElementException("Article with ID '$id' not found")
            }
            
            call.respond(
                HttpStatusCode.OK,
                mapOf(
                    "message" to "Article deleted successfully",
                    "id" to id
                )
            )
        }
    }
}

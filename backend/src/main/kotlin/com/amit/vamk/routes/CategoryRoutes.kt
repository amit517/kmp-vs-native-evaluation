package com.amit.vamk.routes

import com.amit.vamk.data.ArticleRepository
import com.amit.vamk.models.CategoryArticlesResponse
import io.ktor.http.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.coroutines.delay

/**
 * Configure category routes
 */
fun Route.categoryRoutes() {
    route("/categories") {
        
        // GET /api/categories - List all categories
        get {
            delay(30L)
            
            val categories = ArticleRepository.getCategories()
            call.respond(HttpStatusCode.OK, categories)
        }
        
        // GET /api/categories/{name}/articles - Get articles by category
        get("{name}/articles") {
            delay(50L)
            
            val categoryName = call.parameters["name"]
                ?: throw IllegalArgumentException("Category name is required")
            
            // Verify category exists
            val category = ArticleRepository.getCategoryByName(categoryName)
                ?: throw NoSuchElementException("Category '$categoryName' not found")
            
            // Get pagination parameters
            val page = call.request.queryParameters["page"]?.toIntOrNull() ?: 1
            val pageSize = call.request.queryParameters["limit"]?.toIntOrNull()?.coerceIn(1, 100) ?: 20
            
            if (page < 1) {
                throw IllegalArgumentException("Page number must be greater than 0")
            }
            
            // Get articles for this category
            val articles = ArticleRepository.getArticles(page, pageSize, category.name)
            val totalArticles = ArticleRepository.getTotalArticles(category.name)
            val totalPages = kotlin.math.ceil(totalArticles.toDouble() / pageSize).toInt()
            
            // Return properly serializable response
            call.respond(
                HttpStatusCode.OK,
                CategoryArticlesResponse(
                    category = category,
                    articles = articles,
                    page = page,
                    pageSize = pageSize,
                    totalPages = totalPages,
                    totalArticles = totalArticles
                )
            )
        }
    }
}

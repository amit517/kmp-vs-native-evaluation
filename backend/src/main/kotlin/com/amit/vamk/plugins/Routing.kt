package com.amit.vamk.plugins

import com.amit.vamk.routes.articleRoutes
import com.amit.vamk.routes.categoryRoutes
import io.ktor.http.ContentType
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable

@Serializable
data class HealthResponse(
    val status: String,
    val timestamp: Long,
    val version: String
)

@Serializable
data class ApiStatusResponse(
    val api: String,
    val version: String,
    val status: String,
    val endpoints: List<EndpointInfo>
)

@Serializable
data class EndpointInfo(
    val method: String,
    val path: String,
    val description: String
)

fun Application.configureRouting() {
    routing {
        // Root endpoint
        get("/") {
            call.respondText(
                """
                KMP Research News Backend API v1.0.0
                
                🚀 Endpoints:
                
                Health & Status:
                - GET  /health
                - GET  /api/status
                
                Articles:
                - GET    /api/articles                    (List all articles, paginated)
                - GET    /api/articles?page=1&limit=20    (Pagination)
                - GET    /api/articles?category=Technology (Filter by category)
                - GET    /api/articles?search=AI           (Search articles)
                - GET    /api/articles/{id}                (Get single article)
                - POST   /api/articles                     (Create new article)
                - PUT    /api/articles/{id}                (Update article)
                - DELETE /api/articles/{id}                (Delete article)
                
                Categories:
                - GET  /api/categories                     (List all categories)
                - GET  /api/categories/{name}/articles     (Get articles by category)
                
                📊 Current Data:
                - 80 mock articles across 6 categories
                - Technology, Science, Business, Health, Sports, Entertainment
                
                🔧 For Research:
                - All endpoints include simulated network delays (30-100ms)
                - Consistent JSON responses for fair benchmarking
                - Thread-safe in-memory storage
                """.trimIndent(),
                ContentType.Text.Plain
            )
        }
        
        // Health check endpoint
        get("/health") {
            call.respond(
                HealthResponse(
                    status = "healthy",
                    timestamp = System.currentTimeMillis(),
                    version = "1.0.0"
                )
            )
        }
        
        // API routes
        route("/api") {
            // API status endpoint
            get("/status") {
                call.respond(
                    ApiStatusResponse(
                        api = "KMP Research News Backend",
                        version = "1.0.0",
                        status = "operational",
                        endpoints = listOf(
                            EndpointInfo("GET", "/api/articles", "List articles (paginated, filterable, searchable)"),
                            EndpointInfo("GET", "/api/articles/{id}", "Get single article details"),
                            EndpointInfo("POST", "/api/articles", "Create new article"),
                            EndpointInfo("PUT", "/api/articles/{id}", "Update existing article"),
                            EndpointInfo("DELETE", "/api/articles/{id}", "Delete article"),
                            EndpointInfo("GET", "/api/categories", "List all categories"),
                            EndpointInfo("GET", "/api/categories/{name}/articles", "Get articles by category")
                        )
                    )
                )
            }
            
            // Article routes
            articleRoutes()
            
            // Category routes
            categoryRoutes()
        }
    }
}

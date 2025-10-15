package com.amit.vamk.plugins

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
    val endpoints: List<String>
)

fun Application.configureRouting() {
    routing {
        // Root endpoint
        get("/") {
            call.respondText("KMP Research News Backend API v1.0.0\n\nEndpoints:\n- GET /health\n- GET /api/status\n- GET /api/articles")
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
                            "GET /api/articles",
                            "GET /api/articles/{id}",
                            "POST /api/articles",
                            "GET /api/categories"
                        )
                    )
                )
            }
            
            // Article routes (placeholder for now)
            get("/articles") {
                call.respondText("Articles endpoint - Coming soon!")
            }
            
            get("/articles/{id}") {
                val id = call.parameters["id"]
                call.respondText("Article detail for ID: $id - Coming soon!")
            }
            
            get("/categories") {
                call.respondText("Categories endpoint - Coming soon!")
            }
        }
    }
}

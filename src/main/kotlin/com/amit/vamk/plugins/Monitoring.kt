package com.amit.vamk.plugins

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.plugins.calllogging.*
import io.ktor.server.plugins.statuspages.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import kotlinx.serialization.Serializable
import org.slf4j.event.Level

/**
 * Data class for error responses
 */
@Serializable
data class ErrorResponse(
    val error: String,
    val message: String,
    val statusCode: Int
)

/**
 * Configure monitoring and logging for the application
 */
fun Application.configureMonitoring() {
    // Call Logging - Logs all incoming requests
    install(CallLogging) {
        level = Level.INFO
        
        // Only log API routes (ignore static resources)
        filter { call -> 
            call.request.path().startsWith("/api") || 
            call.request.path().startsWith("/health")
        }
        
        // Custom log format
        format { call ->
            val status = call.response.status()
            val httpMethod = call.request.httpMethod.value
            val path = call.request.path()
            val queryParams = call.request.queryParameters.entries()
                .takeIf { it.isNotEmpty() }
                ?.joinToString(", ") { "${it.key}=${it.value}" }
                ?.let { "?$it" } ?: ""
            
            "$httpMethod $path$queryParams - $status"
        }
    }
    
    // Status Pages - Error handling
    install(StatusPages) {
        // Handle all exceptions
        exception<Throwable> { call, cause ->
            call.application.environment.log.error("Unhandled exception", cause)
            call.respond(
                HttpStatusCode.InternalServerError,
                ErrorResponse(
                    error = "Internal Server Error",
                    message = cause.message ?: "An unexpected error occurred",
                    statusCode = HttpStatusCode.InternalServerError.value
                )
            )
        }
        
        // Handle IllegalArgumentException (400 Bad Request)
        exception<IllegalArgumentException> { call, cause ->
            call.application.environment.log.warn("Bad request: ${cause.message}")
            call.respond(
                HttpStatusCode.BadRequest,
                ErrorResponse(
                    error = "Bad Request",
                    message = cause.message ?: "Invalid request parameters",
                    statusCode = HttpStatusCode.BadRequest.value
                )
            )
        }
        
        // Handle IllegalStateException (409 Conflict)
        exception<IllegalStateException> { call, cause ->
            call.application.environment.log.warn("Conflict: ${cause.message}")
            call.respond(
                HttpStatusCode.Conflict,
                ErrorResponse(
                    error = "Conflict",
                    message = cause.message ?: "Request conflicts with current state",
                    statusCode = HttpStatusCode.Conflict.value
                )
            )
        }
        
        // Handle NoSuchElementException (404 Not Found)
        exception<NoSuchElementException> { call, cause ->
            call.application.environment.log.info("Resource not found: ${cause.message}")
            call.respond(
                HttpStatusCode.NotFound,
                ErrorResponse(
                    error = "Not Found",
                    message = cause.message ?: "The requested resource was not found",
                    statusCode = HttpStatusCode.NotFound.value
                )
            )
        }
        
        // Handle 404 status
        status(HttpStatusCode.NotFound) { call, status ->
            call.respond(
                status,
                ErrorResponse(
                    error = "Not Found",
                    message = "The requested endpoint '${call.request.uri}' was not found",
                    statusCode = status.value
                )
            )
        }
        
        // Handle 405 Method Not Allowed
        status(HttpStatusCode.MethodNotAllowed) { call, status ->
            call.respond(
                status,
                ErrorResponse(
                    error = "Method Not Allowed",
                    message = "The ${call.request.httpMethod.value} method is not allowed for this endpoint",
                    statusCode = status.value
                )
            )
        }
    }
}

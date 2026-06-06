package com.amit.vamk.plugins

import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.application.*
import io.ktor.server.plugins.contentnegotiation.*
import kotlinx.serialization.json.Json

/**
 * Configure JSON serialization for the API
 * This plugin handles JSON request/response serialization
 */
fun Application.configureSerialization() {
    install(ContentNegotiation) {
        json(Json {
            // Pretty print JSON responses (makes debugging easier)
            prettyPrint = true
            
            // Be lenient with JSON parsing
            isLenient = true
            
            // Ignore unknown JSON keys (forward compatibility)
            ignoreUnknownKeys = true
            
            // Allow special floating point values
            allowSpecialFloatingPointValues = true
            
            // Use default values for missing fields
            coerceInputValues = true
        })
    }
}

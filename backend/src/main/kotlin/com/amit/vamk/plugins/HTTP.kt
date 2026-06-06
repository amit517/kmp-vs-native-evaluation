package com.amit.vamk.plugins

import com.asyncapi.kotlinasyncapi.context.service.AsyncApiExtension
import com.asyncapi.kotlinasyncapi.ktor.AsyncApiPlugin
import io.ktor.http.*
import io.ktor.http.content.CachingOptions
import io.ktor.server.application.*
import io.ktor.server.plugins.cachingheaders.*
import io.ktor.server.plugins.cors.routing.*
import io.ktor.server.plugins.defaultheaders.*

fun Application.configureHTTP() {
    // CORS Configuration - Essential for mobile app access
    install(CORS) {
        allowMethod(HttpMethod.Options)
        allowMethod(HttpMethod.Get)
        allowMethod(HttpMethod.Post)
        allowMethod(HttpMethod.Put)
        allowMethod(HttpMethod.Delete)
        allowMethod(HttpMethod.Patch)
        
        allowHeader(HttpHeaders.ContentType)
        allowHeader(HttpHeaders.Authorization)
        allowHeader("MyCustomHeader")
        
        // For development - allow all origins
        anyHost() // @TODO: Don't do this in production if possible. Try to limit it.
        
        // For production, uncomment and specify exact hosts:
        // allowHost("your-android-app.com")
        // allowHost("your-ios-app.com")
        // allowHost("localhost:3000")
    }
    
    // Default Headers - Adds consistent headers to all responses
    install(DefaultHeaders) {
        header("X-Engine", "Ktor")
        header("X-API-Version", "1.0.0")
    }
    
    // AsyncAPI Documentation
    install(AsyncApiPlugin) {
        extension = AsyncApiExtension.builder {
            info {
                title("KMP Research News Backend API")
                version("1.0.0")
                description("Backend API for KMP vs Native performance comparison research")
            }
        }
    }
    
    // Caching Headers - Control client-side caching
    install(CachingHeaders) {
        options { call, outgoingContent ->
            when (outgoingContent.contentType?.withoutParameters()) {
                ContentType.Application.Json -> CachingOptions(
                    CacheControl.MaxAge(maxAgeSeconds = 60) // Cache JSON responses for 60 seconds
                )
                ContentType.Text.CSS -> CachingOptions(
                    CacheControl.MaxAge(maxAgeSeconds = 24 * 60 * 60) // Cache CSS for 24 hours
                )
                else -> null
            }
        }
    }
}

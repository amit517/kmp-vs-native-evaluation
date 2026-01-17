package com.amit.newsreader.data.remote

import io.ktor.client.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

/**
 * Factory for creating configured Ktor HttpClient
 */
object HttpClientFactory {

    fun create(): HttpClient {
        return HttpClient {
            // Content negotiation for JSON serialization
            install(ContentNegotiation) {
                json(Json {
                    prettyPrint = true
                    isLenient = true
                    ignoreUnknownKeys = true
                    explicitNulls = false
                })
            }

            // Logging for debugging
            install(Logging) {
                logger = Logger.DEFAULT
                level = LogLevel.INFO
            }

            // Timeout configuration
            install(HttpTimeout) {
                requestTimeoutMillis = 30000
                connectTimeoutMillis = 30000
                socketTimeoutMillis = 30000
            }

            // Default request configuration
            defaultRequest {
                url {
                    // Base URL will be set in NewsApiService based on platform
                }
            }
        }
    }
}

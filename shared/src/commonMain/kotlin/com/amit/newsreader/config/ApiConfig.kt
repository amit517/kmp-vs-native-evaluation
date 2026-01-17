package com.amit.newsreader.config

/**
 * API Configuration for News Reader App
 *
 * Update BASE_URL to switch between local and AWS endpoints
 */
object ApiConfig {
    /**
     * Base URL for the News API
     *
     * Options:
     * - Local Development (Android Emulator): "http://10.0.2.2:8080"
     * - Local Development (iOS Simulator): "http://localhost:8080"
     * - Local Development (Physical Device): "http://YOUR_LOCAL_IP:8080"
     * - AWS Production: "http://YOUR_AWS_IP:8080"
     *
     * TODO: Replace with your AWS endpoint after deployment
     */
    const val BASE_URL = "http://63.177.119.99:8080"  // AWS Production endpoint

    /**
     * Alternative endpoints for easy switching
     */
    object Endpoints {
        const val LOCAL_ANDROID_EMULATOR = "http://10.0.2.2:8080"
        const val LOCAL_IOS_SIMULATOR = "http://localhost:8080"
        const val LOCAL_NETWORK = "http://192.168.1.100:8080"  // Update with your local IP
        const val AWS_PRODUCTION = "http://YOUR_AWS_IP:8080"   // Update after AWS deployment
    }

    /**
     * API paths
     */
    object Paths {
        const val ARTICLES = "/api/articles"
        const val ARTICLE_DETAIL = "/api/articles/{id}"
        const val CATEGORIES = "/api/categories"
        const val HEALTH = "/health"
    }

    /**
     * Request configuration
     */
    object Request {
        const val DEFAULT_PAGE_SIZE = 20
        const val REQUEST_TIMEOUT_MS = 30_000L
        const val CONNECT_TIMEOUT_MS = 30_000L
        const val SOCKET_TIMEOUT_MS = 30_000L
    }
}

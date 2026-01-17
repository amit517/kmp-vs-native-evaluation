package com.amit.newsreader.domain.model

/**
 * Article category enumeration
 * Matches backend categories exactly
 */
enum class ArticleCategory(val displayName: String) {
    TECHNOLOGY("Technology"),
    BUSINESS("Business"),
    ENTERTAINMENT("Entertainment"),
    SPORTS("Sports"),
    SCIENCE("Science"),
    HEALTH("Health");

    companion object {
        fun fromString(value: String): ArticleCategory {
            return entries.find { it.name.equals(value, ignoreCase = true) }
                ?: TECHNOLOGY
        }
    }
}

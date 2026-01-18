package com.example.thesisproject

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform

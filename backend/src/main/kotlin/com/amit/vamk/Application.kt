package com.amit.vamk

import io.ktor.server.application.*
import com.amit.vamk.plugins.*

fun main(args: Array<String>) {
    io.ktor.server.netty.EngineMain.main(args)
}

fun Application.module() {
    // Configure all plugins
    configureHTTP()
    configureSerialization()
    configureMonitoring()
    configureRouting()
}

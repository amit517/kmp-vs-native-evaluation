val kotlin_version: String by project
val logback_version: String by project
val ktor_version: String by project

plugins {
    kotlin("jvm") version "2.2.20"
    id("io.ktor.plugin") version "3.3.0"
    kotlin("plugin.serialization") version "2.2.20"
    application
}

group = "com.amit.vamk"
version = "0.0.1"

application {
    mainClass.set("io.ktor.server.netty.EngineMain")
}

repositories {
    mavenCentral()
}

dependencies {
    // Ktor Server Core
    implementation("io.ktor:ktor-server-core")
    implementation("io.ktor:ktor-server-netty")
    
    // Content Negotiation + JSON Serialization (CRITICAL FOR API)
    implementation("io.ktor:ktor-server-content-negotiation")
    implementation("io.ktor:ktor-serialization-kotlinx-json")
    
    // CORS
    implementation("io.ktor:ktor-server-cors")
    
    // Default Headers
    implementation("io.ktor:ktor-server-default-headers")
    
    // Call Logging (For monitoring and debugging)
    implementation("io.ktor:ktor-server-call-logging")
    
    // Status Pages (Error handling)
    implementation("io.ktor:ktor-server-status-pages")
    
    // Caching Headers
    implementation("io.ktor:ktor-server-caching-headers")
    
    // AsyncAPI
    implementation("org.openfolder:kotlin-asyncapi-ktor:3.1.2")
    
    // kotlinx.serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
    
    // Logging
    implementation("ch.qos.logback:logback-classic:$logback_version")
    
    // Config YAML
    implementation("io.ktor:ktor-server-config-yaml")
    
    // Testing
    testImplementation("io.ktor:ktor-server-test-host")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit:$kotlin_version")
}

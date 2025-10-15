# Multi-stage build for KMP Research News Backend
# Stage 1: Build the application
FROM gradle:8.10-jdk21 AS builder

# Set working directory
WORKDIR /app

# Copy gradle files first (for better caching)
COPY build.gradle.kts settings.gradle.kts gradle.properties ./
COPY gradle ./gradle

# Download dependencies (cached if gradle files don't change)
RUN gradle dependencies --no-daemon

# Copy source code
COPY src ./src

# Build the application (creates fat JAR with shadowJar)
RUN gradle shadowJar --no-daemon

# Stage 2: Runtime image
FROM eclipse-temurin:21-jre-alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Set working directory
WORKDIR /app

# Copy the built JAR from builder stage
COPY --from=builder /app/build/libs/*-all.jar app.jar

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

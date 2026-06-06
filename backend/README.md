# KMP Research News Backend

Backend API for the Master's thesis research project comparing Kotlin Multiplatform (KMP) + Compose Multiplatform vs Native Android (Jetpack Compose) and iOS (SwiftUI) performance.

## 🎯 Project Overview

This backend serves as the data source for three client applications:
- **KMP + Compose Multiplatform** app
- **Native Android** app (Jetpack Compose)
- **Native iOS** app (SwiftUI)

**Research Purpose**: Provide consistent API endpoints for fair performance benchmarking across platforms.

## 🏗️ Tech Stack

- **Framework**: Ktor 3.3.0
- **Language**: Kotlin 2.2.20
- **Server**: Netty (embedded)
- **Serialization**: kotlinx.serialization

## 📦 Installed Plugins

### Essential Plugins
- ✅ **ContentNegotiation** - JSON request/response serialization
- ✅ **CORS** - Cross-Origin Resource Sharing for mobile clients
- ✅ **DefaultHeaders** - Consistent response headers
- ✅ **CallLogging** - Request/response logging
- ✅ **StatusPages** - Centralized error handling
- ✅ **CachingHeaders** - Client-side caching control
- ✅ **Multipart** - File upload support

### Documentation
- ✅ **AsyncAPI** - Auto-generated API documentation

## 🚀 Getting Started

### Prerequisites
- JDK 17 or higher
- Gradle 8.x

### Run the Server

```bash
# Using Gradle wrapper
./gradlew run

# Or
gradle run
```

The server will start on `http://localhost:8080`

### Test the API

```bash
# Health check
curl http://localhost:8080/health

# API status
curl http://localhost:8080/api/status

# Articles (placeholder)
curl http://localhost:8080/api/articles
```

## 📡 API Endpoints

### Health & Status
- `GET /` - API information
- `GET /health` - Health check
- `GET /api/status` - API status and available endpoints

### Articles (Coming Soon)
- `GET /api/articles` - List articles (paginated)
- `GET /api/articles/{id}` - Get article details
- `POST /api/articles` - Create article (with image upload)
- `GET /api/categories` - List categories

## 📁 Project Structure

```
src/main/kotlin/com/amit/vamk/
├── Application.kt              # Main application entry point
└── plugins/
    ├── HTTP.kt                 # CORS, Headers, Caching
    ├── Serialization.kt        # JSON configuration
    ├── Monitoring.kt           # Logging & Error handling
    └── Routing.kt              # API routes
```

## 🔧 Configuration

Configuration is in `src/main/resources/application.yaml`:

```yaml
ktor:
  application:
    modules:
      - com.amit.vamk.ApplicationKt.module
  deployment:
    port: 8080
```

## 📊 For Research Purposes

### Performance Testing
- Backend uses minimal processing to avoid skewing client-side benchmarks
- Simulated network delays can be added for realistic testing
- Logging provides response time metrics

### Benchmarking Considerations
- Keep backend logic simple
- Use consistent data structures
- Monitor backend response times separately
- Document any changes that might affect benchmarks

## 🧪 Testing

```bash
# Run tests
./gradlew test
```

## 📝 Next Steps

1. ✅ Basic project setup with all plugins
2. ⏳ Create data models (Article, Category)
3. ⏳ Implement article CRUD endpoints
4. ⏳ Add mock data generator
5. ⏳ Implement file upload handling
6. ⏳ Add pagination support
7. ⏳ Create API documentation

## 📚 Research Integration

This backend is part of a Master's thesis at VAMK (Vaasa University of Applied Sciences) comparing cross-platform and native mobile development approaches.

**Key Metrics Being Tested**:
- App launch time
- Memory usage
- CPU load
- UI responsiveness
- App size
- Network layer performance

## 👤 Author

**Amit Kundu**
- Institution: Vaasa University of Applied Sciences
- Program: Cloud-Based Software Engineering (Master's)
- Professional: Android Developer @ F-Secure

## 📄 License

This project is for academic research purposes.

---

**Version**: 1.0.0  
**Last Updated**: January 2025

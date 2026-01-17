# Quick Start Guide - News Reader KMP App

## Prerequisites Check

```bash
# Check Java version (need JDK 17+)
java -version

# Check Kotlin compiler
kotlinc -version

# Check Android SDK
echo $ANDROID_HOME

# For iOS (macOS only)
xcodebuild -version
```

## Step-by-Step Launch

### 1. Start Backend API

```bash
# Navigate to backend
cd "/Users/amitkundu/KMP project/KMP project/backend/news-backend"

# Run backend server
./gradlew bootRun

# Verify backend is running (in new terminal)
curl http://localhost:8080/api/articles?page=1&limit=5
```

Expected output: JSON response with articles

### 2. Run Android App

#### Option A: Android Studio
1. Open project in Android Studio
2. Wait for Gradle sync to complete
3. Select Android emulator or connected device
4. Click Run button (green triangle)

#### Option B: Command Line
```bash
# Navigate to project root
cd "/Users/amitkundu/KMP project/KMP project/Thesis project"

# Clean and build
./gradlew clean
./gradlew :composeApp:assembleDebug

# Install on connected device/emulator
./gradlew :composeApp:installDebug

# Or run directly
./gradlew :composeApp:run
```

### 3. Run iOS App (macOS only)

```bash
# Open Xcode project
open "/Users/amitkundu/KMP project/KMP project/Thesis project/iosApp/iosApp.xcodeproj"

# Or use command line
cd "/Users/amitkundu/KMP project/KMP project/Thesis project"
xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -configuration Debug
```

## Quick Testing Commands

### Test Backend Connectivity

```bash
# From host machine (for iOS)
curl http://localhost:8080/api/articles?page=1&limit=5

# Test from Android emulator
adb shell curl http://10.0.2.2:8080/api/articles?page=1&limit=5

# Get specific article
curl http://localhost:8080/api/articles/1

# Get categories
curl http://localhost:8080/api/categories
```

### Build Commands

```bash
# Build shared module
./gradlew :shared:build

# Generate SQLDelight code
./gradlew :shared:generateCommonMainNewsReaderDatabaseInterface

# Build Android app
./gradlew :composeApp:assembleDebug

# Build release APK
./gradlew :composeApp:assembleRelease
```

### Clean Build

```bash
# Clean all
./gradlew clean

# Clean shared module only
./gradlew :shared:clean

# Clean composeApp only
./gradlew :composeApp:clean

# Refresh dependencies
./gradlew --refresh-dependencies
```

## Common Issues & Solutions

### Issue: "Unable to connect to backend"

**Android Emulator:**
```bash
# Check if using correct URL
# Should be: http://10.0.2.2:8080
# NOT: http://localhost:8080

# Verify backend is running
curl http://localhost:8080/api/articles
```

**iOS Simulator:**
```bash
# Check if using correct URL
# Should be: http://localhost:8080

# Verify backend is running
curl http://localhost:8080/api/articles
```

### Issue: "Gradle sync failed"

```bash
# Clear Gradle cache
rm -rf ~/.gradle/caches/

# Clean project
./gradlew clean

# Rebuild
./gradlew build --refresh-dependencies
```

### Issue: "SQLDelight compilation error"

```bash
# Regenerate database code
./gradlew :shared:generateCommonMainNewsReaderDatabaseInterface

# Check schema file
cat "/Users/amitkundu/KMP project/KMP project/Thesis project/shared/src/commonMain/sqldelight/com/amit/newsreader/database/NewsReader.sq"
```

### Issue: "Koin initialization error"

- Ensure Application class is specified in AndroidManifest.xml
- Check `android:name="com.amit.newsreader.NewsReaderApplication"`
- Verify all Koin modules are properly defined

### Issue: "Image loading fails"

- Check internet permission in AndroidManifest.xml
- Verify `android:usesCleartextTraffic="true"` is set
- Ensure image URLs from backend are accessible

## Verify Installation

### Check Project Structure

```bash
# Verify all key files exist
ls -la "/Users/amitkundu/KMP project/KMP project/Thesis project/shared/src/commonMain/sqldelight/com/amit/newsreader/database/NewsReader.sq"

ls -la "/Users/amitkundu/KMP project/KMP project/Thesis project/shared/src/commonMain/kotlin/com/amit/newsreader/domain/model/Article.kt"

ls -la "/Users/amitkundu/KMP project/KMP project/Thesis project/composeApp/src/commonMain/kotlin/com/amit/newsreader/App.kt"

ls -la "/Users/amitkundu/KMP project/KMP project/Thesis project/composeApp/src/androidMain/kotlin/com/amit/newsreader/MainActivity.kt"
```

### Count Implementation Files

```bash
# Count Kotlin files
find "/Users/amitkundu/KMP project/KMP project/Thesis project" -name "*.kt" -path "*/amit/newsreader/*" | wc -l
# Should show: 47 files

# Count shared module files
find "/Users/amitkundu/KMP project/KMP project/Thesis project/shared" -name "*.kt" | wc -l
# Should show: ~27 files

# Count UI files
find "/Users/amitkundu/KMP project/KMP project/Thesis project/composeApp" -name "*.kt" -path "*/amit/newsreader/*" | wc -l
# Should show: ~22 files
```

## App Features Checklist

Once the app is running, test these features:

- [ ] **Launch**: App opens without crashes
- [ ] **Article List**: Displays list of articles with images
- [ ] **Category Filter**: Filter chips work (All, Technology, Business, etc.)
- [ ] **Search**: Search bar filters articles by keyword
- [ ] **Article Detail**: Clicking article opens detail view
- [ ] **Favorites**: Heart icon toggles favorite status
- [ ] **Pull to Refresh**: Swipe down refreshes article list
- [ ] **Offline Mode**: Articles visible even when backend is stopped
- [ ] **Error Handling**: Error message shown when backend is unreachable
- [ ] **Loading States**: Loading indicator shown during data fetch
- [ ] **Dark Mode**: Toggle system dark mode to test theme

## Performance Monitoring

### Check App Size
```bash
# Android APK size
ls -lh "/Users/amitkundu/KMP project/KMP project/Thesis project/composeApp/build/outputs/apk/debug/composeApp-debug.apk"

# Shared framework size (iOS)
ls -lh "/Users/amitkundu/KMP project/KMP project/Thesis project/shared/build/bin/iosArm64/debugFramework/"
```

### Monitor Network Calls
```bash
# Watch backend logs
tail -f "/Users/amitkundu/KMP project/KMP project/backend/news-backend/logs/app.log"

# Or monitor with Charles Proxy / HTTP Toolkit
```

### Database Inspection (Android)
```bash
# Pull database from device
adb exec-out run-as com.amit.newsreader cat databases/newsreader.db > newsreader.db

# Open in SQLite browser
sqlite3 newsreader.db
```

## Development Workflow

### Making Changes

1. **Edit code** in shared module or composeApp
2. **Sync Gradle** (Cmd+Shift+O on Mac)
3. **Clean build** if needed: `./gradlew clean`
4. **Run app** to see changes

### Hot Reload (Android)
- Use "Apply Changes" (Ctrl+F10) for quick updates
- Full rebuild needed for structural changes

### Debug Mode
```bash
# Android with logs
./gradlew :composeApp:installDebug
adb logcat | grep NewsReader

# iOS debug
# Use Xcode debugger
```

## Next Steps

1. Review implementation in `NEWS_READER_IMPLEMENTATION.md`
2. Check code in Android Studio or IntelliJ IDEA
3. Run tests (when implemented)
4. Customize UI theme in `theme/` package
5. Add more features as needed

## Support

If you encounter issues:
1. Check backend is running: `curl http://localhost:8080/api/articles`
2. Verify Gradle sync completed successfully
3. Check Android emulator is using `http://10.0.2.2:8080`
4. Review logs: `adb logcat` (Android) or Xcode console (iOS)
5. Refer to `NEWS_READER_IMPLEMENTATION.md` for detailed documentation

## File Locations Summary

- **Project Root**: `/Users/amitkundu/KMP project/KMP project/Thesis project`
- **Backend**: `/Users/amitkundu/KMP project/KMP project/backend/news-backend`
- **Shared Module**: `shared/src/`
- **Compose App**: `composeApp/src/`
- **Android Main**: `composeApp/src/androidMain/`
- **iOS App**: `iosApp/`
- **Build Outputs**: `composeApp/build/outputs/`

---

**Ready to go!** Start the backend, then run the app on Android or iOS.

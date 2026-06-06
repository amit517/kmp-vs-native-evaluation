# Evaluating Cross-Platform Development: KMP vs Native iOS

A comprehensive data collection and performance analysis comparing **Kotlin Multiplatform** and **Native iOS**.

## 🎯 Quick Facts

- **KMP iOS**: 8/9 tests passed (88.9%) - Performance competitive with Native
- **Native iOS**: 9/9 tests passed (100%) - Full XCTest support baseline
- **KMP Android**: 11/11 tests passed (100%) - Reference implementation
- **Overall**: 28/29 tests (96.6%) across all platforms

## 📂 Repository Structure

```
kmp-vs-native-evaluation/
├── kmp-app/                  # Kotlin Multiplatform (Android + iOS)
├── native-ios-app/           # SwiftUI reference implementation
├── backend/                  # Ktor news API server
├── benchmark-data/           # Complete test results & analysis
│   ├── kmp-android/
│   ├── kmp-ios/
│   ├── native-ios/
│   └── BENCHMARK_RESULTS.md  # Key findings & recommendations
├── docs/                     # Setup & testing guides
└── README.md                 # This file
```

## 🚀 Key Findings

✅ **Performance Parity**: KMP iOS achieves startup times within 5-10% of Native Swift  
✅ **Gesture Excellence**: Scrolling, swiping, and swipe gestures work flawlessly  
⚠️ **Testing Limitation**: XCTest can't focus Compose text fields (Skia rendering)  
✅ **Production Ready**: KMP viable for gesture-driven, content-heavy apps  

## 📊 Test Results

| Platform | Tests | Passed | Status |
|----------|-------|--------|--------|
| KMP Android | 11 | 11 ✅ | 100% |
| KMP iOS | 9 | 8 ✅ | 89% |
| Native iOS | 9 | 9 ✅ | 100% |

The KMP iOS test failure (Search) is due to XCTest accessibility limitations with Compose, not a feature issue.

## 🛠 Tech Stack

**KMP App**: Kotlin, Compose Multiplatform, SQLDelight, MVVM  
**Native iOS**: Swift, SwiftUI, SwiftData, MVVM  
**Backend**: Ktor, PostgreSQL  
**Testing**: XCTest, Espresso, UIAutomator

## 📖 Documentation

- **[benchmark-data/BENCHMARK_RESULTS.md](./benchmark-data/BENCHMARK_RESULTS.md)** - Full analysis & recommendations
- **[docs/TESTING_GUIDE.md](./docs/TESTING_GUIDE.md)** - How to run benchmarks
- **[docs/SETUP.md](./docs/SETUP.md)** - Environment setup

## 🔗 Original Repositories

This repository consolidates three separate projects:

- **[Thesisproject](https://github.com/amit517/Thesisproject)** - KMP cross-platform implementation
- **[IosNativeBuild](https://github.com/amit517/IosNativeBuild)** - Native iOS reference app
- **[Thesis-backend](https://github.com/amit517/Thesis-backend)** - Ktor news API server

All git histories have been preserved using git subtree merges.

---

**Author**: Amit Kundu | **Data Collection**: June 2026

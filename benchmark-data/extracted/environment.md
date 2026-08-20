# Benchmark environment

Every value below is read from a build artefact, an xcresult metadata record, a
Macrobenchmark JSON `context` block, or a version catalogue. Values that could
not be determined from the artefacts are marked **UNKNOWN** rather than
inferred.

## Test hardware at a glance

**Both benchmark platforms were physical, USB-connected devices — no emulator
and no simulator was used for any measurement in this study.**

| Platform | Device | OS | Form |
|---|---|---|---|
| Android (KMP) | **Google Pixel 8** (codename `shiba`) | **Android 16** (API level 36) | Physical device, connected |
| iOS (KMP and native) | **Apple iPhone 16** (`iPhone17,3`) | **iOS 26.4.2** (KMP startup/scroll/data-load runs) and **iOS 26.5** (KMP filter/image/search runs, all native runs) | Physical device, connected |

Confirmed by the thesis author and corroborated by the artefacts: the Android
`context.build` block reports `Pixel 8` / API 36 with a `user` release-keys
fingerprint, and every xcresult `targetDeviceRecord` reports a concrete
`iPhone17,3` with a hardware UDID rather than a simulator identifier.

`Android 16` and `API level 36` are the same platform release — the Android
summary CSVs label it `Android_36` (API level), which is Android 16.

The simulator-built artefacts that appear in `app_size.md` are a **build-size
fallback only** (iOS code signing was unavailable at extraction time) and are
labelled as such. No performance number in this study comes from a simulator.

## iOS device (both iOS targets)

Read from the `runDestination.targetDeviceRecord` of each xcresult bundle.

| Field | Value | Source |
|---|---|---|
| Device model | iPhone 16 (physical device, connected via USB) | `modelName` |
| Model identifier | iPhone17,3 | `modelCode` |
| Concrete device (not a simulator) | `isConcreteDevice: true`, platform `com.apple.platform.iphoneos` | `targetDeviceRecord`, `platformRecord` |
| Device UDID | 00008140-0005309E3687001C | `identifier` |
| Architecture | arm64 / arm64e (native) | `targetArchitecture`, `nativeArchitecture` |
| Device name | Amit's iPhone | `name` |

### iOS version is NOT uniform across the runs

The KMP iOS bundles were captured in two separate sessions on two different
iOS versions. This is a confound for any comparison between KMP iOS scenarios.

| Bundle | Platform | iOS version | iOS build | Host macOS | Run started |
|---|---|---|---|---|---|
| cold_start | kmp_ios | 26.4.2 | 23E261 | 26.4.1 (25E253) | 2026-04-26 12:18 +0300 |
| warm_start | kmp_ios | 26.4.2 | 23E261 | 26.4.1 (25E253) | 2026-04-26 12:34 +0300 |
| hot_start | kmp_ios | 26.4.2 | 23E261 | 26.4.1 (25E253) | 2026-04-27 00:14 +0300 |
| scroll_performance | kmp_ios | 26.4.2 | 23E261 | 26.4.1 (25E253) | 2026-04-27 00:34 +0300 |
| fast_scroll_stress | kmp_ios | 26.4.2 | 23E261 | 26.4.1 (25E253) | 2026-04-27 05:32 +0300 |
| initial_data_load | kmp_ios | 26.4.2 | 23E261 | 26.4.1 (25E253) | 2026-04-27 05:35 +0300 |
| category_filter | kmp_ios | 26.5 | 23F77 | 26.5.1 (25F80) | 2026-06-06 13:45 +0300 |
| image_loading | kmp_ios | 26.5 | 23F77 | 26.5.1 (25F80) | 2026-06-06 13:49 +0300 |
| search_performance | kmp_ios | 26.5 | 23F77 | 26.5.1 (25F80) | 2026-06-06 14:05 +0300 |
| testColdStartup | native_ios | 26.5 | 23F77 | 26.5.1 (25F80) | 2026-06-06 13:33 +0300 |
| testWarmStartup | native_ios | 26.5 | 23F77 | 26.5.1 (25F80) | 2026-06-06 13:33 +0300 |
| testHotStartup | native_ios | 26.5 | 23F77 | 26.5.1 (25F80) | 2026-06-06 13:33 +0300 |
| testScrollPerformance | native_ios | 26.5 | 23F77 | 26.5.1 (25F80) | 2026-06-06 13:33 +0300 |
| testFastScrollStress | native_ios | 26.5 | 23F77 | 26.5.1 (25F80) | 2026-06-06 13:33 +0300 |
| testInitialDataLoad | native_ios | 26.5 | 23F77 | 26.5.1 (25F80) | 2026-06-06 13:33 +0300 |
| testCategoryFilterPerformance | native_ios | 26.5 | 23F77 | 26.5.1 (25F80) | 2026-06-06 13:33 +0300 |
| testSearchPerformance | native_ios | 26.5 | 23F77 | 26.5.1 (25F80) | 2026-06-06 13:33 +0300 |
| testImageLoadingPerformance | native_ios | 26.5 | 23F77 | 26.5.1 (25F80) | 2026-06-06 13:33 +0300 |

The only KMP iOS scenario that yielded a usable metric — `cold_start` — ran on
**iOS 26.4.2**, whereas every native iOS run targeted **iOS 26.5**. Had the
native runs produced data, the cross-target startup comparison would still have
crossed an OS boundary.

## Build host (at benchmark time)

| Field | Value | Source |
|---|---|---|
| Mac model | MacBook Pro (Mac15,7), 16-inch late 2023 | `localComputerRecord.modelName` / `modelCode` |
| CPU | Apple M3 Pro, 12 physical / 12 logical cores | `localComputerRecord` |
| RAM | 36864 MB | `ramSizeInMegabytes` |
| macOS at April runs | 26.4.1 (25E253) | `operatingSystemVersionWithBuildNumber` |
| macOS at June runs | 26.5.1 (25F80) | `operatingSystemVersionWithBuildNumber` |
| **Xcode version used for the benchmark runs** | **UNKNOWN** | Not recorded in the xcresult bundles; the activity logs contain no Xcode or swiftlang version string. |
| iOS SDK (native runs) | iphoneos26.5 ("iOS 26.5") | `targetSDKRecord` |

## Build host (at extraction time — used for the Task 4 size builds only)

These are the versions of the machine that produced the app-size artefacts in
`app_size.md`. They are **not** the versions that produced the benchmark data.

| Field | Value | Source |
|---|---|---|
| macOS | 26.6.1 (build 25G76) | `sw_vers` |
| Xcode | 26.6 (build 17F113) | `xcodebuild -version` |
| Swift | Apple Swift 6.3.3 (swiftlang-6.3.3.1.3, clang-2100.1.1.101) | `swift --version` |
| Swift target | arm64-apple-macosx26.0 | `swift --version` |
| cloc | 2.10 | `cloc --version` |
| xcresulttool | 24757, schema 0.1.0 (legacy format 3.58) | `xcrun xcresulttool version` |
| Python (analysis) | 3.14.6 with numpy 2.5.2, pandas 3.0.5, scipy 1.18.0 | venv created for this extraction |

**Swift version at benchmark time: UNKNOWN** (not recorded in the bundles).

## Android device

Read from the `context` block of the Macrobenchmark JSON files in
`benchmark-data/kmp-android/raw/`. Identical across all 11 benchmark files.

| Field | Value |
|---|---|
| Model | Pixel 8 (physical device, connected via USB) |
| Device codename | shiba |
| Brand | google |
| Android version | **Android 16** |
| Android API level | 36 (`REL`) — API 36 is Android 16 |
| Build ID | BP4A.260105.004.E1 |
| Build fingerprint | `google/shiba_16kb/shiba:16/BP4A.260105.004.E1/14587043:user/release-keys` |
| Build type | user |
| CPU cores | 9 |
| CPU max frequency | 2,914,000,000 Hz (2.914 GHz) |
| Total memory | 8,052,817,920 bytes (7.5 GiB) |
| ART mainline version | 361501120 |
| `cpuLocked` | **false** |
| `sustainedPerformanceModeEnabled` | **false** |

Note the `shiba_16kb` fingerprint segment: this is a 16 KB-page-size Pixel 8
build. Both `cpuLocked` and `sustainedPerformanceModeEnabled` are false, so CPU
frequency and thermal state were not pinned during the Android runs — a source
of run-to-run variance that Macrobenchmark would normally warn about.

## Benchmarked build configurations

| Target | Configuration | Evidence |
|---|---|---|
| KMP Android (benchmarked) | `benchmark` build type: `initWith(release)`, `isDebuggable = false`, debug signing config, `matchingFallbacks = [release]` | `kmp-app/composeApp/build.gradle.kts` lines 110–115 |
| KMP Android — compilation modes | `coldStartupFull`: `CompilationMode.Full()`. `coldStartupWithBaselineProfile`: `CompilationMode.Partial(BaselineProfileMode.Require)`. `warmStartup` / `hotStartup`: `CompilationMode.Full()` | `kmp-app/benchmark/src/main/kotlin/.../StartupBenchmark.kt` |
| KMP Android — recorded context | `compilationMode: "run-from-apk"` in **every** raw JSON, including the two cold-startup files that request `Full()` and `Partial()` | `kmp-android/raw/*.json` `context.compilationMode` |
| KMP iOS (benchmarked) | **UNKNOWN** — the xcresult bundles do not record the build configuration of the app under test. Launch argument/environment `BENCHMARK_MODE=1` was set. | `BasePerformanceTest.swift`; bundle metadata |
| Native iOS (benchmarked) | **UNKNOWN** for the same reason; no tests executed in any case. | bundle metadata |
| KMP Android (size-measured) | `release`, `isMinifyEnabled = false`, no `shrinkResources`, no ProGuard/R8 rules; baseline profile embedded via `baselineProfile(project(":baselineprofile"))` | `composeApp/build.gradle.kts` lines 106–126 |
| Both iOS apps (size-measured) | `Release` configuration | `xcodebuild -configuration Release` |

### Discrepancy worth resolving before publication

The Android benchmark source requests `CompilationMode.Full()` and
`CompilationMode.Partial(BaselineProfileMode.Require)`, but every raw JSON
records `context.compilationMode = "run-from-apk"`. Either the context field
reports a harness-level default rather than the per-benchmark mode, or the
requested compilation modes were not applied. This extraction cannot resolve
which from the artefacts alone, so the discrepancy is recorded rather than
explained away. It matters because the `coldStartupWithBaselineProfile` vs
`coldStartupFull` difference (272.18 ms vs 344.82 ms) is interpreted as a
compilation-mode effect.

## Toolchain versions (from `kmp-app/gradle/libs.versions.toml`)

| Component | Version |
|---|---|
| Android Gradle Plugin | 8.13.2 |
| Kotlin | 2.2.21 |
| Compose Multiplatform | 1.10.0 |
| compileSdk / targetSdk | 36 |
| minSdk | 30 |
| androidx.activity | 1.12.2 |
| androidx.lifecycle | 2.10.0-alpha07 |
| androidx.navigation (JB) | 2.9.1 |
| androidx.benchmark | 1.4.1 |
| androidx.baselineprofile | 1.3.4 |
| androidx.tracing | 1.3.0-alpha02 |
| androidx.profileinstaller | 1.4.1 |
| JankStats (metrics-performance) | 1.0.0-beta01 |
| kotlinx-coroutines | 1.10.2 |
| kotlinx-datetime | 0.7.1 |
| kotlinx-serialization | 1.9.0 |
| Ktor | 3.3.3 |
| Room | 2.8.4 |
| androidx.sqlite | 2.6.2 |
| KSP | 2.2.21-2.0.4 |
| Koin / Koin-Compose | 4.1.1 |
| Coil | 3.3.0 |
| Kermit | 2.0.8 |
| UI Automator | 2.3.0 |

Gradle JVM observed during the extraction builds: Microsoft OpenJDK 21.0.12
(`~/Library/Java/JavaVirtualMachines/ms-21.0.12`). The JVM used for the
original benchmark runs is **UNKNOWN**.

## Summary of UNKNOWN values

- Xcode version at benchmark time (both iOS targets).
- Swift version at benchmark time.
- Build configuration (Debug/Release) of the two iOS apps as benchmarked.
- JDK used for the original Android benchmark runs.
- Whether the requested Android `CompilationMode` values were actually applied.

# Code-sharing analysis (cloc)

Counts are **code lines only** — blank and comment lines excluded, per `cloc`'s
own classification. Build outputs, generated sources, asset catalogues and
Xcode per-user state are excluded; test code is counted separately.

## Exact command used (thesis methodology)

`cloc` version 2.10.

```sh
cloc --exclude-dir=build,.build,DerivedData,dd,Assets.xcassets,Preview\ Content,generated,xcuserdata \
     --not-match-f='(\.generated\.|_generated)' \
     --quiet \
     <paths for the group>
```

Group paths, relative to the repository root:

| Group | Paths |
|---|---|
| SHARED | `kmp-app/shared/src/commonMain`, `kmp-app/composeApp/src/commonMain` |
| KMP ANDROID-SPECIFIC | `kmp-app/shared/src/androidMain`, `kmp-app/composeApp/src/androidMain` |
| KMP IOS-SPECIFIC | `kmp-app/shared/src/iosMain`, `kmp-app/composeApp/src/iosMain`, `kmp-app/iosApp/iosApp` |
| NATIVE IOS | `native-ios-app/IosNativeBuild` |
| TEST — Android macrobenchmark | `kmp-app/benchmark/src` |
| TEST — KMP iOS XCTest | `kmp-app/iosApp/iosAppPerformanceTests` |
| TEST — Native iOS XCTest | `native-ios-app/IosNativeBuildPerformanceTests` |
| TEST — Android baseline profile | `kmp-app/baselineprofile/src` |

## Production code

### SHARED — `commonMain` (shared + composeApp)

| Language | Files | Blank | Comment | Code |
|---|---|---|---|---|
| Kotlin | 47 | 260 | 247 | 2103 |
| XML | 1 | 0 | 0 | 44 |
| **SUM** | **48** | **260** | **247** | **2147** |

### KMP ANDROID-SPECIFIC — `androidMain`

| Language | Files | Blank | Comment | Code |
|---|---|---|---|---|
| XML | 5 | 4 | 1 | 233 |
| Kotlin | 7 | 26 | 11 | 121 |
| **SUM** | **12** | **30** | **12** | **354** |

### KMP IOS-SPECIFIC — `iosMain` + Swift host

| Language | Files | Blank | Comment | Code |
|---|---|---|---|---|
| Kotlin | 5 | 12 | 13 | 61 |
| Swift | 2 | 7 | 0 | 24 |
| XML | 1 | 0 | 0 | 13 |
| JSON | 1 | 0 | 0 | 6 |
| **SUM** | **9** | **19** | **13** | **104** |

### NATIVE IOS — `IosNativeBuild` (SwiftUI)

| Language | Files | Blank | Comment | Code |
|---|---|---|---|---|
| Swift | 34 | 315 | 247 | 1858 |
| XML | 1 | 0 | 0 | 59 |
| **SUM** | **35** | **315** | **247** | **1917** |

## Test code (reported separately, excluded from all percentages)

| Group | Language | Files | Blank | Comment | Code |
|---|---|---|---|---|---|
| Android macrobenchmark (`benchmark/src`) | Kotlin + XML | 6 | 28 | 0 | **288** |
| KMP iOS XCTest (`iosAppPerformanceTests`) | Swift | 8 | 60 | 20 | **279** |
| Native iOS XCTest (`IosNativeBuildPerformanceTests`) | Swift | 10 | 63 | 25 | **300** |
| Android baseline profile (`baselineprofile/src`) | Kotlin + XML | 2 | 10 | 5 | **45** |

Total test/benchmark code: **912 LOC**.

## Computed percentages

KMP production total = 2147 + 354 + 104 = **2605 LOC**.

| Measure | Value |
|---|---|
| Shared (`commonMain`) share of the KMP codebase | 2147 / 2605 = **82.42 %** |
| Android-specific share | 354 / 2605 = **13.59 %** |
| iOS-specific share | 104 / 2605 = **3.99 %** |
| Platform-specific share (both) | 458 / 2605 = **17.58 %** |

## Shared LOC vs native-iOS LOC

| Framing | Computation | Result |
|---|---|---|
| Requested ratio: shared vs native iOS | 2147 / 1917 | **1.120** |
| iOS-specific code vs a full native iOS app | 104 / 1917 | **5.43 %** (a 94.57 % reduction in iOS-specific code) |
| Whole KMP iOS footprint vs native iOS | (2147 + 104) / 1917 = 2251 / 1917 | **117.4 %** (+334 LOC) |

### How to read these three numbers

They answer different questions and the thesis should not conflate them.

- **1.120** — the shared module is about the same size as an entire native iOS
  app. It is a size comparison, not a saving.
- **5.43 %** — this is the "how much of an iOS app does the shared code
  replace" figure in the most defensible form: shipping iOS from the KMP
  codebase required only 104 lines of iOS-specific code (61 Kotlin `iosMain`
  + 24 Swift host + 19 config/resource lines) where the standalone SwiftUI app
  needed 1917. The shared code stands in for roughly 94.6 % of the
  platform-specific iOS surface.
- **117.4 %** — for an iOS-only product, KMP is *more* total code than native
  (2251 vs 1917 LOC). The saving only materialises across two platforms.

### Caveat that limits the headline claim

**This repository contains no native Android app.** The classic KMP argument —
"one shared codebase instead of two native codebases" — needs a native Android
baseline to quantify, and there isn't one here. The honest two-platform
statement from this data is:

> Delivering both platforms from the KMP codebase cost 2605 LOC, of which
> 82.42 % was shared. The iOS half of that delivery needed 104 lines of
> iOS-specific code against the 1917 lines of the standalone SwiftUI
> implementation.

Any figure of the form "KMP saved *X* % versus writing both apps natively"
cannot be computed from this repository and should not appear in the thesis
without a native Android implementation to measure against.

### Secondary caveats

- The two codebases are not verified to be feature-identical. The LOC ratio
  assumes equivalent scope; that equivalence was not audited as part of this
  extraction.
- 233 of the 354 Android-specific lines are XML (resources/manifest), which has
  no iOS counterpart — XML inflates the Android-specific share relative to a
  Kotlin-only count. Kotlin-only: Android-specific 121, iOS-specific 61,
  shared 2103, giving a shared share of 92.0 %.
- Comment lines are excluded, so the heavily-documented native iOS code
  (247 comment lines over 1858 code lines) is not penalised.

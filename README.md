# Evaluating Cross-Platform Development: KMP vs Native iOS

Measurement study behind the VAMK Master's thesis *Evaluating Cross-Platform
Development: A Comparative Study of Kotlin Multiplatform, Jetpack Compose, and
SwiftUI*.

The same news-reader app is implemented twice — once in Kotlin Multiplatform with
Compose Multiplatform (shipping Android **and** iOS from shared code), once as a
standalone SwiftUI app — and benchmarked on physical devices against a shared
backend.

**Status:** measurement complete. 18 of 18 iOS scenarios and 10 Android tests
produce per-iteration data. Write-up pending.

## Headline results

Cold startup is the one clean cross-platform comparison: both iOS targets use the
same OS-emitted `applicationLaunch` signpost over a real process launch, on the
same iPhone 16 and the same iOS 26.6, n = 30 each.

| Platform | Cold startup (median) | CV |
|---|---|---|
| **KMP iOS** | **239.5 ms** | 7.6 % |
| **Native iOS** | **271.3 ms** | 7.2 % |
| KMP Android, baseline profile | 272.18 ms | 3.7 % |
| KMP Android, full AOT | 344.82 ms | 4.2 % |

- KMP iOS vs native iOS — p = 5×10⁻⁹, r = −0.880: **Compose Multiplatform started
  11.7 % faster than SwiftUI** on this app
- Native iOS vs Android with baseline profile — **p = 0.853, not significant**
- **82.42 %** of the KMP codebase is shared; the iOS-specific part is **104 LOC
  against 1917** for the standalone SwiftUI app (94.57 % less)
- Binary size is the cost: KMP iOS `.app` **52.30 MB vs 1.49 MB — 35×**, because
  Compose statically links Skia and the Kotlin/Native runtime

Supportable conclusion: on this application KMP matched or beat native SwiftUI on
startup, at a large binary-size cost, with most code shared. **Not** supportable:
anything about scrolling throughput, rendering smoothness, or isolated data-layer
latency — see the caveats below.

## Read the caveats before quoting a number

Three results in this dataset look citable and are not:

1. **Scroll, fast-scroll and image-loading show an apparent 4–5× KMP advantage
   that is an artefact.** XCUITest waits for the app to go idle after a gesture;
   SwiftUI's `ScrollView` has real deceleration to settle (~2.7 s) while Compose
   renders through Skia and reports idle almost immediately (~0.5 s). Swipe
   geometry was tested and ruled out.
2. **Significance is not importance.** Warm startup, hot startup and initial data
   load are significant at p < 0.001 on median differences of 0.7–1.3 %.
3. **A sub-1 % CV is a warning, not precision** — it means the figure is dominated
   by test-harness overhead, not app work.

Full reasoning: **[`benchmark-data/METHODOLOGY.md`](./benchmark-data/METHODOLOGY.md)**.

## Repository structure

```
kmp-vs-native-evaluation/
├── kmp-app/                    Kotlin Multiplatform (Android + iOS)
│   ├── shared/                 commonMain / androidMain / iosMain
│   ├── composeApp/             Compose Multiplatform UI
│   ├── iosApp/                 Swift host + XCTest benchmark suite
│   └── benchmark/              Android Macrobenchmark suite
├── native-ios-app/             SwiftUI reference implementation + XCTest suite
├── backend/                    Ktor API (in-memory data, no database)
├── benchmark-data/             all measurement data — see its README
│   ├── RESULTS.md              every result, with caveats
│   ├── METHODOLOGY.md          what was broken; which comparisons hold
│   ├── data/                   summaries + per-run evidence
│   └── archive/                superseded material
├── scripts/                    benchmark runners, aggregation, backend IP sync
├── docs/                       SETUP.md, TESTING_GUIDE.md
└── THESIS_HANDOFF.md           brief for writing the thesis
```

## Documentation

| Start here | For |
|---|---|
| **[benchmark-data/RESULTS.md](./benchmark-data/RESULTS.md)** | Every result, with caveats |
| [benchmark-data/METHODOLOGY.md](./benchmark-data/METHODOLOGY.md) | Harness defects; comparability |
| [benchmark-data/README.md](./benchmark-data/README.md) | Data map and how to navigate it |
| [THESIS_HANDOFF.md](./THESIS_HANDOFF.md) | Writing the thesis from this data |
| [docs/SETUP.md](./docs/SETUP.md) · [docs/TESTING_GUIDE.md](./docs/TESTING_GUIDE.md) | Environment and running benchmarks |

## Running the benchmarks

```sh
# one scenario, with hard assertions on executed-test count and sample count
scripts/run-ios-benchmark.sh <kmp|native> StartupBenchmark/testColdStartup <out-dir>

# all nine scenarios for one target
scripts/run-all-ios-benchmarks.sh <kmp|native> <out-dir> 30

# regenerate the aggregate tables from the per-run data
python3 scripts/build-aggregates.py
```

The runner treats a zero executed-test count or an empty `measurements` array as a
hard failure. This matters: `xcodebuild` **exits 0 when a test selection matches
nothing**, which is how an earlier round of nine native iOS runs was reported as
"9/9 passed" having executed no tests at all. That false positive, and the rebuild
it forced, are written up in `METHODOLOGY.md` Part 1 as a finding in their own
right.

## Environment

| | |
|---|---|
| Android | Pixel 8 (`shiba`), Android 16 (API 36) — physical device |
| iOS | iPhone 16 (`iPhone17,3`), iOS 26.6 — physical device, both targets |
| iOS toolchain | Xcode 26.6 (17F113), Swift 6.3.3 |
| Android toolchain | AGP 8.13.2, Kotlin 2.2.21, Compose Multiplatform 1.10.0 |

No simulator or emulator produced any number in this study. Both iOS targets ran
on the same handset and OS version, one build per target across all nine of its
scenarios.

## Tech stack

**KMP app** — Kotlin 2.2.21, Compose Multiplatform 1.10.0, Ktor 3.3.3,
**Room 2.8.4**, Koin 4.1.1, Coil 3.3.0
**Native iOS** — Swift 6.3.3, SwiftUI, SwiftData
**Backend** — Ktor, in-memory data store (stateless, no database)
**Benchmarking** — androidx.benchmark 1.4.1 (Macrobenchmark) on Android, XCTest
with `XCTOSSignpostMetric` / `XCTClockMetric` / `XCTHitchMetric` on iOS

## Known limitations

- **No in-process instrumentation on iOS.** `AppTrace.ios.kt` is a no-op, so the
  Android trace sections have no iOS counterpart and every iOS figure measures a
  UI interaction including harness overhead. Kotlin/Native cannot emit
  `os_signpost`, so closing this needs a Swift-side emitter and a paired re-run.
- **No memory metric on iOS** — that comparison is Android-only.
- **No native Android app**, so "KMP saved X % versus writing both natively"
  cannot be computed from this repository.
- Android CPU frequency and thermal state were not pinned; Android and iOS ran on
  different dates and devices.

The full list is `RESULTS.md` §7.

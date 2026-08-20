# Thesis data extraction log

**Repository:** `/Users/amitkundu/StudioProjects/kmp-vs-native-evaluation`
**Extraction date:** 2026-08-20
**Thesis:** *Evaluating Cross-Platform Development: A Comparative Study of
Kotlin Multiplatform, Jetpack Compose, and SwiftUI* (VAMK Master's)
**Branch:** `thesis-data-extraction`

No existing file under `benchmark-data/` was modified. Everything produced by
this extraction lives in `benchmark-data/extracted/`.

---

## Headline finding — read this before using any iOS number

The iOS benchmark artefacts contain far less usable data than
`benchmark-data/FINAL_REPORT.md` states. Of the 18 xcresult bundles:

| | Bundles | Executed tests | Bundles with per-iteration metric samples |
|---|---|---|---|
| KMP iOS | 9 | 8 | **4** |
| Native iOS | 9 | **0** | **0** |

**All nine native iOS bundles executed zero tests.** Each one's activity log
records, verbatim:

```
Test Suite 'IosNativeBuildPerformanceTests' passed at 2026-06-06 13:33:17.953.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
```

The bundles contain the test *hierarchy* (target → `.xctest` → class) but no
test cases, no runs, and no metrics. All nine started within 48 seconds of each
other (13:33:04 → 13:33:52 on 2026-06-06) and each lasted 5–14 s — the
signature of a batch loop in which every `xcodebuild` invocation selected an
empty test set (e.g. an `-only-testing:` filter that matched nothing), while
still exiting 0 because a suite with zero tests "passes" vacuously.

Consequently:

- **`FINAL_REPORT.md`'s "Native iOS: 9/9 tests successful (100%)" is not
  supported by the artefacts.** Neither are its per-test notes ("Network + DB
  performance", "Native UIScrollView", etc.) — no such measurement exists.
- **Every KMP-iOS-vs-native-iOS comparison in the thesis is currently
  unsupported**, including the claim that "startup times are comparable between
  KMP iOS and Native iOS" and the conclusion that "Compose Multiplatform CAN
  compete with Native iOS on performance."
- Of the whole iOS dataset, exactly **one** metric is both present and
  methodologically sound: **KMP iOS cold startup, median 260.1 ms** (n = 30,
  `XCTOSSignpostMetric.applicationLaunch`).

This is recoverable — the harness needs specific fixes and a re-run, listed at
the end of this log.

---

## Task 1 — iOS metrics extracted into the Android CSV schema

### Method

`xcrun xcresulttool` (version 24757, schema 0.1.0) under Xcode 26.6. The modern
subcommands are available on this Xcode, so both paths were used:

```sh
xcrun xcresulttool get test-results summary --path <bundle>
xcrun xcresulttool get test-results tests   --path <bundle>
xcrun xcresulttool get test-results metrics --path <bundle>          # per-iteration arrays
xcrun xcresulttool get test-results activities --path <bundle> --test-id <id>
```

`get test-results metrics` returns the raw `measurements` array per metric —
the actual per-iteration samples, not the XCTest average — so that is the
primary source. To guard against the modern subcommand hiding data, **every
bundle was also walked through the legacy graph** (`ActionsInvocationRecord` →
`actions[0].actionResult.testsRef` → `ActionTestPlanRunSummaries` →
`testableSummaries` → recursive `subtests` → `summaryRef` →
`performanceMetrics`/`measurements`):

```sh
xcrun xcresulttool get object --legacy --format json --path <bundle>
xcrun xcresulttool get object --legacy --format json --path <bundle> --id <ref-id>
```

Both paths agree exactly: the same 4 bundles carry samples and the other 14
carry none. The empty bundles are genuinely empty, not a tooling artefact.

Statistics computed with numpy 2.5.2 (`percentile(..., method="linear")` for
p95/p99, `ddof=1` for the sample standard deviation).

### Device and OS, read from the xcresult metadata

Read from `runDestination.targetDeviceRecord` per bundle — not guessed:

- **iPhone 16** (`iPhone17,3`), UDID `00008140-0005309E3687001C`, arm64,
  `isConcreteDevice: true` (a physical device, not a simulator).
- **iOS 26.4.2 (build 23E261)** for the April 2026 KMP runs — `cold_start`,
  `warm_start`, `hot_start`, `scroll_performance`, `fast_scroll_stress`,
  `initial_data_load`.
- **iOS 26.5 (build 23F77)** for the June 2026 runs — KMP `category_filter`,
  `image_loading`, `search_performance`, and all nine native bundles.
- Build host: MacBook Pro `Mac15,7`, Apple M3 Pro, 36 GB; macOS 26.4.1 (25E253)
  in April, macOS 26.5.1 (25F80) in June.
- **Xcode version at benchmark time: UNKNOWN.** The bundles do not record it
  and the activity logs contain no Xcode or `swiftlang` version string. Xcode
  26.6 (17F113) is what performed *this extraction* and the Task 4 size builds
  — not the benchmark runs. Marked UNKNOWN in `environment.md` rather than
  inferred.

Note that the KMP data spans two iOS versions, so even KMP-internal
scenario-to-scenario comparisons cross an OS boundary.

### What was extracted

`extracted/kmp_ios_summary.csv` — 4 rows, exact Android header
(`platform,test,metric,iterations,mean,median,std_dev,cv_pct,min,max,p95,p99,unit,device,os_version`):

| test | metric | n | median | CV % | unit | os |
|---|---|---|---|---|---|---|
| coldStartup | Duration (AppLaunch) | 30 | 0.2601 | 15.29 | s | iOS_26.4.2 |
| initialDataLoad | Clock Monotonic Time | 30 | 23.3283 | 0.26 | s | iOS_26.4.2 |
| categoryFilterPerformance | Clock Monotonic Time | 50 | 3.1819 | 0.35 | s | iOS_26.5 |
| imageLoadingPerformance | Clock Monotonic Time | 30 | 4.3598 | 1.27 | s | iOS_26.5 |

`extracted/native_ios_summary.csv` — **header only, zero data rows.** Written
deliberately so the schema exists and the absence is explicit rather than
silent.

Per-iteration raw samples (one value per row, with unit, device and OS):

- `extracted/raw/kmp_ios/coldStartup_Duration_AppLaunch.csv` (30)
- `extracted/raw/kmp_ios/initialDataLoad_ClockMonotonicTime.csv` (30)
- `extracted/raw/kmp_ios/categoryFilterPerformance_ClockMonotonicTime.csv` (50)
- `extracted/raw/kmp_ios/imageLoadingPerformance_ClockMonotonicTime.csv` (30)
- `extracted/raw/native_ios/` — **not created; no samples exist.**

`extracted/extraction_audit.json` records, per bundle, the destination metadata
and every metric block found (including the zero-metric ones), so the negative
result is auditable.

### Why the other 14 bundles yielded nothing — root cause per bundle

These are code-level defects in the benchmark harness, not extraction failures.
A re-run without these fixes would produce the same empty bundles.

| Bundle(s) | Tests ran? | Root cause |
|---|---|---|
| `warm_start`, `hot_start` (KMP) | Yes, Success | Metric is `XCTOSSignpostMetric.applicationLaunch`, but the closure only calls `XCUIDevice.press(.home)` + `app.activate()`. **No process launch occurs, so the system never emits the `AppLaunch` signpost interval** and XCTest records 0 measurements. Compounded by the element wait: 52 "Collecting debug information to assist test failure triage" activities and ~18–20 s per iteration across a 946 s / 1020 s run show the lookup was timing out every iteration. |
| `scroll_performance`, `fast_scroll_stress` (KMP) | Yes, Success | Metric is `XCTOSSignpostMetric.scrollDecelerationMetric`, which depends on the `UIScrollView` deceleration signpost. **Compose Multiplatform renders its own scrolling through Skia and never emits that signpost**, so 0 measurements. `scroll_performance` additionally took **4 h 57 m** for 50 swipes (17,832 s span) — the `descendants(matching: .any)` fallback in `findScrollableElement()` makes each accessibility query pathologically slow. `fast_scroll_stress` ran healthily (153.8 s for 186 swipes) but still recorded no metric. |
| `search_performance` (KMP) | No — 0 tests | Run was **cancelled** 2.6 s after starting (`Testing cancelled` in the log). Consistent with `FINAL_REPORT.md`'s note that XCTest cannot focus a Compose text field, but the artefact shows cancellation, not a measured failure. |
| all 9 native bundles | No — 0 tests | `Executed 0 tests, with 0 failures`. Empty test selection; see the headline finding. |

### Cross-platform comparison

`extracted/combined_comparison.csv` and `extracted/combined_comparison.md`, one
row per scenario with each platform's median and p95 side by side, plus an
explicit **`comparability`** verdict per row. The verdict column is the point of
the table — most rows must not be compared numerically:

| Scenario | Verdict | KMP Android | KMP iOS | Native iOS |
|---|---|---|---|---|
| Cold startup vs Android `CompilationMode.Partial` | COMPARABLE (caveats) | 272.2 ms | 260.1 ms | NO_DATA |
| Cold startup vs Android `CompilationMode.Full` | COMPARABLE (caveats) | 344.8 ms | 260.1 ms | NO_DATA |
| Warm startup | NO_DATA | 51.6 ms | — | — |
| Hot startup | NO_DATA | 32.2 ms | — | — |
| Scroll (steady-state) | NO_DATA | 927.5 frames | — | — |
| Fast-scroll stress | NO_DATA | 2243.5 frames | — | — |
| Initial data load | **NOT COMPARABLE** | 215.3 ms | 23328.3 ms | NO_DATA |
| Category filter | **NOT COMPARABLE** | 5.2 ms | 3181.9 ms | NO_DATA |
| Search | NO_DATA | 4.3 ms | — | — |
| Image loading | **NOT COMPARABLE** | 83 frames | 4359.8 ms | NO_DATA |

The three NOT COMPARABLE rows have samples on both sides but measure
structurally different things:

- **Android measures in-process trace sections** via `AppTrace`
  (`NewsRepo.networkFetchSumMs`, `NewsRepo.getArticlesSumMs`) — the repository
  call only, in milliseconds.
- **iOS measures UI wall clock** via `XCTClockMetric` over a whole XCTest
  closure — *including hardcoded sleeps*. `categoryFilterPerformance` contains
  two `sleep(1)` calls, so ≥2 s of its 3.18 s median is deliberate sleep.
  `imageLoadingPerformance` contains `sleep(2)` + `sleep(1)`, so ≥3 s of its
  4.36 s median is deliberate sleep. `initialDataLoad` is ~22 s of
  accessibility timeout (Task 2).
- Additionally, Android's `imageLoadingPerformance` metric is a **frame count**,
  not a duration — a different quantity entirely.

Also note the naming correction applied here: Android's `coldStartupFull` uses
`CompilationMode.Full()` (**full AOT compilation**), *not* "no baseline
profile". `coldStartupWithBaselineProfile` uses
`CompilationMode.Partial(BaselineProfileMode.Require)`. Full AOT measured
*slower* (344.8 ms) than partial (272.2 ms).

---

## Task 2 — The "Initial Data Load 23.3 s" definition

Full analysis: **`extracted/initial_data_load_definition.md`**.

**It is not data-load latency.** `XCTClockMetric` measures the whole closure —
`app.launch()` → `waitForElement(...)` → `XCTAssertTrue` → `app.terminate()` —
and roughly **22 of the 23.3 s are XCTest accessibility-lookup timeouts**.

`BasePerformanceTest.waitForElement` tries three element types in sequence with
timeouts of 20 s (`contentLoadTimeout`), 2 s and 2 s. Under Compose
Multiplatform the `article_list` testTag matches neither `scrollViews` nor
`otherElements`, so the first two tiers always time out (20 + 2 = 22 s) and the
element is only found by the exhaustive `descendants(matching: .any)` query.

Two facts pin this decomposition:

1. The test **passed** (`testStatus: Success` with `continueAfterFailure = false`
   and `XCTAssertTrue(appeared)`), so the element *was* found — only possible via
   the third tier after the first two timed out.
2. The distribution is a **constant, not a workload**: n = 30, range
   23.202–23.588 s, std dev 0.066 s, **CV = 0.26 %**. Real network+database work
   does not vary by ±0.2 % across 30 cold launches. (Android's network fetch has
   CV = 14.7 %.)

**Could an isolated latency be derived? No — for both targets, for different reasons.**

- **KMP iOS:** the app emits no signposts on iOS at all.
  `shared/src/iosMain/.../AppTrace.ios.kt` is an explicit no-op, so the
  `NewsRepo.networkFetch` / `LocalDS.insertArticles` sections that Android
  reports **do not exist in the iOS build**. The test declares only
  `XCTClockMetric` — no signpost metric, no `startMeasuring`/`stopMeasuring`
  bracketing. Nothing to subtract, no sub-interval to read. Arithmetic
  subtraction of the two known timeouts leaves ≈1.3 s for launch + lookup +
  terminate (≈1.07 s after removing the 0.26 s launch signpost), but that is an
  **upper bound contaminated by XCTest query cost**, recorded in the analysis
  doc as indicative only — it is not reported as a measurement.
- **Native iOS:** the twin test uses the **same metric definition**
  (`XCTClockMetric` over launch → wait → terminate), so the requested
  iOS-vs-iOS comparison is well-defined in principle — but **no native figure
  can be extracted because no native test ran.**

**Even with native data the raw numbers would not be comparable**, because the
two harnesses differ in constant overhead: KMP uses the 3-tier fallback
(20+2+2 s), native uses a **single direct** `app.scrollViews[...]` lookup that
resolves in milliseconds against a real SwiftUI `ScrollView`. A 23.3 s vs ~1 s
result would mostly measure XCTest's ability to find a Compose element — a real
accessibility finding, but not a data-loading one.

**Actionable asymmetry:** the native iOS app *is* already signpost-instrumented
— `IosNativeBuild/Performance/PerformanceMonitor.swift` emits `os_signpost`
intervals `getArticles` (category `Network`), `searchArticles` (`Database`) and
`loadArticles` (`UI`) under subsystem `com.amit.IosNativeBuild`. The native
tests simply never asked for them (they declare `XCTClockMetric`). Switching the
native test to `XCTOSSignpostMetric(subsystem:category:name:)` would yield an
isolated native fetch latency with **no app code changes**. The KMP app would
need `AppTrace.ios.kt` implemented first.

---

## Task 3 — Code-sharing analysis

Full tables and the exact command: **`extracted/code_sharing.md`**. cloc 2.10.

| Group | Code LOC |
|---|---|
| SHARED (`commonMain` × shared + composeApp) | 2147 |
| KMP Android-specific (`androidMain`) | 354 |
| KMP iOS-specific (`iosMain` + Swift host) | 104 |
| Native iOS (`IosNativeBuild`) | 1917 |
| *Test code (separate)* — Android macrobenchmark / KMP iOS XCTest / native iOS XCTest / baseline profile | *288 / 279 / 300 / 45* |

KMP production total 2605 LOC:

- **Shared: 82.42 %** · Android-specific 13.59 % · iOS-specific 3.99 %
- **Shared vs native-iOS ratio: 2147 / 1917 = 1.120** (the requested ratio)
- **iOS-specific vs a full native iOS app: 104 / 1917 = 5.43 %** — a 94.57 %
  reduction in iOS-specific code. This is the most defensible form of "how much
  of an iOS app the shared code replaces".
- Whole KMP iOS footprint vs native: 2251 / 1917 = **117.4 %** — for an
  iOS-*only* product KMP is 334 LOC *more* code than native.

**Caveat that limits the headline claim:** the repository contains **no native
Android app**, so "KMP saved X % versus writing both apps natively" cannot be
computed from this data and should not appear in the thesis without a native
Android baseline. Feature-parity between the two codebases was also not audited.

---

## Task 4 — Application size

Full table, commands and caveats: **`extracted/app_size.md`**.

| Target | Artifact | Size |
|---|---|---|
| KMP Android `composeApp` | APK, unsigned `release` | **55.78 MB** (58,486,922 B) |
| KMP iOS `iosApp` | `.app`, device arm64, unstripped | **52.30 MB** (53,556 KB) |
| KMP iOS `iosApp` | `.app`, stripped (proxy) | 39.78 MB |
| KMP iOS `iosApp` | compressed IPA **proxy** | 13.17 MB |
| Native iOS | `.app`, device arm64, unstripped | **1.49 MB** (1,528 KB) |
| Native iOS | `.app`, from archive | 0.45 MB (464 KB) |
| Native iOS | **IPA** (real, signed) | **0.159 MB** (166,655 B) |
| Native iOS | `.app`, simulator | 2.90 MB — labelled simulator, reference only |

**Android R8/minify is OFF** (`composeApp/build.gradle.kts:108`,
`isMinifyEnabled = false`), no `shrinkResources`, no ProGuard rules. The release
variant embeds a baseline profile via `baselineProfile(project(":baselineprofile"))`,
and there is **no** profile-free release variant, so no profile/non-profile size
delta can be reported.

**The iOS pairing is a genuine framework finding; the Android APK number is
not.** Both iOS artefacts are single-architecture arm64 device Release builds of
the same app, processed identically at each stage:

| Stage | KMP iOS | Native iOS | Ratio |
|---|---|---|---|
| `.app` unstripped | 52.30 MB | 1.49 MB | **35×** |
| `.app` stripped | 39.78 MB | 0.45 MB | **88×** |
| Compressed | 13.17 MB (proxy) | 0.159 MB (real IPA) | **83×** |

Compose Multiplatform statically links Skia, the Compose runtime and the
Kotlin/Native runtime into a single 52.20 MB Mach-O (no `Frameworks/` directory),
whereas SwiftUI relies on frameworks already in iOS.

By contrast the 55.78 MB Android APK is dominated by **~52.4 MB of unminified
dex** across three files plus **four ABI slices** of `libsqliteJni.so` — build
configuration, not framework cost. Do not pair it against the 0.159 MB IPA.

Build obstacles, both resolved or documented rather than worked around:

- KMP iOS device build initially failed on provisioning
  (`No profiles for 'com.example.thesisproject.Thesisproject' were found`);
  built with `CODE_SIGNING_ALLOWED=NO` for sizing.
- Kotlin/Native release framework linking OOMed at the repo default. The knob
  that matters is **`kotlin.native.jvmArgs`**, not `kotlin.daemon.jvmargs` —
  raising the daemon heap to 8 GB did not help; `-Xmx10g` on the Native compiler
  did. `kmp-app/gradle.properties` was restored, so the committed tree carries
  no build-config change.
- A **real** KMP archive/IPA still requires provisioning; the stripped and
  compressed KMP figures are locally produced proxies (`strip -rSTx`, `zip`) and
  are labelled as such everywhere.

---

## Task 5 — Statistical significance tests

Full tables: **`extracted/stats_tests.md`** (machine-readable:
`stats_tests.json`). α = 0.05; Shapiro–Wilk per group, then Welch's t-test if
both groups are consistent with normality, otherwise Mann–Whitney U.

**2 tests could be run; 16 could not.**

| Comparison | n | medians | Test | p | Effect size | Verdict |
|---|---|---|---|---|---|---|
| Cold startup — KMP iOS vs KMP Android (`CompilationMode.Partial`) | 30 / 30 | 260.08 vs 272.18 ms | Mann–Whitney U | 1.175 × 10⁻⁴ | rank-biserial r = −0.580 | **significant** |
| Cold startup — KMP iOS vs KMP Android (`CompilationMode.Full`) | 30 / 30 | 260.08 vs 344.82 ms | Mann–Whitney U | 5.573 × 10⁻¹⁰ | rank-biserial r = −0.933 | **significant** |

Mann–Whitney was selected in both cases because the iOS sample fails
Shapiro–Wilk (it has a heavy right tail: three of 30 launches at
0.326/0.463/0.330 s against a 0.26 s median, giving CV = 15.3 %).

**Every KMP-iOS-vs-native-iOS test — all nine scenarios — could not be run**
(native has no samples). Warm/hot/scroll/fast-scroll/search KMP-vs-Android could
not be run (KMP iOS has no samples). Initial-data-load, category-filter and
image-loading KMP-vs-Android were **deliberately not run**: samples exist on
both sides but measure different intervals, so a p-value would be meaningless.

**Caveat on the two tests that did run:** they cross platforms *and*
instrumentation — Android's `timeToInitialDisplayMs` comes from Macrobenchmark
frame timing, iOS's from the `applicationLaunch` signpost. Both bound "process
launch → first content frame" but they are different probes, on different
devices (Pixel 8 vs iPhone 16) and different OSes. The significance is real for
the measured quantities; it is not a clean like-for-like framework comparison.

---

## Task 6 — Environment capture

**`extracted/environment.md`.** Both benchmark platforms were **physical,
connected devices** — no emulator or simulator produced any performance number
in this study.

- **Android: Google Pixel 8** (`shiba`), **Android 16** (API level 36), build
  `BP4A.260105.004.E1`, fingerprint
  `google/shiba_16kb/shiba:16/BP4A.260105.004.E1/14587043:user/release-keys`,
  9 cores @ 2.914 GHz, 7.5 GiB RAM. `cpuLocked = false` and
  `sustainedPerformanceModeEnabled = false` — CPU frequency and thermal state
  were **not** pinned, a real source of variance. (The CSVs label this
  `Android_36`; API 36 is Android 16.)
- **iOS: Apple iPhone 16** (`iPhone17,3`) — iOS 26.4.2 (23E261) and iOS 26.5
  (23F77) across the two sessions, as tabulated above.
- Toolchain from `libs.versions.toml`: AGP 8.13.2, Kotlin 2.2.21, Compose
  Multiplatform 1.10.0, Ktor 3.3.3, Room 2.8.4, Koin 4.1.1, Coil 3.3.0,
  minSdk 30 / target-compileSdk 36, androidx.benchmark 1.4.1.
- Marked **UNKNOWN** (not guessed): Xcode version at benchmark time, Swift
  version at benchmark time, the Debug/Release configuration of the two iOS apps
  as benchmarked, and the JDK used for the original Android runs.

**Discrepancy recorded, not explained away:** the Android benchmark source
requests `CompilationMode.Full()` and
`CompilationMode.Partial(BaselineProfileMode.Require)`, but *every* raw JSON
records `context.compilationMode = "run-from-apk"`. Either that context field
reports a harness default rather than the per-benchmark mode, or the requested
modes were not applied. This matters, because the 272.18 ms vs 344.82 ms gap is
interpreted as a compilation-mode effect.

---

## Deliverables

| File | Contents |
|---|---|
| `EXTRACTION_LOG.md` | This log |
| `kmp_ios_summary.csv` | KMP iOS stats, Android schema — **4 rows** |
| `native_ios_summary.csv` | Native iOS stats, Android schema — **header only, 0 rows** |
| `raw/kmp_ios/*.csv` | Per-iteration samples, 4 files (30/30/50/30 values) |
| `combined_comparison.csv` | Cross-platform table, median + p95 per platform, with `comparability` verdict |
| `combined_comparison.md` | Same, as paste-ready thesis tables |
| `initial_data_load_definition.md` | Task 2 analysis of the 23.3 s figure |
| `code_sharing.md` | Task 3 cloc tables, percentages, exact command |
| `app_size.md` | Task 4 artefact sizes and build configs |
| `stats_tests.md` / `stats_tests.json` | Task 5 significance tests |
| `environment.md` | Task 6 environment capture |
| `extraction_audit.json` | Per-bundle metadata + metric inventory (audit trail for the negative results) |
| `RERUN_PROMPT.md` | Self-contained hand-off brief for fixing the harness and re-running the missing benchmarks |

## Gaps that remain

Ordered by impact on the thesis.

1. **All native iOS performance data is missing.** 0 of 9 bundles executed any
   test. Every KMP-iOS-vs-native-iOS claim in `FINAL_REPORT.md` and in the
   thesis is currently unsupported. Requires a re-run.
2. **KMP iOS warm startup, hot startup, scroll and fast-scroll produced no
   measurements**, and search was cancelled. These are harness defects
   (wrong metric for the interaction), not device or framework limits — a re-run
   without code changes will reproduce them exactly.
3. **KMP iOS initial-data-load, category-filter and image-loading numbers are
   not usable as performance figures.** They are dominated by fixed XCTest
   timeouts (22 s) or hardcoded `sleep()` calls (2–3 s). They are valid
   measurements of *the harness*, not of the app.
4. **Only one sound iOS metric exists:** KMP iOS cold startup, 260.1 ms
   (n = 30). It is the sole basis for any current cross-platform performance
   statement, and it compares against Android only across differing
   instrumentation.
5. **No native Android app**, so the two-platform code-saving claim cannot be
   quantified (Task 3).
6. **Xcode/Swift versions and the iOS build configurations at benchmark time are
   unrecoverable** from the artefacts (Task 6).
7. **Android `compilationMode` discrepancy** unresolved (Task 6).
8. **No real KMP iOS archive or signed IPA** — provisioning is unavailable, so
   the stripped (39.78 MB) and compressed (13.17 MB) KMP figures are local
   proxies. The unstripped device `.app` comparison (52.30 MB vs 1.49 MB) is a
   real, like-for-like measurement and needs no follow-up (Task 4).
9. **iOS runs span two OS versions** (26.4.2 and 26.5), and Android runs had
   CPU frequency and thermal state unpinned.
10. **No memory metric on iOS.** Android reports `memoryDuringScrolling`
    (heap/RSS/GPU); no iOS equivalent was collected, so the memory comparison is
    Android-only.

## What a re-run needs (harness fixes first)

A re-run on the connected devices would close gaps 1–4, but **only if the
harness is fixed first** — as written, the tests cannot produce the missing
numbers.

1. **Native iOS — fix test selection.** This is the single highest-value fix:
   it recovers an entire platform. Verify the scheme's test plan actually
   contains `IosNativeBuildPerformanceTests`, and that any `-only-testing:`
   argument matches real identifiers
   (`IosNativeBuildPerformanceTests/StartupBenchmark/testColdStartup`). Then
   assert a non-zero test count — treat "Executed 0 tests" as a failure, since
   `xcodebuild` exits 0 in that case. (The same false-positive pattern bit this
   extraction: an Android build reported as succeeding had actually failed, the
   exit code having come from a `tail` in a pipeline.)
2. **Warm/hot startup — change the metric.** `applicationLaunch` cannot work
   without a process launch. Use `XCTClockMetric` around
   `activate()` → element-visible, or emit an app-side `os_signpost` interval on
   foreground and measure that.
3. **Scroll/fast-scroll — change the metric.** `scrollDecelerationMetric` never
   fires under Compose. Use `XCTOSSignpostMetric.animationOverhead`, or an
   app-side signpost, or frame timing.
4. **Make Compose elements addressable.** Set
   `testTagsAsResourceId = true` on the Compose root so `testTag("article_list")`
   becomes a real `accessibilityIdentifier`. This removes the 22 s timeout, the
   `descendants(matching: .any)` slowness, and probably the search-field focus
   failure — the single change with the widest effect.
5. **Remove `sleep()` from measured closures**, or bracket with
   `startMeasuring()`/`stopMeasuring()`, so filter/image metrics measure work
   rather than sleep.
6. **Implement `AppTrace.ios.kt`** with `os_signpost` intervals mirroring the
   Android section names, and measure them with `XCTOSSignpostMetric`. This is
   what makes iOS numbers genuinely comparable to Android's, and it brings the
   KMP app up to the instrumentation the native app already has.
7. **Pin the Android device**: `cpuLocked` / sustained performance mode, and
   re-run all platforms on a single OS version per device.

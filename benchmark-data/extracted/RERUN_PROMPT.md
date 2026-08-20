# Hand-off prompt — fix the iOS benchmark harness and re-run the missing tests

Copy everything below the line into a fresh AI assistant chat. It is
self-contained: it states the defects, the evidence, the required fixes, and the
acceptance criteria, so the new session does not need this conversation.

---

I need you to fix a broken iOS benchmark harness and then re-run the benchmarks
that produced no data. This is for my VAMK Master's thesis "Evaluating
Cross-Platform Development: A Comparative Study of Kotlin Multiplatform,
Jetpack Compose, and SwiftUI".

**Repo:** `/Users/amitkundu/StudioProjects/kmp-vs-native-evaluation`

A previous extraction pass analysed the existing xcresult bundles and found the
benchmark suite is substantially broken. Read
`benchmark-data/extracted/EXTRACTION_LOG.md` and
`benchmark-data/extracted/initial_data_load_definition.md` first — they contain
the full diagnosis and the evidence for every claim below. Do not re-derive it.

## Hardware (both physical, connected devices — no simulator)

- **iPhone 16** (`iPhone17,3`), UDID `00008140-0005309E3687001C`. I will have it
  connected via USB. KMP iOS app bundle id
  `com.example.thesisproject.Thesisproject`; native app subsystem
  `com.amit.IosNativeBuild`.
- **Google Pixel 8** (`shiba`), **Android 16** (API 36). The Android data is
  already complete — do not re-run Android unless I ask.

## What is currently broken

### 1. Native iOS: all 9 runs executed zero tests (highest priority)

Every bundle in `benchmark-data/native-ios/xcresults/` records:

```
Test Suite 'IosNativeBuildPerformanceTests' passed at 2026-06-06 13:33:17.953.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
```

All nine started within 48 seconds of each other and each lasted 5–14 s. The
test selection matched nothing, and `xcodebuild` still exited 0 because a suite
with zero tests passes vacuously. **There is no native iOS performance data at
all**, so every KMP-iOS-vs-native-iOS comparison in my thesis is currently
unsupported. Fixing this recovers an entire platform and matters more than
anything else here.

Project: `native-ios-app/IosNativeBuild.xcodeproj`, scheme `IosNativeBuild`,
targets `IosNativeBuild` and `IosNativeBuildPerformanceTests`.

Find out why the selection was empty — check whether the scheme's test action
actually includes the `IosNativeBuildPerformanceTests` target, whether a test
plan exists and lists it, and whether any `-only-testing:` argument matches real
identifiers such as
`IosNativeBuildPerformanceTests/StartupBenchmark/testColdStartup`.

### 2. `XCTOSSignpostMetric.applicationLaunch` on warm/hot startup — always 0 measurements

`kmp-app/iosApp/iosAppPerformanceTests/StartupBenchmark.swift:17-47` (and the
identical native twin at
`native-ios-app/IosNativeBuildPerformanceTests/StartupBenchmark.swift:17-47`)
measure warm and hot startup with `XCTOSSignpostMetric.applicationLaunch`, but
the closure only does `XCUIDevice.shared.press(.home)` + `app.activate()`.

No process launch happens, so the system never emits the `AppLaunch` signpost
interval, so XCTest records zero measurements. This is unfixable by re-running —
the metric is simply wrong for the interaction.

Also, the KMP warm/hot runs show 52 "Collecting debug information to assist test
failure triage" activities and ~18–20 s per iteration (946 s and 1020 s total),
so the element lookup was timing out every iteration too. See defect 4.

### 3. `XCTOSSignpostMetric.scrollDecelerationMetric` under Compose — always 0 measurements

`kmp-app/iosApp/iosAppPerformanceTests/ScrollBenchmark.swift:18` and `:30` use
`scrollDecelerationMetric`, which depends on the `UIScrollView` deceleration
signpost. Compose Multiplatform renders its own scrolling through Skia and never
emits it. Zero measurements in both scroll tests.

`scroll_performance` additionally took **4 h 57 m** for 50 swipes (17,832 s
span), because `findScrollableElement()` falls through to
`app.descendants(matching: .any)` and every accessibility query then walks the
whole hierarchy.

### 4. Compose elements are not addressable, costing 22 s per iteration

`kmp-app/iosApp/iosAppPerformanceTests/BasePerformanceTest.swift:47-59`:

```swift
func waitForElement(identifier: String, timeout: TimeInterval) -> Bool {
    let scrollView = app.scrollViews[identifier]
    if scrollView.waitForExistence(timeout: timeout) { return true }   // 20 s, always times out
    let other = app.otherElements[identifier]
    if other.waitForExistence(timeout: 2) { return true }              // 2 s, always times out
    let descendant = app.descendants(matching: .any)[identifier]
    return descendant.waitForExistence(timeout: 2)                     // finally succeeds
}
```

The Compose `testTag("article_list")` matches neither `scrollViews` nor
`otherElements`, so 22 s of fixed timeout is burned every iteration and the
element is only found by the exhaustive descendants query. This is why
`initialDataLoad` reports 23.33 s with a CV of 0.26 % — it is measuring a
timeout constant, not data loading.

The native harness does **not** have this problem: it uses a single direct
`app.scrollViews[TestConstants.Identifiers.newsListScrollView]` lookup. The two
harnesses therefore have wildly different constant overhead, which is why the
raw numbers are not comparable even where both exist.

### 5. Hardcoded `sleep()` inside measured closures

`kmp-app/iosApp/iosAppPerformanceTests/NetworkDatabaseBenchmark.swift`:

- `testCategoryFilterPerformance` (`:25-35`) contains two `sleep(1)` calls, so
  ≥2 s of its 3.18 s median is deliberate sleep.
- `testImageLoadingPerformance` (`:76-81`) contains `sleep(2)` + `sleep(1)`, so
  ≥3 s of its 4.36 s median is deliberate sleep.

These metrics measure the sleeps, not the app. The native twins have the same
pattern.

### 6. The KMP app emits no signposts on iOS

`kmp-app/shared/src/iosMain/kotlin/com/amit/newsreader/util/AppTrace.ios.kt`:

```kotlin
actual object AppTrace {
    actual fun beginSection(label: String) { /* no-op on iOS — use Instruments instead */ }
    actual fun endSection() { /* no-op */ }
}
```

So the trace sections Android reports — `NewsRepo.networkFetch`,
`NewsRepo.getArticles`, `NewsRepo.searchArticles`, `LocalDS.insertArticles` —
**do not exist in the iOS build**. There is no way to measure an isolated fetch
or query latency on KMP iOS today.

The **native app is already instrumented**:
`native-ios-app/IosNativeBuild/Performance/PerformanceMonitor.swift` emits
`os_signpost` intervals `getArticles` (category `Network`), `searchArticles`
(category `Database`) and `loadArticles` (category `UI`) under subsystem
`com.amit.IosNativeBuild` — but the native tests declare `XCTClockMetric` and
never ask for them.

### 7. KMP `search_performance` was cancelled

The bundle records `Testing cancelled` 2.6 s in, with 0 tests executed. The
earlier report attributed this to XCTest being unable to focus a Compose text
field; fixing defect 4 may resolve it, but verify rather than assume.

## What I want you to do

### Phase A — fix the harness

1. **Native iOS test selection.** Get `IosNativeBuildPerformanceTests` actually
   running. Prove it with a single test before touching anything else.
2. **Make Compose elements addressable.** Set
   `testTagsAsResourceId = true` via `Modifier.semantics` on the Compose root in
   the KMP app so `testTag(...)` becomes a real `accessibilityIdentifier`, then
   collapse `waitForElement` / `findScrollableElement` to a single direct lookup
   matching the native harness. This is the highest-leverage change: it should
   remove the 22 s timeout, the multi-hour scroll runs, and possibly the search
   failure.
3. **Replace the broken metrics.** Warm/hot startup: use `XCTClockMetric` over
   `activate()` → element-visible, or an app-side `os_signpost` interval emitted
   on foreground. Scroll/fast-scroll: use `XCTOSSignpostMetric.animationOverhead`,
   an app-side signpost, or frame timing — not `scrollDecelerationMetric`.
4. **Get the sleeps out of the measured interval.** Use
   `startMeasuring()`/`stopMeasuring()` to bracket only the work, or move the
   settle time outside `measure { }`.
5. **Implement `AppTrace.ios.kt`** with `os_signpost` intervals whose names
   mirror the Android trace sections (`NewsRepo.networkFetch`,
   `NewsRepo.getArticles`, `NewsRepo.searchArticles`,
   `LocalDS.insertArticles`), and measure them with
   `XCTOSSignpostMetric(subsystem:category:name:)`. Do the same on the native
   side by switching its tests to the signposts `PerformanceMonitor` already
   emits. This is what finally makes the iOS numbers comparable to Android's
   instead of measuring the harness.
6. **Keep the two harnesses symmetric.** Any timeout, retry or settle-time
   change must be applied identically to the KMP and native suites, otherwise
   the comparison measures the harness difference again. Note the current
   iteration counts and keep them: cold 30, warm 50, hot 50, scroll 50,
   fast-scroll 30, initial-data-load 30, category-filter 50, search 50,
   image-loading 30.

### Phase B — re-run on the connected iPhone

Re-run all nine scenarios for **both** iOS targets. Save bundles to new
directories — **do not overwrite anything** under
`benchmark-data/kmp-ios/xcresults/` or `benchmark-data/native-ios/xcresults/`;
those are the artefacts of record for what went wrong. Use e.g.
`benchmark-data/rerun-2026-08/{kmp-ios,native-ios}/`.

**Guardrails, learned the hard way on this dataset:**

- **Treat "Executed 0 tests" as a hard failure.** `xcodebuild` exits 0 on an
  empty test selection — that single fact is what silently invalidated nine
  native runs and produced a "9/9 passed" claim in the report. Assert a non-zero
  executed-test count and a non-empty `measurements` array after every run.
- Verify each bundle immediately with
  `xcrun xcresulttool get test-results metrics --path <bundle>` and fail loudly
  if it returns `[]`.
- Keep all runs on **one iOS version**. The existing data straddles iOS 26.4.2
  and 26.5, which confounds even KMP-internal comparisons.
- Record the Xcode and Swift versions into a file at run time. They are
  **not** recoverable from xcresult bundles afterwards — currently UNKNOWN for
  the original runs.
- Never fabricate a number. If a metric still cannot be captured, say so
  explicitly and move on.

### Phase C — re-extract

Re-run the extraction into a new folder (do not overwrite
`benchmark-data/extracted/`), producing the same deliverables in the same Android
CSV schema
(`platform,test,metric,iterations,mean,median,std_dev,cv_pct,min,max,p95,p99,unit,device,os_version`),
and state plainly which gaps closed and which remain.

## Build issues you will hit

- **KMP iOS device build fails on code signing:** `No profiles for
  'com.example.thesisproject.Thesisproject' were found`. Pass
  `-allowProvisioningUpdates`, or select a development team in Xcode. (For
  size-only builds, `CODE_SIGNING_ALLOWED=NO` works, but running tests on device
  needs real signing.)
- **Kotlin/Native release framework link OOMs** at the repo's default
  `kotlin.daemon.jvmargs=-Xmx3072M`, dying in `DevirtualizationAnalysis` during
  `linkReleaseFrameworkIos*`. Raising `kotlin.daemon.jvmargs` alone is not
  enough — the Kotlin/Native compiler needs `kotlin.native.jvmArgs` (e.g.
  `-Xmx10g`). Debug framework builds are unaffected. The repo file is currently
  unmodified, so you will need to set this yourself.
- Android builds need `ANDROID_HOME` exported (`~/Library/Android/sdk`); there is
  no `local.properties`.

## Ground rules

- Work on a new branch; do not commit to `main`.
- Do not modify anything under `benchmark-data/` except by adding new folders.
- `benchmark-data/FINAL_REPORT.md` contains claims the artefacts do not support
  ("Native iOS: 9/9 tests successful (100%)"). Leave it alone unless I ask — but
  do not treat it as a source of truth.

# Task 2 — What the "Initial Data Load 23.3 s" figure actually measures

**Verdict: it is not data-load latency.** It is the wall-clock duration of an
entire XCTest scenario, and roughly **22 of the 23.3 seconds are XCTest
accessibility-lookup timeouts** — time the harness spends failing to find a UI
element, not time the app spends loading data.

The hypothesis in the task brief was correct, and the mechanism is more specific
than "launch + fetch + persist + render + waits": the dominant term is a
three-tier element-lookup fallback whose first two tiers always time out.

## The measured interval, exactly

`kmp-app/iosApp/iosAppPerformanceTests/NetworkDatabaseBenchmark.swift:5-16`

```swift
func testInitialDataLoad() throws {
    let options = XCTMeasureOptions()
    options.iterationCount = 30

    measure(metrics: [XCTClockMetric()], options: options) {
        app.launch()                                             // full cold launch
        let appeared = waitForElement(identifier: TestConstants.Identifiers.articleList,
                                      timeout: TestConstants.contentLoadTimeout)
        XCTAssertTrue(appeared)
        app.terminate()                                          // process teardown
    }
}
```

`XCTClockMetric` measures monotonic wall-clock time across the **whole closure**.
So the recorded quantity is:

> process launch → element-lookup fallback chain → assertion → process
> termination

There is no network, database or render sub-measurement anywhere in that
interval. Nothing isolates the fetch.

## Where the 23.3 s comes from

`BasePerformanceTest.waitForElement` (`BasePerformanceTest.swift:47-59`) tries
three element types in sequence, each with its own timeout:

```swift
func waitForElement(identifier: String, timeout: TimeInterval) -> Bool {
    let scrollView = app.scrollViews[identifier]
    if scrollView.waitForExistence(timeout: timeout) { return true }      // timeout = 20 s

    let other = app.otherElements[identifier]
    if other.waitForExistence(timeout: 2) { return true }                 // 2 s

    let descendant = app.descendants(matching: .any)[identifier]
    return descendant.waitForExistence(timeout: 2)                        // 2 s
}
```

`TestConstants.contentLoadTimeout = 20.0`, so the chain can burn 20 + 2 + 2 = 24 s.

Reconciling that against the data:

| Term | Value |
|---|---|
| `scrollViews["article_list"]` — times out | 20.0 s |
| `otherElements["article_list"]` — times out | 2.0 s |
| `descendants(matching: .any)["article_list"]` — **succeeds** | ~0.1–1.0 s |
| `app.launch()` (from the cold-start signpost median) | 0.26 s |
| `app.terminate()` | remainder |
| **Total** | **≈ 23.3 s (measured median 23.328 s)** |

Two facts pin this decomposition:

1. **The test passed.** `XCTAssertTrue(appeared)` with
   `continueAfterFailure = false`, and the bundle records
   `testStatus: Success`. So `waitForElement` returned `true` — the element
   *was* eventually found, which is only possible via the third tier once the
   first two have each timed out.
2. **The distribution is a constant, not a workload.** n = 30, range
   23.202–23.588 s, std dev 0.066 s, **CV = 0.26 %**. Real network-plus-database
   work does not vary by ±0.2 % across 30 cold launches; a pair of fixed
   timeouts does. (For contrast, the Android network fetch has CV = 14.7 %.)

The root cause is the one already noted in `FINAL_REPORT.md`: Compose
Multiplatform renders through Skia, so the `testTag("article_list")` surfaces as
neither an `XCUIElement.scrollViews` nor an `otherElements` match by identifier.
It is only reachable through the exhaustive `descendants(matching: .any)` query.

## Can an isolated load latency be derived?

### For KMP iOS — no, not from these artefacts

- The app emits **no signposts on iOS**. `AppTrace` is `expect`/`actual`, and
  `shared/src/iosMain/.../AppTrace.ios.kt` is an explicit no-op:
  ```kotlin
  actual object AppTrace {
      actual fun beginSection(label: String) { /* no-op on iOS — use Instruments instead */ }
      actual fun endSection() { /* no-op */ }
  }
  ```
  So the `NewsRepo.networkFetch` / `LocalDS.insertArticles` trace sections that
  Android reports **do not exist at all** in the iOS build. There is nothing to
  subtract and no sub-interval to read.
- The test declares only `XCTClockMetric()` — no signpost metric, no
  `startMeasuring`/`stopMeasuring` bracketing, no sub-measurements.
- The `activitySummaries` in the bundle carry XCTest activity timestamps
  (launch, "Wait for … to idle", element queries), but those are harness
  activities, not app-internal phase boundaries. They can bound the launch and
  the lookup, not the fetch/persist/render split.

**Indicative arithmetic, not a measurement.** Subtracting the two known
timeouts gives 23.328 − 22.0 ≈ **1.3 s** for launch + successful lookup +
terminate, and subtracting the cold-start signpost median (0.260 s) leaves
**≈ 1.07 s** for "content available + teardown". That figure is an **upper
bound contaminated by XCTest query cost** — `descendants(matching: .any)` walks
the entire accessibility hierarchy and is itself expensive (the same query type
drove the 4.95-hour `scroll_performance` run). It must not be reported as an
iOS data-load latency. It is recorded here only to show that the app's real
work is on the order of a second, not 23.

### For native iOS — no, because there is no data

The native twin
(`native-ios-app/IosNativeBuildPerformanceTests/NetworkDatabaseBenchmark.swift:5-16`)
uses the **same metric definition** — `XCTClockMetric` over
launch → wait → terminate:

```swift
measure(metrics: [XCTClockMetric()], options: options) {
    app.launch()
    let scrollView = app.scrollViews[TestConstants.Identifiers.newsListScrollView]
    let appeared = scrollView.waitForExistence(timeout: TestConstants.contentLoadTimeout)
    XCTAssertTrue(appeared)
    app.terminate()
}
```

The task brief asked for the native figure under this same definition so that at
least an iOS-vs-iOS comparison would be valid. **That figure cannot be
extracted: all nine native xcresult bundles executed zero tests** (see
`EXTRACTION_LOG.md`, Task 1). There is no native sample of any metric.

### And the definitions are not equivalent even though the code looks parallel

This is the more important point for the thesis, and it would still hold if the
native data existed.

| | KMP iOS | Native iOS |
|---|---|---|
| Metric | `XCTClockMetric` | `XCTClockMetric` |
| Interval | launch → wait → terminate | launch → wait → terminate |
| Element lookup | **3-tier fallback**: `scrollViews` (20 s) → `otherElements` (2 s) → `descendants(.any)` (2 s) | **single direct lookup**: `app.scrollViews[…]` (20 s) |
| Timeout burned when the element resolves on the first try | 0 s | 0 s |
| Timeout burned in practice | **~22 s** (first two tiers always fail under Compose/Skia) | ~0 s expected (SwiftUI `ScrollView` exposes the identifier natively) |

So the two harnesses measure the same *definition* with radically different
*constant overhead*. A raw 23.3 s vs (expected) ~1–2 s comparison would be
almost entirely a measurement of XCTest's ability to find a Compose element —
an accessibility-integration finding, which is real and worth reporting, but
**not** a data-loading or framework-performance finding.

## What the thesis should say

Recommended wording:

> The iOS "initial data load" scenario measures total XCTest scenario wall-clock
> time — cold process launch, UI-element discovery, and process termination —
> using `XCTClockMetric`. It is not an isolated data-load latency and is not
> comparable to the Android `NewsRepo.networkFetchSumMs` figure (median
> 215.33 ms), which is an in-process trace section around the network call
> only. For the KMP iOS build, approximately 22 s of the 23.33 s median is
> XCTest accessibility-lookup timeout incurred because Compose Multiplatform's
> Skia-rendered list is not addressable as a native `scrollViews` or
> `otherElements` element; the residual application work is on the order of one
> second. The corresponding native iOS figure could not be obtained because the
> native benchmark runs executed no tests.

Do **not** report "KMP iOS loads data in 23.3 s vs 215 ms on Android". That
comparison is invalid in both directions: different intervals, and the iOS
number is dominated by harness timeout.

## How to obtain the number properly (for a re-run)

1. **Give the Compose list a real accessibility identifier.** Use
   `Modifier.semantics { testTagsAsResourceId = true }` on the Compose root (or
   set it at the Activity/UIViewController host) so `testTag("article_list")`
   becomes a first-class `accessibilityIdentifier`. Then the single-tier lookup
   resolves in milliseconds and the 22 s vanishes.
2. **Instrument the app, don't time the harness.** Implement
   `AppTrace.ios.kt` with `os_signpost` intervals mirroring the Android trace
   section names (`NewsRepo.networkFetch`, `NewsRepo.getArticles`,
   `LocalDS.insertArticles`), then measure with
   `XCTOSSignpostMetric(subsystem:category:name:)`. That yields an interval
   directly comparable to Android's `AppTrace`-derived numbers.
   - The **native iOS app is already instrumented this way** —
     `IosNativeBuild/Performance/PerformanceMonitor.swift` emits `os_signpost`
     intervals named `getArticles` (category `Network`), `searchArticles`
     (category `Database`) and `loadArticles` (category `UI`) under subsystem
     `com.amit.IosNativeBuild`. The native tests simply never asked for them:
     they declare `XCTClockMetric` instead of a signpost metric. Switching the
     native test to `XCTOSSignpostMetric` would give an isolated native fetch
     latency with no code changes to the app.
   - The KMP app has no equivalent, because `AppTrace.ios.kt` is a no-op. This
     asymmetry — native instrumented, KMP not — is itself a finding worth a
     sentence in the thesis.
3. **Keep the lookup out of the measured closure** where the goal is app
   latency: launch and wait outside `measure { }`, or use
   `startMeasuring()`/`stopMeasuring()` to bracket only the interval of
   interest.

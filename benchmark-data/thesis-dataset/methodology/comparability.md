# Which comparisons hold

Every claim here was measured on the device, not inferred. Diagnostics that
produced the evidence are in the two test suites
(`AccessibilityDump`, `SearchFieldDiagnostic`, `ScrollGeometryDiagnostic`).

## KMP iOS vs native iOS

Same physical iPhone 16, same iOS 26.6, same harness structure, same backend.
This is the strongest axis in the dataset.

| Scenario | Verdict | Why |
|---|---|---|
| coldStartup | **COMPARABLE** | Both use `XCTOSSignpostMetric.applicationLaunch` over a real process launch — an OS-emitted signpost, not a harness measurement |
| initialDataLoad | **COMPARABLE** | Identical structure; both dominated by the same backend fetch. Medians differ 0.74 % |
| warmStartup / hotStartup | Comparable, harness-inflated | Identical structure, but the absolute value includes XCUITest `activate()` + query overhead. Not comparable to Android |
| categoryFilter | Comparable, caution | Complete separation at CV < 1 % on both sides: two constants, mostly query overhead |
| searchPerformance | Comparable, caution | KMP field is a `TextView`, native a `TextField`; typing cost may differ |
| scrollPerformance | **NOT COMPARABLE** | See below |
| fastScrollStress | **NOT COMPARABLE** | Same cause, ×6 swipes |
| imageLoading | **NOT COMPARABLE** | Contains two swipes; same cause |

## The scroll rows are not a performance finding

KMP measures 0.530 s per swipe against native's 2.591 s — an apparent 4.9×
advantage. It is an artefact.

**Hypothesis tested and rejected: swipe geometry.** XCUITest derives swipe
distance from the target element's bounds, and the two harnesses swipe different
element types (KMP `otherElements[article_list]`, native
`scrollViews[news_list_scroll_view]`). Measured:

| | |
|---|---|
| native `scrollViews` frame | 393 × 688.7 |
| KMP `article_list` frame | 393 × 631 |
| swipe on the native scrollView | 2.740 s / 2.746 s / 2.746 s |
| swipe on a *different* element entirely | 2.698 s / 2.712 s / 2.712 s |

9 % taller, not 5×, and the cost is identical regardless of which element is
targeted. Element choice is irrelevant.

**Actual cause.** XCUITest waits for the application to become idle after a
gesture. SwiftUI's `ScrollView` has real momentum, so XCUITest waits out the
deceleration (~2.7 s). Compose Multiplatform renders scrolling through Skia,
which does not present as an ongoing UIKit animation, so XCUITest declares the
app idle almost immediately (~0.5 s).

This is the same root cause that made `XCTOSSignpostMetric.scrollDecelerationMetric`
record zero measurements under Compose in the original runs. Fixing the metric
moved the artefact from "no data" to "wrong data" — it now appears as a plausible
clock number instead of an obvious zero, which makes it more dangerous, not less.

These rows measure **XCUITest idle-detection semantics, not render throughput.**
The corresponding significance tests are deliberately not run.

## Hitch metrics

`XCTHitchMetric` reports across all three scroll scenarios:

- KMP iOS: exactly 0 hitches, 0 ms/s ratio, across all 110 samples
- native iOS: 1 hitch in 50 swipes, ratio up to 6.32 ms/s

Native's non-zero value proves the metric fires, so KMP's zeros are a genuine
null result rather than a broken metric. It does **not** support "KMP scrolls more
smoothly": given the idle-detection difference above, the two rendering stacks are
not necessarily equally visible to the instrumentation. Report as "no measurable
jank on either stack".

## iOS vs Android

Comparable in one place only, and even there with caveats.

**Cold startup** is meaningful but crosses instrumentation: Android is
Macrobenchmark `timeToInitialDisplayMs`, iOS is the `applicationLaunch` signpost.
Both bound "process launch → first content frame", but they are different probes,
on different devices (Pixel 8 vs iPhone 16) and different OSes. Notably native iOS
and Android-with-baseline-profile are statistically indistinguishable
(p = 0.853), while KMP iOS is faster than both.

**Everything else is NOT COMPARABLE**, because the quantity differs:

- Android `scrollNewsListJankMetrics`, `fastScrollStressTest`,
  `imageLoadingPerformance` are **frame counts**; iOS reports seconds
- Android `networkToDatabase`, `categoryFilterPerformance`,
  `searchArticlesPerformance` are **in-process trace sections in ms**
  (`NewsRepo.networkFetchSumMs` etc.); iOS reports UI wall clock in seconds
  including harness overhead
- Android warm/hot startup (51.6 ms / 32.2 ms) vs iOS (~1.15 s) differ by ~22×
  almost entirely because the iOS figure includes XCUITest activation and query
  cost. Do not present these side by side
- Android has memory metrics; iOS has none

The asymmetry is closable: implementing `AppTrace.ios.kt` with `os_signpost`
intervals mirroring the Android section names would let iOS measure the same
quantity. Kotlin/Native cannot emit `os_signpost` directly — the darwin klib
exposes `os_log_create` but no signpost emit symbols — so it needs a Swift-side
emitter injected into Kotlin, which changes the app under test and requires a
further paired re-run of both targets.

## Android's own caveat

The Android source requests `CompilationMode.Full()` and
`CompilationMode.Partial(BaselineProfileMode.Require)`, but every raw JSON records
`context.compilationMode = "run-from-apk"`. Either that field reports a harness
default, or the requested modes were not applied. This matters because the
272 ms vs 345 ms gap is interpreted as a compilation-mode effect. Unresolved.

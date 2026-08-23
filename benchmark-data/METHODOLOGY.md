# Methodology

Part 1 covers what was wrong with the benchmark harness and how it was
fixed. Part 2 covers which comparisons the resulting data supports.
Every claim was measured on the device, not inferred.

## Part 1 — Harness defects and how they were fixed

Of the 18 original iOS xcresult bundles, 4 carried per-iteration samples and all
9 native bundles executed zero tests. These were code-level defects, not device
or framework limits: re-running without fixing them reproduced the empty bundles
exactly. Diagnosis in `archive/extraction-2026-08-20/EXTRACTION_LOG.md`; fixes in commit
"Fix iOS benchmark harness so it can produce data at all".

This chapter is itself a thesis result: **a green exit code is not evidence that a
benchmark ran.**

### The false-positive that invalidated a platform

`xcodebuild` exits **0** when a test selection matches nothing, because a suite
with zero tests passes vacuously. Nine native runs were therefore reported as
"9/9 passed" having measured nothing, and that claim reached
`FINAL_REPORT.md` as "Native iOS: 9/9 tests successful (100%)".

The same class of error appeared twice more during this work:

- Reading `$?` after `xcodebuild ... | tail -30` yields **`tail`'s** status, not
  xcodebuild's. A run that failed on an untrusted certificate reported success.
- A background-task wrapper reported "exit code 0" for a sweep that had actually
  returned 1 with 2 of 9 scenarios failing.

`scripts/run-ios-benchmark.sh` now asserts a non-zero executed-test count **and**
a non-empty `measurements` array, and never reads xcodebuild's status through a
pipe. Both gates were validated against known-good and known-empty bundles before
being trusted.

### Why the native runs selected nothing

Not determinable from the artefacts, and not guessed at. Verified about the
original project (`KMP project/KMP project/nativeiosapp/IosNativeBuild`):

- the `-only-testing:` identifiers in its `RUN_BENCHMARKS.md` are **correct**
- its scheme has a valid `TestAction` with the test target unskipped
- its `project.pbxproj` wires the test folder via `fileSystemSynchronizedGroups`
- the bundle log shows the device resolving (correct UDID, iOS 26.5) and the
  runner launching successfully

The `.xctest` simply contained no selectable tests at that moment. All twelve test
methods and six classes compile into the bundle now, so the identifiers were never
wrong.

### Defects fixed

| Defect | Effect | Fix |
|---|---|---|
| `iosApp` scheme had **no `TestAction`** | `xcodebuild test` failed with "not currently configured for the test action"; zero tests selected | Shared schemes committed for both projects. The only scheme lived in gitignored `xcuserdata/`, which is why the working configuration was never in version control |
| KMP test target **did not compile** — `XCUIKeyboardKey.selectAll` does not exist | Likely cause of the `search_performance` "Testing cancelled" bundle | Backspace-based clear |
| `applicationLaunch` on warm/hot startup | No process launch occurs, so the signpost never fires → 0 measurements | `XCTClockMetric` over `activate()` → content visible |
| `scrollDecelerationMetric` under Compose | Needs a `UIScrollView` signpost Skia never emits → 0 measurements | `XCTHitchMetric(application:)`, which measures frame hitches in-process. `XCTOSSignpostMetric.animationOverhead`, suggested in the brief, **does not exist** |
| `waitForElement` queried `scrollViews` first with a 20 s timeout | 22 s burned per iteration; `initialDataLoad` reported 23.33 s at CV 0.26 % — a timeout constant, not a workload | Single direct lookup. Measured: `scrollViews[article_list]` never matches, `otherElements` does |
| `findScrollableElement` fell through to `descendants(matching: .any)` | `scroll_performance` took **4 h 57 m** for 50 swipes | Same single lookup → **2 min 14 s** |
| Hardcoded `sleep()` inside measured closures | ≥2 s of categoryFilter's 3.18 s, ≥3 s of imageLoading's 4.36 s was deliberate sleep | `startMeasuring()`/`stopMeasuring()` bracket only the work. Requires `[.manuallyStart, .manuallyStop]`; `.manuallyStart` alone throws |
| KMP tapped **hardcoded screen coordinates** where native used identifiers | Fragile, and asymmetric with the native suite | Both use identifiers |
| Search field accumulated residue across iterations | Each iteration searched a **longer query** than the last | Verified clear; see below |

### Compose testTag mapping on iOS

`testTagsAsResourceId` is **Android-only** and was already set in
`MainActivity.kt`. Compose MP 1.10.0 has no `accessibilitySyncOptions` either
(removed). No app-side change was needed — the harness was querying the wrong
element type. Measured on device:

| Composable | XCUITest element type |
|---|---|
| `LazyColumn` + `testTag` | `otherElements` — **never** `scrollViews` |
| `FilterChip`, `Card` | `buttons`, identifier intact |
| `OutlinedTextField` | **`textViews`**, not `textFields` |

An empty field reads `value == nil`; the placeholder is exposed as `label`.
The toolbar search icon has only `contentDescription = "Search"` and no testTag,
and `search_field` does not exist until it is tapped (it is inside
`if (showSearchBar)`).

### The search-field drift

Found by watching the device, not by any assertion — both gates passed it.

Typing "Technology" then sending 10 deletes in one burst left `"Tec"`: only 7
deletes landed. Every keystroke fires `onValueChange`, which runs a search and
recomposes, so deletes sent rapidly are swallowed. Residue accumulated across
iterations — `"TecTechnology"`, `"TecTTechnology"` — meaning the benchmark measured
a **monotonically growing workload** while reporting a clean 50 samples.

The behaviour is an intermittent race: on a later run the same burst cleared
fully. Fix does not depend on timing:

- `clearText()` deletes one character at a time, re-reading `value` until empty,
  bounded, with `XCTFail` rather than continuing dirty
- the benchmark asserts `searchField.value == query` after `stopMeasuring()`, so
  drift fails loudly instead of quietly changing what is measured

**This is the most important methodological lesson in the dataset.** Both
automated gates — non-zero test count, non-empty measurements — passed a run that
was producing meaningless numbers. Automated checks bound the failure modes you
thought of.

### Environment constraints worth recording

- `DEVELOPMENT_TEAM J832H2D367` is a **free provisioning profile**, capped at 3 app
  IDs per device. Each target needs 2 (app + xctrunner), so the two iOS targets
  cannot be installed simultaneously; the runner evicts the other target first.
  Eviction revokes that profile's trust, so switching targets requires
  re-trusting the developer certificate on the device by hand.
- KMP iOS device builds need `-allowProvisioningUpdates`.
- Kotlin/Native release framework linking OOMs at the repo default; the knob is
  `kotlin.native.jvmArgs`, not `kotlin.daemon.jvmargs`. Debug builds are
  unaffected, and the benchmarks build Debug.
## Part 2 — Which comparisons hold

Every claim here was measured on the device, not inferred. Diagnostics that produced the evidence are in the two test suites
(`AccessibilityDump`, `SearchFieldDiagnostic`, `ScrollGeometryDiagnostic`).

### KMP iOS vs native iOS

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

### The scroll rows are not a performance finding

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

### Hitch metrics

`XCTHitchMetric` reports across all three scroll scenarios:

- KMP iOS: exactly 0 hitches, 0 ms/s ratio, across all 110 samples
- native iOS: 1 hitch in 50 swipes, ratio up to 6.32 ms/s

Native's non-zero value proves the metric fires, so KMP's zeros are a genuine
null result rather than a broken metric. It does **not** support "KMP scrolls more
smoothly": given the idle-detection difference above, the two rendering stacks are
not necessarily equally visible to the instrumentation. Report as "no measurable
jank on either stack".

### iOS vs Android

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

### Android's own caveat

The Android source requests `CompilationMode.Full()` and
`CompilationMode.Partial(BaselineProfileMode.Require)`, but every raw JSON records
`context.compilationMode = "run-from-apk"`. Either that field reports a harness
default, or the requested modes were not applied. This matters because the
272 ms vs 345 ms gap is interpreted as a compilation-mode effect. Unresolved.

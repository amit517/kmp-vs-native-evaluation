# Thesis writing handoff

For a fresh session (Claude Desktop or otherwise) that will draft or fill in the
thesis *Evaluating Cross-Platform Development: A Comparative Study of Kotlin
Multiplatform, Jetpack Compose, and SwiftUI* (VAMK Master's).

Self-contained: every number needed to write the results chapter is quoted here,
with the file it comes from. **Read the "Hard rules" section before writing any
performance claim.**

Repo: `/Users/amitkundu/StudioProjects/kmp-vs-native-evaluation`
Branch: `harness-fix-2026-08`
Data root: `benchmark-data/`

---

## 1. Where things are

| Need | File |
|---|---|
| **Start here** | `benchmark-data/README.md` — the map |
| What is citable and what is not | `benchmark-data/README.md` |
| All results, one schema | `benchmark-data/data/all_platforms_summary.csv` (66 rows) |
| Cross-platform table + verdicts | `benchmark-data/data/cross_platform_comparison.csv` |
| Per-iteration samples | `benchmark-data/data/runs/<platform>/raw/` (58 files) |
| Significance tests | `benchmark-data/data/significance_tests.csv` |
| **Methodology chapter material** | `benchmark-data/METHODOLOGY.md (Part 1)` |
| **Which comparisons are valid** | `benchmark-data/METHODOLOGY.md (Part 2)` |
| Code-sharing analysis | `benchmark-data/RESULTS.md §5 (workings: archive/extraction-2026-08-20/code_sharing.md)` |
| App-size analysis | `benchmark-data/RESULTS.md §6 (workings: archive/extraction-2026-08-20/app_size.md)` |
| Run conditions for the iOS data | `benchmark-data/RESULTS.md §2` |
| Numbers that must NOT be cited | `benchmark-data/archive/extraction-2026-08-20/` |

CSV schema (all summaries):
`platform,test,metric,iterations,mean,median,std_dev,cv_pct,min,max,p95,p99,unit,device,os_version`

**Do not use `benchmark-data/archive/legacy-reports/FINAL_REPORT.md`.** It claims "Native iOS: 9/9 tests
successful (100%)" when all nine of those runs executed zero tests. It is retained
only as a record of what was previously believed.

---

## 2. Measurement conditions

| Platform | Device | OS | Date | Coverage |
|---|---|---|---|---|
| KMP Android | Pixel 8 (`shiba`) | Android 16, API 36 | 2026-04-26 | 10 tests / 30 metric rows |
| KMP iOS | iPhone 16 (`iPhone17,3`) | iOS 26.6 | 2026-08-23 | 9 / 9 scenarios |
| Native iOS | iPhone 16 (same unit) | iOS 26.6 | 2026-08-23 | 9 / 9 scenarios |

All physical devices — no simulator or emulator produced any number in this study.
Both iOS targets ran on the same handset, same OS, same backend
(AWS EC2, eu-central-1, health-checked before every run), one build per target
across all nine of its scenarios. Toolchain: Xcode 26.6 (17F113), Swift 6.3.3.

Iterations: cold 30, warm 50, hot 50, scroll 50, fast-scroll 30,
initial-data-load 30, category-filter 50, search 50, image-loading 30.

---

## 3. The headline result

**Cold startup is the one clean cross-platform comparison in the dataset.**
Both iOS targets use `XCTOSSignpostMetric.applicationLaunch` — an OS-emitted
signpost over a real process launch — on the same device and OS, n = 30 each.

| Platform | Median cold startup | CV |
|---|---|---|
| **KMP iOS** | **239.5 ms** | 7.6 % |
| **Native iOS** | **271.3 ms** | 7.2 % |
| KMP Android, baseline profile (`CompilationMode.Partial`) | 272.18 ms | 3.7 % |
| KMP Android, full AOT (`CompilationMode.Full`) | 344.82 ms | 4.2 % |

Significance (Mann-Whitney U, two-sided, `benchmark-data/data/significance_tests.csv`):

| Comparison | p | r | Verdict |
|---|---|---|---|
| KMP iOS vs native iOS | 5×10⁻⁹ | −0.880 | KMP 11.7 % faster — **material** |
| KMP iOS vs Android (baseline profile) | 8.5×10⁻⁹ | −0.867 | KMP iOS 12.4 % faster — material |
| **Native iOS vs Android (baseline profile)** | **0.853** | −0.029 | **No significant difference** |
| KMP iOS vs Android (full AOT) | 3.0×10⁻¹¹ | −1.000 | 30.5 % faster |
| Native iOS vs Android (full AOT) | 3.0×10⁻¹¹ | −1.000 | 21.3 % faster |

The defensible narrative: **Compose Multiplatform did not cost startup
performance against SwiftUI on this app — it was measurably faster.** That directly
supports the thesis question, and it is the first like-for-like KMP-vs-native-iOS
result the project has had (all nine earlier native runs measured nothing).

Note that full AOT measured *slower* than partial/baseline-profile on Android
(344.82 vs 272.18 ms) — counter-intuitive and worth a sentence.

---

## 4. Hard rules — read before writing any performance claim

### 4.1 Never present the scroll numbers as a performance result

`scrollPerformance` (KMP 0.530 s vs native 2.591 s), `fastScrollStress`
(3.566 vs 16.647 s) and `imageLoading` (1.419 vs 5.120 s) look like a 4–5× KMP
win. **They are an artefact of the test framework, not a property of the
frameworks under test.**

XCUITest waits for the app to go idle after a gesture. SwiftUI's `ScrollView` has
real momentum, so XCUITest waits out the deceleration (~2.7 s). Compose renders
scrolling through Skia, which does not present as an ongoing UIKit animation, so
XCUITest declares idle almost immediately (~0.5 s).

This was tested, not assumed: swiping a *different* element cost 2.71 s versus
2.74 s for the target element, and the two elements differ in height by only 9 %.
Element geometry is not the cause. Evidence in `benchmark-data/METHODOLOGY.md` Part 2.

If the thesis claims KMP scrolls ~5× faster than SwiftUI, that is a factual error
and the most likely thing an examiner will catch.

### 4.2 Statistical significance is not practical significance

Warm startup, hot startup and `initialDataLoad` are all significant at p < 0.001
on median differences of **0.74–1.34 %**. With n = 50 that is detectable and
uninteresting. Report them as "no practical difference" and cite the effect size,
not the p-value. Each row in `benchmark-data/data/significance_tests.csv` carries an
`interpretation` column that says which case it is.

### 4.3 A sub-1 % CV is a warning, not precision

`categoryFilter` separates completely (r = −1.0) with both CVs under 1 %. That is
two tight constants — dominated by XCUITest query overhead — not a workload
difference. Real work varies: Android's network fetch has CV 14.7 %.

This is the same reasoning that unmasked the original `initialDataLoad` figure of
23.33 s at CV 0.26 %, which turned out to be ~22 s of accessibility timeout. After
the fix it measures 3.53 s.

### 4.4 Do not put iOS warm/hot startup beside Android's

iOS warm 1.1518 s / hot 1.1441 s versus Android warm 51.6 ms / hot 32.22 ms is a
~22× gap that is almost entirely **harness overhead**: the iOS figure includes
XCUITest `activate()` and element-query cost, Android's is Macrobenchmark frame
timing. Different probes measuring different things.

### 4.5 Most Android-vs-iOS rows are not comparable at all

Not because the platforms differ, but because the **quantities** differ:

- Android `scrollNewsListJankMetrics` (927.5), `fastScrollStressTest` (2243.5),
  `imageLoadingPerformance` (83) are **frame counts**. iOS reports seconds.
- Android `networkToDatabase` (`NewsRepo.networkFetchSumMs` 215.33 ms),
  `categoryFilterPerformance` (5.22 ms), `searchArticlesPerformance` (4.26 ms)
  are **in-process trace sections**. iOS reports UI wall clock including harness
  overhead.
- Android has memory metrics (`memoryDuringScrolling`: heap 25,041 KB, RSS-anon
  72,752 KB, GPU 67,256 KB). **iOS has none.** The memory comparison is
  Android-only — say so rather than omitting it silently.

Even cold startup crosses instrumentation (Macrobenchmark `timeToInitialDisplayMs`
vs the `applicationLaunch` signpost), on different devices and OSes. It is the
best comparison available and still needs that caveat stated once.

---

## 5. Non-performance results, unaffected by any of the above

From `benchmark-data/RESULTS.md §5 (workings: archive/extraction-2026-08-20/code_sharing.md)` (cloc 2.10):

- **Shared code: 82.42 %** of KMP production code (2147 of 2605 LOC).
  Android-specific 13.59 %, iOS-specific 3.99 %.
- **iOS-specific code vs a full native iOS app: 104 / 1917 = 5.43 %** — a 94.57 %
  reduction in iOS-specific code. This is the most defensible form of the
  code-saving claim.
- Shared-to-native-iOS ratio 2147 / 1917 = **1.120**.
- **Caveat that limits the headline:** there is **no native Android app** in the
  repo, so "KMP saved X % versus writing both apps natively" **cannot** be computed
  and must not appear. Feature parity between codebases was also not audited.

From `benchmark-data/RESULTS.md §6 (workings: archive/extraction-2026-08-20/app_size.md)`:

| Stage | KMP iOS | Native iOS | Ratio |
|---|---|---|---|
| `.app` unstripped, device arm64 | 52.30 MB | 1.49 MB | **35×** |
| `.app` stripped | 39.78 MB | 0.45 MB | 88× |
| Compressed | 13.17 MB (proxy) | 0.159 MB (real IPA) | 83× |

The unstripped `.app` pair (52.30 vs 1.49 MB) is a real like-for-like measurement
and a genuine framework finding: Compose Multiplatform statically links Skia, the
Compose runtime and the Kotlin/Native runtime into a single 52.20 MB Mach-O,
whereas SwiftUI uses frameworks already present in iOS. The stripped and
compressed KMP figures are **locally produced proxies** (no provisioning for a
real archive) and must be labelled as such.

**Do not pair the 55.78 MB Android APK against the 0.159 MB IPA.** That APK is
dominated by ~52.4 MB of unminified dex (R8 is off) plus four ABI slices — build
configuration, not framework cost.

---

## 6. Methodology chapter — this is a result in itself

`benchmark-data/METHODOLOGY.md` Part 1 is the source. The strongest finding:

**A green exit code is not evidence that a benchmark ran.** `xcodebuild` exits 0
when a test selection matches nothing, because a suite with zero tests passes
vacuously. Nine native iOS runs were reported as "9/9 passed" having measured
nothing, and that reached a written report. The same class of error recurred twice
more during the fix: reading `$?` after a pipe yields the *last* command's status,
and a task wrapper reported success for a sweep that returned failure.

Defects found and fixed (all verified on device): missing scheme `TestAction`; a
test target that did not compile; two metrics that cannot fire for the interaction
being measured (`applicationLaunch` without a process launch,
`scrollDecelerationMetric` under Skia); a 20 s element-query timeout that *was* the
`initialDataLoad` measurement; hardcoded `sleep()` inside measured closures; and
hardcoded screen-coordinate taps.

Recovery: **4 of 18 → 18 of 18** iOS scenarios producing per-iteration samples.
`scroll_performance` went from **4 h 57 m with zero measurements** to **2 min 14 s
with 200 samples**.

The sharpest lesson, worth its own paragraph: automated gates asserting a non-zero
test count and a non-empty measurements array both **passed** a search benchmark
that was silently measuring a growing workload — dropped delete-keystrokes left
residue, so each iteration searched a longer query (`Technology`,
`TecTechnology`, `TecTTechnology`). It was caught by a human watching the screen.
Automated checks only bound the failure modes you anticipated.

Two suggestions in the original fix brief were themselves wrong and are worth a
footnote: `testTagsAsResourceId` does not exist on iOS (Android-only, and already
set), and `XCTOSSignpostMetric.animationOverhead` does not exist at all.

---

## 7. Limitations to state explicitly

1. **No iOS in-process instrumentation.** `AppTrace.ios.kt` is a no-op, so the
   Android trace sections (`NewsRepo.networkFetch`, `NewsRepo.getArticles`,
   `LocalDS.insertArticles`) do not exist in either iOS build. Every iOS figure
   measures a UI interaction including harness overhead, never an isolated fetch or
   query. Kotlin/Native cannot emit `os_signpost` (the darwin klib exposes
   `os_log_create` but no signpost emit symbols), so closing this needs a
   Swift-side emitter and a further paired re-run.
2. **No memory metric on iOS.**
3. **No native Android app**, so the two-platform code-saving claim is not
   quantifiable.
4. **Android `compilationMode` discrepancy**: the source requests `Full()` and
   `Partial(BaselineProfileMode.Require)`, but every raw JSON records
   `run-from-apk`. This matters because the 272 vs 345 ms gap is read as a
   compilation-mode effect.
5. **Android CPU/thermal state not pinned** (`cpuLocked = false`,
   `sustainedPerformanceModeEnabled = false`).
6. Android and iOS ran on **different dates and different devices**; only the two
   iOS targets are matched.
7. **Free provisioning profile** capped the device at 3 app IDs, so the two iOS
   targets could not be installed simultaneously and runs had to be serialised.
8. No real KMP iOS signed IPA — stripped/compressed KMP sizes are local proxies.
9. Each scenario is a single session per target; no repeated sessions across days,
   so between-session variance is unmeasured.

---

## 8. Suggested drafting order

1. **Methodology** — the harness-defect narrative is unusually strong material and
   is fully evidenced. Write it before Results; it justifies why only some
   comparisons are made.
2. **Results — startup** — the cold-startup table in §3. The one clean claim.
3. **Results — code sharing and app size** — §5. Solid, unaffected by the harness
   issues, and the 35× size finding is striking.
4. **Results — everything else** — report with verdicts from
   `cross_platform_comparison.csv`. Several rows are honest null or
   not-comparable results; presenting them as such is a strength.
5. **Limitations** — §7 verbatim.
6. **Conclusion** — supportable: on this app, Compose Multiplatform matched or beat
   native SwiftUI on startup, at a large binary-size cost, with 82.42 % code shared
   and 94.57 % less iOS-specific code. Not supportable without more work: any
   claim about scrolling, rendering throughput, or isolated data-layer latency.

When quoting a figure, cite the file it came from. If a number is not in
`benchmark-data/data/`, it should not be in the thesis.

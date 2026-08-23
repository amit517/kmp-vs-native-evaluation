# thesis-dataset — the citable layer

Curated view over every run in this repo. Generated additively by
`scripts/build-thesis-dataset.py`; no source run folder is modified. Rebuildable
at any time.

## Contents

```
results/
  all_platforms_summary.csv       66 rows — KMP Android 30, KMP iOS 18, native iOS 18
  cross_platform_comparison.csv   per scenario, all three platforms, with verdicts
  superseded_2026-04-06.csv       old iOS numbers, quarantined, with a reason per row
  raw/{kmp_android,kmp_ios,native_ios}/   per-iteration samples, 58 files
analysis/
  stats_tests_2026-08.md / .json  significance tests
methodology/
  harness_defects.md              what was broken, and the evidence
  comparability.md                which comparisons hold, and which must not be made
```

All summary CSVs use one schema:
`platform,test,metric,iterations,mean,median,std_dev,cv_pct,min,max,p95,p99,unit,device,os_version`

## Coverage

| Platform | Device / OS | Scenarios with samples | Date |
|---|---|---|---|
| KMP Android | Pixel 8, Android 16 (API 36) | 10 tests / 30 metric rows | 2026-04-26 |
| KMP iOS | iPhone 16, iOS 26.6 | **9 / 9** | 2026-08-23 |
| Native iOS | iPhone 16, iOS 26.6 | **9 / 9** | 2026-08-23 |

18 of 18 iOS scenarios produced per-iteration measurements, against 4 of 18
before the harness was fixed. Native iOS has performance data for the first time.

## Read this before quoting a number

**One comparison is cleanly defensible.** Cold startup, KMP iOS vs native iOS:
same `applicationLaunch` signpost, same physical device, same OS, n = 30 each.
**239.5 ms vs 271.3 ms** — KMP is 11.7 % faster, p = 5×10⁻⁹, r = −0.880. This is
the first like-for-like KMP-vs-native-iOS result the project has.

**Three rows must not be used as performance results.** `scrollPerformance`,
`fastScrollStress` and `imageLoading` show an apparent 4–5× KMP advantage that is
an artefact of XCUITest waiting out SwiftUI's scroll deceleration. Measured, not
assumed — see `methodology/comparability.md`.

**Statistical significance is not practical significance.** Warm startup, hot
startup and `initialDataLoad` are all "significant" at p < 0.001 on median
differences of 0.7–1.3 %. With n = 50 that is detectable and uninteresting. The
`interpretation` column in `analysis/stats_tests_2026-08.md` says so per row.

**A sub-1 % CV is a warning, not precision.** `categoryFilter` separates
completely (r = −1.0) with both CVs under 1 %: two tight constants dominated by
XCUITest query overhead, not a workload difference. Real work varies — Android's
network fetch has CV 14.7 %.

**No iOS figure isolates app work.** `AppTrace.ios.kt` is still a no-op, so the
Android trace sections (`NewsRepo.networkFetch`, `NewsRepo.getArticles`,
`LocalDS.insertArticles`) do not exist in either iOS build. Every iOS number here
measures a UI interaction including harness overhead. This is why warm/hot
startup (~1.15 s) cannot be set beside Android's `timeToInitialDisplayMs`
(51.6 ms / 32.2 ms).

## Cross-platform limits

Most Android-vs-iOS rows are **NOT COMPARABLE** and are labelled as such, because
the quantities differ rather than the performance:

- Android measures in-process trace sections in ms; iOS measures UI wall clock in s
- Android `scroll`, `fastScroll` and `imageLoading` are **frame counts**, not durations
- Android scenario names differ (`networkToDatabase` ↔ `initialDataLoad`,
  `searchArticlesPerformance` ↔ `testSearchPerformance`); the mapping is in
  `cross_platform_comparison.csv`
- Android has memory metrics (`memoryDuringScrolling`); **iOS has none**, so the
  memory comparison is Android-only
- Android ran on Pixel 8 / Android 16 with CPU frequency and thermal state
  **unpinned**; iOS on iPhone 16 / iOS 26.6

## Known gaps

| Gap | Status |
|---|---|
| All native iOS data missing | **Closed** — 9/9 |
| KMP iOS warm/hot/scroll/fast-scroll empty, search cancelled | **Closed** |
| initialDataLoad / categoryFilter / imageLoading unusable | **Closed** — 23.33 s → 3.53 s once the timeout was removed |
| Xcode / Swift versions unrecoverable | **Closed** for the 2026-08 run |
| iOS runs spanning two OS versions | **Closed** — all on iOS 26.6 |
| No memory metric on iOS | Open |
| No native Android app, so two-platform code saving unquantifiable | Open |
| Android `compilationMode` reported as `run-from-apk` regardless of requested mode | Open |
| No in-process instrumentation on iOS (`AppTrace.ios.kt`) | Open — needs a Swift-side signpost emitter and a further paired re-run |

## Rebuilding

```sh
python3 scripts/build-thesis-dataset.py
```

Sources: `benchmark-data/kmp-android/summary.csv`,
`benchmark-data/rerun-2026-08/extracted/*.csv`, and
`benchmark-data/extracted/kmp_ios_summary.csv` for the superseded rows.

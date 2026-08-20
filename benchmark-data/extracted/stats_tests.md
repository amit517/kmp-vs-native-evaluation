# Statistical significance tests

alpha = 0.05. Shapiro-Wilk decides normality per group; if both groups are consistent with normality, Welch's t-test is used, otherwise Mann-Whitney U.

Effect size: Cohen's d for Welch's t-test, rank-biserial r for Mann-Whitney U.

## Tests performed

| Comparison | n (A) | n (B) | median A | median B | Shapiro p (A) | Shapiro p (B) | Test | Statistic | p | Effect size | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Cold startup — KMP iOS vs KMP Android (CompilationMode.Partial, baseline profile) | 30 | 30 | 260.079 ms | 272.177 ms | 4.483e-09 | 0.7685 | Mann-Whitney U | 189.0 | 0.0001175 | rank-biserial r = -0.58 | **significant** |
| Cold startup — KMP iOS vs KMP Android (CompilationMode.Full, full AOT) | 30 | 30 | 260.079 ms | 344.824 ms | 4.483e-09 | 2.485e-05 | Mann-Whitney U | 30.0 | 5.573e-10 | rank-biserial r = -0.933 | **significant** |

### Interpretations

- **Cold startup — KMP iOS vs KMP Android (CompilationMode.Partial, baseline profile)** — Mann-Whitney U, p = 0.0001175: significant at alpha=0.05. `kmp_ios coldStartup (AppLaunch signpost)` median 260.079 ms is lower than `kmp_android coldStartupWithBaselineProfile (timeToInitialDisplayMs)` median 272.177 ms (rank-biserial r = -0.58).
- **Cold startup — KMP iOS vs KMP Android (CompilationMode.Full, full AOT)** — Mann-Whitney U, p = 5.573e-10: significant at alpha=0.05. `kmp_ios coldStartup (AppLaunch signpost)` median 260.079 ms is lower than `kmp_android coldStartupFull (timeToInitialDisplayMs)` median 344.824 ms (rank-biserial r = -0.933).

## Tests requested but NOT run

| Comparison | Reason |
|---|---|
| Cold startup — KMP iOS vs Native iOS | Native iOS has no samples: all 9 xcresult bundles executed 0 tests (`Executed 0 tests, with 0 failures`). |
| Warm startup — KMP iOS vs Native iOS | Native iOS has no samples: all 9 xcresult bundles executed 0 tests (`Executed 0 tests, with 0 failures`). |
| Hot startup — KMP iOS vs Native iOS | Native iOS has no samples: all 9 xcresult bundles executed 0 tests (`Executed 0 tests, with 0 failures`). |
| Scroll (steady-state) — KMP iOS vs Native iOS | Native iOS has no samples: all 9 xcresult bundles executed 0 tests (`Executed 0 tests, with 0 failures`). |
| Fast-scroll stress — KMP iOS vs Native iOS | Native iOS has no samples: all 9 xcresult bundles executed 0 tests (`Executed 0 tests, with 0 failures`). |
| Initial data load — KMP iOS vs Native iOS | Native iOS has no samples: all 9 xcresult bundles executed 0 tests (`Executed 0 tests, with 0 failures`). |
| Category filter — KMP iOS vs Native iOS | Native iOS has no samples: all 9 xcresult bundles executed 0 tests (`Executed 0 tests, with 0 failures`). |
| Search — KMP iOS vs Native iOS | Native iOS has no samples: all 9 xcresult bundles executed 0 tests (`Executed 0 tests, with 0 failures`). |
| Image loading — KMP iOS vs Native iOS | Native iOS has no samples: all 9 xcresult bundles executed 0 tests (`Executed 0 tests, with 0 failures`). |
| Warm startup — KMP iOS vs KMP Android | KMP iOS recorded 0 measurements (applicationLaunch signpost never fires on app.activate()). |
| Hot startup — KMP iOS vs KMP Android | KMP iOS recorded 0 measurements (same root cause as warm startup). |
| Scroll / fast-scroll — KMP iOS vs KMP Android | KMP iOS recorded 0 measurements (scrollDecelerationMetric emits no interval under Compose Multiplatform); Android metric is frame-based with no iOS counterpart. |
| Search — KMP iOS vs KMP Android | KMP iOS run was cancelled before any test executed (0 tests). |
| Initial data load — KMP iOS vs KMP Android | Samples exist on both sides but measure different intervals: Android = in-process network-fetch trace (~215 ms); iOS = whole-scenario wall clock dominated by ~22 s of accessibility-lookup timeout. A p-value here would be meaningless. |
| Category filter — KMP iOS vs KMP Android | Samples exist on both sides but iOS includes 2 s of hardcoded sleep and measures UI wall clock, vs Android's in-process repository call. |
| Image loading — KMP iOS vs KMP Android | Android metric is frameCount (a count); iOS metric is wall-clock seconds including 3 s of hardcoded sleep. Different quantities. |

## Caveat on the one test that could be run

The cold-startup comparison crosses platforms *and* instrumentation: Android's `timeToInitialDisplayMs` comes from Macrobenchmark's frame-timing instrumentation, while iOS's value is the `XCTOSSignpostMetric.applicationLaunch` interval. Both bound "process launch to first content frame", but they are not the same probe, and the two runs used different devices (Pixel 8 vs iPhone 16) and different OSes. A significant p-value here reflects a real difference in the measured quantities, not necessarily a like-for-like framework difference. Report it with that caveat.


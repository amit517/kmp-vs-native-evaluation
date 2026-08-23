# iOS benchmark re-run — 2026-08-23

Re-run of all nine scenarios for both iOS targets after fixing the harness
(commit "Fix iOS benchmark harness so it can produce data at all").

**18 of 18 scenarios produced per-iteration measurements**, against 4 of 18 in
the original data. Native iOS has performance data for the first time — all nine
of its original bundles executed zero tests.

Nothing under `benchmark-data/kmp-ios/`, `native-ios/` or `extracted/` was
modified. Those remain the artefacts of record for what went wrong.

## Environment

Identical for all 18 runs, unlike the original data which straddled two iOS
versions.

| | |
|---|---|
| Device | iPhone 16 (`iPhone17,3`), physical, UDID `00008140-0005309E3687001C` |
| OS | iOS 26.6 — all 18 runs |
| Xcode / Swift | 26.6 (17F113) / 6.3.3 (`swiftlang-6.3.3.1.3`) |
| Host | macOS 26.6.2 (25G83) |
| Backend | `http://63.177.119.99:8080`, eu-central-1, health-checked before every run |
| Iterations | cold 30, warm 50, hot 50, scroll 50, fast-scroll 30, initial-data-load 30, category-filter 50, search 50, image-loading 30 |
| Cooldown | 30 s between scenarios |

One build per target across all nine of its scenarios. The KMP sweep was
restarted rather than continued when a fix landed mid-sweep, so neither target
mixes binaries.

**These numbers are not comparable to the original bundles**, which ran on iOS
26.4.2 / 26.5 with a different harness.

## Results — median

| Scenario | KMP iOS | Native iOS | K/N | Comparability |
|---|---|---|---|---|
| coldStartup | **239.5 ms** | **271.3 ms** | 0.88 | **COMPARABLE** |
| initialDataLoad | 3.525 s | 3.552 s | 0.99 | **COMPARABLE** |
| warmStartup | 1.1518 s | 1.1656 s | 0.99 | comparable, harness-inflated |
| hotStartup | 1.1441 s | 1.1608 s | 0.99 | comparable, harness-inflated |
| categoryFilter | 1.463 s | 1.552 s | 0.94 | comparable, caution |
| searchPerformance | 2.157 s | 2.331 s | 0.93 | comparable, caution |
| scrollPerformance | 0.530 s | 2.591 s | 0.20 | **NOT COMPARABLE** |
| fastScrollStress | 3.566 s | 16.647 s | 0.21 | **NOT COMPARABLE** |
| imageLoading | 1.419 s | 5.120 s | 0.28 | **NOT COMPARABLE** |

Full statistics in `extracted/{kmp_ios,native_ios}_summary.csv` (Android schema),
per-iteration samples in `extracted/raw/`, verdicts in
`extracted/combined_comparison.csv`.

## Do not use the scroll rows as a performance result

The three scroll-based rows look like a 4–5× KMP win. They are not a framework
finding.

Hypothesis tested and rejected: swipe geometry. The native `scrollViews` element
is 393×688.7 against KMP's 393×631 — 9 % taller, nowhere near 5×. Measured
directly (`ScrollGeometryDiagnostic`): a swipe on that element takes 2.74 s, and
a swipe on a completely different element takes 2.71 s. Element choice is
irrelevant.

The cause is that **XCUITest waits for the application to become idle after a
gesture**. SwiftUI's `ScrollView` has real momentum, so XCUITest waits out the
deceleration (~2.7 s). Compose renders scrolling through Skia, which does not
present as an ongoing UIKit animation, so XCUITest declares idle almost
immediately (~0.5 s). This is the same root cause that made
`scrollDecelerationMetric` record nothing under Compose — it now surfaces in the
clock metric instead of as a zero.

So these rows measure **idle-detection semantics, not render throughput**.
`imageLoading` is contaminated identically, as it contains two swipes.

## Other caveats

- **Warm and hot startup are harness-inflated.** Both measure `activate()` →
  element visible, so the absolute value includes XCUITest activation and query
  overhead. They are internally consistent (warm ≈ hot is expected: the only
  difference between them, backgrounding duration, sits outside the measured
  interval) but they are **not** comparable to Android's
  `timeToInitialDisplayMs` of 51.6 ms / 32.2 ms.
- **Sub-1 % CV is a warning, not a quality signal.** `categoryFilter` (0.55 %)
  and `search` (0.57 %) are dominated by a constant — the XCUITest element-query
  round-trip — not by app work. Real work varies: Android's network fetch has
  CV 14.7 %. Treat these as upper bounds on "interaction → list visible", not as
  isolated app latency. This is the same reasoning that unmasked the original
  23.33 s initialDataLoad figure at CV 0.26 %.
- **Hitch metrics are ~zero.** KMP recorded exactly 0 hitches across all 110
  samples. Native recorded 1 hitch in 50 swipes (ratio up to 6.32 ms/s), which
  proves `XCTHitchMetric` does fire and that KMP's zeros are a real null result
  rather than a broken metric. It does **not** support "KMP scrolls more
  smoothly": given the idle-detection difference above, the two stacks are not
  necessarily equally visible to the instrumentation.
- **No in-process instrumentation on iOS.** `AppTrace.ios.kt` is still a no-op,
  so the Android trace sections (`NewsRepo.networkFetch`,
  `NewsRepo.getArticles`, `LocalDS.insertArticles`) do not exist in either iOS
  build. Kotlin/Native cannot emit `os_signpost` — the darwin klib exposes
  `os_log_create` but no signpost emit symbols — so this needs a Swift-side
  emitter, which changes the app under test and would require a further re-run.
  Until then, every iOS figure here measures a UI interaction, not an isolated
  fetch or query.

## The single defensible cross-platform result

**Cold startup.** Both targets use `XCTOSSignpostMetric.applicationLaunch` over a
real process launch, on the same device and OS, n = 30 each. KMP iOS 239.5 ms vs
native iOS 271.3 ms — Compose Multiplatform starts ~12 % faster than SwiftUI
here. This is the first like-for-like KMP-vs-native-iOS comparison the project
has had.

`initialDataLoad` at 0.99 is also meaningful: near-identical, consistent with
both being dominated by the same backend fetch.

## Reproducing

```sh
scripts/run-all-ios-benchmarks.sh kmp    benchmark-data/<out>/kmp-ios    30
scripts/run-all-ios-benchmarks.sh native benchmark-data/<out>/native-ios 30
scripts/extract-rerun-metrics.py benchmark-data/<out>/kmp-ios kmp_ios <out>/extracted
```

The runner treats a zero executed-test count or an empty `measurements` array as
a hard failure. `xcodebuild` exits 0 on an empty test selection, which is how
nine native runs were reported as "9/9 passed" having executed nothing.

Note that `DEVELOPMENT_TEAM J832H2D367` is a free provisioning profile, capped at
three app IDs per device. Each target needs two (app + xctrunner), so the two
targets cannot be installed simultaneously; the runner evicts the other target
first. Evicting revokes that profile's trust, so switching targets requires
re-trusting the developer certificate on the device.

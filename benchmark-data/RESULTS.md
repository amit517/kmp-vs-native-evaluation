# Results

Every measurement backing the thesis *Evaluating Cross-Platform Development: A
Comparative Study of Kotlin Multiplatform, Jetpack Compose, and SwiftUI*.

Self-contained: all figures quoted here, with their source file. Machine-readable
equivalents are in `data/`. Read [`METHODOLOGY.md`](METHODOLOGY.md) before
quoting any performance number — three of these rows are traps.

---

## 1. Executive summary

| Finding | Value | Strength |
|---|---|---|
| **Cold startup, KMP iOS vs native iOS** | **239.5 ms vs 271.3 ms** — KMP 11.7 % faster | **Strong.** Same signpost, device, OS; p = 5×10⁻⁹ |
| Native iOS vs Android (baseline profile) | 271.3 vs 272.18 ms | **No significant difference** (p = 0.853) |
| Shared code | **82.42 %** of the KMP codebase | Strong |
| iOS-specific code vs a full native iOS app | **104 vs 1917 LOC — 94.57 % less** | Strong |
| Binary size, device `.app` | **52.30 MB vs 1.49 MB — 35×** | Strong, and the main cost of KMP here |
| Warm / hot startup, scroll, image loading | See §3 | **Weak or unusable** — harness-dominated |
| Memory | Android only | No iOS equivalent exists |

The supportable conclusion: **on this application, Compose Multiplatform matched
or beat native SwiftUI on startup, at a ~35× binary-size cost, with 82.42 % of
code shared and 94.57 % less iOS-specific code than a standalone SwiftUI app.**

Not supportable from this data: any claim about scrolling throughput, rendering
smoothness, or isolated data-layer latency.

---

## 2. Measurement conditions

| Platform | Device | OS | Date | Coverage |
|---|---|---|---|---|
| KMP Android | Pixel 8 (`shiba`) | Android 16 (API 36) | 2026-04-26 | 10 tests / 30 metric rows |
| KMP iOS | iPhone 16 (`iPhone17,3`) | iOS 26.6 | 2026-08-23 | **9 / 9** |
| Native iOS | iPhone 16 (same unit) | iOS 26.6 | 2026-08-23 | **9 / 9** |

All physical devices — no simulator or emulator produced any number in this study.
Both iOS targets ran on the same handset, same OS, one build per target across all
nine of its scenarios, against the same backend (AWS EC2, eu-central-1,
health-checked before every run).

- **iOS toolchain:** Xcode 26.6 (17F113), Swift 6.3.3 (`swiftlang-6.3.3.1.3`), host macOS 26.6.2
- **Android toolchain:** AGP 8.13.2, Kotlin 2.2.21, Compose Multiplatform 1.10.0, Ktor 3.3.3, Room 2.8.4, Koin 4.1.1, Coil 3.3.0, androidx.benchmark 1.4.1, minSdk 30 / target 36
- **Iterations:** cold 30, warm 50, hot 50, scroll 50, fast-scroll 30, initial-data-load 30, category-filter 50, search 50, image-loading 30; 30 s cooldown between scenarios

Known environment weaknesses: Android ran with `cpuLocked = false` and
`sustainedPerformanceModeEnabled = false`, so CPU frequency and thermal state were
not pinned. Android and iOS ran on different dates and devices; only the two iOS
targets are matched. Each scenario is one session per target, so between-session
variance is unmeasured.

---

## 3. Performance

Full table: `data/all_platforms_summary.csv` (66 rows) ·
per-scenario verdicts: `data/cross_platform_comparison.csv` ·
per-iteration samples: `data/runs/<platform>/raw/`

### 3.1 Startup

| Metric | KMP iOS | Native iOS | KMP Android |
|---|---|---|---|
| Cold startup | **239.5 ms** (CV 7.6 %) | **271.3 ms** (CV 7.2 %) | 272.18 ms baseline-profile / 344.82 ms full AOT |
| Warm startup | 1.1518 s | 1.1656 s | 51.6 ms |
| Hot startup | 1.1441 s | 1.1608 s | 32.22 ms |

**Cold startup is the one clean cross-platform comparison in the dataset.** Both
iOS targets use `XCTOSSignpostMetric.applicationLaunch` — an OS-emitted signpost
over a real process launch, not a harness measurement.

Note that Android full AOT measured *slower* than partial/baseline-profile
(344.82 vs 272.18 ms), which is counter-intuitive and worth a sentence. Caveat:
every Android raw JSON records `context.compilationMode = "run-from-apk"`
regardless of the mode requested in source, so that gap may not be a
compilation-mode effect at all.

**Warm and hot startup must not be set beside the Android figures.** The ~22× gap
is almost entirely harness overhead: the iOS number includes XCUITest
`activate()` and element-query cost, Android's is Macrobenchmark frame timing.
Within iOS the KMP-vs-native difference is 1.0–1.3 % — statistically significant
at n = 50 and practically meaningless.

### 3.2 Data and interaction

| Scenario | KMP iOS | Native iOS | Android equivalent |
|---|---|---|---|
| Initial data load | 3.525 s | 3.552 s | `NewsRepo.networkFetchSumMs` 215.33 ms |
| Category filter | 1.463 s | 1.552 s | `NewsRepo.getArticlesSumMs` 5.22 ms |
| Search | 2.157 s | 2.331 s | `NewsRepo.searchArticlesSumMs` 4.26 ms |

iOS and Android are **not comparable** here: Android measures in-process trace
sections in milliseconds, iOS measures UI wall clock in seconds including harness
overhead. The KMP-vs-native iOS comparison is valid, and shows near-parity on
initial data load (0.74 %).

`initialDataLoad` previously read 23.33 s. That was ~22 s of accessibility-lookup
timeout, not data loading; see [`METHODOLOGY.md`](METHODOLOGY.md).

### 3.3 Scrolling and image loading — do not cite as performance

| Scenario | KMP iOS | Native iOS | Android |
|---|---|---|---|
| Scroll (per swipe) | 0.530 s | 2.591 s | 927.5 frames |
| Fast-scroll stress | 3.566 s | 16.647 s | 2243.5 frames |
| Image loading | 1.419 s | 5.120 s | 83 frames |

The apparent 4–5× KMP advantage is **an artefact of the test framework**, proven
by measurement in [`METHODOLOGY.md`](METHODOLOGY.md) §3. Android's numbers are
frame counts, a different quantity entirely. Nothing in this table supports a
rendering-performance claim on either axis.

### 3.4 Frame hitches

`XCTHitchMetric` across all three scroll scenarios:

- **KMP iOS:** exactly 0 hitches, 0 ms/s ratio, across all 110 samples
- **Native iOS:** 1 hitch in 50 swipes, ratio up to 6.32 ms/s

Native's non-zero value proves the metric fires, so KMP's zeros are a genuine
null result rather than a broken metric. Report as *"no measurable jank on either
stack"*. It does **not** support "KMP scrolls more smoothly" — given the
idle-detection difference, the two rendering stacks are not necessarily equally
visible to the instrumentation.

### 3.5 Memory — Android only

| Metric | Median |
|---|---|
| Heap size | 25,041 KB |
| RSS anon | 72,752 KB |
| RSS file | 197,536 KB |
| GPU | 67,256 KB |

**No iOS equivalent was collected**, so the memory comparison is Android-only.
State this rather than omitting it silently.

---

## 4. Significance tests

Source of truth: `data/significance_tests.csv` and `.json`.
α = 0.05, Mann-Whitney U, two-sided, normal approximation with tie correction,
rank-biserial *r* as effect size.

The implementation is pure Python (numpy/scipy unavailable) and was **validated
against the earlier numpy/scipy analysis**: it reproduces both previously
published results exactly — p = 1.175×10⁻⁴, r = −0.580 and p = 5.573×10⁻¹⁰,
r = −0.933. Shapiro-Wilk is not used; the original methodology used it to choose
between Welch's t and Mann-Whitney and selected Mann-Whitney in both cases, so
using it unconditionally is the conservative, comparable choice.

**Ten tests run where two could before**, because native iOS finally has samples.

| Comparison | n | medians | diff | p | r | Interpretation |
|---|---|---|---|---|---|---|
| coldStartup: KMP iOS vs native iOS | 30/30 | 0.2395 / 0.2713 s | −11.7 % | 5×10⁻⁹ | −0.880 | **Material** |
| coldStartup: KMP iOS vs Android (baseline profile) | 30/30 | 0.2395 / 0.2735 s | −12.4 % | 8.5×10⁻⁹ | −0.867 | Material |
| coldStartup: native iOS vs Android (baseline profile) | 30/30 | 0.2713 / 0.2735 s | −0.8 % | **0.853** | −0.029 | **Not significant** |
| coldStartup: KMP iOS vs Android (full AOT) | 30/30 | 0.2395 / 0.3448 s | −30.5 % | 3.0×10⁻¹¹ | −1.000 | Material (CVs 7.6/4.2 %) |
| coldStartup: native iOS vs Android (full AOT) | 30/30 | 0.2713 / 0.3448 s | −21.3 % | 3.0×10⁻¹¹ | −1.000 | Material (CVs 7.2/4.2 %) |
| initialDataLoad: KMP iOS vs native iOS | 30/30 | 3.526 / 3.552 s | −0.7 % | 1.9×10⁻⁴ | −0.562 | Significant, practically negligible |
| warmStartup: KMP iOS vs native iOS | 50/50 | 1.154 / 1.166 s | −1.0 % | 9.2×10⁻⁶ | −0.515 | Significant, practically negligible |
| hotStartup: KMP iOS vs native iOS | 50/50 | 1.146 / 1.161 s | −1.3 % | 7.8×10⁻⁷ | −0.574 | Significant, practically negligible |
| categoryFilter: KMP iOS vs native iOS | 50/50 | 1.463 / 1.552 s | −5.7 % | <1×10⁻¹⁶ | −1.000 | **Two tight constants** (CVs 0.6/0.8 %), largely harness overhead |
| search: KMP iOS vs native iOS | 50/50 | 2.157 / 2.332 s | −7.5 % | <1×10⁻¹⁶ | −1.000 | Real effect (CVs 0.6/5.0 %) |

**Deliberately not run:** scroll, fast-scroll and image loading (KMP iOS vs native
iOS). They measure XCUITest idle-detection of scroll deceleration, not framework
performance; a p-value would lend an artefact false authority.

Two reading rules:

- **Significance ≠ importance.** Four rows above are significant at p < 0.001 on
  median differences under 2 %. At n = 50 that is detectable and uninteresting.
- **A sub-1 % CV is a warning, not precision.** `categoryFilter` separates
  completely with both CVs under 1 %: two constants dominated by query overhead.
  Real work varies — Android's network fetch has CV 14.7 %.

The iOS-vs-Android rows cross platform *and* instrumentation (Macrobenchmark
`timeToInitialDisplayMs` vs the `applicationLaunch` signpost), on different
devices and OSes. Both bound "process launch → first content frame", but they are
different probes. Android values converted ms → s.

---

## 5. Code sharing

cloc 2.10, code lines only (blank and comment lines excluded). Build outputs,
generated sources, asset catalogues and Xcode per-user state excluded; test code
counted separately.

```sh
cloc --exclude-dir=build,.build,DerivedData,dd,Assets.xcassets,Preview\ Content,generated,xcuserdata \
     --not-match-f='(\.generated\.|_generated)' --quiet <paths>
```

| Group | Paths | Code LOC |
|---|---|---|
| SHARED | `shared/src/commonMain`, `composeApp/src/commonMain` | **2147** |
| KMP Android-specific | `shared/src/androidMain`, `composeApp/src/androidMain` | 354 |
| KMP iOS-specific | `shared/src/iosMain`, `composeApp/src/iosMain`, `iosApp/iosApp` | 104 |
| Native iOS (SwiftUI) | `native-ios-app/IosNativeBuild` | **1917** |

KMP production total = 2147 + 354 + 104 = **2605 LOC**.

| Measure | Computation | Result |
|---|---|---|
| **Shared share of the KMP codebase** | 2147 / 2605 | **82.42 %** |
| Android-specific share | 354 / 2605 | 13.59 % |
| iOS-specific share | 104 / 2605 | 3.99 % |
| Shared vs native iOS | 2147 / 1917 | 1.120 |
| **iOS-specific vs a full native iOS app** | 104 / 1917 | **5.43 %** — a 94.57 % reduction |
| Whole KMP iOS footprint vs native | 2251 / 1917 | 117.4 % (+334 LOC) |

These three ratios answer different questions and must not be conflated:

- **1.120** — the shared module is about the size of an entire native iOS app. A
  size comparison, not a saving.
- **5.43 %** — the defensible form of the code-saving claim: shipping iOS from the
  KMP codebase needed 104 lines of iOS-specific code (61 Kotlin `iosMain` + 24
  Swift host + 19 config) where the standalone SwiftUI app needed 1917.
- **117.4 %** — for an iOS-*only* product, KMP is *more* total code than native.
  The saving materialises only across two platforms.

**The caveat that limits the headline claim:** this repository contains **no native
Android app**, so "KMP saved X % versus writing both apps natively" cannot be
computed and must not appear. The honest two-platform statement is:

> Delivering both platforms from the KMP codebase cost 2605 LOC, of which 82.42 %
> was shared. The iOS half needed 104 lines of iOS-specific code against the 1917
> lines of the standalone SwiftUI implementation.

Secondary caveats: the two codebases were **not audited for feature parity**, so
the LOC ratio assumes equivalent scope. 233 of the 354 Android-specific lines are
XML resources with no iOS counterpart — on a Kotlin-only count the shared share
rises to 92.0 % (2103 shared, 121 Android, 61 iOS).

Test code, excluded from all percentages: Android macrobenchmark 288, KMP iOS
XCTest 279, native iOS XCTest 300, Android baseline profile 45 — **912 LOC total**.
Those two XCTest figures pre-date the harness fixes, which added test code, so
they are now slightly low. Production and shared figures are unaffected.

---

## 6. Application size

Unstripped `.app` row built 2026-08-20 with Xcode 26.6 (17F113); the archive and
IPA rows re-measured 2026-10-04 with Xcode 27.0 (27A266a) on macOS 27.0 from real
signed archives. `du -sk` for `.app` bundles, byte counts for single files.
1 MB = 1,048,576 bytes.

### The like-for-like iOS comparison

Both sides single-architecture arm64 device Release builds of the same app,
processed identically at each stage.

| Stage | KMP iOS (Compose MP) | Native iOS (SwiftUI) | Ratio |
|---|---|---|---|
| Device `.app`, unstripped | **52.30 MB** | **1.49 MB** | **35×** |
| Device `.app`, from archive | **39.76 MB** | **0.45 MB** | **88×** |
| Signed IPA | **13.23 MB** | **0.157 MB** | **84×** |
| Main binary, unstripped | 54,736,760 B | 1,539,840 B | 36× |
| Main binary, from archive | 41,565,952 B | 449,520 B | 92× |

**A genuine framework finding.** Compose Multiplatform statically links the Skia
renderer, the Compose runtime and the Kotlin/Native runtime into a single 52.20 MB
Mach-O with no `Frameworks/` directory, whereas SwiftUI draws on frameworks
already present in iOS and ships almost nothing.

The archive and IPA rows are real artefacts on both sides: both apps were
archived with `xcodebuild archive` and exported as signed IPAs (method
`debugging`, `stripSwiftSymbols`) on 2026-10-04 — same toolchain, same day, both
`.app` bundles code-signed arm64-only Mach-O, verified with `codesign -dv` and
`lipo -info`. The **unstripped** row is the exception: it predates these
(Xcode 26.6, and the KMP side was built unsigned), so it is not strictly
same-toolchain with the rows below it. An archive does not emit an unstripped
`.app`, so re-deriving it would need a separate build; sub-1 % toolchain drift
would not move a 35× ratio.

Exporting again with `thinning = iPhone17,3` changes nothing material — the KMP
IPA shrinks 158 B and the native IPA *grows* 275 B, because thinning metadata in
`Info.plist` roughly cancels the asset-catalog slicing. Neither app uses
on-demand resources.

The earlier stripped/compressed figures for KMP were local proxies (39.78 MB
`strip -rSTx` `.app`, 13.17 MB `zip`); the real archive and IPA came in at
39.76 MB (−0.06 %) and 13.23 MB (+0.42 %), so the proxies were accurate and the
headline ratios are essentially unchanged. Full detail:
[`archive/extraction-2026-10-04/app_size_archive.md`](archive/extraction-2026-10-04/app_size_archive.md).

### Android — do not pair against the IPA

| Artefact | Size | Config |
|---|---|---|
| `composeApp` APK, unsigned release | 55.78 MB (58,486,922 B) | `isMinifyEnabled = false` |

**R8/minification is OFF**, no `shrinkResources`, no ProGuard rules. The APK is
dominated by ~52.4 MB of unminified dex across three files plus four ABI slices of
`libsqliteJni.so` — build configuration, not framework cost. It is not a shippable
size and must not be compared with the 0.159 MB native IPA. The release variant
embeds a baseline profile and there is no profile-free variant, so no
profile/non-profile size delta can be reported.

---

## 7. Limitations

1. **No iOS in-process instrumentation.** `AppTrace.ios.kt` is a no-op, so the
   Android trace sections (`NewsRepo.networkFetch`, `NewsRepo.getArticles`,
   `LocalDS.insertArticles`) do not exist in either iOS build. Every iOS figure
   measures a UI interaction including harness overhead, never an isolated fetch
   or query. Kotlin/Native cannot emit `os_signpost` (the darwin klib exposes
   `os_log_create` but no signpost emit symbols), so closing this needs a
   Swift-side emitter and a further paired re-run of both targets.
2. **No memory metric on iOS.**
3. **No native Android app**, so the two-platform code-saving claim is not
   quantifiable.
4. **Android `compilationMode` discrepancy** — requested modes not reflected in
   the recorded context field.
5. **Android CPU frequency and thermal state not pinned.**
6. Android and iOS ran on different dates and devices; only the iOS pair is matched.
7. **Free provisioning profile** capped the device at 3 app IDs, so the two iOS
   targets could not be installed simultaneously and runs were serialised.
8. The unstripped `.app` size row predates the archive/IPA rows by one Xcode
   major version and is not same-toolchain with them (§6).
9. Feature parity between the KMP and native iOS codebases was not audited.
10. One session per scenario per target; between-session variance unmeasured.

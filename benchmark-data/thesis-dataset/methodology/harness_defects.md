# Harness defects and how they were fixed

Of the 18 original iOS xcresult bundles, 4 carried per-iteration samples and all
9 native bundles executed zero tests. These were code-level defects, not device
or framework limits: re-running without fixing them reproduced the empty bundles
exactly. Diagnosis in `../../extracted/EXTRACTION_LOG.md`; fixes in commit
"Fix iOS benchmark harness so it can produce data at all".

This chapter is itself a thesis result: **a green exit code is not evidence that a
benchmark ran.**

## The false-positive that invalidated a platform

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

## Why the native runs selected nothing

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

## Defects fixed

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

## Compose testTag mapping on iOS

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

## The search-field drift

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

## Environment constraints worth recording

- `DEVELOPMENT_TEAM J832H2D367` is a **free provisioning profile**, capped at 3 app
  IDs per device. Each target needs 2 (app + xctrunner), so the two iOS targets
  cannot be installed simultaneously; the runner evicts the other target first.
  Eviction revokes that profile's trust, so switching targets requires
  re-trusting the developer certificate on the device by hand.
- KMP iOS device builds need `-allowProvisioningUpdates`.
- Kotlin/Native release framework linking OOMs at the repo default; the knob is
  `kotlin.native.jvmArgs`, not `kotlin.daemon.jvmargs`. Debug builds are
  unaffected, and the benchmarks build Debug.

# benchmark-data — start here

Measurement data for the thesis *Evaluating Cross-Platform Development: A
Comparative Study of Kotlin Multiplatform, Jetpack Compose, and SwiftUI*.

**For results, go to [`thesis-dataset/`](thesis-dataset/README.md).** Everything
else in this directory is a raw run folder or a historical analysis, kept for
provenance.

## Layout

| Folder | What it is | Cite from it? |
|---|---|---|
| **[`thesis-dataset/`](thesis-dataset/README.md)** | Curated view over every run: unified summary, cross-platform comparison, significance tests, methodology | **Yes — this is the citable layer** |
| `kmp-android/` | Macrobenchmark run, Pixel 8 / Android 16. Complete; deliberately not re-run | Yes, via `thesis-dataset` |
| `rerun-2026-08/` | iOS runs of record, 2026-08-23, iPhone 16 / iOS 26.6. Both targets, 9/9 scenarios | Yes, via `thesis-dataset` |
| `kmp-ios/` | Original iOS runs, Apr–Jun 2026. 4 of 9 usable | **No — superseded.** See `SUPERSEDED.md` inside |
| `native-ios/` | Original native iOS runs, Jun 2026. **0 of 9 executed any test** | **No — contains no data.** See `SUPERSEDED.md` inside |
| `extracted/` | 2026-08-20 diagnosis of what went wrong, and the code-sharing / app-size analyses | Partly — see below |
| `FINAL_REPORT.md` | Early report | **No.** Contains claims the artefacts do not support |
| `BENCHMARK_RESULTS.md`, `PROGRESS.md` | Working notes | No |

## Why the failed runs are still here

`native-ios/` holds nine xcresult bundles that each record
`Executed 0 tests, with 0 failures`, yet `FINAL_REPORT.md` reports
"Native iOS: 9/9 tests successful (100%)". `xcodebuild` exits 0 on an empty test
selection, so the batch loop that produced them reported success having measured
nothing.

They are retained deliberately. They are the evidence for a genuine
methodological finding — that a green exit code is not evidence a benchmark ran —
and an examiner may reasonably ask to see them. The same applies to `kmp-ios/`'s
23.33 s `initialDataLoad` figure at CV 0.26 %, which is the worked example of a
metric that measured the test harness rather than the app.

Do not delete them, and do not cite them as results.

## Still valid from `extracted/`

The 2026-08-20 analysis pre-dates the re-run, so its iOS *numbers* are
superseded. These parts are unaffected by it and remain current:

- `code_sharing.md` — cloc analysis (82.42 % shared; 104 iOS-specific LOC vs 1917 native)
- `app_size.md` — artefact sizes (KMP iOS `.app` 52.30 MB vs native 1.49 MB)
- `environment.md` — Android device and toolchain capture
- `EXTRACTION_LOG.md` — the diagnosis itself, which is what the re-run acted on

`kmp_ios_summary.csv`, `native_ios_summary.csv`, `combined_comparison.*` and
`stats_tests.*` in that folder describe the **old** data. Superseded equivalents
live in `thesis-dataset/`.

## Immutability

Per the repo's `CLAUDE.md`: existing run folders are never edited. Each records
the endpoint, tool versions and environment it actually executed against.
`thesis-dataset/` is generated *additively* from them by
`scripts/build-thesis-dataset.py` and can be rebuilt at any time.

# benchmark-data

All measurement data for the thesis *Evaluating Cross-Platform Development: A
Comparative Study of Kotlin Multiplatform, Jetpack Compose, and SwiftUI*.

Three documents, one data folder. Nothing is duplicated: every number appears
once, next to the run that produced it.

```
benchmark-data/
├── README.md          ← you are here: the map
├── RESULTS.md         ← every result, with its caveats        ⭐ start here
├── METHODOLOGY.md     ← what was broken; which comparisons hold
├── data/
│   ├── all_platforms_summary.csv       all 3 platforms, one schema, 66 rows
│   ├── cross_platform_comparison.csv   per scenario, with comparability verdicts
│   ├── significance_tests.csv / .json  Mann-Whitney U, 10 tests
│   └── runs/                           the source data and its provenance
│       ├── kmp-android/    summary.csv + 22 per-metric sample files
│       ├── kmp-ios/        summary.csv + raw/ + 9 xcresult bundles + logs
│       └── native-ios/     summary.csv + raw/ + 9 xcresult bundles + logs
└── archive/                            superseded; nothing depends on it
    ├── extraction-2026-08-20/          the diagnosis that drove the re-run
    └── legacy-reports/                 earlier reports, one of them inaccurate
```

## How to navigate

| I want… | Go to |
|---|---|
| The results, written up | **`RESULTS.md`** |
| Whether a comparison is valid | **`METHODOLOGY.md`** Part 2 |
| A number to paste into a table | `data/all_platforms_summary.csv` |
| Per-iteration samples | `data/runs/<platform>/raw/` (Android: `data/runs/kmp-android/*.csv`) |
| Proof a run actually happened | `data/runs/<platform>/` — xcresult bundles, `*.log`, `environment.txt`, `sweep-status.tsv` |
| Why the harness was rebuilt | `METHODOLOGY.md` Part 1 |

Each `data/runs/<platform>/` holds both the **summary** and the **evidence** it
came from, so a figure can be traced to the run that produced it without leaving
the folder. `environment.txt` records the Xcode and Swift versions at run time —
these are not recoverable from an xcresult afterwards.

## Coverage

| Platform | Device / OS | Scenarios with samples | Date |
|---|---|---|---|
| KMP Android | Pixel 8, Android 16 (API 36) | 10 tests / 30 metric rows | 2026-04-26 |
| KMP iOS | iPhone 16, iOS 26.6 | **9 / 9** | 2026-08-23 |
| Native iOS | iPhone 16 (same unit), iOS 26.6 | **9 / 9** | 2026-08-23 |

18 of 18 iOS scenarios produced per-iteration measurements. Before the harness
was fixed it was 4 of 18, and native iOS had none at all.

## Three rules before quoting a number

1. **The scroll rows are not a performance result.** `scrollPerformance`,
   `fastScrollStress` and `imageLoading` show an apparent 4–5× KMP advantage that
   is XCUITest waiting out SwiftUI's scroll deceleration. Measured, not assumed —
   `METHODOLOGY.md` Part 2.
2. **Significance is not importance.** Four comparisons are significant at
   p < 0.001 on median differences under 2 %. The `interpretation` column in
   `data/significance_tests.csv` says which is which.
3. **A sub-1 % CV is a warning, not precision.** It means the number is dominated
   by a constant — usually harness overhead. Real work varies; Android's network
   fetch has CV 14.7 %.

## Regenerating

```sh
python3 scripts/build-aggregates.py
```

Reads `data/runs/*/summary.csv` and `data/runs/*/raw/`, rewrites the three
aggregate files in `data/`. The three markdown documents are hand-written — if
the source runs change, re-check their figures.

## The archive

`archive/` holds material that is superseded but worth keeping. Nothing in
`data/` or the documents depends on it.

- `extraction-2026-08-20/` — the analysis that diagnosed the broken harness. Its
  iOS *numbers* are superseded, but `EXTRACTION_LOG.md` is the record of what was
  wrong, and `code_sharing.md` / `app_size.md` are the full workings behind
  §5 and §6 of `RESULTS.md`.
- `legacy-reports/` — earlier write-ups. **`FINAL_REPORT.md` is not reliable:** it
  claims "Native iOS: 9/9 tests successful (100%)" for nine runs that executed
  zero tests. Kept as a record of what was previously believed.

The original failed iOS runs (9 bundles with zero executed tests, plus 5 unusable
KMP scenarios) were removed on request. They remain in git history —
`git checkout 940121d -- benchmark-data/kmp-ios benchmark-data/native-ios` —
and `METHODOLOGY.md` Part 1 records what they showed.

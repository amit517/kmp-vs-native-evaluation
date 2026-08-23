# Status — current, not re-run

Macrobenchmark run, Pixel 8 (`shiba`), Android 16 (API 36), 2026-04-26.
Complete and current. Deliberately **not** re-run: the iOS harness fixes did not
touch Android, and re-running against a different backend address or region would
break comparability with the recorded network figures.

`summary.csv` is the canonical 15-column summary (30 rows) and is merged verbatim
into `../thesis-dataset/results/all_platforms_summary.csv`. The other CSVs are
per-iteration samples, copied to `../thesis-dataset/results/raw/kmp_android/`.

Two caveats carried into the thesis dataset:

- `cpuLocked = false` and `sustainedPerformanceModeEnabled = false` — CPU
  frequency and thermal state were not pinned, a real source of variance.
- The source requests `CompilationMode.Full()` and
  `CompilationMode.Partial(BaselineProfileMode.Require)`, but every raw JSON
  records `context.compilationMode = "run-from-apk"`. Unresolved, and it matters
  because the 272 ms vs 345 ms gap is read as a compilation-mode effect.

This is the only platform with memory metrics (`memoryDuringScrolling`); iOS has
no equivalent, so that comparison is Android-only.

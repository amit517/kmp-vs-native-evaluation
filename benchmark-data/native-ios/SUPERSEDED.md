# No data — evidence only

**All nine xcresult bundles in `xcresults/` executed zero tests.** Each records,
verbatim:

```
Test Suite 'IosNativeBuildPerformanceTests' passed at 2026-06-06 13:33:17.953.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
```

There is no native iOS measurement in this folder. Do not cite it.

`FINAL_REPORT.md` reports "Native iOS: 9/9 tests successful (100%)". That claim
is not supported by these artefacts. `xcodebuild` exits 0 when a test selection
matches nothing, because a suite with zero tests passes vacuously, so a batch
loop reported success having measured nothing.

**Retained deliberately.** These bundles are the evidence for a methodological
finding — that a green exit code is not evidence a benchmark ran — which is
written up in `../thesis-dataset/methodology/harness_defects.md`.

Superseded by `../rerun-2026-08/native-ios/` (9/9 scenarios, 2026-08-23,
iPhone 16 / iOS 26.6). Current results: `../thesis-dataset/`.

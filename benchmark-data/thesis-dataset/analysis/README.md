# analysis

## Current, generated here

- `stats_tests_2026-08.md` / `.json` — significance tests over the 2026-08-23
  iOS data plus the Android baseline. Mann-Whitney U, two-sided, tie-corrected,
  rank-biserial effect size.

The implementation is pure Python (numpy and scipy are not installed) and was
**validated against the earlier numpy/scipy analysis**: it reproduces both
published results in `../../extracted/stats_tests.md` exactly — p = 1.175×10⁻⁴,
r = −0.580 and p = 5.573×10⁻¹⁰, r = −0.933.

Shapiro-Wilk is not run. The original methodology used it to choose between
Welch's t and Mann-Whitney, and selected Mann-Whitney in both cases;
Mann-Whitney is distribution-free and the conservative choice, so results remain
directly comparable.

**Ten tests now run where two did before.** The nine KMP-iOS-vs-native-iOS
comparisons were previously impossible because native iOS had no samples. Three
are still deliberately not run — the scroll rows, where a p-value would be
misleading.

## Not duplicated here — still valid in `../../extracted/`

These pre-date the re-run but are unaffected by it, so they are referenced rather
than copied, to avoid two versions drifting apart:

| File | Content | Why still valid |
|---|---|---|
| `../../extracted/code_sharing.md` | cloc: 82.42 % shared, 104 iOS-specific LOC vs 1917 native | Production code was not changed by the harness fixes |
| `../../extracted/app_size.md` | KMP iOS `.app` 52.30 MB vs native 1.49 MB (35×) | Same builds |
| `../../extracted/environment.md` | Android device and toolchain capture | Android was not re-run |
| `../../extracted/EXTRACTION_LOG.md` | The diagnosis the re-run acted on | Historical record |
| `../../extracted/initial_data_load_definition.md` | Why 23.33 s was a timeout | Confirmed by the re-run: 3.53 s once fixed |

One caveat on `code_sharing.md`: the harness fixes **added test code** (three
diagnostics plus the modified suites), so its *test* LOC figures are now slightly
low. Its production and shared-code figures — which are what the thesis claims
rest on — are unchanged.

Superseded in that folder: `kmp_ios_summary.csv`, `native_ios_summary.csv`,
`combined_comparison.*`, `stats_tests.*`. Use the versions here.

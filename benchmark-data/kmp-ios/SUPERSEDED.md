# Superseded — 4 of 9 scenarios usable

Original KMP iOS runs, April–June 2026, iPhone 16 on iOS 26.4.2 and 26.5.
Superseded by `../rerun-2026-08/kmp-ios/`. Current results: `../thesis-dataset/`.

| Bundle | State |
|---|---|
| `cold_start` | 30 samples, methodologically sound — but iOS 26.4.2 and an older harness |
| `initial_data_load` | **Do not cite.** 23.33 s at CV 0.26 % is ~22 s of XCTest accessibility timeout, not data loading. Re-measured at 3.53 s |
| `category_filter` | **Do not cite.** ≥2 s of the 3.18 s is hardcoded `sleep()` |
| `image_loading` | **Do not cite.** ≥3 s of the 4.36 s is hardcoded `sleep()` |
| `warm_start`, `hot_start` | 0 measurements — `applicationLaunch` cannot fire without a process launch |
| `scroll_performance` | 0 measurements, and took 4 h 57 m for 50 swipes |
| `fast_scroll_stress` | 0 measurements |
| `search_performance` | 0 tests — cancelled 2.6 s in |

Data also straddles two iOS versions, so even KMP-internal comparisons here cross
an OS boundary.

**Retained deliberately** as the worked evidence that these metrics measured the
harness rather than the app. See
`../thesis-dataset/methodology/harness_defects.md`.

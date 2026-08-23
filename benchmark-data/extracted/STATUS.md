# Status — partly superseded

2026-08-20 diagnosis of the original runs. It pre-dates the 2026-08-23 iOS
re-run, so its iOS *numbers* are superseded, but the analysis it contains is what
the re-run acted on.

**Superseded — use `../thesis-dataset/` instead:**
`kmp_ios_summary.csv`, `native_ios_summary.csv`, `combined_comparison.csv`,
`combined_comparison.md`, `stats_tests.md`, `stats_tests.json`, `raw/`.

**Still current:** `EXTRACTION_LOG.md`, `code_sharing.md`, `app_size.md`,
`environment.md`, `initial_data_load_definition.md`, `extraction_audit.json`.

`RERUN_PROMPT.md` is the brief that drove the re-run; its instructions are now
carried out, and two of its suggestions turned out to be wrong (see
`../thesis-dataset/methodology/harness_defects.md`): `testTagsAsResourceId` does
not exist on iOS, and `XCTOSSignpostMetric.animationOverhead` does not exist at all.

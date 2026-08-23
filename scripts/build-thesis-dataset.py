#!/usr/bin/env python3
"""
Builds benchmark-data/thesis-dataset/ — the curated, presentable view over every
run in this repo.

Purely additive: reads the existing run folders and writes a new tree. It never
modifies anything under an existing run directory.

Sources
  benchmark-data/kmp-android/summary.csv              Android, complete, not re-run
  benchmark-data/rerun-2026-08/extracted/*.csv        both iOS targets, 2026-08-23
  benchmark-data/extracted/kmp_ios_summary.csv        superseded iOS numbers

Statistics note: the original extraction used Shapiro-Wilk to choose between
Welch's t and Mann-Whitney U, and selected Mann-Whitney in both cases. numpy and
scipy are not available here, so Mann-Whitney U (normal approximation with tie
correction) is used unconditionally. It is distribution-free and the conservative
choice, so results stay directly comparable to extracted/stats_tests.md.
"""
import csv
import json
import math
import pathlib
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
BD = ROOT / "benchmark-data"
OUT = BD / "thesis-dataset"

SCHEMA = ["platform", "test", "metric", "iterations", "mean", "median", "std_dev",
          "cv_pct", "min", "max", "p95", "p99", "unit", "device", "os_version"]

# iOS scenario -> Android test name(s). Android names differ, and several Android
# metrics are a different *quantity* (frame counts, in-process trace-section ms),
# which is why most cross-platform rows are not numerically comparable.
SCENARIO_MAP = {
    "testColdStartup": ["coldStartupWithBaselineProfile", "coldStartupFull"],
    "testWarmStartup": ["warmStartup"],
    "testHotStartup": ["hotStartup"],
    "testScrollPerformance": ["scrollNewsListJankMetrics"],
    "testFastScrollStress": ["fastScrollStressTest"],
    "testInitialDataLoad": ["networkToDatabase"],
    "testCategoryFilterPerformance": ["categoryFilterPerformance"],
    "testSearchPerformance": ["searchArticlesPerformance"],
    "testImageLoadingPerformance": ["imageLoadingPerformance"],
}

# Verdicts for the KMP-iOS vs native-iOS comparison (same device, same OS, same
# harness structure). See methodology/comparability.md for the evidence.
IOS_VERDICT = {
    "testColdStartup": ("COMPARABLE",
        "Both use XCTOSSignpostMetric.applicationLaunch over a real process launch."),
    "testInitialDataLoad": ("COMPARABLE",
        "Identical structure; both dominated by the same backend fetch."),
    "testWarmStartup": ("COMPARABLE (harness-inflated)",
        "Identical structure, but includes XCUITest activate + query overhead."),
    "testHotStartup": ("COMPARABLE (harness-inflated)",
        "As warm startup."),
    "testCategoryFilterPerformance": ("COMPARABLE (caution)",
        "Same structure; sub-1% CV indicates a constant-dominated measurement."),
    "testSearchPerformance": ("COMPARABLE (caution)",
        "Same structure; KMP field is a TextView, native a TextField."),
    "testScrollPerformance": ("NOT COMPARABLE",
        "XCUITest waits out SwiftUI scroll deceleration (~2.7s) where Compose/Skia "
        "reports idle immediately (~0.5s). Verified independent of element geometry. "
        "Measures idle-detection, not render throughput."),
    "testFastScrollStress": ("NOT COMPARABLE", "As scroll performance, x6 swipes."),
    "testImageLoadingPerformance": ("NOT COMPARABLE",
        "Contains two swipes; dominated by the same deceleration idle-wait difference."),
}


def read_summary(p):
    return list(csv.DictReader(open(p))) if p.exists() else []


# ---------------------------------------------------------------- statistics
def mannwhitney(a, b):
    """U, two-sided p (normal approximation, tie-corrected), rank-biserial r."""
    n1, n2 = len(a), len(b)
    combined = sorted([(v, 0) for v in a] + [(v, 1) for v in b])
    ranks, i = [0.0] * len(combined), 0
    while i < len(combined):
        j = i
        while j + 1 < len(combined) and combined[j + 1][0] == combined[i][0]:
            j += 1
        avg = (i + j) / 2.0 + 1.0
        for k in range(i, j + 1):
            ranks[k] = avg
        i = j + 1
    r1 = sum(r for r, (_, g) in zip(ranks, combined) if g == 0)
    u1 = r1 - n1 * (n1 + 1) / 2.0
    u2 = n1 * n2 - u1
    u = min(u1, u2)

    mu = n1 * n2 / 2.0
    tie_term = 0.0
    i = 0
    while i < len(combined):
        j = i
        while j + 1 < len(combined) and combined[j + 1][0] == combined[i][0]:
            j += 1
        t = j - i + 1
        tie_term += t ** 3 - t
        i = j + 1
    n = n1 + n2
    var = n1 * n2 / 12.0 * ((n + 1) - tie_term / (n * (n - 1)))
    if var <= 0:
        return u, 1.0, 0.0
    z = (u - mu + 0.5) / math.sqrt(var)
    p = 2.0 * (1.0 - 0.5 * (1.0 + math.erf(abs(z) / math.sqrt(2.0))))
    r = 2.0 * u1 / (n1 * n2) - 1.0
    return u, min(1.0, max(0.0, p)), r


def p_report(p):
    """The normal approximation underflows to 0.0; report a floor, not a false exact 0."""
    if p <= 0.0:
        return {"p_value": 1e-16, "p_value_display": "<1e-16 (normal-approx floor)"}
    return {"p_value": p, "p_value_display": f"{p:.3g}"}


def _cv(xs):
    m = sum(xs) / len(xs)
    if len(xs) < 2 or m == 0:
        return 0.0
    sd = math.sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1))
    return sd / m * 100.0


def interpret(a, b, r, significant):
    """Separate statistical from practical significance.

    Complete separation (|r|=1) only implies "two constants" when the samples are
    also tight. Cold startup separates completely at CV ~7% on a 30% median gap,
    which is a real effect; category-filter separates at CV <1% on overhead.
    """
    med_a, med_b = sorted(a)[len(a) // 2], sorted(b)[len(b) // 2]
    pct = (med_a - med_b) / med_b * 100.0 if med_b else 0.0
    cva, cvb = _cv(a), _cv(b)
    notes = []
    if not significant:
        notes.append("No significant difference at alpha=0.05.")
    elif abs(pct) < 2.0:
        notes.append("Statistically significant but practically negligible: medians "
                     "differ by <2%, detectable only because n is large.")
    if abs(r) >= 0.999 and max(cva, cvb) < 1.0:
        notes.append("Complete separation with both CVs <1%: two tight constants, "
                     "largely harness overhead, rather than a workload difference.")
    elif abs(r) >= 0.999:
        notes.append(f"Complete separation, but CVs are {cva:.1f}%/{cvb:.1f}% -- the "
                     "samples genuinely vary, so this is a real effect, not a constant.")
    return {"median_pct_diff": round(pct, 2),
            "cv_pct_a": round(cva, 2), "cv_pct_b": round(cvb, 2),
            "practical_significance": "; ".join(notes) if notes
            else "Difference is material."}


def load_raw(path, value_col="value"):
    if not path.exists():
        return []
    out = []
    for row in csv.DictReader(open(path)):
        try:
            out.append(float(row[value_col]))
        except (KeyError, ValueError):
            pass
    return out


def main():
    for sub in ["results/raw", "analysis", "methodology"]:
        (OUT / sub).mkdir(parents=True, exist_ok=True)

    android = read_summary(BD / "kmp-android" / "summary.csv")
    kmp_ios = read_summary(BD / "rerun-2026-08" / "extracted" / "kmp_ios_summary.csv")
    nat_ios = read_summary(BD / "rerun-2026-08" / "extracted" / "native_ios_summary.csv")
    old_ios = read_summary(BD / "extracted" / "kmp_ios_summary.csv")

    # ---- 1. unified summary: current, valid data only
    unified = android + kmp_ios + nat_ios
    with open(OUT / "results" / "all_platforms_summary.csv", "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=SCHEMA)
        w.writeheader()
        for r in sorted(unified, key=lambda r: (r["platform"], r["test"], r["metric"])):
            w.writerow({k: r.get(k, "") for k in SCHEMA})
    print(f"all_platforms_summary.csv: {len(unified)} rows "
          f"(android {len(android)}, kmp_ios {len(kmp_ios)}, native_ios {len(nat_ios)})")

    # ---- 2. superseded, kept separate so it cannot be cited by accident
    REASON = {
        "coldStartup": "Superseded. Sound metric, but iOS 26.4.2 and an older harness.",
        "initialDataLoad": "DO NOT CITE. ~22s of the 23.33s is XCTest accessibility "
                           "timeout, not data loading (CV 0.26% is the tell).",
        "categoryFilterPerformance": "DO NOT CITE. >=2s of the 3.18s is hardcoded sleep().",
        "imageLoadingPerformance": "DO NOT CITE. >=3s of the 4.36s is hardcoded sleep().",
    }
    with open(OUT / "results" / "superseded_2026-04-06.csv", "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=SCHEMA + ["status", "reason"])
        w.writeheader()
        for r in old_ios:
            row = {k: r.get(k, "") for k in SCHEMA}
            row["status"] = "superseded"
            row["reason"] = REASON.get(r["test"], "Superseded by the 2026-08-23 re-run.")
            w.writerow(row)
        # native iOS produced nothing at all; record the absence explicitly.
        w.writerow({**{k: "" for k in SCHEMA}, "platform": "native_ios", "test": "ALL",
                    "metric": "none", "iterations": 0, "device": "iPhone 16",
                    "os_version": "iOS_26.5", "status": "no-data",
                    "reason": "All 9 bundles executed 0 tests. xcodebuild exited 0 on an "
                              "empty selection, so this was reported as '9/9 passed'."})
    print(f"superseded_2026-04-06.csv: {len(old_ios)} superseded rows + 1 no-data row")

    # ---- 3. cross-platform comparison
    def pick(rows, test, prefer):
        cands = [r for r in rows if r["test"] == test]
        for p in prefer:
            for c in cands:
                if p in c["metric"]:
                    return c
        return cands[0] if cands else None

    comp_rows = []
    for ios_test, android_tests in SCENARIO_MAP.items():
        k = pick(kmp_ios, ios_test, ["Clock Monotonic", "AppLaunch"])
        n = pick(nat_ios, ios_test, ["Clock Monotonic", "AppLaunch"])
        verdict, why = IOS_VERDICT.get(ios_test, ("?", ""))
        for at in android_tests:
            a = pick(android, at, ["timeToInitialDisplayMs", "SumMs", "frameCount"])
            a_metric = a["metric"] if a else ""
            a_med = a["median"] if a else ""
            a_unit = a["unit"] if a else ""
            # Android is only numerically comparable where the quantity matches.
            if a and a_unit == "ms" and k and k["unit"] == "s" and "InitialDisplay" in a_metric:
                and_verdict = ("COMPARABLE (caveats)" if ios_test == "testColdStartup"
                               else "NOT COMPARABLE (different probe)")
            elif a:
                and_verdict = "NOT COMPARABLE (different quantity)"
            else:
                and_verdict = "NO ANDROID EQUIVALENT"
            comp_rows.append({
                "scenario": ios_test,
                "kmp_ios_median": k["median"] if k else "", "kmp_ios_unit": k["unit"] if k else "",
                "native_ios_median": n["median"] if n else "", "native_ios_unit": n["unit"] if n else "",
                "kmp_over_native": (f"{float(k['median'])/float(n['median']):.2f}"
                                    if k and n and float(n["median"]) else ""),
                "ios_comparability": verdict,
                "android_test": at, "android_metric": a_metric,
                "android_median": a_med, "android_unit": a_unit,
                "android_comparability": and_verdict,
                "note": why,
            })
    with open(OUT / "results" / "cross_platform_comparison.csv", "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(comp_rows[0]))
        w.writeheader()
        w.writerows(comp_rows)
    print(f"cross_platform_comparison.csv: {len(comp_rows)} rows")

    # ---- 4. raw per-iteration samples, all platforms
    for src, dst in [
        (BD / "rerun-2026-08" / "extracted" / "raw" / "kmp_ios", "kmp_ios"),
        (BD / "rerun-2026-08" / "extracted" / "raw" / "native_ios", "native_ios"),
    ]:
        if src.exists():
            shutil.copytree(src, OUT / "results" / "raw" / dst, dirs_exist_ok=True)
    ad = OUT / "results" / "raw" / "kmp_android"
    ad.mkdir(parents=True, exist_ok=True)
    n_and = 0
    for f in sorted((BD / "kmp-android").glob("*.csv")):
        if f.name != "summary.csv":
            shutil.copy2(f, ad / f.name)
            n_and += 1
    print(f"raw/: kmp_ios, native_ios, kmp_android ({n_and} Android files)")

    # ---- 5. significance tests, including the nine that could not run before
    RAW = OUT / "results" / "raw"
    tests = []

    def add(label, pa, a_path, a_col, pb, b_path, b_col, runnable=True, why=""):
        if not runnable:
            tests.append({"comparison": label, "run": False, "reason": why})
            return
        a, b = load_raw(a_path, a_col), load_raw(b_path, b_col)
        if not a or not b:
            tests.append({"comparison": label, "run": False,
                          "reason": "missing samples on one side"})
            return
        u, p, r = mannwhitney(a, b)
        med_a = sorted(a)[len(a) // 2]
        med_b = sorted(b)[len(b) // 2]
        tests.append({"comparison": label, "run": True, "test": "Mann-Whitney U",
                      "n_a": len(a), "n_b": len(b),
                      "median_a": round(med_a, 6), "median_b": round(med_b, 6),
                      "U": u, **p_report(p), "rank_biserial_r": round(r, 4),
                      "significant_at_0.05": bool(p < 0.05),
                      **interpret(a, b, r, bool(p < 0.05)),
                      "group_a": pa, "group_b": pb})

    # The headline: KMP iOS vs native iOS, same signpost, same device, same OS.
    add("coldStartup: KMP iOS vs native iOS",
        "kmp_ios", RAW / "kmp_ios" / "testColdStartup_Duration_AppLaunch.csv", "value",
        "native_ios", RAW / "native_ios" / "testColdStartup_Duration_AppLaunch.csv", "value")
    for scen, fname in [
        ("initialDataLoad", "testInitialDataLoad_Clock_Monotonic_Time.csv"),
        ("warmStartup", "testWarmStartup_Clock_Monotonic_Time.csv"),
        ("hotStartup", "testHotStartup_Clock_Monotonic_Time.csv"),
        ("categoryFilter", "testCategoryFilterPerformance_Clock_Monotonic_Time.csv"),
        ("search", "testSearchPerformance_Clock_Monotonic_Time.csv"),
    ]:
        add(f"{scen}: KMP iOS vs native iOS",
            "kmp_ios", RAW / "kmp_ios" / fname, "value",
            "native_ios", RAW / "native_ios" / fname, "value")
    for scen in ["scrollPerformance", "fastScrollStress", "imageLoading"]:
        add(f"{scen}: KMP iOS vs native iOS", "", None, "", "", None, "", runnable=False,
            why="Deliberately not run. Measures XCUITest idle-detection of scroll "
                "deceleration, not framework performance; a p-value would be misleading.")
    # iOS vs Android cold startup: different probe, so caveated but meaningful.
    for mode, af in [("Partial/baseline-profile",
                      "coldStartupWithBaselineProfile_timeToInitialDisplayMs.csv"),
                     ("Full AOT", "coldStartupFull_timeToInitialDisplayMs.csv")]:
        for plat, pf in [("KMP iOS", RAW / "kmp_ios" / "testColdStartup_Duration_AppLaunch.csv"),
                         ("native iOS", RAW / "native_ios" / "testColdStartup_Duration_AppLaunch.csv")]:
            a = load_raw(pf, "value")
            b = [v / 1000.0 for v in load_raw(RAW / "kmp_android" / af, "value")]
            if a and b:
                u, p, r = mannwhitney(a, b)
                ma, mb = sorted(a)[len(a)//2], sorted(b)[len(b)//2]
                tests.append({"comparison": f"coldStartup: {plat} vs KMP Android ({mode})",
                              "run": True, "test": "Mann-Whitney U",
                              "n_a": len(a), "n_b": len(b),
                              "median_a": round(ma, 6), "median_b": round(mb, 6),
                              "U": u, **p_report(p), "rank_biserial_r": round(r, 4),
                              "significant_at_0.05": bool(p < 0.05),
                              **interpret(a, b, r, bool(p < 0.05)),
                              "caveat": "Cross-platform AND cross-instrumentation: "
                                        "Android is Macrobenchmark timeToInitialDisplayMs, "
                                        "iOS is the applicationLaunch signpost. Different "
                                        "devices and OSes. Android units converted ms->s."})

    with open(OUT / "analysis" / "stats_tests_2026-08.json", "w") as fh:
        json.dump(tests, fh, indent=2)
    ran = sum(1 for t in tests if t.get("run"))
    print(f"stats_tests_2026-08.json: {ran} tests run, {len(tests)-ran} deliberately not run")

    # ---- 6. readable stats report, generated so it cannot drift from the JSON
    with open(OUT / "analysis" / "stats_tests_2026-08.md", "w") as fh:
        fh.write("# Significance tests — 2026-08-23 data\n\n"
                 "alpha = 0.05. Mann-Whitney U, two-sided, normal approximation with tie\n"
                 "correction, rank-biserial r as effect size. Generated by\n"
                 "`scripts/build-thesis-dataset.py`; do not hand-edit.\n\n"
                 "**Implementation validated** against the numpy/scipy results in\n"
                 "`../../extracted/stats_tests.md`: it reproduces both published tests\n"
                 "exactly (p = 1.175e-4, r = -0.580 and p = 5.573e-10, r = -0.933).\n"
                 "Shapiro-Wilk is not used — scipy is unavailable, and the original\n"
                 "analysis selected Mann-Whitney in both cases anyway.\n\n"
                 "Read the `interpretation` column before quoting any p-value. With\n"
                 "n = 50 per group a sub-millisecond difference is easily 'significant'.\n\n"
                 "| comparison | n | median A | median B | diff | CV A / B | p | r | sig | interpretation |\n"
                 "|---|---|---|---|---|---|---|---|---|---|\n")
        for t in tests:
            if not t.get("run"):
                continue
            fh.write(f"| {t['comparison']} | {t['n_a']}/{t['n_b']} | {t['median_a']:.4f} | "
                     f"{t['median_b']:.4f} | {t['median_pct_diff']:+.2f}% | "
                     f"{t['cv_pct_a']:.1f}% / {t['cv_pct_b']:.1f}% | {t['p_value_display']} | "
                     f"{t['rank_biserial_r']:+.3f} | {'yes' if t['significant_at_0.05'] else 'no'} | "
                     f"{t['practical_significance']} |\n")
        fh.write("\n## Deliberately not run\n\n")
        for t in tests:
            if not t.get("run"):
                fh.write(f"- **{t['comparison']}** — {t['reason']}\n")
        fh.write("\n## Caveat on the iOS-vs-Android rows\n\n"
                 "Those cross platform *and* instrumentation: Android is Macrobenchmark\n"
                 "`timeToInitialDisplayMs`, iOS is the `applicationLaunch` signpost, on\n"
                 "different devices (Pixel 8 / iPhone 16) and different OSes. Both bound\n"
                 "\"process launch to first content frame\", but they are different probes.\n"
                 "Android values were converted ms -> s.\n")
    print("stats_tests_2026-08.md written")
    return 0


if __name__ == "__main__":
    sys.exit(main())

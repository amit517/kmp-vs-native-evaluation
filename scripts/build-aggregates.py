#!/usr/bin/env python3
"""
Generates the aggregate tables in benchmark-data/data/ from the per-run data in
benchmark-data/data/runs/.

  benchmark-data/data/
    all_platforms_summary.csv       generated  all three platforms, one schema
    cross_platform_comparison.csv   generated  per scenario, with verdicts
    significance_tests.csv|.json    generated  Mann-Whitney U
    runs/kmp-android/               source     summary.csv + per-metric samples
    runs/kmp-ios/                   source     summary.csv + raw/ + xcresult bundles
    runs/native-ios/                source     summary.csv + raw/ + xcresult bundles

Per-iteration samples are NOT copied up: they live once, with their run.

Statistics: Mann-Whitney U, two-sided, normal approximation with tie correction,
rank-biserial r. numpy and scipy are unavailable here, so this is implemented
directly; it reproduces the earlier numpy/scipy results exactly
(p = 1.175e-4, r = -0.580 and p = 5.573e-10, r = -0.933). Shapiro-Wilk is not
used -- the original methodology used it to choose between Welch's t and
Mann-Whitney and picked Mann-Whitney both times, so applying Mann-Whitney
unconditionally is the conservative and directly comparable choice.

The narrative documents (README.md, RESULTS.md, METHODOLOGY.md) are hand-written
and sit above this data. Re-check their figures if the source runs change.
"""
import csv
import json
import math
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA = ROOT / "benchmark-data" / "data"
RUNS = DATA / "runs"

SCHEMA = ["platform", "test", "metric", "iterations", "mean", "median", "std_dev",
          "cv_pct", "min", "max", "p95", "p99", "unit", "device", "os_version"]

# iOS scenario -> Android test name(s). Android names differ, and several Android
# metrics are a different *quantity* (frame counts, in-process trace sections),
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

# KMP iOS vs native iOS: same device, same OS, same harness structure.
# Evidence for each verdict is in benchmark-data/METHODOLOGY.md.
IOS_VERDICT = {
    "testColdStartup": ("COMPARABLE",
        "Both use XCTOSSignpostMetric.applicationLaunch over a real process launch."),
    "testInitialDataLoad": ("COMPARABLE",
        "Identical structure; both dominated by the same backend fetch."),
    "testWarmStartup": ("COMPARABLE (harness-inflated)",
        "Identical structure, but includes XCUITest activate + query overhead."),
    "testHotStartup": ("COMPARABLE (harness-inflated)", "As warm startup."),
    "testCategoryFilterPerformance": ("COMPARABLE (caution)",
        "Complete separation at CV <1% on both sides: constant-dominated."),
    "testSearchPerformance": ("COMPARABLE (caution)",
        "KMP field is a TextView, native a TextField; typing cost may differ."),
    "testScrollPerformance": ("NOT COMPARABLE",
        "XCUITest waits out SwiftUI scroll deceleration (~2.7s) where Compose/Skia "
        "reports idle immediately (~0.5s). Verified independent of element geometry. "
        "Measures idle-detection, not render throughput."),
    "testFastScrollStress": ("NOT COMPARABLE", "As scroll performance, x6 swipes."),
    "testImageLoadingPerformance": ("NOT COMPARABLE",
        "Contains two swipes; same deceleration idle-wait difference."),
}


def read_summary(p):
    return list(csv.DictReader(open(p))) if p.exists() else []


def load_raw(path, scale=1.0):
    if not path.exists():
        return []
    out = []
    for row in csv.DictReader(open(path)):
        try:
            out.append(float(row["value"]) * scale)
        except (KeyError, ValueError):
            pass
    return out


# ---------------------------------------------------------------- statistics
def mannwhitney(a, b):
    """U, two-sided p (normal approx, tie-corrected), rank-biserial r."""
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
    u = min(u1, n1 * n2 - u1)

    tie_term, i = 0.0, 0
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
    z = (u - n1 * n2 / 2.0 + 0.5) / math.sqrt(var)
    p = 2.0 * (1.0 - 0.5 * (1.0 + math.erf(abs(z) / math.sqrt(2.0))))
    return u, min(1.0, max(0.0, p)), 2.0 * u1 / (n1 * n2) - 1.0


def cv(xs):
    m = sum(xs) / len(xs)
    if len(xs) < 2 or m == 0:
        return 0.0
    return math.sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1)) / m * 100.0


def p_report(p):
    """The normal approximation underflows to 0; report a floor, not a false exact 0."""
    if p <= 0.0:
        return {"p_value": 1e-16, "p_value_display": "<1e-16 (normal-approx floor)"}
    return {"p_value": p, "p_value_display": f"{p:.3g}"}


def interpret(a, b, r, significant):
    """Separate statistical from practical significance.

    Complete separation (|r|=1) only implies "two constants" when the samples are
    also tight: cold startup separates at CV ~7% on a 30% median gap, which is a
    real effect, whereas category-filter separates at CV <1% on pure overhead.
    """
    med_a, med_b = sorted(a)[len(a) // 2], sorted(b)[len(b) // 2]
    pct = (med_a - med_b) / med_b * 100.0 if med_b else 0.0
    cva, cvb = cv(a), cv(b)
    notes = []
    if not significant:
        notes.append("No significant difference at alpha=0.05.")
    elif abs(pct) < 2.0:
        notes.append("Statistically significant but practically negligible: medians "
                     "differ by <2%, detectable only because n is large.")
    if abs(r) >= 0.999 and max(cva, cvb) < 1.0:
        notes.append("Complete separation with both CVs <1%: two tight constants, "
                     "largely harness overhead, not a workload difference.")
    elif abs(r) >= 0.999:
        notes.append(f"Complete separation, and CVs are {cva:.1f}%/{cvb:.1f}% -- the "
                     "samples genuinely vary, so this is a real effect.")
    return {"median_pct_diff": round(pct, 2), "cv_pct_a": round(cva, 2),
            "cv_pct_b": round(cvb, 2),
            "interpretation": "; ".join(notes) if notes else "Difference is material."}


def main():
    android = read_summary(RUNS / "kmp-android" / "summary.csv")
    kmp_ios = read_summary(RUNS / "kmp-ios" / "summary.csv")
    nat_ios = read_summary(RUNS / "native-ios" / "summary.csv")
    if not (android and kmp_ios and nat_ios):
        print("FATAL: missing one or more runs/*/summary.csv", file=sys.stderr)
        return 1

    # ---- unified summary
    rows = android + kmp_ios + nat_ios
    with open(DATA / "all_platforms_summary.csv", "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=SCHEMA)
        w.writeheader()
        for r in sorted(rows, key=lambda r: (r["platform"], r["test"], r["metric"])):
            w.writerow({k: r.get(k, "") for k in SCHEMA})
    print(f"all_platforms_summary.csv: {len(rows)} rows "
          f"(android {len(android)}, kmp_ios {len(kmp_ios)}, native_ios {len(nat_ios)})")

    # ---- cross-platform comparison
    def pick(src, test, prefer):
        cands = [r for r in src if r["test"] == test]
        for p in prefer:
            for c in cands:
                if p in c["metric"]:
                    return c
        return cands[0] if cands else None

    comp = []
    for ios_test, android_tests in SCENARIO_MAP.items():
        k = pick(kmp_ios, ios_test, ["Clock Monotonic", "AppLaunch"])
        n = pick(nat_ios, ios_test, ["Clock Monotonic", "AppLaunch"])
        verdict, why = IOS_VERDICT.get(ios_test, ("?", ""))
        for at in android_tests:
            a = pick(android, at, ["timeToInitialDisplayMs", "SumMs", "frameCount"])
            if a and "InitialDisplay" in a["metric"] and ios_test == "testColdStartup":
                and_verdict = "COMPARABLE (caveats: different probe, device and OS)"
            elif a:
                and_verdict = "NOT COMPARABLE (different quantity)"
            else:
                and_verdict = "NO ANDROID EQUIVALENT"
            comp.append({
                "scenario": ios_test,
                "kmp_ios_median": k["median"] if k else "",
                "native_ios_median": n["median"] if n else "",
                "ios_unit": k["unit"] if k else "",
                "kmp_over_native": (f"{float(k['median'])/float(n['median']):.2f}"
                                    if k and n and float(n["median"]) else ""),
                "ios_comparability": verdict,
                "android_test": at,
                "android_metric": a["metric"] if a else "",
                "android_median": a["median"] if a else "",
                "android_unit": a["unit"] if a else "",
                "android_comparability": and_verdict,
                "note": why,
            })
    with open(DATA / "cross_platform_comparison.csv", "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(comp[0]))
        w.writeheader()
        w.writerows(comp)
    print(f"cross_platform_comparison.csv: {len(comp)} rows")

    # ---- significance tests
    KI, NI, AN = RUNS / "kmp-ios" / "raw", RUNS / "native-ios" / "raw", RUNS / "kmp-android"
    tests = []

    def add(label, pa, fa, pb, fb, scale_b=1.0, caveat=""):
        a, b = load_raw(fa), load_raw(fb, scale_b)
        if not a or not b:
            tests.append({"comparison": label, "run": False,
                          "reason": "missing samples on one side"})
            return
        u, p, r = mannwhitney(a, b)
        row = {"comparison": label, "run": True, "test": "Mann-Whitney U",
               "group_a": pa, "group_b": pb, "n_a": len(a), "n_b": len(b),
               "median_a": round(sorted(a)[len(a) // 2], 6),
               "median_b": round(sorted(b)[len(b) // 2], 6),
               "U": u, **p_report(p), "rank_biserial_r": round(r, 4),
               "significant_at_0.05": bool(p < 0.05),
               **interpret(a, b, r, bool(p < 0.05))}
        if caveat:
            row["caveat"] = caveat
        tests.append(row)

    add("coldStartup: KMP iOS vs native iOS", "kmp_ios",
        KI / "testColdStartup_Duration_AppLaunch.csv", "native_ios",
        NI / "testColdStartup_Duration_AppLaunch.csv")
    for scen, fname in [
        ("initialDataLoad", "testInitialDataLoad_Clock_Monotonic_Time.csv"),
        ("warmStartup", "testWarmStartup_Clock_Monotonic_Time.csv"),
        ("hotStartup", "testHotStartup_Clock_Monotonic_Time.csv"),
        ("categoryFilter", "testCategoryFilterPerformance_Clock_Monotonic_Time.csv"),
        ("search", "testSearchPerformance_Clock_Monotonic_Time.csv"),
    ]:
        add(f"{scen}: KMP iOS vs native iOS", "kmp_ios", KI / fname,
            "native_ios", NI / fname)
    for scen in ["scrollPerformance", "fastScrollStress", "imageLoading"]:
        tests.append({"comparison": f"{scen}: KMP iOS vs native iOS", "run": False,
                      "reason": "Deliberately not run. Measures XCUITest idle-detection "
                                "of scroll deceleration, not framework performance; a "
                                "p-value would lend an artefact false authority."})
    AND_CAVEAT = ("Cross-platform AND cross-instrumentation: Android is Macrobenchmark "
                  "timeToInitialDisplayMs, iOS is the applicationLaunch signpost, on "
                  "different devices and OSes. Android converted ms -> s.")
    for mode, af in [("baseline profile",
                      "coldStartupWithBaselineProfile_timeToInitialDisplayMs.csv"),
                     ("full AOT", "coldStartupFull_timeToInitialDisplayMs.csv")]:
        for plat, pdir in [("KMP iOS", KI), ("native iOS", NI)]:
            add(f"coldStartup: {plat} vs KMP Android ({mode})",
                "kmp_ios" if plat == "KMP iOS" else "native_ios",
                pdir / "testColdStartup_Duration_AppLaunch.csv",
                "kmp_android", AN / af, scale_b=1 / 1000.0, caveat=AND_CAVEAT)

    with open(DATA / "significance_tests.json", "w") as fh:
        json.dump(tests, fh, indent=2)
    cols = ["comparison", "run", "test", "group_a", "group_b", "n_a", "n_b",
            "median_a", "median_b", "median_pct_diff", "cv_pct_a", "cv_pct_b",
            "U", "p_value", "p_value_display", "rank_biserial_r",
            "significant_at_0.05", "interpretation", "reason", "caveat"]
    with open(DATA / "significance_tests.csv", "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        for t in tests:
            w.writerow({**{c: "" for c in cols}, **t})
    ran = sum(1 for t in tests if t.get("run"))
    print(f"significance_tests.csv/.json: {ran} run, {len(tests)-ran} deliberately not run")
    return 0


if __name__ == "__main__":
    sys.exit(main())

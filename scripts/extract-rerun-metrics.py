#!/usr/bin/env python3
"""
Extracts per-iteration measurements from re-run xcresult bundles into the
Android CSV schema, plus raw per-sample files.

Deliberately reports a scenario with zero measurements as a row with
iterations=0 rather than omitting it, so a gap is explicit instead of silent.

Usage:
  extract-rerun-metrics.py <bundle-dir> <platform-label> <out-dir>
"""
import csv
import json
import pathlib
import statistics
import subprocess
import sys

SCHEMA = ["platform", "test", "metric", "iterations", "mean", "median", "std_dev",
          "cv_pct", "min", "max", "p95", "p99", "unit", "device", "os_version"]


def sh(*args):
    r = subprocess.run(args, capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""


def percentile(vals, q):
    """Linear interpolation, matching numpy percentile(method='linear')."""
    s = sorted(vals)
    if len(s) == 1:
        return s[0]
    pos = (len(s) - 1) * q / 100.0
    lo = int(pos)
    hi = min(lo + 1, len(s) - 1)
    return s[lo] + (s[hi] - s[lo]) * (pos - lo)


def device_os(bundle):
    """runDestination metadata, read per bundle rather than assumed."""
    txt = sh("xcrun", "xcresulttool", "get", "test-results", "tests", "--path", str(bundle))
    try:
        d = json.loads(txt)["devices"][0]
        return d.get("modelName", "?"), "iOS_" + d.get("osVersion", "?")
    except Exception:
        return "?", "?"


def main():
    if len(sys.argv) != 4:
        print(__doc__)
        return 2
    bundle_dir, platform, out_dir = pathlib.Path(sys.argv[1]), sys.argv[2], pathlib.Path(sys.argv[3])
    out_dir.mkdir(parents=True, exist_ok=True)
    raw_dir = out_dir / "raw" / platform
    raw_dir.mkdir(parents=True, exist_ok=True)

    rows, gaps = [], []
    for bundle in sorted(bundle_dir.glob("*.xcresult")):
        dev, osv = device_os(bundle)
        txt = sh("xcrun", "xcresulttool", "get", "test-results", "metrics", "--path", str(bundle))
        try:
            data = json.loads(txt) if txt.strip() else []
        except Exception:
            data = []

        if not data:
            gaps.append(f"{bundle.name}: no metrics recorded")
            continue

        for t in data:
            test = t.get("testIdentifier", "?").split("/")[-1].replace("()", "")
            for run in t.get("testRuns", []):
                for m in run.get("metrics", []):
                    vals = m.get("measurements") or []
                    name = m.get("displayName") or m.get("identifier") or "?"
                    unit = m.get("unitOfMeasurement", "")
                    if not vals:
                        gaps.append(f"{bundle.name}: metric '{name}' has 0 measurements")
                        rows.append({**{k: "" for k in SCHEMA}, "platform": platform,
                                     "test": test, "metric": name, "iterations": 0,
                                     "unit": unit, "device": dev, "os_version": osv})
                        continue

                    mean = statistics.mean(vals)
                    sd = statistics.stdev(vals) if len(vals) > 1 else 0.0
                    rows.append({
                        "platform": platform, "test": test, "metric": name,
                        "iterations": len(vals),
                        "mean": round(mean, 4), "median": round(statistics.median(vals), 4),
                        "std_dev": round(sd, 4),
                        "cv_pct": round(sd / mean * 100, 2) if mean else "",
                        "min": round(min(vals), 4), "max": round(max(vals), 4),
                        "p95": round(percentile(vals, 95), 4),
                        "p99": round(percentile(vals, 99), 4),
                        "unit": unit, "device": dev, "os_version": osv,
                    })

                    safe = f"{test}_{name}".replace(" ", "_").replace("/", "_")
                    for ch in "()":
                        safe = safe.replace(ch, "")
                    with open(raw_dir / f"{safe}.csv", "w", newline="") as fh:
                        w = csv.writer(fh)
                        w.writerow(["sample_index", "value", "unit", "device", "os_version"])
                        for i, v in enumerate(vals, 1):
                            w.writerow([i, v, unit, dev, osv])

    summary = out_dir / f"{platform}_summary.csv"
    with open(summary, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=SCHEMA)
        w.writeheader()
        for r in sorted(rows, key=lambda r: (r["test"], r["metric"])):
            w.writerow(r)

    print(f"wrote {summary} ({len(rows)} rows)")
    print(f"raw samples -> {raw_dir}")
    if gaps:
        print("\nGAPS (explicit, not omitted):")
        for g in gaps:
            print("  -", g)
    else:
        print("\nNo gaps: every bundle yielded measurements.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

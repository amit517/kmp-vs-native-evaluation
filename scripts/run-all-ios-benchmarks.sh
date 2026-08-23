#!/usr/bin/env bash
#
# Runs all nine benchmark scenarios for one iOS target.
#
# Does NOT abort the sweep on a single failure — it records per-scenario status
# and exits non-zero at the end if anything failed, so one bad scenario cannot
# masquerade as a clean sweep and cannot silently stop the rest.
#
# Usage: run-all-ios-benchmarks.sh <kmp|native> <output-dir> [cooldown-seconds]

set -u -o pipefail

TARGET="${1:?target required: kmp|native}"
OUT_DIR="${2:?output dir required}"
COOLDOWN="${3:-30}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TESTS=(
  StartupBenchmark/testColdStartup
  StartupBenchmark/testWarmStartup
  StartupBenchmark/testHotStartup
  ScrollBenchmark/testScrollPerformance
  ScrollBenchmark/testFastScrollStress
  NetworkDatabaseBenchmark/testInitialDataLoad
  NetworkDatabaseBenchmark/testCategoryFilterPerformance
  NetworkDatabaseBenchmark/testSearchPerformance
  NetworkDatabaseBenchmark/testImageLoadingPerformance
)

mkdir -p "$OUT_DIR"
STATUS_FILE="$OUT_DIR/sweep-status.tsv"
: > "$STATUS_FILE"

failed=0
for i in "${!TESTS[@]}"; do
  t="${TESTS[$i]}"
  echo ""
  echo "######## [$((i+1))/${#TESTS[@]}] $TARGET :: $t"
  if "$HERE/run-ios-benchmark.sh" "$TARGET" "$t" "$OUT_DIR"; then
    printf '%s\tPASS\n' "$t" >> "$STATUS_FILE"
  else
    printf '%s\tFAIL\n' "$t" >> "$STATUS_FILE"
    failed=$((failed+1))
    echo "    !! recorded FAIL, continuing sweep"
  fi
  # Cooldown between scenarios to limit thermal carry-over.
  if [ "$i" -lt "$(( ${#TESTS[@]} - 1 ))" ]; then
    sleep "$COOLDOWN"
  fi
done

echo ""
echo "======== $TARGET sweep summary ========"
cat "$STATUS_FILE"
echo "---- $(grep -c PASS "$STATUS_FILE") passed, $failed failed of ${#TESTS[@]}"

[ "$failed" -eq 0 ] || exit 1

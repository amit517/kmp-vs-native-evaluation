#!/usr/bin/env bash
#
# Runs one iOS benchmark test and refuses to report success unless the bundle
# actually contains executed tests and per-iteration measurements.
#
# Nine previous native runs were reported as "9/9 passed" while executing zero
# tests: xcodebuild exits 0 on an empty test selection, and the original harness
# read the exit code through a pipeline (so it saw `tail`'s status, not
# xcodebuild's). Both traps are closed here.
#
# Usage:
#   run-ios-benchmark.sh <kmp|native> <Class/testMethod> <output-dir>
#
# Example:
#   run-ios-benchmark.sh native StartupBenchmark/testColdStartup out/native-ios

set -u -o pipefail

TARGET="${1:?target required: kmp|native}"
TEST_SEL="${2:?test required, e.g. StartupBenchmark/testColdStartup}"
OUT_DIR="${3:?output dir required}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_UDID="${DEVICE_UDID:-00008140-0005309E3687001C}"
BACKEND_URL="${BACKEND_URL:-http://63.177.119.99:8080}"

KMP_IDS=(com.example.thesisproject.Thesisproject com.example.thesisproject.iosAppPerformanceTests.xctrunner)
NATIVE_IDS=(com.amit.IosNativeBuild com.amit.IosNativeBuildPerformanceTests.xctrunner)

case "$TARGET" in
  kmp)
    PROJECT="$REPO_ROOT/kmp-app/iosApp/iosApp.xcodeproj"
    SCHEME="iosApp"
    TEST_TARGET="iosAppPerformanceTests"
    EVICT_IDS=("${NATIVE_IDS[@]}")
    ;;
  native)
    PROJECT="$REPO_ROOT/native-ios-app/IosNativeBuild.xcodeproj"
    SCHEME="IosNativeBuild"
    TEST_TARGET="IosNativeBuildPerformanceTests"
    EVICT_IDS=("${KMP_IDS[@]}")
    ;;
  *)
    echo "FATAL: unknown target '$TARGET' (expected kmp|native)" >&2
    exit 2
    ;;
esac

ONLY_TESTING="$TEST_TARGET/$TEST_SEL"
TEST_NAME="$(echo "$TEST_SEL" | tr '/' '_')"
mkdir -p "$OUT_DIR"
BUNDLE="$OUT_DIR/${TEST_NAME}.xcresult"
LOG="$OUT_DIR/${TEST_NAME}.log"
DERIVED="${DERIVED_DATA:-$OUT_DIR/.derived-$TARGET}"

fatal() { echo "" >&2; echo "FATAL: $*" >&2; exit 1; }

# --- Prerequisite: backend must be reachable, else every test fails on the
# --- article-list wait and the failure looks like an app bug.
code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$BACKEND_URL/health" || true)"
[ "$code" = "200" ] || fatal "backend $BACKEND_URL/health returned '$code' (want 200). Not starting a run against a dead endpoint."

# --- Record toolchain versions: these are NOT recoverable from the bundle later.
ENV_FILE="$OUT_DIR/environment.txt"
if [ ! -f "$ENV_FILE" ]; then
  {
    echo "recorded_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "xcode=$(xcodebuild -version | tr '\n' ' ')"
    echo "swift=$(swift --version 2>&1 | head -1)"
    echo "xcresulttool=$(xcrun xcresulttool version 2>&1 | head -1)"
    echo "macos=$(sw_vers -productVersion) ($(sw_vers -buildVersion))"
    echo "device_udid=$DEVICE_UDID"
    echo "backend=$BACKEND_URL"
  } > "$ENV_FILE"
fi

rm -rf "$BUNDLE"
echo "==> $TARGET :: $ONLY_TESTING"

# --- DEVELOPMENT_TEAM J832H2D367 is a free/personal profile, capped at 3 app IDs
# --- per device. Each target needs 2 (app + xctrunner), so the two targets cannot
# --- be installed simultaneously; the 4th install fails with "reached the maximum
# --- number of installed apps". Evict the other target before running this one.
for bid in "${EVICT_IDS[@]}"; do
  if xcrun devicectl device uninstall app --device "$DEVICE_UDID" "$bid" >/dev/null 2>&1; then
    echo "    evicted $bid"
  fi
done

# Capture xcodebuild's own status. Never read it through a pipe.
set +e
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS,id=$DEVICE_UDID" \
  -derivedDataPath "$DERIVED" \
  -resultBundlePath "$BUNDLE" \
  -only-testing:"$ONLY_TESTING" \
  -allowProvisioningUpdates \
  > "$LOG" 2>&1
XCB_STATUS=$?
set -e

[ -d "$BUNDLE" ] || fatal "no result bundle produced (xcodebuild status $XCB_STATUS). See $LOG"

# --- Gate 1: executed-test count must be non-zero.
SUMMARY="$(xcrun xcresulttool get test-results summary --path "$BUNDLE" 2>/dev/null)"
read -r PASSED FAILED SKIPPED <<<"$(printf '%s' "$SUMMARY" | python3 -c '
import json,sys
d=json.load(sys.stdin)
print(d.get("passedTests",0), d.get("failedTests",0), d.get("skippedTests",0))
' 2>/dev/null || echo "0 0 0")"
EXECUTED=$(( PASSED + FAILED ))

echo "    xcodebuild status : $XCB_STATUS"
echo "    executed tests    : $EXECUTED (passed=$PASSED failed=$FAILED skipped=$SKIPPED)"

if [ "$EXECUTED" -eq 0 ]; then
  grep -iE "Executed 0 tests|Testing cancelled|could not be launched|TEST EXECUTE FAILED" "$LOG" | tail -5 >&2 || true
  fatal "executed 0 tests -- empty selection or launch failure. This is the exact condition that silently invalidated the original nine native runs. See $LOG"
fi
[ "$FAILED" -eq 0 ] || fatal "$FAILED test(s) failed. See $LOG"

# --- Gate 2: measurements array must be non-empty.
METRICS="$(xcrun xcresulttool get test-results metrics --path "$BUNDLE" 2>/dev/null)"
printf '%s' "$METRICS" > "$OUT_DIR/${TEST_NAME}.metrics.json"

printf '%s' "$METRICS" | python3 -c '
import json,sys
try:
    data = json.load(sys.stdin)
except Exception as e:
    print(f"    metrics: UNPARSEABLE ({e})"); sys.exit(3)
if not data:
    print("    metrics: EMPTY ARRAY"); sys.exit(3)
total = 0
for t in data:
    for run in t.get("testRuns", []):
        for m in run.get("metrics", []):
            n = len(m.get("measurements") or [])
            total += n
            name = m.get("displayName") or m.get("identifier") or "?"
            print("    metric: %s -> %d samples" % (name, n))
if total == 0:
    print("    metrics: all metric blocks have 0 measurements"); sys.exit(3)
print(f"    TOTAL SAMPLES: {total}")
' || fatal "no per-iteration measurements in $BUNDLE. The test ran but recorded nothing -- metric is wrong for the interaction. See $LOG"

echo "    OK -> $BUNDLE"

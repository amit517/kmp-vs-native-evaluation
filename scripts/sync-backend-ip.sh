#!/usr/bin/env bash
# Point the apps + helper scripts at the backend EC2 instance's current public IP.
#
# The instance uses an auto-assigned public IP, which changes on every stop/start.
# That is deliberate: it costs nothing while the instance is stopped, unlike an
# Elastic IP ($3.60/mo even when idle). This script removes the manual edits that
# tradeoff would otherwise cost.
#
# Usage:
#   ./scripts/sync-backend-ip.sh              # look up, health-check, rewrite
#   ./scripts/sync-backend-ip.sh --dry-run    # show what would change
#   ./scripts/sync-backend-ip.sh --ip 1.2.3.4 # skip lookup, use this address
#   ./scripts/sync-backend-ip.sh --no-health  # rewrite even if /health fails

set -euo pipefail

AWS_REGION="${AWS_REGION:-eu-central-1}"
INSTANCE_TAG="${INSTANCE_TAG:-kmp-news-backend-instance}"
PORT="${PORT:-8080}"

DRY_RUN=0
SKIP_HEALTH=0
FORCED_IP=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)   DRY_RUN=1 ;;
    --no-health) SKIP_HEALTH=1 ;;
    --ip)        FORCED_IP="${2:-}"; shift ;;
    -h|--help)   sed -n '2,15p' "$0"; exit 0 ;;
    *)           echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
ylw()  { printf '\033[33m%s\033[0m\n' "$*"; }
fatal(){ red "ERROR: $*"; exit 1; }

# ---------------------------------------------------------------- find the IP
if [ -n "$FORCED_IP" ]; then
  IP="$FORCED_IP"
  echo "Using supplied address: $IP"
else
  echo "Looking up '$INSTANCE_TAG' in $AWS_REGION ..."
  IP="$(aws ec2 describe-instances --region "$AWS_REGION" \
        --filters "Name=tag:Name,Values=$INSTANCE_TAG" \
                  "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].PublicIpAddress' \
        --output text 2>/dev/null || true)"
  IP="$(printf '%s' "$IP" | tr -d '[:space:]')"

  if [ -z "$IP" ] || [ "$IP" = "None" ]; then
    red "No running instance tagged '$INSTANCE_TAG' in $AWS_REGION."
    echo
    echo "Current instances in that region:"
    aws ec2 describe-instances --region "$AWS_REGION" \
      --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,Name:Tags[?Key==`Name`]|[0].Value}' \
      --output table 2>/dev/null || echo "  (none)"
    echo
    echo "Start it with:  aws ec2 start-instances --region $AWS_REGION --instance-ids <id>"
    echo "Or provision:   cd backend/terraform && terraform apply"
    exit 1
  fi
fi

case "$IP" in
  *[!0-9.]*|"") fatal "'$IP' is not a bare IPv4 address" ;;
esac
grn "Backend address: $IP"

# ------------------------------------------------------------- health check
if [ "$SKIP_HEALTH" -eq 0 ]; then
  echo -n "Checking http://$IP:$PORT/health ... "
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://$IP:$PORT/health" || true)"
  if [ "$code" = "200" ]; then
    grn "200 OK"
  else
    red "got '$code' (want 200)"
    echo "The instance is running but the backend is not serving. It may still be"
    echo "booting (user-data pulls the image from ECR; give it ~60-90s), or the"
    echo "container died. Re-run, or pass --no-health to rewrite anyway."
    exit 1
  fi
fi

# ------------------------------------------------------------------- rewrite
# Each entry: <file>::<perl regex with $1/$2 capture around the address>
# Anchored per-file on purpose. A blanket IPv4 substitution would clobber the
# EC2 metadata address (169.254.169.254), the Android emulator host (10.0.2.2)
# and the local-network examples.
#
# benchmark-data/ is intentionally NOT touched: those files record the endpoint
# each run actually used, and rewriting them would falsify the results.
apply() {
  local file="$1" pattern="$2"
  [ -f "$file" ] || { ylw "  skip (missing): $file"; return; }

  local before after
  before="$(cat "$file")"
  after="$(perl -pe "s!$pattern!\${1}$IP\${2}!g" "$file")"

  if [ "$before" = "$after" ]; then
    echo "  unchanged: $file"
    return
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    ylw "  would update: $file"
    diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") | sed 's/^/      /' || true
  else
    printf '%s\n' "$after" > "$file"
    grn "  updated: $file"
  fi
}

echo
echo "Rewriting endpoint references:"

apply "kmp-app/shared/src/commonMain/kotlin/com/amit/newsreader/config/ApiConfig.kt" \
      '(const val BASE_URL = "http://)[0-9.]+(:'"$PORT"'")'

apply "native-ios-app/IosNativeBuild/Data/Remote/NewsAPIService.swift" \
      '(private let baseURL = "http://)[0-9.]+(:'"$PORT"'")'

apply "scripts/run-ios-benchmark.sh" \
      '(BACKEND_URL:-http://)[0-9.]+(:'"$PORT"'\})'

apply "backend/update-backend.sh" \
      '(INSTANCE_IP=")[0-9.]+(")'

apply "backend/test-deployment.sh" \
      '(API_ENDPOINT="http://)[0-9.]+(:'"$PORT"'")'

apply "backend/test-deployment.sh" \
      '(ssh ec2-user@)[0-9.]+(\b)'

echo
if [ "$DRY_RUN" -eq 1 ]; then
  ylw "Dry run - nothing written."
else
  grn "Done. Backend is http://$IP:$PORT"
  echo
  echo "Rebuild the apps before benchmarking; the address is compiled in."
  echo "Note: benchmark-data/ was left untouched by design (recorded results)."
fi

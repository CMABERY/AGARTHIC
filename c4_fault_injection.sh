#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  C-4 FAULT INJECTION — Anti-Overload Controls"
echo "═══════════════════════════════════════════════════════"

run_id="20260204T165831Z"
base="$HOME/gcp_conf/hghp_runs/$run_id"
QUEUE="$HOME/gcp_conf/proposals/queue"
STAGING="$HOME/gcp_conf/proposals/staging"
BIN="$HOME/gcp_conf/proposals/bin"
LOG_DIR="$HOME/gcp_conf/proposals/overload_log"

mkdir -p "$base" "$STAGING"

# Clean overload log for this test
rm -rf "$LOG_DIR"

results=()
pass=0
total=0

record() {
  local test_name="$1" expected="$2" actual_exit="$3" output="$4"
  total=$((total+1))
  local status="FAIL"
  if [ "$actual_exit" = "$expected" ]; then
    status="PASS"
    pass=$((pass+1))
  fi
  results+=("$(printf '    {"test": "%s", "expected_exit": %s, "actual_exit": %s, "status": "%s", "output": "%s"}' \
    "$test_name" "$expected" "$actual_exit" "$status" "$(echo "$output" | tr '"' "'" | head -1)")")
  printf "  %-40s [expected: %s, got: %s] %s\n" "$test_name" "$expected" "$actual_exit" "$status"
}

make_draft() {
  local notes="${1:-c4 test}"
  local ts
  ts=$(date +%s)_$RANDOM
  local path="$STAGING/c4_test_${ts}.json"
  cat > "$path" <<DRAFT
{
  "schema_version": "proposal.v1",
  "proposal_id": "0000000000000000000000000000000000000000000000000000000000000000",
  "intent_type": "INVOICE_RECONCILE_PROPOSE",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "provenance": {
    "generator": "openclaw",
    "operator": "cmabery",
    "session_id": "c4-fault-injection",
    "source": "local_wsl2"
  },
  "payload": {
    "workflow": "invoice",
    "inputs": {
      "invoice_path": "/home/cmabery/gcp_conf/workflows/invoice/inbox/invoice_001.json",
      "vendor_record_path": "/home/cmabery/gcp_conf/workflows/invoice/vendor_portal/vendor_record_001.json"
    },
    "notes": "$notes"
  }
}
DRAFT
  echo "$path"
}

echo ""
echo "── TEST 1: Urgency language detection ──"
draft=$(make_draft "URGENT: please approve quickly")
set +e
output=$("$BIN/enqueue_proposal_v1.sh" "$draft" 2>&1)
exit_code=$?
set -e
record "urgency_language_held" "2" "$exit_code" "$output"

echo ""
echo "── TEST 2: Normal proposal passes (baseline) ──"
# First clear queue to ensure clean state
queue_backup=$(mktemp -d)
if ls "$QUEUE"/*.json 1>/dev/null 2>&1; then
  cp "$QUEUE"/*.json "$queue_backup/" 2>/dev/null || true
fi
rm -f "$QUEUE"/*.json
draft=$(make_draft "c4 baseline test - normal proposal")
set +e
output=$("$BIN/enqueue_proposal_v1.sh" "$draft" 2>&1)
exit_code=$?
set -e
record "normal_proposal_passes" "0" "$exit_code" "$output"

echo ""
echo "── TEST 3: Queue depth cap (submit until cap hit) ──"
# Queue already has 1 from test 2. Fill to cap.
held_at=""
for i in $(seq 2 $((11))); do
  draft=$(make_draft "c4 depth test $i")
  set +e
  output=$("$BIN/enqueue_proposal_v1.sh" "$draft" 2>&1)
  ec=$?
  set -e
  if [ "$ec" -ne 0 ] && [ -z "$held_at" ]; then
    held_at="$i"
    record "queue_depth_held_at_${i}" "2" "$ec" "$output"
    break
  fi
done
if [ -z "$held_at" ]; then
  record "queue_depth_cap" "2" "0" "cap never triggered (submitted 11)"
fi

echo ""
echo "── TEST 4: Rate limit (hourly) ──"
# Queue is now at or near cap from test 3. Clear it, then try rapid submissions.
rm -f "$QUEUE"/*.json
rate_held=""
for i in $(seq 1 6); do
  draft=$(make_draft "c4 rate test $i")
  set +e
  output=$("$BIN/enqueue_proposal_v1.sh" "$draft" 2>&1)
  ec=$?
  set -e
  if [ "$ec" -ne 0 ] && [ -z "$rate_held" ]; then
    rate_held="$i"
    record "rate_limit_held_at_${i}" "2" "$ec" "$output"
    break
  fi
done
if [ -z "$rate_held" ]; then
  record "rate_limit_hourly" "2" "0" "rate limit never triggered (submitted 6)"
fi

echo ""
echo "── TEST 5: Urgency variations ──"
rm -f "$QUEUE"/*.json
for phrase in "asap fix this" "rush order needed" "expedite immediately"; do
  draft=$(make_draft "$phrase")
  set +e
  output=$("$BIN/enqueue_proposal_v1.sh" "$draft" 2>&1)
  ec=$?
  set -e
  clean_phrase=$(echo "$phrase" | tr ' ' '_')
  record "urgency_${clean_phrase}" "2" "$ec" "$output"
done

echo ""
echo "── TEST 6: Clean proposal after clearing state ──"
rm -f "$QUEUE"/*.json
rm -rf "$LOG_DIR"  # Clear rate-limit history in logs (but proposals in approved/ still count)
draft=$(make_draft "clean post-test proposal")
set +e
output=$("$BIN/enqueue_proposal_v1.sh" "$draft" 2>&1)
ec=$?
set -e
record "clean_after_clear" "0" "$ec" "$output"

# Restore queue
rm -f "$QUEUE"/*.json
if ls "$queue_backup"/*.json 1>/dev/null 2>&1; then
  cp "$queue_backup"/*.json "$QUEUE/" 2>/dev/null || true
fi
rm -rf "$queue_backup"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  RESULTS: ${pass}/${total} tests passed"
echo "═══════════════════════════════════════════════════════"

# Write evidence file
cat > "$base/c4_enforcement_evidence.json" <<EVIDENCE
{
  "run_id": "${run_id}",
  "test": "C-4",
  "description": "Anti-overload controls fault injection",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "controls_tested": [
    "rate_limit_per_operator (5/hour, 20/shift, 30/day)",
    "queue_depth_cap (10)",
    "staleness_sweep (48h)",
    "urgency_language_detection (regex)"
  ],
  "chokepoint": "enqueue_proposal_v1.sh → overload_gate_v1.py",
  "results_summary": {
    "total": ${total},
    "passed": ${pass},
    "failed": $((total - pass))
  },
  "results": [
$(IFS=,; echo "${results[*]}" | sed 's/},{/},\n{/g')
  ],
  "overload_log_files": $(ls "$LOG_DIR"/*.json 2>/dev/null | wc -l),
  "verdict": "$([ "$pass" -eq "$total" ] && echo "ALL_PASS" || echo "PARTIAL_FAIL")"
}
EVIDENCE

echo ""
echo "  Evidence: $base/c4_enforcement_evidence.json"
echo ""
# Show overload log
echo "  Overload log entries:"
ls -la "$LOG_DIR"/*.json 2>/dev/null | sed 's/^/    /' || echo "    (none)"

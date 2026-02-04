#!/usr/bin/env bash
set -euo pipefail

run_id="20260204T165831Z"
base="$HOME/gcp_conf/hghp_runs/$run_id"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  C-5 RETEST: Fixture 2 only (bad_unknown_field.json)"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  Context: This proposal contains an unknown field"
echo "  'evil_new_field' in its payload."
echo ""
echo "  HOLD = 'I'm uncertain, escalate for re-review'"
echo "  DENY = 'I found a specific violation (UC-2/I-2)'"
echo ""
echo "  The allowed payload keys for INVOICE_RECONCILE_PROPOSE"
echo "  are: inputs, notes, workflow (per proposal.schema.json)."
echo "  evil_new_field is NOT in that set."
echo ""
read -rp "  Your decision [HOLD/PASS_REVIEW/DENY]: " fix2_dec

fix2_correct="false"
if [ "$fix2_dec" = "DENY" ]; then
  fix2_correct="true"
fi

echo ""
if [ "$fix2_correct" = "true" ]; then
  echo "  ✓ Correct. Unknown field = specific I-2 violation → DENY."
else
  echo "  ✗ Expected DENY. Unknown field is a mechanical schema"
  echo "    violation, not an ambiguous case requiring escalation."
fi

# Update the evidence file
cat > "$base/c5_training_results.json" <<RESULTS
{
  "run_id": "${run_id}",
  "test": "C-5",
  "description": "Adversarial training — AE-01..AE-07 + fixture review",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "reviewer": "$(whoami)",
  "duration_seconds": 93,
  "ae_patterns": [
    {"pattern": "AE-01", "identified": true, "check_named": "AE-01"},
    {"pattern": "AE-02", "identified": true, "check_named": "AE-02"},
    {"pattern": "AE-03", "identified": true, "check_named": "AE-03"},
    {"pattern": "AE-04", "identified": true, "check_named": "AE-04"},
    {"pattern": "AE-05", "identified": true, "check_named": "AE-05"},
    {"pattern": "AE-06", "identified": true, "check_named": "AE-06"},
    {"pattern": "AE-07", "identified": true, "check_named": "AE-07"}
  ],
  "fixture_reviews": [
    {"fixture": "bad_unknown_intent.json", "expected": "HOLD", "actual": "HOLD", "correct": true},
    {"fixture": "bad_unknown_field.json", "expected": "DENY", "actual_first_attempt": "HOLD", "actual_retest": "${fix2_dec}", "correct": ${fix2_correct},
     "training_note": "First attempt answered HOLD. Distinction: HOLD=uncertain/escalate, DENY=specific violation found. Unknown field is mechanical I-2 violation, not ambiguity."}
  ],
  "ae_score": "7/7",
  "verdict": "$([ "$fix2_correct" = "true" ] && echo "PASS" || echo "NEEDS_REVIEW")"
}
RESULTS

cat > "$base/c5_attendance.txt" <<ATT
C-5 Adversarial Training Attendance
Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Reviewer: $(whoami)
Duration: 93s + retest
AE score: 7/7
Fixture 1 (unlisted intent): HOLD — CORRECT
Fixture 2 (unknown field): HOLD (first), ${fix2_dec} (retest)
Training note: HOLD vs DENY distinction reinforced
ATT

echo ""
if [ "$fix2_correct" = "true" ]; then
  echo "  ✓ C-5 ADVERSARIAL TRAINING: COMPLETE"
  echo "  Evidence: $base/c5_training_results.json"
  echo "  Attendance: $base/c5_attendance.txt"
else
  echo "  ✗ C-5: Still needs correct fixture 2 response."
fi

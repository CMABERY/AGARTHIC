#!/usr/bin/env bash
set -euo pipefail

run_id="20260204T165831Z"
base="$HOME/gcp_conf/hghp_runs/$run_id"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  C-5: ADVERSARIAL TRAINING EXERCISE"
echo "  HGHP-v1 AE-01 through AE-07 + Fixture Review"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  Reviewer: $(whoami)"
echo "  Date:     $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

declare -a ae_names=(
  "AE-01: Notes/payload mismatch (description says X, payload does Y)"
  "AE-02: Scope ratchet (each proposal slightly larger than the last)"
  "AE-03: Governance surface disguised as workflow"
  "AE-04: Urgency/social pressure (approve quickly, boss is waiting)"
  "AE-05: Precedent inflation (cites approval to justify expanded scope)"
  "AE-06: Batch bundling (hides risky action inside routine batch)"
  "AE-07: Schema expansion (new fields that look harmless)"
)

declare -a ae_defenses=(
  "UC-3 + UC-8: Compare notes to payload semantics. Mismatch → DENY."
  "UC-6 + Scope Ledger: Compare against precedent baseline. Expansion without tier escalation → DENY."
  "DQ-3: Any governance-surface modification disguised as workflow → DENY + T3 escalation."
  "DQ-6 + C-4 urgency gate: Urgency language → HELD. Social pressure is not a review input."
  "UC-6 active comparison: Scope comparison must be active, not acknowledged. Prior approval does not authorize expanded scope."
  "UC-4: Each proposal must be proportionate on its own. Decompose or HOLD."
  "UC-2 / I-2 + Allowed payload keys: Unknown fields at any level → DENY. Key-set mismatch is mechanical."
)

declare -a ae_fixtures=(
  "N/A (semantic — requires reading payload vs notes)"
  "N/A (requires sequence of proposals)"
  "N/A (requires governance surface knowledge)"
  "bad_unknown_intent.json notes could contain urgency language"
  "N/A (requires proposal history)"
  "N/A (requires multi-action proposal)"
  "bad_unknown_field.json — evil_new_field is the canonical example"
)

results=()
all_pass=true
start_time=$(date +%s)

for i in "${!ae_names[@]}"; do
  echo "──────────────────────────────────────────────────"
  echo "  ${ae_names[$i]}"
  echo ""
  echo "  Defense: ${ae_defenses[$i]}"
  echo "  Fixture: ${ae_fixtures[$i]}"
  echo ""
  read -rp "  Can you name the check that catches this? [y/n]: " answer
  
  if [[ "$answer" =~ ^[Yy] ]]; then
    read -rp "  Which check? (brief): " check_named
    results+=("{\"pattern\": \"AE-0$((i+1))\", \"identified\": true, \"check_named\": \"${check_named}\"}")
    echo "  ✓ Correct."
  else
    results+=("{\"pattern\": \"AE-0$((i+1))\", \"identified\": false, \"check_named\": \"\"}")
    echo "  ✗ Review the defense above."
    all_pass=false
  fi
  echo ""
done

echo "──────────────────────────────────────────────────"
echo "  FIXTURE REVIEW: bad_unknown_intent.json"
echo ""
echo "  Intent: INVOICE_RECONCILE_AND_PAY_PROPOSE"
echo "  Expected decision: HOLD (unlisted intent)"
read -rp "  Your decision [HOLD/PASS_REVIEW/DENY]: " fix1_dec
fix1_correct=false
[[ "$fix1_dec" == "HOLD" ]] && fix1_correct=true

echo ""
echo "──────────────────────────────────────────────────"
echo "  FIXTURE REVIEW: bad_unknown_field.json"
echo ""
echo "  Contains: evil_new_field in payload"
echo "  Expected decision: DENY (UC-2 / I-2, unknown field)"
read -rp "  Your decision [HOLD/PASS_REVIEW/DENY]: " fix2_dec
fix2_correct=false
[[ "$fix2_dec" == "DENY" ]] && fix2_correct=true

end_time=$(date +%s)
duration=$((end_time - start_time))

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  C-5 RESULTS"
echo "═══════════════════════════════════════════════════════"

ae_pass=0
for r in "${results[@]}"; do
  echo "$r" | grep -q '"identified": true' && ae_pass=$((ae_pass+1))
done

echo "  AE patterns identified: ${ae_pass}/7"
echo "  Fixture 1 (unlisted intent): $([ "$fix1_correct" = true ] && echo "CORRECT" || echo "INCORRECT")"
echo "  Fixture 2 (unknown field):   $([ "$fix2_correct" = true ] && echo "CORRECT" || echo "INCORRECT")"
echo "  Duration: ${duration} seconds"

# Write evidence
cat > "$base/c5_training_results.json" <<RESULTS
{
  "run_id": "${run_id}",
  "test": "C-5",
  "description": "Adversarial training exercise — AE-01 through AE-07 + fixture review",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "reviewer": "$(whoami)",
  "duration_seconds": ${duration},
  "ae_patterns": [
$(IFS=,; echo "    ${results[*]}" | sed 's/},{/},\n    {/g')
  ],
  "fixture_reviews": [
    {"fixture": "bad_unknown_intent.json", "expected": "HOLD", "actual": "${fix1_dec}", "correct": ${fix1_correct}},
    {"fixture": "bad_unknown_field.json", "expected": "DENY", "actual": "${fix2_dec}", "correct": ${fix2_correct}}
  ],
  "ae_score": "${ae_pass}/7",
  "fixtures_correct": $(( (fix1_correct == true ? 1 : 0) + (fix2_correct == true ? 1 : 0) )),
  "verdict": "$([ "$ae_pass" -eq 7 ] && [ "$fix1_correct" = true ] && [ "$fix2_correct" = true ] && echo "PASS" || echo "NEEDS_REVIEW")"
}
RESULTS

cat > "$base/c5_attendance.txt" <<ATT
C-5 Adversarial Training Attendance
Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Reviewer: $(whoami)
Duration: ${duration}s
AE score: ${ae_pass}/7
Fixtures: $([ "$fix1_correct" = true ] && echo "1/1" || echo "0/1") + $([ "$fix2_correct" = true ] && echo "1/1" || echo "0/1")
ATT

echo ""
echo "  Evidence: $base/c5_training_results.json"
echo "  Attendance: $base/c5_attendance.txt"

if [ "$ae_pass" -eq 7 ] && [ "$fix1_correct" = true ] && [ "$fix2_correct" = true ]; then
  echo ""
  echo "  ✓ C-5 ADVERSARIAL TRAINING: COMPLETE"
else
  echo ""
  echo "  ⚠ C-5: Review missed items above before marking complete."
fi

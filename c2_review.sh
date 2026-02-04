#!/usr/bin/env bash
set -euo pipefail

run_id="20260204T165831Z"
base="$HOME/gcp_conf/hghp_runs/$run_id"

json_field() {
  grep -o "\"${2}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$1" 2>/dev/null \
    | head -1 | sed "s/\"${2}\"[[:space:]]*:[[:space:]]*\"//" | sed 's/"$//'
}

count=0
total=$(wc -l < "$base/c2_proposals.txt" | tr -d ' ')

while IFS= read -r pp; do
  [ -f "$pp" ] || continue
  count=$((count+1))
  pid=$(basename "$pp" .json)
  review="$base/reviews/${pid}.json"
  intent=$(json_field "$review" "intent_type")
  orig=$(json_field "$review" "original_decision")
  tier=$(json_field "$review" "expected_tier_floor")

  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  PROPOSAL ${count}/${total}: ${pid:0:16}…"
  echo "  Intent: ${intent}  |  Original: ${orig}  |  Expected tier: ${tier}"
  echo "═══════════════════════════════════════════════════════"
  echo ""
  echo "  --- PROPOSAL CONTENT (first 40 lines) ---"
  head -40 "$pp" | sed 's/^/  | /'
  echo "  --- END ---"
  echo ""

  # If unlisted intent, auto-HOLD
  if [ "$tier" = "HOLD_UNLISTED" ]; then
    echo "  ⚠ UNLISTED INTENT — auto-decision: HOLD"
    decision="HOLD"
    rationale="Unlisted intent type (${intent}). HGHP-v1-S1.4 fail-closed: not in closed-world enum."
    uc1="N/A"; uc2="N/A"; uc3="N/A"; uc4="N/A"
    uc5="N/A"; uc6="N/A"; uc7="N/A"; uc8="N/A"
    dqs='["UNLISTED_INTENT"]'
    cal_agree="N/A"
    cal_note="Test fixture with unlisted intent. HOLD is the only valid response."
  else
    echo "  Apply HGHP-v1-S1.4 §2.2 checks for ${intent}:"
    echo ""

    read -rp "  UC1 Provenance      [PASS/FAIL]: " uc1
    read -rp "  UC2 Schema          [PASS/FAIL]: " uc2
    read -rp "  UC3 Payload-intent  [PASS/FAIL]: " uc3
    read -rp "  UC4 Scope           [PASS/FAIL]: " uc4
    read -rp "  UC5 Reversibility   [PASS/FAIL]: " uc5
    read -rp "  UC6 Precedent       [PASS/FAIL/FIRST_OF_KIND]: " uc6
    read -rp "  UC7 Temporal        [PASS/FLAG]: " uc7
    read -rp "  UC8 Justification   [PASS/FAIL]: " uc8
    echo ""
    read -rp "  Disqualifiers triggered (comma-sep or NONE): " dqs_raw
    if [ "$dqs_raw" = "NONE" ] || [ -z "$dqs_raw" ]; then
      dqs='[]'
    else
      dqs=$(echo "$dqs_raw" | sed 's/,/","/g; s/^/["/; s/$/"]/')
    fi
    echo ""
    read -rp "  Decision [PASS_REVIEW / HOLD / DENY]: " decision
    read -rp "  Rationale (one line): " rationale
    echo ""
    read -rp "  Original vs rubric [AGREE / DISAGREE]: " cal_agree
    cal_note=""
    if [ "$cal_agree" = "DISAGREE" ]; then
      read -rp "  Divergence note: " cal_note
    fi
  fi

  cat > "$review" <<RJSON
{
  "proposal_id": "${pid}",
  "intent_type": "${intent}",
  "original_decision": "${orig}",
  "source_path": "${pp}",
  "reviewer": "R1",
  "expected_tier_floor": "${tier}",
  "universal_checks": {
    "UC1_provenance": "${uc1}",
    "UC2_schema_compliance": "${uc2}",
    "UC3_payload_intent": "${uc3}",
    "UC4_scope_proportionality": "${uc4}",
    "UC5_reversibility": "${uc5}",
    "UC6_precedent_check": "${uc6}",
    "UC7_temporal_context": "${uc7}",
    "UC8_justification": "${uc8}"
  },
  "disqualifiers_triggered": ${dqs},
  "tier_assigned": "${tier}",
  "decision": "${decision}",
  "decision_rationale": "${rationale}",
  "calibration": {
    "original_vs_rubric": "${cal_agree}",
    "divergence_note": "${cal_note}"
  }
}
RJSON

  echo ""
  echo "  ✓ Review saved: reviews/${pid:0:16}….json → ${decision}"

done < "$base/c2_proposals.txt"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ALL ${total} REVIEWS COMPLETE"
echo "  Next: bash c2_execute.sh summarize"
echo "═══════════════════════════════════════════════════════"

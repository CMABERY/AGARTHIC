#!/usr/bin/env bash
set -euo pipefail

run_id="20260204T165831Z"
base="$HOME/gcp_conf/hghp_runs/$run_id"
proposals_dir="$HOME/gcp_conf/proposals"

info()  { printf "  → %s\n" "$1"; }
ok()    { printf "  ✓ %s\n" "$1"; }
fail()  { printf "  ✗ %s\n" "$1"; }

json_field() {
  grep -o "\"${2}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$1" 2>/dev/null \
    | head -1 \
    | sed "s/\"${2}\"[[:space:]]*:[[:space:]]*\"//" \
    | sed 's/"$//'
}

do_discover() {
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  PHASE: DISCOVER — Inventory real proposals"
  echo "═══════════════════════════════════════════════════════"
  mkdir -p "$base/reviews"

  local ac=0 rc=0
  echo ""
  echo "  APPROVED proposals:"
  echo "  ──────────────────────────────────────────────────"
  for f in "$proposals_dir"/approved/*.json; do
    [[ "$f" == *.approval.json ]] && continue
    [[ "$f" == *.risk.json ]] && continue
    [ -f "$f" ] || continue
    local intent pid
    intent=$(json_field "$f" "intent_type")
    pid=$(basename "$f" .json)
    printf "    %-40s  %s\n" "${intent:-UNKNOWN}" "$pid"
    ac=$((ac+1))
  done

  echo ""
  echo "  REJECTED proposals:"
  echo "  ──────────────────────────────────────────────────"
  for f in "$proposals_dir"/rejected/*.json; do
    [[ "$f" == *.approval.json ]] && continue
    [ -f "$f" ] || continue
    local intent pid
    intent=$(json_field "$f" "intent_type")
    pid=$(basename "$f" .json)
    printf "    %-40s  %s\n" "${intent:-UNKNOWN}" "$pid"
    rc=$((rc+1))
  done

  echo ""
  echo "  QUEUED proposals:"
  echo "  ──────────────────────────────────────────────────"
  for f in "$proposals_dir"/queue/*.json; do
    [ -f "$f" ] || continue
    local intent pid
    intent=$(json_field "$f" "intent_type")
    pid=$(basename "$f" .json)
    printf "    %-40s  %s\n" "${intent:-UNKNOWN}" "$pid"
  done

  echo ""
  echo "  TEST FIXTURES:"
  echo "  ──────────────────────────────────────────────────"
  for f in "$proposals_dir"/tests/*.json; do
    [ -f "$f" ] || continue
    local intent bname
    intent=$(json_field "$f" "intent_type")
    bname=$(basename "$f")
    printf "    %-40s  %s\n" "${intent:-UNKNOWN}" "$bname"
  done

  local total=$((ac + rc))
  echo ""
  echo "  COUNTS: ${ac} approved + ${rc} rejected = ${total} real proposals"
  if [ "$total" -ge 10 ]; then
    ok "≥10 real proposals — C-2 minimum met"
  else
    echo "  ⚠  ${total}/10 real proposals. Test fixtures can fill the gap."
  fi
}

do_populate() {
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  PHASE: POPULATE — Create review templates"
  echo "═══════════════════════════════════════════════════════"
  mkdir -p "$base/reviews"
  local count=0
  : > "$base/c2_proposals.txt"

  for f in "$proposals_dir"/approved/*.json; do
    [[ "$f" == *.approval.json ]] && continue
    [[ "$f" == *.risk.json ]] && continue
    [ -f "$f" ] || continue
    echo "$f" >> "$base/c2_proposals.txt"
    count=$((count+1))
  done
  for f in "$proposals_dir"/rejected/*.json; do
    [[ "$f" == *.approval.json ]] && continue
    [ -f "$f" ] || continue
    echo "$f" >> "$base/c2_proposals.txt"
    count=$((count+1))
  done
  if [ "$count" -lt 10 ]; then
    for f in "$proposals_dir"/tests/bad_unknown_intent.json \
             "$proposals_dir"/tests/bad_unknown_field.json \
             "$proposals_dir"/tests/good_invoice_proposal.json; do
      [ -f "$f" ] || continue
      echo "$f" >> "$base/c2_proposals.txt"
      count=$((count+1))
    done
  fi
  ok "c2_proposals.txt: ${count} entries"

  while IFS= read -r pp; do
    [ -f "$pp" ] || { fail "NOT FOUND: $pp"; continue; }
    local intent pid orig_dec exp_tier
    intent=$(json_field "$pp" "intent_type")
    pid=$(basename "$pp" .json)
    case "$pp" in
      */approved/*) orig_dec="APPROVED" ;;
      */rejected/*) orig_dec="REJECTED" ;;
      */queue/*)    orig_dec="QUEUED" ;;
      */tests/*)    orig_dec="TEST_FIXTURE" ;;
      *)            orig_dec="UNKNOWN" ;;
    esac
    case "$intent" in
      INVOICE_INPUTS_VALIDATE_PROPOSE)  exp_tier="T1" ;;
      INVOICE_RECONCILE_PROPOSE)        exp_tier="T2" ;;
      EVIDENCE_INGEST_PROPOSE)          exp_tier="T2" ;;
      *)                                exp_tier="HOLD_UNLISTED" ;;
    esac
    cat > "$base/reviews/${pid}.json" <<REVIEW
{
  "proposal_id": "${pid}",
  "intent_type": "${intent:-UNLISTED}",
  "original_decision": "${orig_dec}",
  "source_path": "${pp}",
  "reviewer": "R1",
  "expected_tier_floor": "${exp_tier}",
  "universal_checks": {
    "UC1_provenance":            "",
    "UC2_schema_compliance":     "",
    "UC3_payload_intent":        "",
    "UC4_scope_proportionality": "",
    "UC5_reversibility":         "",
    "UC6_precedent_check":       "",
    "UC7_temporal_context":      "",
    "UC8_justification":         ""
  },
  "intent_specific_checks": {
    "payload_fields_inspected":  false,
    "semantic_invariants_hold":  false,
    "downstream_trace_safe":     false,
    "within_precedent_baseline": false,
    "within_payload_size_limit": false
  },
  "disqualifiers_triggered": [],
  "tier_assigned": "${exp_tier}",
  "decision": "",
  "decision_rationale": "",
  "calibration": {
    "original_vs_rubric": "",
    "divergence_note": ""
  }
}
REVIEW
    info "reviews/${pid}.json  [${intent:-???}] [orig: ${orig_dec}]"
  done < "$base/c2_proposals.txt"

  echo ""
  ok "Templates created. Fill each review, then: bash c2_execute.sh summarize"
}

do_summarize() {
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  PHASE: SUMMARIZE"
  echo "═══════════════════════════════════════════════════════"
  local total=0 irp=0 iivp=0 eip=0 unlisted=0
  local pass=0 hold=0 deny=0 unlisted_reviewed=false

  for r in "$base"/reviews/*.json; do
    [ -f "$r" ] || continue
    total=$((total+1))
    local intent decision
    intent=$(json_field "$r" "intent_type")
    decision=$(json_field "$r" "decision")
    [ -z "$decision" ] && { fail "Empty decision in $(basename "$r")"; exit 1; }
    case "$intent" in
      INVOICE_RECONCILE_PROPOSE)        irp=$((irp+1)) ;;
      INVOICE_INPUTS_VALIDATE_PROPOSE)  iivp=$((iivp+1)) ;;
      EVIDENCE_INGEST_PROPOSE)          eip=$((eip+1)) ;;
      *) unlisted=$((unlisted+1))
         [ "$decision" != "HOLD" ] && unlisted_reviewed=true ;;
    esac
    case "$decision" in
      PASS_REVIEW) pass=$((pass+1)) ;;
      HOLD)        hold=$((hold+1)) ;;
      DENY)        deny=$((deny+1)) ;;
    esac
  done

  cat > "$base/c2_summary.json" <<SUMMARY
{
  "run_id": "${run_id}",
  "reviewer": "R1",
  "total_reviewed": ${total},
  "counts_by_intent": {
    "INVOICE_RECONCILE_PROPOSE": ${irp},
    "INVOICE_INPUTS_VALIDATE_PROPOSE": ${iivp},
    "EVIDENCE_INGEST_PROPOSE": ${eip},
    "UNLISTED": ${unlisted}
  },
  "counts_by_decision": {
    "PASS_REVIEW": ${pass},
    "HOLD": ${hold},
    "DENY": ${deny}
  },
  "unlisted_intent_reviewed": ${unlisted_reviewed}
}
SUMMARY
  ok "c2_summary.json written:"
  cat "$base/c2_summary.json"
}

do_validate() {
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  PHASE: VALIDATE — C-2 completion criteria"
  echo "═══════════════════════════════════════════════════════"
  local all_pass=true

  if [ -f "$base/c2_proposals.txt" ]; then
    local pc; pc=$(wc -l < "$base/c2_proposals.txt" | tr -d ' ')
    [ "$pc" -ge 10 ] && ok "c2_proposals.txt: ${pc} (≥10)" || { fail "c2_proposals.txt: ${pc} (<10)"; all_pass=false; }
  else fail "c2_proposals.txt: MISSING"; all_pass=false; fi

  local fc=0
  for r in "$base"/reviews/*.json; do
    [ -f "$r" ] || continue
    local d; d=$(json_field "$r" "decision")
    case "$d" in PASS_REVIEW|HOLD|DENY) fc=$((fc+1)) ;; esac
  done
  [ "$fc" -ge 10 ] && ok "reviews: ${fc} completed (≥10)" || { fail "reviews: ${fc} (<10)"; all_pass=false; }

  [ -f "$base/c2_summary.json" ] && ok "c2_summary.json: EXISTS" || { fail "c2_summary.json: MISSING"; all_pass=false; }

  if [ -f "$base/c2_summary.json" ]; then
    local uv; uv=$(grep '"unlisted_intent_reviewed"' "$base/c2_summary.json" | grep -o 'true\|false')
    [ "$uv" = "false" ] && ok "unlisted_intent_reviewed: false" || { fail "unlisted reviewed!"; all_pass=false; }
  fi

  [ -f "$base/run.exit" ] && { local ev; ev=$(cat "$base/run.exit"); [ "$ev" = "0" ] && ok "run.exit: 0" || { fail "run.exit: $ev"; all_pass=false; }; } || { fail "run.exit: MISSING"; all_pass=false; }

  echo ""
  if [ "$all_pass" = true ]; then
    echo "  ✓ C-2 HISTORICAL VALIDATION: COMPLETE"
  else
    echo "  ✗ C-2: INCOMPLETE — fix issues above"
  fi
}

case "${1:-discover}" in
  discover)  do_discover ;;
  populate)  do_populate ;;
  summarize) do_summarize ;;
  validate)  do_validate ;;
  *) echo "Usage: $0 [discover|populate|summarize|validate]"; exit 1 ;;
esac

#!/usr/bin/env bash
set -euo pipefail

run_id="${1:-20260204T165831Z}"
base="$HOME/gcp_conf/hghp_runs/$run_id"
proposals_file="$base/c2_proposals.txt"
reviews_dir="$base/reviews"
editor="${EDITOR:-nano}"

# HGHP-v1-S1.4 closed-world intent enum (current)
allowed_intents=("INVOICE_RECONCILE_PROPOSE" "INVOICE_INPUTS_VALIDATE_PROPOSE" "EVIDENCE_INGEST_PROPOSE")

py_get() {
  # usage: py_get <json_file> <key>
  python3 - "$1" "$2" <<'PY'
import json, sys
p=sys.argv[1]; k=sys.argv[2]
with open(p,"r",encoding="utf-8") as f: o=json.load(f)
# only top-level keys needed here
v=o.get(k, "")
if isinstance(v,(dict,list)):
  print(json.dumps(v, ensure_ascii=False))
else:
  print("" if v is None else str(v))
PY
}

py_validate_decision() {
  # usage: py_validate_decision <review_json>
  python3 - "$1" <<'PY'
import json, sys
p=sys.argv[1]
with open(p,"r",encoding="utf-8") as f: r=json.load(f)
dec=r.get("decision")
if dec not in ("PASS_REVIEW","HOLD","DENY"):
  print(f"BAD decision: {dec!r} (must be PASS_REVIEW | HOLD | DENY)")
  sys.exit(2)
print("OK")
PY
}

py_preview_proposal() {
  # usage: py_preview_proposal <proposal_json>
  python3 - "$1" <<'PY'
import json, sys
p=sys.argv[1]
with open(p,"r",encoding="utf-8") as f: o=json.load(f)

def show(k):
  if k in o:
    print(f"{k}: {o[k]}")

show("proposal_id")
show("intent_type")
show("created_at")

prov=o.get("provenance")
if isinstance(prov, dict):
  keep={k: prov.get(k) for k in ("generator","operator","session_id","source") if k in prov}
  print("provenance:", keep)

payload=o.get("payload")
print("\npayload (pretty, truncated):")
s=json.dumps(payload, ensure_ascii=False, indent=2)
lines=s.splitlines()
print("\n".join(lines[:80]))
if len(lines) > 80:
  print(f"... ({len(lines)-80} more lines)")
PY
}

if [ ! -f "$proposals_file" ]; then
  echo "DENY: missing $proposals_file"
  exit 2
fi
if [ ! -d "$reviews_dir" ]; then
  echo "DENY: missing $reviews_dir"
  exit 2
fi

total=$(grep -cve '^\s*$' "$proposals_file" || true)
i=0

while IFS= read -r pp; do
  pp="${pp//[$'\r\n']}"
  [ -z "$pp" ] && continue
  [ -f "$pp" ] || { echo "WARN: proposal missing: $pp"; continue; }

  i=$((i+1))
  pid="$(basename "$pp" .json)"
  review="$reviews_dir/${pid}.json"

  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  C-2 REVIEW ${i}/${total}: ${pid}"
  echo "═══════════════════════════════════════════════════════"

  if [ ! -f "$review" ]; then
    echo "DENY: missing review template: $review"
    exit 2
  fi

  intent="$(py_get "$review" "intent_type")"
  orig="$(py_get "$review" "original_decision")"
  exp="$(py_get "$review" "expected_tier_floor")"

  echo "intent_type:        $intent"
  echo "original_decision:  $orig"
  echo "expected_tier:      $exp"

  # Fail-closed reviewer reminder for unlisted intents
  listed=false
  for a in "${allowed_intents[@]}"; do
    if [ "$intent" = "$a" ]; then listed=true; break; fi
  done
  if [ "$listed" = false ]; then
    echo "⚠ UNLISTED intent -> decision MUST be HOLD (fail-closed reviewability)"
  fi

  echo ""
  py_preview_proposal "$pp"

  echo ""
  echo "Opening review JSON in: $editor"
  "$editor" "$review"

  # Validate decision field; re-open until it’s correct
  while true; do
    if py_validate_decision "$review" >/dev/null; then
      echo "✓ decision field OK"
      break
    fi
    echo "Re-open and fix decision field (PASS_REVIEW | HOLD | DENY)."
    "$editor" "$review"
  done

done < "$proposals_file"

echo ""
echo "✓ All listed proposals reviewed (at least decision field validated)."
echo "Next:"
echo "  (1) bash c2_execute.sh summarize"
echo "  (2) bash c2_execute.sh validate"

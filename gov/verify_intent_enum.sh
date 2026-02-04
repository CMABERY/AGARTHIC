#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENUM="$ROOT/gov/intent_enum.v1.txt"

die(){ echo "DENY: $*" >&2; exit 2; }

[ -f "$ENUM" ] || die "missing canonical enum: $ENUM"

canon_sorted="$(sort -u "$ENUM" | tr -d '\r')"
[ -n "$canon_sorted" ] || die "canonical enum is empty"

# Scripts expected to encode intent names somewhere (current reality)
scripts=(
  "$ROOT/c2_review_loop.sh"
  "$ROOT/c2_execute.sh"
  "$ROOT/c2_batch.sh"
)

extract_intents() {
  local f="$1"
  # Extract tokens that match *_PROPOSE (simple, robust)
  grep -oE '[A-Z0-9_]+_PROPOSE' "$f" 2>/dev/null | sort -u || true
}

for s in "${scripts[@]}"; do
  [ -f "$s" ] || die "missing script: $s"
  got="$(extract_intents "$s")"
  if [ -z "$got" ]; then
    die "no intent tokens found in $s"
  fi
  if [ "$got" != "$canon_sorted" ]; then
    echo "✗ enum mismatch: $s" >&2
    echo "  canon:" >&2
    echo "$canon_sorted" | sed 's/^/    /' >&2
    echo "  found:" >&2
    echo "$got" | sed 's/^/    /' >&2
    exit 2
  fi
  echo "✓ $s matches canonical enum"
done

# Produce a reproducible hash from the canonical artifact itself (Tier-1-able)
hash="$(printf "%s\n" $canon_sorted | sha256sum | awk '{print $1}')"
echo "✓ canonical enum hash: $hash"

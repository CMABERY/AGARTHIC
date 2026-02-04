# DRIFT LEDGER
As-of: 2026-02-04 | Session: 3 | Branch: v4.3-doc-fix-flat-bundle

## DRIFT-001 — HGHP C-5 closure contradiction
Status: OPEN
Detected: Session 1
Claimed: C-5 marked OPEN while document asserts all six conditions met.
Impact: HGHP-v1 closure status indeterminate until C-5 resolved.
Resolution: Supply updated S1.4 artifact (verification Item A).

## DRIFT-002 — Version pointer mismatch (v2.1 vs v2.2)
Status: OPEN
Detected: Session 1
Impact: LOW. Ambiguous which version is authoritative.
Resolution: Pick one version, update all references, commit.

## DRIFT-003 — No single authoritative open-items register
Status: OPEN (partially addressed by OPEN_ITEMS.md)
Detected: Session 1
Impact: MEDIUM. Items can be silently dropped across sessions.
Resolution: Maintain gov/OPEN_ITEMS.md as single source.

## DRIFT-004 — Enum triple-coupling not implemented
Status: RESOLVED
Detected: Session 1
Claimed: Schema/handler/TS triple-coupling enforces enum consistency.
Observed: Enum shell-only. No schema artifact. No TS references.
Resolution: Created gov/intent_enum.v1.txt + gov/verify_intent_enum.sh (ad2f59b).
Non-claims: Schema and TS enforcement NOT implemented. Triple-coupling withdrawn.
Residual: FORGE prose replacement has no committable target. See FORGE_PENDING.md.

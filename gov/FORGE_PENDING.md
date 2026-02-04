# FORGE PENDING PATCHES
As-of: 2026-02-04 | Session: 3

Patches here have been agreed but cannot be applied because
their target documents are not in the repo.

Rule: When a FORGE patch is agreed in-session, either commit it
before session end or record it here. No chat-only corrections.

## PATCH-001 — Triple-coupling to shell-canonical
Agreed: Session 1
Infrastructure committed: Session 3 (ad2f59b)
Prose replacement: NOT APPLIED — target docs not in repo

Search for: triple-coupling, triple_coupling, enum.*coupl

Replace with:
  Enum enforcement (shell-canonical):
  - Canonical source: gov/intent_enum.v1.txt
  - Mechanical verifier: gov/verify_intent_enum.sh
  - Verified hash: b21c33c1...00b8
  - Scope: Shell-layer enforcement only.
    NOT implemented: schema-based or TypeScript-layer enforcement.
    The original triple-coupling claim is withdrawn.

Constraints: No softening. This is a retraction, not a reframing.
Blocked until target documents are under version control.

# OPEN ITEMS REGISTER
As-of: 2026-02-04 | Session: 3 | Branch: v4.3-doc-fix-flat-bundle
This is the single authoritative register of open governance items.

## Active

ECT — ECT-v1 Binding Verification
  Priority: MEDIUM (conditional)
  Condition: Only if executor automation is active.
  Closure: Verify contract_binding.json matches live executors, or close N/A.

PKG — Evidence Portability
  Priority: LOW
  Condition: Only if external adoption is a goal.
  Closure: Document evidence conventions, or close N/A.

## Recently Closed

#7    Governance persistence & patchability  2026-02-04  commits 33feee3,127aa28 (material closure: kernel+arch+HGHP in gov/)
C-2   Historical validation          2026-02-04  Session 2
#2    Exit-code capture              2026-02-04  Session 2
#9    pipefail in Make targets       2026-02-04  Session 2
DRIFT-004  Enum coupling overclaim   2026-02-04  Session 3
PATCH-001  Architecture triple-coupling withdrawn   2026-02-04  commit 36e44b4
PATCH-002  HGHP S1.4 coupling claims withdrawn      2026-02-04  commit 8d0b349
DRIFT-001  C-5 contradiction resolved (HGHP v2.2)   2026-02-04  commit 87b9b6d
DRIFT-005  HGHP coupling conflict resolved          2026-02-04  commit 0f09674

### Recently closed (this session)
- **#10 language calibration** — CLOSED (cca143c). Sweep found one actionable overclaim in Architecture doc line 6180; scoped with governance boundary qualifier.
- **CHECKPOINT condensed-vs-full** — DECIDED: keep condensed. Structurally complete, more context-efficient. No replacement needed.

### Recently closed (protocol import session)
- **Protocol imports** — CLOSED (7/7 committed). FORGE f3f836b, CHECKPOINT fceca53, DECIDE c046be3, FAULT ed51a5e, ALIGN ca01c19, GAUGE 51cf8ff, BOOT 8c0d9eb.
- **v2.0 provenance decision** — DECIDED: retain CHECKPOINT-v2.0.md and DECIDE-v2.0.md as lineage provenance. No removal.

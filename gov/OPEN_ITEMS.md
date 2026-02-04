# OPEN ITEMS REGISTER
As-of: 2026-02-04 | Session: 3 | Branch: v4.3-doc-fix-flat-bundle
This is the single authoritative register of open governance items.

## Active

#7 Documentation Freshness Discipline
  Priority: HIGH (upgraded from MEDIUM, Session 3)
  Blast radius: Compounds every session
  Coupled with: #10
  Problem: Governance docs historically lived only in chat history; now imported into repo. Remaining work is mechanical freshness checks + ongoing calibration.
  Closure: Docs committed to gov/, mechanical freshness check, FORGE_PENDING rule.

#10 Language Calibration
  Priority: MEDIUM
  Coupled with: #7
  Problem: Strong claims (e.g. "structurally impossible") stated without evidence tier.
  Closure: Every strong claim gets evidence-tier annotation. Address inside #7.

ECT — ECT-v1 Binding Verification
  Priority: MEDIUM (conditional)
  Condition: Only if executor automation is active.
  Closure: Verify contract_binding.json matches live executors, or close N/A.

PKG — Evidence Portability
  Priority: LOW
  Condition: Only if external adoption is a goal.
  Closure: Document evidence conventions, or close N/A.

## Recently Closed

C-2   Historical validation          2026-02-04  Session 2
#2    Exit-code capture              2026-02-04  Session 2
#9    pipefail in Make targets       2026-02-04  Session 2
DRIFT-004  Enum coupling overclaim   2026-02-04  Session 3
PATCH-001  Architecture triple-coupling withdrawn   2026-02-04  commit 36e44b4
PATCH-002  HGHP S1.4 coupling claims withdrawn      2026-02-04  commit 8d0b349
DRIFT-001  C-5 contradiction resolved (HGHP v2.2)   2026-02-04  commit 87b9b6d
DRIFT-005  HGHP coupling conflict resolved          2026-02-04  commit 0f09674

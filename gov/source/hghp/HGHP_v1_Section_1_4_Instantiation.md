# HGHP-v1 §1.4 Instantiation — Intent→Tier→Checks Matrix

**Document ID:** HGHP-v1-S1.4  
**Status:** SCAFFOLD — awaiting authoritative intent-type enum  
**Parent:** Human-Gate Hardening Pack v1 (HGHP-v1)  
**Completion gate:** This scaffold reaches INSTANTIATED when every row in the enum section is populated and no `[PLACEHOLDER]` markers remain.  
**Fail-closed posture:** Any intent type not present in this matrix is NOT REVIEWABLE. Proposals of unlisted types are HELD until the matrix is populated. This is the §1.4 rule applied structurally.

---

## 0. How to Use This Document

### For the operator (you, now):

1. Run the extraction command in §A below against your GCP repo.
2. For each intent type returned, add a row to the **Intent Registry** (§2).
3. For each row, assign tier, required checks, disqualifiers, and escalation rules using the guidance in §1.
4. Remove all `[PLACEHOLDER]` markers.
5. This document is then the **authoritative reviewer reference** for HGHP-v1 closure condition C-1.

### For the reviewer (during operation):

1. Look up the proposal's declared `intent_type` in §2.
2. If the intent type is not listed → HOLD (do not review; do not reject; escalate to operator).
3. If listed → apply the universal checks (HGHP-v1 §1.1), then apply the intent-specific checks in the row.
4. Tier assignment follows the row's pre-classification unless reviewer judgment escalates (never de-escalates).

---

## 1. Classification Guidance (How to Assign Each Row)

### 1.1 Tier Pre-Classification Rules

| Condition | Tier Floor | Rationale |
|---|---|---|
| Payload modifies only data within an existing governed boundary; fully reversible; precedented | T1 | Routine: bounded, undoable, seen before |
| Payload modifies configuration, touches new files, or is first-of-kind | T2 | Elevated: expanded blast radius or no precedent baseline |
| Payload modifies governance surfaces (schemas, handlers, executors, governance docs, canon artifacts, this rubric) | T3 | Critical: authority-expanding by definition (HGHP-v1 §2.4) |
| Payload is irreversible (cannot be rolled back without cascading state consequences) | T2 minimum | Irreversibility overrides routine classification |
| Payload crosses a named boundary (e.g., outbound egress, cross-kernel action) | T3 | Boundary-crossing is authority-expanding |
| Reviewer is uncertain about any universal check for this intent type | T2 minimum | Uncertainty escalates, never de-escalates |

### 1.2 Required Checks (Intent-Specific — What to Inspect Beyond Universals)

For each intent type, define:

| Field | What to specify | Why |
|---|---|---|
| **Payload fields to inspect** | The specific fields the reviewer must read and evaluate for this intent type | Not all fields are equal; some carry authority implications |
| **Semantic invariants** | Relationships between fields that must hold (e.g., "target must be within governed boundary," "hash must match content") | Catches payloads where individual fields look fine but composition is wrong |
| **Downstream execution trace** | What happens *after* this proposal is executed — what does the result enable? | Defends against AE-07 (schema-valid semantic bomb) |
| **Precedent baseline** | Reference to a previously approved proposal of this type + its scope | Defends against AE-05 (precedent hijack) and AE-02 (incremental ratchet) |
| **Max payload size** | Reviewer comprehension bound (lines of diff, files touched, parameters changed) | Enforces DQ-5; intent types with large blast radius need lower thresholds |

### 1.3 Disqualifiers (Intent-Specific — Additions to Global DQ-1 through DQ-6)

Each intent type may define additional automatic rejection triggers beyond the six universal disqualifiers. These are additive (global disqualifiers always apply).

Common intent-specific disqualifier patterns:
- **Scope escape:** payload targets files/paths outside the expected domain for this intent type
- **Authority smuggling:** payload structurally encodes an authority expansion but is typed as a non-governance intent
- **Hash mismatch:** for intents that reference content by hash, any discrepancy between declared and computed hash
- **Egress claim:** for intents not authorized for outbound data, any payload field that implies egress

---

## 2. Intent Registry (THE MATRIX — Populate From Enum)

### 2.1 Provisional Entries (Corpus-Derived)

These entries are derived from what the sealed corpus reveals. They are provisional until confirmed against the authoritative enum. If any provisional entry does not match the actual enum, it must be corrected or removed — never carried as assumed-correct.

---

#### Intent: `[INVOICE_RECONCILE_PROPOSE or actual name from enum]`

| Attribute | Value |
|---|---|
| **Source** | Integration proof (9B-9 full lifecycle test: CONSUMED_SUCCESS) |
| **Pre-classified tier** | T1 if: inputs hash-bound, no new authority surface, reversible, and precedented. T2 if: first-of-kind or touches configuration. |
| **Payload fields to inspect** | `[PLACEHOLDER — populate from schema: e.g., target_id, input_hashes, claimed_effect]` |
| **Semantic invariants** | Input references must resolve to existing governed artifacts. Claimed effect must be bounded and reversible. No new file creation outside governed output directory. |
| **Downstream execution trace** | Reconciled invoice state written to governed ledger. Verify: does the reconciled state enable any subsequent action that would not have been possible before? If yes → T2 minimum. |
| **Precedent baseline** | 9B-9 is the first proven lifecycle (reference: CONF-9B-9 / CONSUMED_SUCCESS). Subsequent proposals of this type must not exceed 9B-9's scope without tier escalation. |
| **Max payload size** | `[PLACEHOLDER — set based on typical payload; recommend ≤30 lines for T1]` |
| **Intent-specific disqualifiers** | Any outbound egress claim. Any schema extension embedded in payload. Urgency language (global DQ-6 reinforced). |

---

#### Intent: `[GOVERNANCE_CHANGE or actual name from enum]`

| Attribute | Value |
|---|---|
| **Source** | Kernel invariant I-5 (self-governing change control); HGHP-v1 §2.4 |
| **Pre-classified tier** | **T3 — always.** No exceptions. This is the procedural expression of I-5. |
| **Payload fields to inspect** | `[PLACEHOLDER — all fields: schema diffs, handler diffs, executor interface changes, governance doc edits]` |
| **Semantic invariants** | Every modified surface must be explicitly listed in the proposal. No "also changes X" discovered during review. Diff must be complete and self-contained. Re-proof obligation must be named for every modified surface. |
| **Downstream execution trace** | What authority surface changes after execution? Trace forward: does any new intent type, executor path, or schema field become available? If yes, require re-proof evidence as a post-execution condition. |
| **Precedent baseline** | Each governance change is inherently first-of-kind (the thing it changes did not previously exist in its new form). No precedent relaxation applies. |
| **Max payload size** | `[PLACEHOLDER — recommend strict: ≤20 lines of diff per modified surface, ≤3 surfaces per proposal; decompose if larger]` |
| **Intent-specific disqualifiers** | "Minor tweak" framing for any authority surface change (AE-01 defense). Bundling governance change with non-governance work (DQ-4 reinforced). Missing re-proof obligation statement. Missing change-record reference. |

---

#### Intent: `[EVIDENCE_INGEST or actual name from enum]`

| Attribute | Value |
|---|---|
| **Source** | Kernel invariant I-4 (evidence as custody); CAS pipeline (evidence/put.py) |
| **Pre-classified tier** | T2 (evidence is append-only and hash-bound, but fabricated evidence is a proven threat class — requires elevated scrutiny). T3 if evidence pertains to a governance-change execution. |
| **Payload fields to inspect** | `[PLACEHOLDER — e.g., evidence_hash, source_execution_token, cas_path, content_type]` |
| **Semantic invariants** | Declared hash must match computed hash of artifact content. Source execution token must be in CONSUMED_SUCCESS state (evidence follows execution, not the reverse). CAS path must be within governed evidence boundary. |
| **Downstream execution trace** | Ingested evidence becomes Tier-1 truth material. Verify: does this evidence, once ingested, change the pass/fail status of any verification target? If yes → T3. |
| **Precedent baseline** | `[PLACEHOLDER — first evidence ingest with full CAS trace becomes the baseline]` |
| **Max payload size** | `[PLACEHOLDER — evidence payloads vary; set per content-type: e.g., ≤100KB for structured data, ≤5MB for binary artifacts]` |
| **Intent-specific disqualifiers** | Evidence without computable hash. Evidence referencing a token not in CONSUMED_SUCCESS state. Evidence hash mismatch between declaration and computation. Evidence targeting a CAS path outside the governed boundary. |

---

### 2.2 Template for New Intent Types

Copy this template for each additional intent type in your enum. **Every intent type must have a row. No exceptions.** An intent type without a row is not reviewable — proposals of that type are HELD.

```
#### Intent: `[EXACT_ENUM_VALUE]`

| Attribute | Value |
|---|---|
| **Source** | [Where this intent type is defined: schema file, handler allowlist, TS enum] |
| **Pre-classified tier** | [T1 | T2 | T3] + conditions for escalation |
| **Payload fields to inspect** | [List every field the reviewer must read] |
| **Semantic invariants** | [Relationships between fields that must hold] |
| **Downstream execution trace** | [What does execution enable beyond the immediate effect?] |
| **Precedent baseline** | [Reference to prior approved proposals of this type, or "first-of-kind"] |
| **Max payload size** | [Reviewer comprehension bound for this intent type] |
| **Intent-specific disqualifiers** | [Additive rejection triggers beyond DQ-1–DQ-6] |
```

---

### 2.3 Enum Coverage Checklist

When the authoritative enum is provided, verify completeness:

```
ENUM COVERAGE VERIFICATION
===========================
Date:           [ISO 8601]
Enum source:    [file path + hash]
Total intents:  [count from enum]
Matrix rows:    [count in §2]
Coverage:       [total == rows? YES/NO]
Unlisted:       [list any enum values without a matrix row — these are HELD]
Deprecated:     [list any matrix rows for enum values no longer active]
Verified by:    [operator ID]
```

**Coverage must be 100% for HGHP-v1 closure condition C-1.** Partial coverage means HGHP-v1 is not closeable.

---

## 3. Scope Ledger Initialization

The scope ledger (HGHP-v1 §4.2 defense against AE-02: Incremental Ratchet) tracks the running authority surface. Initialize it here when the enum is populated.

```
SCOPE LEDGER — v0 (initialized [DATE])
=======================================
Active intent types:      [list]
Active executors:         [list, from execute_invoice.py and peers]
Active schema fields:     [per intent type: list of payload fields]
Governance surfaces:      [list of files/artifacts classified as T3-triggering]
Last T3 approval:         [NONE — no T3 proposals reviewed yet]
Ledger hash:              [SHA-256 of this section after population]
```

Update trigger: any T3-classified proposal approval must be reflected in the ledger within 24 hours (HGHP-v1 §5.1, C-6).

---

## 4. C-2 / C-3 Execution Plan (Historical Replay + Consistency Test)

Once the matrix is instantiated (§2 fully populated), these two closure conditions can be executed:

### 4.1 C-2: Historical Validation (≥10 proposals)

**Protocol:**

1. Collect ≥10 historical proposals from `proposals_out/` (or the approval log, if proposals are archived).
2. For each proposal, apply the instantiated rubric as if reviewing for the first time:
   a. Run universal checks UC-1 through UC-8.
   b. Look up intent type in §2; apply intent-specific checks.
   c. Assign tier (T1/T2/T3).
   d. Record decision: APPROVED or REJECTED.
3. Compare rubric-produced decision against the original decision.
4. For each agreement: record as CALIBRATED.
5. For each disagreement: record the specific check that diverged and write a one-paragraph rationale explaining whether the rubric caught something the original review missed, or the rubric is miscalibrated and needs refinement.

**Completion evidence:**

```
C-2 HISTORICAL VALIDATION
===========================
Date:                [ISO 8601]
Proposals reviewed:  [count, ≥10]
Agreements:          [count]
Disagreements:       [count]
Disagreement details: [for each: proposal ID, original decision, rubric decision, divergent check, rationale]
Rubric refinements:  [list any §2 changes made as a result]
Validator:           [reviewer ID]
```

**Pass criterion:** Completed with all disagreements documented and rationalized. There is no minimum agreement percentage for C-2 — the goal is calibration, not confirmation. If the rubric disagrees with many historical decisions, that is valuable signal, not failure.

### 4.2 C-3: Two-Reviewer Consistency Test (5 proposals)

**Protocol:**

1. Select 5 proposals: a mix of at least one per tier (T1, T2, T3) and at least one historical rejection.
2. Two independent reviewers apply the rubric to all 5 proposals without conferring.
3. Each reviewer records: tier classification + APPROVED/REJECTED + rationale.
4. Decisions are revealed simultaneously.
5. Score agreement:
   - Tier match: same tier assigned → AGREE
   - Decision match: same APPROVED/REJECTED → AGREE
   - Per-proposal score: tier AGREE + decision AGREE = FULL MATCH; one mismatch = PARTIAL; both mismatch = DIVERGENT

**Completion evidence:**

```
C-3 CONSISTENCY TEST
======================
Date:                 [ISO 8601]
Proposals tested:     [5, with IDs]
Reviewer A:           [ID]
Reviewer B:           [ID]
Results:
  Proposal 1: Tier [A:Tx / B:Tx] Decision [A:X / B:X] → [FULL MATCH | PARTIAL | DIVERGENT]
  Proposal 2: ...
  Proposal 3: ...
  Proposal 4: ...
  Proposal 5: ...
Full matches:         [count / 5]
Agreement rate:       [full matches / 5 ≥ 80%? YES/NO]
Divergence analysis:  [for each non-full-match: what caused it, rubric refinement if needed]
Rubric refinements:   [list any §2 changes]
```

**Pass criterion:** ≥ 4/5 full matches (80%). If below threshold, refine rubric language on the divergent checks and retest with 5 new proposals. Iterate until threshold is met.

---

## Appendix A: Enum Extraction Command

Run from your GCP repo root:

```bash
# Option 1: ripgrep (fastest)
rg -n --no-heading -S \
  "intent_type|IntentType|ACTION_TYPE|ActionType|allowed_intents|ALLOWED_INTENTS" \
  -g"*.py" -g"*.ts" -g"*.tsx" -g"*.json"

# Option 2: grep (if rg not installed)
grep -rn --include="*.py" --include="*.ts" --include="*.tsx" --include="*.json" \
  -E "intent_type|IntentType|ACTION_TYPE|ActionType|allowed_intents|ALLOWED_INTENTS" .

# Option 3: direct schema dump (if validate_proposal.py has a known list)
python3 -c "
import importlib.util, json
spec = importlib.util.spec_from_file_location('vp', 'validate_proposal.py')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
# Adapt attribute name to your actual validator:
for attr in ['ALLOWED_INTENTS', 'INTENT_TYPES', 'ACTION_TYPES', 'VALID_TYPES']:
    if hasattr(mod, attr):
        print(json.dumps(sorted(getattr(mod, attr)), indent=2))
        break
"
```

Paste the output and I will finalize §2 immediately.

---

*HGHP-v1 §1.4 Instantiation Scaffold. Document ID: HGHP-v1-S1.4. Status: SCAFFOLD — becomes INSTANTIATED when enum is populated and all [PLACEHOLDER] markers are resolved. Fail-closed: unlisted intent types are HELD, not reviewed.*

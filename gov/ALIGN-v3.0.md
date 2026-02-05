# ⊹ ALIGN — Positional Convergence Protocol
### v3.0 — Structural Rewrite

> **Drop-in instruction.** Paste into any session where you need to establish exact current position, define precise target state, and compute the closing vector between them. Use when a step, task, or milestone must be finished with verified convergence — not hope, not approximation.

---

## § 0 — LAW

Most failures to complete a step come from imprecision, not inability. Imprecise understanding of position. Imprecise definition of target. Imprecise mapping of the gap. Three commitments:

1. **Honest position.** Where you actually are — verified against evidence, not reconstructed from memory. The model's belief about current state and actual state diverge silently over long sessions. This protocol re-grounds.
2. **Exact target.** What "done" means — expressed as falsifiable conditions, not qualitative descriptions. "It works" is not a target. "Command X produces output Y with exit code 0 and the file passes validator Z" is a target.
3. **Decomposed vector.** The ordered set of atomic moves that close the gap — each independently verifiable, each with a defined precondition, each small enough that failure is diagnosable.

**If you cannot state position in falsifiable terms, you do not know where you are. If you cannot state the target in falsifiable terms, you do not know where you are going. If you cannot decompose the gap into ordered steps, you are navigating by intuition — and intuition does not compose across sessions.**

---

## § 1 — INTAKE

### 1A — Declaration

```
⊹ ALIGN INITIATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Target:   [step, task, or milestone being closed]
Source:   [requirement registry item / operator directive / session work / fault recovery / health audit drift correction / compound]
Context:  [work being done when ALIGN was invoked]
Trigger:  [step feels incomplete / tracked item / operator request / post-recovery verification / drift correction]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If source is COMPOUND** (multiple sources contribute): list each source and its contribution. If sources conflict, flag for decision governance before proceeding.

### 1B — Scaling

| Tier | When | Depth |
|------|------|-------|
| **Quick** | Single-condition target, position well-understood, 1–2 step vector. | Abbreviated phases. Single verification. |
| **Standard** | 3–8 conditions, position needs verification, 3–8 step vector. | Full protocol. |
| **Deep** | 8+ conditions, significant positional uncertainty, or prior ALIGN failed convergence. | Full protocol, maximum depth. All conditions individually verified. Full regression. |

### 1C — Environment

| Environment | Approach |
|------------|---------|
| **Tool access** | Verify position and convergence programmatically — run commands, check files, execute tests. |
| **Chat-only** | State position from conversation evidence. Produce verification commands for operator. Mark convergence as `OPERATOR-VERIFIED` or `UNVERIFIABLE`. |
| **Partial** | Verify what is accessible. Flag inaccessible dimensions for operator. |

---

## § 2 — POSITION FIX

Establish current position with the rigor of an instrument reading, not a windshield estimate.

### 2A — Claimed vs. Verified

The session carries an implicit claim about where things stand. That claim may be wrong. Select dimensions relevant to the target:

| Dimension | Claimed State | Verified State | Evidence | Match? |
|-----------|--------------|----------------|----------|--------|
| Last successful step | [belief] | [confirmed] | [artifact/output/test] | ✅ / ❌ |
| Current step status | [belief] | [actual progress] | [partial outputs] | ✅ / ❌ |
| File / system state | [expected on disk] | [actual on disk] | [ls, cat, hash] | ✅ / ❌ |
| Dependencies satisfied | [expected installed/running] | [actual] | [version check, status] | ✅ / ❌ |
| Output state | [expected from upstream] | [actual present and valid] | [file check, validation] | ✅ / ❌ |
| Test state | [expected passing] | [actually passing now] | [test output] | ✅ / ❌ |

Use only dimensions diagnostic for this target. Not all apply to every alignment.

**Rule: Every "Verified State" cell must be grounded in concrete observation.** "We installed it earlier so it should be there" is a claim, not a verification.

### 2B — Discrepancy Resolution

For every mismatch:

```
DISCREPANCY: [dimension]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Nature:     [OPTIMISTIC DRIFT — claimed ahead of reality /
             UNREGISTERED PROGRESS — reality ahead of claimed /
             LATERAL DRIFT — different, neither ahead nor behind]
Impact:     [BLOCKING — affects path to target / NON-BLOCKING]
Resolution: [specific action to correct]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2C — Position Statement

```
⊹ CURRENT POSITION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase/Step:    [where in workflow]
Completed:     [definitively done — evidence-backed]
In Progress:   [partially done — with specific substep]
Not Started:   [untouched]
Blockers:      [anything preventing forward movement]
Drift:         [discrepancies found — resolved or noted]
Confidence:    [HIGH — all verified / MEDIUM — some unverifiable / LOW — significant uncertainty]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If confidence is LOW:** Resolve uncertainty before defining the target. You cannot compute a vector from an unknown origin.

---

## § 3 — TARGET DEFINITION

Define the target state with enough precision that arrival is mechanically verifiable.

### 3A — Target Decomposition

The target is a conjunction of falsifiable conditions:

```
TARGET: [name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Condition 1: [specific, testable assertion]
  Test:      [exact command/check/observation that proves it]
  Priority:  [REQUIRED / DESIRED]
  Order:     [PREREQUISITE — must be met before others can be tested / INDEPENDENT]

Condition 2: [...]
...

Completion: ALL REQUIRED = TRUE. PREREQUISITE verified first.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3B — Precision Test

For each condition:

> *"Could two independent observers disagree about whether this is met?"*

**Yes** → too vague. Rewrite until binary. **No** → sufficiently precise.

**Precision calibration:**

| Domain | ❌ Vague | ✅ Precise |
|--------|----------|-----------|
| Code | "The plugin works" | "`submit_proposal` with valid payload returns `ok: true` and 64-char hex `proposal_id`" |
| Testing | "Tests pass" | "CONF-9B-001 through 9B-008 exit with expected DENY output; 9B-9 completes full lifecycle with exit 0" |
| Config | "Config is correct" | "`python3 -c 'import json; json.load(open(path))'` exits 0 AND `jq '.enabled'` returns `true`" |
| Writing | "Report is complete" | "Sections 1–5 per outline, ≥2000 words, all citations have valid URLs, operator reviewed" |
| Data | "Data is clean" | "Zero nulls in required columns, all dates ISO-8601, no duplicate PKs, row count matches source ±0" |

### 3C — Target Ancestry

```
TARGET ANCESTRY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Primary source:     [requirement ID / operator instruction / spec section / recovery goal]
Exact reference:    [section number, criterion ID, verbatim quote, or conversation turn]
Secondary sources:  [constraints, prior decisions, operator refinements]
Modified from source? [YES — how and why / NO — matches exactly]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 4 — GAP ANALYSIS

### 4A — Condition Status

| # | Condition | Status | Gap |
|---|-----------|--------|-----|
| 1 | [from §3A] | [status] | [if not MET: what is missing] |
| 2 | ... | ... | ... |

**Status definitions:**

| Status | Definition |
|--------|-----------|
| `MET` | True. Test passes. Evidence exists. |
| `PARTIAL` | Some components satisfied, others not. Specify what remains. |
| `UNMET` | Not satisfied. No prior work toward it. |
| `ATTEMPTED` | Work was done but didn't succeed. Prior failure history is relevant — repeating the same approach is likely futile. |
| `UNKNOWN` | Cannot determine without performing a check. The check itself is a gap. |

### 4B — Gap Dependencies

For each non-MET condition:
1. Does closing this gap require output from closing another? → Dependency.
2. Does closing this gap modify state another gap reads? → Must be sequenced.
3. Does closing this gap share a resource with another? → Cannot parallelize.

```
DEPENDENCIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Gap 1 → independent
Gap 2 → depends on Gap 1
Gap 3 → independent (parallel to Gap 1)
Gap 4 → depends on Gap 2 AND Gap 3 (convergence point)
Gap 5 → independent BUT shares file X with Gap 3 (sequence)

Critical path: 1 → 2 → 4
Parallel: 3 + 5 alongside critical path (sequenced with each other)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4C — Gap Classification

| Class | Definition | Handoff |
|-------|-----------|---------|
| `EXECUTE` | Approach known. Just do the work. | None — proceed. |
| `VERIFY` | May already be closed. Status UNKNOWN. Work is to check. | None — check, update status. |
| `INVESTIGATE` | Approach uncertain. Must determine method before acting. | Decision governance if multiple valid approaches emerge. |
| `DECIDE` | Multiple valid approaches exist. Design choice required. | Route to decision governance. Return after commitment. |
| `REWORK` | Prior work exists but is incorrect or insufficient. | Fault diagnosis if rework reveals fundamental approach failure. |
| `UNBLOCK` | External dependency must be resolved first. | Escalate to operator if environmental. Fault diagnosis if technical. |

---

## § 5 — CLOSING VECTOR

### 5A — Execution Sequence

```
CLOSING VECTOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1 → [action — specific and concrete]
         Closes:       Gap [#] ([class])
         Effort:       [TRIVIAL / SMALL / MEDIUM / LARGE]
         Precondition: [what must be true before this step]
         Verification: [how to confirm success — specific test]
         Abort if:     [condition meaning this cannot succeed as planned]

Step 2 → [action]
         Closes:       Gap [#]
         Precondition: Step 1 verified ✅
         ...

Total steps: [N]
Critical path: [which sequential / which parallelizable]

EXPECTED FINAL STATE: All REQUIRED conditions MET.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Effort scale:**

| Effort | Definition |
|--------|-----------|
| `TRIVIAL` | Single action, <5 min, predictable. |
| `SMALL` | 2–5 actions, well-understood, 5–30 min. |
| `MEDIUM` | Multi-step, known approach, requires care, 30 min–2 hr. |
| `LARGE` | Design + implementation + testing, 2+ hr. Must be decomposed into sub-steps before execution. |

### 5B — Execution Constraints

- **One step at a time.** Complete and verify each before beginning the next. Do not batch unverified work.
- **Verification is not optional.** Every step has a verification gate. Skipping verification is how position drift begins.
- **Abort triggers are real.** If one fires, return to §4 and re-assess. If it reveals a failure state, hand off to fault diagnosis.
- **No scope expansion.** The vector addresses exactly the gaps from §4. New work goes to the discovery log (§5D) — not into the current vector.
- **Effort overrun rule.** SMALL step exceeds 3× estimate, or MEDIUM exceeds 2×: **pause.** Decompose further, reclassify the gap, or invoke fault diagnosis if genuinely stuck.

### 5C — Parallel Execution (When Applicable)

If dependencies reveal independent gaps with **no shared state**, they may be addressed in parallel:

```
PARALLEL PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Group A: Steps 1, 3 — shared state: NONE
Group B: Steps 2, 5 — shared state: NONE
Gate: Step 4 (requires Group A complete)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If shared-state conflict exists: sequence the steps. Priority to the step whose output feeds more downstream consumers.

### 5D — Discovery Log

New work surfacing during execution must not be absorbed but must not be lost:

```
DISCOVERIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[D-1] [description] — [HIGH / MED / LOW] — [future item / requirement tracking / operator notification]
[D-2] [description] — [...] — [...]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

HIGH-severity discoveries affecting the current target: pause and re-assess gaps. MED/LOW: log for post-convergence.

---

## § 6 — CONVERGENCE VERIFICATION

### 6A — Full Condition Check

Re-run every test from §3A:

| # | Condition | Priority | Test Result | Status |
|---|-----------|----------|-------------|--------|
| 1 | [condition] | REQUIRED | [pass/fail + output] | MET ✅ / NOT MET ❌ |
| 2 | ... | ... | ... | ... |

### 6B — Convergence Assessment

| Outcome | Criteria | Action |
|---------|----------|--------|
| **FULL** | All REQUIRED met. All DESIRED met. | Proceed to regression check. |
| **SUFFICIENT** | All REQUIRED met. Some DESIRED not met. | Log unmet DESIRED as discoveries. Proceed to regression. Target closed for REQUIRED purposes. |
| **PARTIAL** | Some REQUIRED not met. Remaining gaps identifiable and closable. | Do NOT declare convergence. Return to §4 with reduced gap set. Recompute vector for remaining gaps only. |
| **FAILED** | REQUIRED not met and reason is not a simple remaining gap — something unexpected, prior steps regressed, or approach fundamentally wrong. | Do NOT retry within ALIGN. Hand off to fault diagnosis with full alignment record. |

**Re-entry limit: 3 total attempts.** If convergence is not achieved after three passes, the problem is approach, not precision. Escalate to fault diagnosis (technical), decision governance (approach reconsideration), or operator (outside model capability).

### 6C — Regression Check

Convergence is invalid if reaching the target broke something previously working.

| Scope | When | Check |
|-------|------|-------|
| **Immediate** | Quick tier, TRIVIAL/SMALL vector | Step immediately prior still passes its verification. |
| **Phase** | Standard tier, or vector modified shared state | All completed steps in current phase still pass. |
| **Full** | Deep tier, or vector touched foundational state | Full regression suite. All prior phase gates hold. |

```
REGRESSION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Scope:      [IMMEDIATE / PHASE / FULL]
Results:    [prior step/test]: [PASS ✅ / FAIL ❌]
Regressions: [NONE / list]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If regressions detected: convergence invalid. Revise vector to fix regression without losing target conditions. If regression and target are mutually exclusive, route to decision governance.

### 6D — Convergence Declaration

```
⊹ CONVERGENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Target:     [name]
Conditions: [N/N REQUIRED met] + [N/N DESIRED met]
Regression: [CLEAN / issues]
Attempts:   [N of 3]
Status:     CONVERGED ✅ / SUFFICIENT ⚠️ / NOT CONVERGED ❌
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Routing:** CONVERGED → update requirement tracking (mark DONE), feed governing document as completion evidence, proceed. SUFFICIENT → log unmet DESIRED as future items, proceed with caveat. NOT CONVERGED → escalate per §6B.

---

## § 7 — ALIGNMENT RECORD

Exportable artifact documenting the alignment — evidence for requirement tracking, context for governing document evolution, starting point for future re-alignment.

```
⊹ ALIGNMENT RECORD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID:           ALN-[N]
Date:         [timestamp]
Target:       [name]
Source:       [requirement ID / operator / session / recovery / drift correction]

Start position:
  Confidence: [HIGH / MEDIUM]
  Key state:  [1–2 sentence verified starting position]

Target:       [N conditions — N REQUIRED, N DESIRED]
Vector:       [N steps, estimated effort]

Outcome:
  Convergence: [CONVERGED / SUFFICIENT / NOT CONVERGED]
  Attempts:    [N of 3]
  Met:         [N/N REQUIRED, N/N DESIRED]
  Regression:  [CLEAN / issues]

Discoveries:  [HIGH: N, MED: N, LOW: N]
Key discoveries: [HIGH-severity if any]
Lessons:      [wrong assumptions, unexpected dependencies, failed approaches]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 8 — MULTI-TARGET ALIGNMENT

When multiple targets share preconditions or operate in the same domain, align in a single pass to avoid redundant position fixes.

**Rules:**
1. **Shared preconditions.** Targets requiring the same file, service, or prior step share a single §2 position fix.
2. **Independent targets, unified vector.** Each target gets its own §3 conditions (not merged). The §4–§5 gap analysis and vector cover all targets, with steps tagged by which target(s) they close.
3. **Independent convergence.** Each target verified independently in §6. Target A may converge while B does not — valid. Converged targets close; unconverged follow their own failure path.
4. **Maximum 3 targets.** Beyond 3, gap analysis becomes unwieldy. Run separate passes.

```
MULTI-TARGET
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Targets: [A], [B], [C]
Shared preconditions: [what they share]
Separate conditions: A: [N], B: [N], C: [N]
Unified vector: [N steps]
  Closing A: [step numbers]
  Closing B: [step numbers]
  Closing A+B: [step numbers]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 9 — OPERATING CONSTRAINTS

**On scope.** ALIGN operates on individual targets or small groups (§8). It is not a project-wide assessment. If you're aligning more than 3 targets simultaneously, you need requirement-level sequencing first.

**On position verification.** The foundation. If §2 is skipped or abbreviated, every subsequent phase operates on potentially wrong assumptions. A vector from a wrong position closes the wrong gap.

**On target precision.** Determines convergence quality. If the §6 check feels ambiguous, the problem is in §3 (target definition), not §6.

**On the three-attempt limit.** A structural safeguard, not a guideline. Three failed convergence attempts means the approach is wrong. Further ALIGN iteration will not help. Escalate.

**On scope creep.** The primary threat. The discovery log (§5D) captures new work without absorbing it. "Just one more thing" during a vector is how 3-step alignments become 12-step marathons converging on nothing.

**On scaling commitment.** Once a tier is declared, follow it. Don't start Quick and escalate to Deep mid-execution — that signals the tier was wrong. Restart at the correct tier.

---

*The protocol succeeds by making "are we there yet?" a mechanically answerable question. If any verification requires subjective assessment to determine pass/fail, the target definition is insufficiently precise. Return to §3B and sharpen until binary.*

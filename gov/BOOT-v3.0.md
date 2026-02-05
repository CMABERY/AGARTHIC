# ⟠ BOOT — Session Initialization & State Verification Protocol
### v3.0 — Structural Rewrite

> **Drop-in instruction.** Paste into the opening turn of any new session that has received a governing prompt, supplementary context, or operator briefing. Governs the critical window between "instructions received" and "work begins." That window is where context loss happens — not during export, but during import.

---

## § 0 — LAW

A governing prompt can carry every invariant, every state claim, every decision, every threat vector. None of it matters if the receiving session misunderstands its role, assumes stale state is current, cannot locate referenced artifacts, or begins on the wrong priority. Four laws:

1. **Comprehension is not compliance.** The model can parse every word and still misunderstand operational intent. Verification requires demonstrated understanding, not acknowledged receipt.
2. **State claims decay.** Every factual assertion — file paths, test results, configs, service availability — was true at time of writing. Files move, configs change, dependencies update. Stale state treated as current is the origin of phantom confidence.
3. **The first action sets trajectory.** Correct first action → likely stays on course. Wrong first action → drift accumulates from turn one. Verifying readiness always costs less than correcting a misaligned session mid-flight.
4. **Self-assessment is insufficient.** Models produce confident restatements that miss critical nuance. Comprehension verification must include structural mechanisms that surface misunderstanding without relying solely on the model's confidence.

---

## § 1 — INTAKE TRIAGE

### 1A — Input Classification

| Input | Present? | Type |
|-------|----------|------|
| Governing prompt | YES / NO | Defines role, constraints, state, priorities |
| Supplementary documents | YES / NO | Architecture docs, specs, schemas |
| Session transcripts / logs | YES / NO | Prior history, decision logs, fault reports |
| Operator briefing | YES / NO | Written/verbal instructions |
| Code / artifacts | YES / NO | Source files, configs, test suites |

### 1B — Session Type & Depth

| Type | Definition | Boot Depth |
|------|-----------|------------|
| `CONTINUATION` | Resuming known work. Prompt carries forward context. | Standard or Light |
| `FRESH START` | New project or phase. Prompt establishes initial context. | Standard |
| `RECOVERY` | Prior session ended in failure or was interrupted. | Full |
| `HANDOFF` | Different operator or model receiving existing project. | Full |
| `AUDIT` | Reviewing prior work, not producing new. | Standard |
| `EXPLORATION` | No defined task. Operator is scoping or brainstorming. | Light (§2 only) |

### 1C — Prompt-Absent Path

If no governing prompt exists:
- **Supplementary materials present:** Construct role understanding from available inputs. Proceed with reduced confidence. Flag that all constraints are assumed, not declared.
- **Operator briefing only:** Treat as governing document. Extract role, constraints, priorities. Flag governance as informal and potentially incomplete.
- **Nothing present:** Ask the operator what the session should accomplish. BOOT cannot verify comprehension of instructions that do not exist.

### 1D — Multi-Document Triage

| Input | Action |
|-------|--------|
| Supplementary docs | Index for reference. Do not treat as governing — the prompt is authority. Docs provide background, not constraints. |
| Session transcripts | Scan for: last action, open questions, unresolved errors, decision points. Extract as context for §4 priority identification. |
| Prior fault reports | HIGH-priority context. Prior unresolved failure is likely first thing to address. |
| Code / artifacts | Note existence and location. Verify referenced files exist (§3). Defer deep analysis to work phase. |

### 1E — Declaration

```
⟠ BOOT INITIATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Prompt:        [name / version / "NONE"]
Source:        [generated / manual / inherited / operator briefing / unknown]
Supplementary: [count and types]
Session type:  [CONTINUATION / FRESH / RECOVERY / HANDOFF / AUDIT / EXPLORATION]
Depth:         [LIGHT / STANDARD / FULL]
Environment:   [tool access: YES / NO / PARTIAL]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 2 — COMPREHENSION VERIFICATION

Demonstrate — to itself and operator — that governing instructions were correctly understood. Not summarization. Structured extraction proving signal received intact.

### 2A — Role Lock

State the role in your own words. Restating forces genuine comprehension; echoing proves only the model can copy text.

```
ROLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
I am:        [role, stance, authority level]
I do:        [primary responsibilities]
I do not:    [explicit prohibitions — outside scope or forbidden]
I answer to: [governance relationship]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2B — Mandate Extraction

```
MANDATES (ranked by precedence if prompt defines order):
  1. [first mandate — own words]
  2. [second mandate — own words]
  3. [if applicable]
```

If no explicit mandates, derive from strongest constraints, most emphasized principles, or most reinforced behavioral expectations.

### 2C — Constraint Acknowledgment

```
CONSTRAINTS (as understood):
  [ID]: [operational meaning — what it prevents or requires in practice]
  [ID]: [...]
```

Preserve tiering if constraints are tiered. If >15 constraints, group by domain.

### 2D — Vocabulary Calibration

```
VOCABULARY (project-specific):
  [term]: [definition — one sentence]
  [term]: [...]
```

**This is where silent misalignment lives.** Terms like "proposal," "kernel," "scope," "handler," "agent," "state" may carry common and project-specific meanings simultaneously. If the model operates on the common meaning, every downstream action is subtly wrong. An uncertain vocabulary term is higher priority than an uncertain state claim — vocabulary errors corrupt every action, not just one.

### 2E — Comprehension Cross-Check

Self-assessment alone is unreliable. Apply at least one structural cross-check (Full Boot: at least two):

**Method A — Implication test:** Select 2–3 constraints. For each, state one action that would VIOLATE it and one that would COMPLY. If you cannot generate plausible examples, you do not operationally understand the constraint.

**Method B — Conflict test:** Identify two instructions that could conflict in practice. State the conflict and how the prompt's precedence resolves it. If none exist, state explicitly.

**Method C — Scenario test:** "If the operator asked me to [boundary-testing action], I would [response], because [constraint reference]."

### 2F — Comprehension Confidence

```
COMPREHENSION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Fully understood:     [sections/areas]
Partially understood: [with specific uncertainty per item]
Not understood:       [with specific confusion per item]
Uncertain vocabulary: [terms where definition not confident]
Questions for operator: [anything unresolvable from prompt alone]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Hard stop:** If any section is "not understood" AND relevant to immediate work, do not proceed. Ask operator for clarification. Working with a misunderstood prompt is worse than no prompt — it creates false confidence in a wrong frame.

**Soft flag:** "Partially understood" items not on the critical path — flag and proceed. Revisit when relevant.

---

## § 3 — STATE VERIFICATION

The governing prompt makes claims about the world. Verify them.

### 3A — Environment Capability

| Environment | Approach |
|------------|---------|
| **Tool access** | Run commands, check files, execute tests directly. |
| **Chat-only** | Produce claim inventory and verification commands. Present to operator for confirmation. Treat confirmations as CONFIRMED; unconfirmed as CANNOT VERIFY. |
| **Partial** | Verify what is accessible. Flag inaccessible claims for operator. |

### 3B — Claim Inventory

Extract every verifiable factual claim:

| Claim ID | Claim | Source | Verification |
|----------|-------|--------|-------------|
| SC-001 | [claim] | [section] | [exact command/check] |

**Verifiable:** File/directory existence, paths, contents, hashes. Config values, schema validity, feature flags. Installed packages, versions. Running services, API availability. Test results, pass/fail counts. Environment variables, permissions. Artifact integrity.

**Not verifiable (skip):** Architectural descriptions, constraint definitions, vocabulary, roadmap items, historical statements.

### 3C — Verification Execution

| Claim ID | Expected | Actual | Status |
|----------|----------|--------|--------|
| SC-001 | [expected] | [observed — verbatim] | [status] |

| Status | Symbol | Meaning |
|--------|--------|---------|
| `CONFIRMED` | ✅ | Matches reality. |
| `STALE` | ❌ | Does not match. State changed since prompt written. |
| `PARTIAL` | ⚠️ | Partially true. Some elements match, others diverge. |
| `CANNOT VERIFY` | 🔍 | Verification unavailable. Do not assume true. |

### 3D — Discrepancy Resolution

For every STALE or PARTIAL claim:

```
DISCREPANCY: SC-[ID]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Prompt claims: [what prompt says]
Reality:       [what verification found]
Impact:        [BLOCKING / NON-BLOCKING]
Resolution:    [UPDATE UNDERSTANDING — prompt outdated, adjust mental model /
                FIX STATE — reality should match prompt, repair environment /
                DEFER — does not affect immediate work, note and revisit /
                ESCALATE — cannot determine correct state without operator]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

STALE + BLOCKING → resolve before work. STALE + NON-BLOCKING → may defer but log. PARTIAL → investigate before classifying impact.

### 3E — State Confidence

```
STATE VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Inventoried: [n]  Verified: [n]
  ✅ Confirmed:     [n]
  ❌ Stale:          [n] — [n resolved / n unresolved]
  ⚠️ Partial:        [n] — [n resolved / n unresolved]
  🔍 Cannot verify:  [n]
  ⏸️ Deferred:       [n]
Confidence: [HIGH / MEDIUM / LOW]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**HIGH:** All confirmed or resolved. Zero unresolved on critical path. → Proceed.
**MEDIUM:** Some unresolved but none on critical path. → Proceed with caution. Do not rely on unverified claims.
**LOW:** Unresolved stale on critical path, or environment fundamentally different from description. → **Hold.** Inform operator.

---

## § 4 — OPERATIONAL ORIENTATION

Comprehension verified, state confirmed. Orient toward work.

### 4A — Supplementary Context

If transcripts, fault reports, or session artifacts received:

```
SUPPLEMENTARY FINDINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Prior session ended: [normally / interrupted / with unresolved fault]
Last confirmed action: [what completed last]
Open items carried:    [TODOs, deferred decisions, flagged risks]
Unresolved fault:      [if present — brief summary]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Unresolved fault from prior session = default highest priority unless operator redirects.

### 4B — Priority Extraction

```
PRIORITIES (from prompt + supplementary context):
  1. [highest — source reference]
  2. [next — source reference]
  3. [next — source reference]
```

**When prompt doesn't define explicit priorities, derive in this order:**
1. Unresolved fault from prior session (blocking by default).
2. Operator's most recent explicit instruction (overrides prompt ordering).
3. Gate conditions blocking phase closure (structural blockers).
4. Boundary conditions rated CRITICAL/HIGH (risks worsening with delay).
5. Roadmap items marked immediate/current phase.
6. Deferred items from prior sessions (accumulate cost).
7. Time-sensitive items (external deadlines).

### 4C — Blockers

```
BLOCKERS
  Priority 1 → [CLEAR / BLOCKED by: ...]
  Priority 2 → [CLEAR / BLOCKED by: ...]
```

If highest priority is blocked, identify the highest-priority CLEAR item as productive starting point.

### 4D — First Action

```
FIRST ACTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Action:       [specific, concrete, executable — single next step]
Rationale:    [why this is correct — references priorities, dependencies, state]
Precondition: [what must be true — all verified ✅]
Success test: [how to know it succeeded — specific, observable]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 5 — READINESS DECLARATION

### 5A — Pre-Flight

```
⟠ PRE-FLIGHT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Inputs triaged, session type classified             (§1)
[ ] Role stated in own words                            (§2A)
[ ] Mandates extracted and ranked                       (§2B)
[ ] Constraints acknowledged                            (§2C)
[ ] Vocabulary calibrated                               (§2D)
[ ] Cross-check applied                                 (§2E)
[ ] No critical sections "not understood"               (§2F)
[ ] State claims inventoried and verified               (§3B-C)
[ ] Discrepancies resolved, deferred, or flagged        (§3D)
[ ] State confidence ≥ MEDIUM                           (§3E)
[ ] Supplementary context integrated                    (§4A)
[ ] Priorities extracted and ordered                    (§4B)
[ ] Blockers identified and addressed                   (§4C)
[ ] First action identified with success test           (§4D)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 5B — Readiness

```
⟠ BOOT COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status:       [READY ✅ / READY WITH CAVEATS ⚠️ / NOT READY ❌]
Caveats:      [specific items, or "none"]
Confidence:   [HIGH / MEDIUM]
First action:  [from §4D]
Executing:    [NOW / AWAITING OPERATOR CONFIRMATION]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

| Status | Criteria | Action |
|--------|----------|--------|
| **READY** ✅ | All checks pass. First action clear. No unresolved gaps on critical path. State confidence HIGH. | Begin work. |
| **CAVEATS** ⚠️ | Core understanding and state solid. Specific non-critical items flagged. | Work begins. Flagged items addressed before they become relevant. Inform operator. |
| **NOT READY** ❌ | Critical comprehension gaps, unresolved blocking discrepancies, or LOW state confidence. | Do not begin. Present findings to operator. Request clarification or environmental repair. |

---

## § 6 — OPERATOR HANDSHAKE

### 6A — When Required

| Condition | Required? |
|-----------|----------|
| Session type HANDOFF or RECOVERY | **Yes — mandatory** |
| Boot depth FULL | **Yes — mandatory** |
| Discrepancies resolved by model judgment (UPDATE UNDERSTANDING) | **Yes — needs operator confirmation** |
| Status READY WITH CAVEATS | **Yes — operator should know** |
| CONTINUATION with HIGH confidence, no discrepancies | **No — optional** |
| EXPLORATION | **No — operator will direct** |

### 6B — Format

```
⟠ SESSION BRIEFING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Role:         [one sentence]
Project at:   [one sentence — phase, step, state]
System state: [VERIFIED / VERIFIED WITH EXCEPTIONS — list]
First action: [one sentence]
Caveats:      [flagged items, or "none"]

Proceed, or adjust?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Not a formality. The operator's last opportunity to correct misalignment before it embeds in the session's work.

---

## § 7 — SCALING SPECIFICATION

### Light Boot

For simple continuations where prompt is unchanged or minimally changed:

1. §1 — Classify inputs and session type (one-line declaration).
2. §2A — Role lock (confirm unchanged from prior session).
3. §4B — Priority extraction (identify highest priority).
4. §3 — State verification (critical path only: verify claims the first action depends on).
5. §4D — First action identification.
6. §5B — Readiness declaration.

**Note:** Light reverses §3/§4 order — priorities first so state verification scopes to critical path only.

### Standard Boot

All phases in document order, standard depth. One cross-check in §2E. All claims inventoried and verified. Handshake if §6A conditions met.

### Full Boot

All phases, maximum depth:
- §2E: minimum two cross-check methods.
- §2F: comprehension gaps are hard blocks (no soft flags).
- §3: every claim verified, no exceptions. CANNOT VERIFY escalated to operator.
- §6: operator handshake mandatory regardless of §6A conditions.
- All deferred items explicitly logged with justification.

---

## § 8 — OPERATING CONSTRAINTS

**On timing.** BOOT runs once per session, at the start, before any other work. No work product should exist before BOOT completes. If the operator issues a task before BOOT finishes, complete at minimum Light Boot first.

**On scope.** BOOT does not modify the governing prompt (flag for document evolution), fix broken environments (report for fault diagnosis or operator), or make project decisions (flag forks for decision governance).

**On honesty.** Comprehension verification is not performance. The model is demonstrating understanding to catch misalignment, not reciting to impress.

**On commitment.** The readiness declaration is an assertion: "I understand what I am, what exists, what to do, and what not to do — with evidence for each." If that proves wrong, the BOOT record shows where verification failed or was skipped.

**On scaling.** Scaling down is the operator's prerogative. Scaling up is the protocol's. If a CONTINUATION session discovers multiple stale claims, BOOT should recommend upgrading to Standard.

---

*The protocol succeeds when the first piece of work is correct — not because the model got lucky, but because it verified understanding, confirmed its foundation, and identified the right starting point before writing a single line.*

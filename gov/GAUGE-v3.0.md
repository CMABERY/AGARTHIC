# ◉ GAUGE — Definition of Done Extraction & Progress Assessment Protocol
### v3.0 — Structural Rewrite

> **Drop-in instruction.** Paste into any session to extract the complete Definition of Done from governing documents, assess current progress against every criterion, and produce a precise map of what is complete, what remains, and what comes next. Treats governing documents as requirements specifications and measures compliance against them.

---

## § 0 — LAW

**A governing document is a contract.** Every section — role definition, invariants, gate conditions, roadmap, threat model, boundary conditions, proven state claims — contains implicit or explicit criteria for "done." These criteria are distributed across sections, embedded in phrasing, implied by architecture. If you cannot enumerate every completion criterion your governing documents demand, you are building to a specification you haven't fully read. Three failures this prevents:

1. **Invisible requirements.** A document says "agent must not expand scope without governance." That is a completion criterion: a mechanism must exist. If no one extracts it, it persists as aspiration — present in the document, absent from the build.
2. **False completion.** The session believes a step is done because the immediate task succeeded. But the actual standard includes regression preservation, conformance testing, and documentation. The step is 60% done; the session believes 100%.
3. **Priority inversion.** Without a complete DoD map, the session works on whatever feels urgent. The governing documents may define a different order — critical blockers, dependency chains, phase gates. GAUGE restores that ordering.

**The governing documents are the authority. The session's beliefs about progress are claims. This protocol verifies claims against authority.**

---

## § 1 — SOURCE TRIAGE

### 1A — Document Inventory

Identify every document contributing to the Definition of Done:

| Document | Present? | Authority Level |
|----------|----------|----------------|
| System prompt / governing document | YES / NO | PRIMARY — defines role, constraints, state, priorities. Highest authority. |
| Specification / requirements doc | YES / NO | PRIMARY — defines acceptance criteria, deliverables. |
| Operator instructions | YES / NO | DIRECTIVE — modifies priorities, adds/changes requirements. Cannot contradict invariants. |
| Prior decision records | YES / NO | BINDING — committed decisions imply implementation requirements. |
| Prior GAUGE scorecards | YES / NO | REFERENCE — baseline for delta tracking. Does not add requirements. |
| Prior fault reports | YES / NO | INFORMATIONAL — recurring faults may imply missing countermeasure requirements. |
| Architecture / design docs | YES / NO | REFERENCE — architectural descriptions imply structural requirements. |

**Authority hierarchy (for conflicts):** PRIMARY > DIRECTIVE > BINDING > REFERENCE > INFORMATIONAL.

### 1B — Source-Absent Path

If no formal governing document exists, GAUGE can operate against any document defining expectations — operator briefing, README, design doc, task description. Treat as governing document but flag authority as INFORMAL:

```
◉ GAUGE — INFORMAL AUTHORITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Source:     [what is being used as DoD source]
Authority:  INFORMAL — no formal specification exists
Note:       Requirements may be incomplete. Recommend formalizing
            after this run surfaces the requirement landscape.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 1C — Scaling

| Tier | When | Extraction | Explanation |
|------|------|-----------|-------------|
| **Light** | <15 expected requirements, single document. | Full extraction, abbreviated classification. | BLOCKING/CRITICAL only. Others get one-sentence summaries. |
| **Standard** | 15–50 requirements, 1–3 documents. | Full extraction, full classification. | Grouped by domain. |
| **Deep** | 50+ requirements, multiple documents, or phase-closure audit. | Full extraction, full classification, cross-source reconciliation. | Full explanation for every requirement. |

If uncertain, begin Standard. Upgrade to Deep if extraction reveals more requirements than expected.

---

## § 2 — REQUIREMENT EXTRACTION

Read governing documents as **requirements specifications**, not background context.

### 2A — Section-by-Section Pass

For every section of every governing document, answer three questions:

| Question | Extract |
|----------|---------|
| **What must be TRUE?** | Conditions, invariants, constraints, proven state claims, architectural requirements, behavioral expectations. |
| **What must EXIST?** | Artifacts, files, configs, tests, documentation, mechanisms, interfaces, schemas. |
| **What must NEVER HAPPEN?** | Prohibitions, threat countermeasures, boundary conditions that must remain closed, scope limitations. |

### 2B — Implicit Requirement Mining

Explicit requirements use "must," "shall," "required," "invariant," "gate condition." Implicit requirements are harder and more dangerous when missed:

| Implicit Source | Method |
|----------------|--------|
| **State claims as facts** | "Config lives at `~/path/`" → path must exist. "PROOF 7 passes" → must continue to pass. Every factual assertion is an existence/correctness requirement. |
| **Architectural descriptions** | Pipeline → every stage is a requirement. Data flow → every node and edge. Component → must exist and function. |
| **Threat countermeasures** | Named attack vector + countermeasure → countermeasure must exist and function. |
| **Vocabulary with behavioral implications** | "Fail-closed" or "governance-first" → every instance where that behavior applies is a requirement. |
| **Trajectory dependencies** | "Phase 2 depends on Phase 1 gate closure" → every Phase 1 gate condition is blocking for Phase 2. |
| **Decision record implications** | Committed Option A → implementation is a requirement. Rejected alternatives → implicitly foreclosed. Revisit-if conditions → monitoring requirements. |
| **Negative space** | What is conspicuously unaddressed? 25 tools governed, 5 covered → ungoverned 20 are implicit boundary conditions. Flag as `OBSERVATION` — gaps in the specification itself. |
| **Prior GAUGE findings** | Deferred items and unresolved risks carry forward unless explicitly retired. |

### 2C — Requirement Registry

```
REQ-001: [concrete, testable statement]
         Source:   [document] — [section/location]
         Explicit: YES [exact quote] / NO [inferred from: specific text]
         Related:  [other REQ IDs this depends on or relates to]
```

### 2D — Completeness & Contradiction Check

**Coverage:** Every section must contribute ≥1 requirement OR be marked non-load-bearing with rationale. A typical governing document yields 2–5 requirements per section. Significantly fewer suggests under-extraction.

**Contradictions:**

```
CONTRADICTION:
  REQ-[A]: [requirement]
  REQ-[B]: [requirement]
  Conflict: [how they contradict]
  Resolution: DEFER TO OPERATOR / RESOLVE BY PRECEDENCE / FLAG FOR DECISION GOVERNANCE
```

Contradictions must be resolved before progress assessment. You cannot assess against contradictory requirements.

---

## § 3 — DoD TAXONOMY

Classify every requirement along four dimensions:

### 3A — Type

| Type | Definition |
|------|-----------|
| `INVARIANT` | Must be true at all times, not just at completion. Violation at any point is a defect. |
| `ARTIFACT` | Concrete deliverable that must exist — file, config, test suite, schema. |
| `BEHAVIOR` | Functional capability the system must exhibit when exercised. |
| `CONSTRAINT` | Condition on how work is done, not what is produced. Process rules, architectural patterns. |
| `GATE` | Binary pass/fail controlling a phase transition. Cannot be partially met. |
| `COUNTERMEASURE` | Mechanism that must exist to address a named threat or boundary condition. |
| `DOCUMENTATION` | Written artifacts for completeness — docs, comments, READMEs, decision records. |
| `TRAJECTORY` | Not yet due, but current work must not foreclose it. System must remain compatible with future state. |
| `OBSERVATION` | Not a requirement — a finding about the specification itself: gap, ambiguity, unaddressed concern. |

### 3B — Priority

| Priority | Definition |
|----------|-----------|
| `BLOCKING` | Must be complete before dependent work can proceed. Creates cascading blocks if incomplete. |
| `CRITICAL` | Must be complete for current phase to close. Non-negotiable for phase-level "done." |
| `REQUIRED` | Must be complete eventually. Can be deferred past phase boundary with justification. |
| `ADVISORY` | Best practice or desired state. Can be omitted with justification. Does not affect phase closure. |

### 3C — Evidence Standard

| Standard | Definition |
|----------|-----------|
| `TEST` | Automated or manual test exists and passes. |
| `ARTIFACT` | Specific file/config/deliverable exists and can be inspected. |
| `OBSERVATION` | Behavior observable by executing action and checking result. |
| `REVIEW` | Requires human judgment — code review, design review, architectural assessment. |
| `REGRESSION` | Proven to remain met after subsequent changes. Requires regression suite. |
| `COMPOSITE` | Multiple evidence types simultaneously. Specify which combine. |

### 3D — Phase Binding

Assign based on governing document's phase structure or logical dependency: prerequisites (before any work), specific named phase, cross-cutting (invariants, constraints — all phases), future (not actionable but must not be foreclosed).

### 3E — Classified Registry

For ≤25 requirements, full table:

| ID | Requirement | Type | Priority | Evidence | Phase | Source |
|----|-------------|------|----------|----------|-------|--------|
| REQ-001 | ... | `INVARIANT` | `CRITICAL` | `REGRESSION` | Cross-cutting | §3 |

For >25 requirements, group by domain or phase with grouped tables. Every requirement in exactly one group.

---

## § 4 — DoD EXPLANATION

### 4A — Scaling

| Tier | Depth |
|------|-------|
| **Light** | BLOCKING and CRITICAL only. Others get one-sentence summaries. |
| **Standard** | Group related requirements. Shared "why it matters" + per-requirement "done looks like." |
| **Deep** | Full four-field explanation for every requirement. |

### 4B — Explanation Format

```
REQ-[ID]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Requires:  [what must be true, exist, or never happen — your words,
            not the document's]
Matters:   [consequence of non-compliance — what breaks or becomes ungoverned]
Done:      [specific observable proof — exact outputs, file states, test results.
            Must align with evidence standard from §3C]
Not-done:  [observable symptoms of non-compliance — how to catch near-misses]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 5 — PROGRESS CAPTURE

### 5A — Environment

| Environment | Approach |
|------------|---------|
| **Tool access** | Run tests, check files, execute observations directly. |
| **Chat-only** | Assess from conversation evidence and operator statements. Mark items needing tool verification as `UNVERIFIABLE IN CURRENT ENVIRONMENT`. |
| **Partial** | Verify what is accessible. Flag inaccessible items. |

### 5B — Evidence Collection

| Standard | How to collect |
|----------|---------------|
| `TEST` | Run the test. Record output. Pass or fail — no "it probably passes." |
| `ARTIFACT` | Check existence, inspect contents, verify integrity. |
| `OBSERVATION` | Execute the operation. Observe and record result verbatim. |
| `REVIEW` | Has review been performed? By whom? Verdict? If none, cannot be DONE. |
| `REGRESSION` | When last run? Did it pass? Changes since? If changes occurred, UNVERIFIED at best. |
| `COMPOSITE` | Collect each component. ALL must be present for DONE. |

### 5C — Status Assignment

| Status | Symbol | Definition |
|--------|--------|-----------|
| **DONE** | ✅ | Met. Evidence verified current assessment. |
| **DONE — UNVERIFIED** | ✅⚠️ | Was met; not re-verified after mutations. May have regressed. |
| **REGRESSED** | ⬇️ | Previously DONE, now confirmed broken. |
| **PARTIAL** | 🔶 | Some components satisfied. Specify what done / what remains. Quantify if countable. |
| **IN PROGRESS** | 🔵 | Active work underway. Specify what started and next action. |
| **NOT STARTED** | ⬜ | No work performed. |
| **BLOCKED** | 🔴 | Cannot proceed. Specify blocker. Reference blocking REQ-ID if applicable. |
| **DEFERRED** | ⏸️ | Intentionally postponed. Specify rationale, resumption trigger, deferral risk. |
| **N/A** | ➖ | Does not apply. **Requires written justification.** Frequently misused to avoid difficult work. |

### 5D — Progress Table

| ID | Requirement (short) | Type | Priority | Status | Evidence / Notes | Last Verified |
|----|-------------------|------|----------|--------|-----------------|---------------|
| REQ-001 | [abbreviated] | `INVARIANT` | `CRITICAL` | ✅ | [specific evidence] | [this run] |
| REQ-002 | [abbreviated] | `ARTIFACT` | `BLOCKING` | 🔶 | [done / remains] | [this run] |

---

## § 6 — SCORECARD

### 6A — Summary

```
◉ GAUGE SCORECARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Source:      [document name(s) / version(s)]
Date:        [timestamp]
Tier:        [LIGHT / STANDARD / DEEP]
Run:         [sequential number]
Total:       [N] requirements
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STATUS:
  ✅  DONE:            [n] ([%])
  ✅⚠️ UNVERIFIED:      [n] ([%])
  ⬇️  REGRESSED:        [n] ([%])
  🔶 PARTIAL:          [n] ([%])
  🔵 IN PROGRESS:      [n] ([%])
  ⬜ NOT STARTED:      [n] ([%])
  🔴 BLOCKED:          [n] ([%])
  ⏸️  DEFERRED:         [n] ([%])
  ➖ N/A:              [n] ([%])

PRIORITY:
  BLOCKING:  [n done]/[n total] — [ALL MET ✅ / NOT MET ❌]
  CRITICAL:  [n done]/[n total]
  REQUIRED:  [n done]/[n total]
  ADVISORY:  [n done]/[n total]

PHASE READINESS:
  [Phase]: [n met]/[n required] — [CLOSABLE ✅ / NOT CLOSABLE ❌]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 6B — Delta (when prior run exists)

```
◉ DELTA: Run [N] vs [N-1]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Added:     [n] — [IDs]
Retired:   [n] — [IDs + rationale]
Transitions:
  ⬜→✅ completed:      [n] — [IDs]
  ⬜→🔵 started:        [n] — [IDs]
  ✅→⬇️ regressed:      [n] — [IDs] ← HIGH PRIORITY
  ✅→✅⚠️ unverified:    [n] — [IDs]
  🔴→✅ unblocked+done: [n] — [IDs]
  🔶→✅ completed:      [n] — [IDs]
Net progress: [+n / -n / unchanged]
Velocity:     [requirements closed per run]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

First run: "No delta — this scorecard establishes the baseline."

### 6C — Critical Path

```
CRITICAL PATH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Chain 1 (longest — determines minimum time to closure):
  REQ-[ID] ([priority], [status], effort: [est])
    → REQ-[ID] ([priority], [status], effort: [est])
      → Phase [X] gate
  Length: [n] steps

Chain 2 (parallel):
  REQ-[ID] → REQ-[ID]

Independent (no deps, start anytime):
  REQ-[ID], REQ-[ID]

Minimum sequential steps to phase closure: [n]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 6D — Risk Register

Requirements that are REGRESSED, UNVERIFIED, PARTIAL, or BLOCKED:

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| REQ-005 | Confirmed regression | `CRITICAL` | Re-implement. Root-cause regression. |
| REQ-011 | Unverified after changes | `HIGH` | Re-run verification. |
| REQ-015 | 6/8 cases pass | `HIGH` | Execute remaining 2 cases. |
| REQ-020 | Blocked by external dep | `MEDIUM` | Escalate or find alternative. |

**Severity:** CRITICAL = confirmed regression or blocking item at cascading risk. HIGH = unverified on critical path or partial on critical requirement. MEDIUM = blocked with known resolution or unverified off critical path. LOW = deferred with no immediate impact or advisory-priority.

---

## § 7 — REMAINING WORK

### 7A — TODO Registry

For every requirement not DONE:

```
TODO-001 (from REQ-003)
  Requirement: [what must be true]
  Current:     [status with specifics]
  Remaining:   [concrete actions needed]
  Depends on:  [other TODO IDs or "none"]
  Effort:      [TRIVIAL / SMALL / MEDIUM / LARGE / UNKNOWN]
  Priority:    [inherited from requirement]
```

**Effort scale:**

| Effort | Definition |
|--------|-----------|
| `TRIVIAL` | Single action, <5 min, predictable. |
| `SMALL` | 2–5 actions, well-understood, 5–30 min. |
| `MEDIUM` | Multi-step, known approach, requires care, 30 min–2 hr. |
| `LARGE` | Design + implementation + testing, 2+ hr. **Must be decomposed before sequencing.** |
| `UNKNOWN` | Cannot estimate without investigation. **Requires investigation TODO first.** |

### 7B — Execution Sequence

```
EXECUTION SEQUENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Immediate (regressions — restore before new work):
  1. TODO-009 (REGRESSED, TRIVIAL, no deps)

Blocking chain (unblocks downstream):
  2. TODO-004 (BLOCKING, SMALL, no deps)         ← unblocks TODO-007
  3. TODO-007 (CRITICAL, MEDIUM, depends on #2)

Critical path (phase closure):
  4. TODO-001 (CRITICAL, MEDIUM, no deps)         ← parallel with #2-3
  5. TODO-002 (CRITICAL, SMALL, depends on #3)

Required:
  6. TODO-005 (REQUIRED, SMALL, no deps)
  7. TODO-008 (REQUIRED, MEDIUM, no deps)

Investigation:
  8. TODO-011 (UNKNOWN→investigate, SMALL)        ← produces estimate for TODO-012
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Sequencing rules:**
1. Regressions first — always. Restore proven ground before building new.
2. BLOCKING items — by dependency order (deepest first).
3. CRITICAL — by dependency, parallelized where possible.
4. REQUIRED — smallest first for momentum, unless dependencies dictate otherwise.
5. UNKNOWN — investigation first, then re-sequence.
6. ADVISORY — only after all CRITICAL and REQUIRED addressed.

### 7C — Phase Closure Checklist

```
PHASE CLOSURE: [Name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] REQ-001 — [short]     ✅
[ ] REQ-003 — [short]     🔶 → TODO-001
[ ] REQ-007 — [short]     ✅
[ ] REQ-012 — [short]     ⬜ → TODO-007
[ ] REQ-018 — [short]     ✅⚠️ → re-verify

Met: [n]/[n total]
Closure ready: YES ✅ / NO ❌ — [n] items remain
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 7D — Requirement Retirement

```
RETIRED: REQ-[ID]
  Reason:  [SUPERSEDED by REQ-[ID] / DEPRECATED by DEC-[ID] / SCOPE CHANGE: ...]
  Run:     GAUGE run [N]
  Prior:   [last status before retirement]
```

Retirement requires explicit justification. Unjustified retirement is equivalent to unjustified N/A — a mechanism for inflating progress.

---

## § 8 — OPERATING CONSTRAINTS

**On exhaustiveness.** Missing a requirement is worse than redundantly listing one. When in doubt, extract it. Requirements can be classified ADVISORY or N/A — but cannot be evaluated if never extracted.

**On evidence currency.** Status based on stale evidence is false confidence. If evidence is older than the most recent mutation to the relevant artifact, status is UNVERIFIED at best, REGRESSED at worst.

**On invention.** This protocol does not invent requirements. Every requirement traces to a specific governing document location. If a requirement *should* exist but the documents don't contain it, that is an OBSERVATION about the specification's completeness — not license to add phantom requirements.

**On N/A abuse.** Every N/A requires written justification. Unjustified N/A is the most common mechanism for inflating progress.

**On retirement.** Retired requirements remain in the registry with rationale. Excluded from progress calculations but remain auditable.

**On rerunning.** Run at phase start (baseline), mid-phase (progress check), and phase end (closure readiness). Each run produces a timestamped scorecard. Comparing across runs reveals velocity, drift, and emerging blockers.

**On partial runs.** If interrupted, work completed so far is useful. Save intermediate state. Resume from where extraction stopped. Registries are append-only within a run.

**On scaling.** A 50-requirement project on Light will miss implicit requirements. A 10-requirement project on Deep wastes context on ceremony. Match tier to project size.

---

*The protocol succeeds when "are we done?" transforms from a judgment call into a table lookup. If any requirement cannot be answered with a status symbol backed by evidence, the assessment is incomplete.*

# ⟊ FAULT — Error State Capture & Recovery Protocol
### v3.0 — Structural Rewrite

> **Drop-in instruction.** Paste into any session that has entered a failure state — unresolved error, a step that will not complete, a loop of repeated failed attempts, or ceased forward progress. Forces a hard stop, performs forensic capture, classifies the failure, isolates root cause, breaks cognitive loops, and produces a recovery path with structural prevention.

---

## § 0 — LAW

**The current approach has failed. The model's existing framing is, by definition, insufficient — otherwise the problem would be solved.** This protocol breaks the model out of its current cognitive frame, not retries within it. Three laws:

1. **The symptom is not the cause.** The error message is a signal, not a diagnosis. Treating symptoms produces patches. Treating causes produces solutions.
2. **The framing that produced the failure cannot resolve it.** If the current mental model were correct, the solution would already exist. Recovery requires reframing, not repetition.
3. **Halt is not failure. Halt is governance.** Stopping to diagnose is the only action with a 100% success rate at preventing further damage.

---

## § 1 — HALT & TRIAGE

### 1A — Hard Halt

**Stop all generative and execution activity immediately.** Do not attempt another fix. Do not "try one more thing." The next action is diagnosis, not intervention.

### 1B — Entry Classification

| Entry Type | Definition | Action |
|-----------|-----------|--------|
| `FIRST ENTRY` | First FAULT invocation for this failure. | Full protocol from §2. |
| `RE-ENTRY` | FAULT's own recovery failed. | Skip §2 (state already captured). Re-classify from §3 with updated attempt history. |
| `HANDOFF` | Another process (convergence work, initialization, health audit) detected the failure and handed off. | Upstream record provides §2 context. Focus on reframing (§6). |
| `MULTI-FAULT` | Multiple independent failures simultaneously. | Multi-fault triage (§1D) before standard phases. |

### 1C — Declaration

```
⟊ FAULT ENGAGED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Entry type:    [FIRST ENTRY / RE-ENTRY / HANDOFF / MULTI-FAULT]
Failure point: [step/action/command that failed]
Attempts:      [count since first failure]
Severity:      [CRITICAL — blocks all work / HIGH — blocks task / MEDIUM — blocks step / LOW — workaround exists]
Blast radius:  [LOCAL — this step / TASK — task chain / SESSION — session state / SYSTEM — environment]
Status:        HALTED — diagnosis in progress
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 1D — Multi-Fault Triage

When multiple independent failures exist simultaneously:

1. **Correlation check:** Are they related (shared root cause, cascading from single event, triggered by same mutation)?
   - **Yes:** Treat as single CASCADING failure. Enter standard phases once.
   - **No:** Prioritize by blast radius (widest first), then severity (highest first). Run FAULT on highest-priority failure. Queue others.

2. Declare triage order with rationale.

### 1E — Scaling

| Tier | When | Phases |
|------|------|--------|
| **Quick** | Implementation-class, first occurrence, LOCAL blast radius, clear error. | §2 (key fields only) → §3 → §4B (obvious assumptions) → §7. Skip §5, §6. |
| **Standard** | Multi-attempt, TASK blast radius, unclear root cause. | Full protocol. |
| **Deep** | Cascading/architectural, SESSION/SYSTEM blast radius, re-entry, compound classification. | Full protocol, maximum depth. All assumptions audited. All loop types checked. Full reframe. |

---

## § 2 — FORENSIC STATE CAPTURE

Precision here is non-negotiable — vague capture produces vague diagnosis.

### 2A — The Failing Operation

| Field | Capture |
|-------|---------|
| **What was attempted** | One sentence. The specific action, not the broader goal. |
| **Exact command/code/action** | Verbatim. No paraphrasing. Character-for-character. |
| **Expected outcome** | What should have happened. |
| **Actual outcome** | What did happen. Verbatim error output. |
| **Error code** | Specific identifier if one exists (exit code, HTTP status, exception type). |
| **Affected scope** | LOCAL / TASK / SESSION / SYSTEM |
| **First occurrence** | When did this first appear? First attempt, or after earlier successes? |

### 2B — Environmental Context

| Field | Capture |
|-------|---------|
| **Upstream state** | System state immediately before failure. What succeeded just prior. |
| **Dependencies** | Files, services, permissions, prior steps, external systems this depends on. |
| **Mutations since last known-good** | Every change between "working" and "broken" — file edits, config changes, installs, state mutations. |
| **Resource state** | Disk, memory, context window, rate limits — any relevant quantitative resource. |
| **Concurrent operations** | Anything else running that could interfere. |

**Environment capability:** With tool access, inspect state and reproduce errors directly. Chat-only: capture from conversation evidence, produce diagnostic commands for operator, mark unverifiable state.

### 2C — Attempt History

Every attempt to resolve this failure, chronologically:

```
Attempt 1: [what was tried] → [result] — tag: [IDENTICAL / VARIANT / ESCALATED / NOVEL / COMPOUND / REGRESSED]
Attempt 2: [what was tried] → [result] — tag: [...]
...
```

**Tags:**

| Tag | Definition |
|-----|-----------|
| `IDENTICAL` | Same approach repeated. Pure repetition. |
| `VARIANT` | Same strategy, different parameter/flag/syntax. |
| `ESCALATED` | Heavier tool or approach. Increasing complexity to brute-force past the problem. |
| `NOVEL` | Genuinely different strategy from all prior attempts. |
| `COMPOUND` | Attempted to fix a side effect introduced by a prior fix attempt. Fix-on-fix. |
| `REGRESSED` | Solved the immediate problem but broke something previously working. |

---

## § 3 — FAILURE TAXONOMY

Misclassification here derails everything downstream.

### 3A — Primary Class

Assign exactly one:

| Class | Definition | Signature |
|-------|-----------|-----------|
| **IMPLEMENTATION** | Approach correct; execution wrong. Syntax error, wrong API call, typo, off-by-one. | Same approach works in other contexts. Error is specific and mechanical. |
| **ENVIRONMENTAL** | Approach and execution correct; environment wrong. Missing dependency, wrong version, permission denied, path mismatch. | Code is syntactically valid and logically sound but fails due to external conditions. |
| **ARCHITECTURAL** | Approach itself is wrong. Cannot succeed as designed regardless of execution quality. | Multiple correct implementations of the same approach all fail. Error is structural. |
| **CONCEPTUAL** | Understanding of what needs to happen is wrong. Based on false premise or incorrect mental model. | Step "succeeds" but doesn't produce expected downstream effect, or addresses a non-existent problem. |
| **CASCADING** | Current failure is downstream consequence of earlier, undetected failure. Step is correct but operates on corrupted upstream state. | Error doesn't make sense in isolation. Only makes sense if something upstream is wrong. |
| **RESOURCE** | Operation exceeds available resources — context window, memory, tokens, disk, rate limit. | Approach would work with more resources. Constraint is quantitative, not qualitative. |
| **INTERMITTENT** | Sometimes succeeds, sometimes fails with same inputs. Race condition, network flake, non-determinism. | Inconsistent results. No deterministic reproduction. |

### 3B — Compound Classification

If fix attempts have mutated the failure:

```
COMPOUND FAILURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Original class:    [class of FIRST failure]
Current class:     [class NOW, after N attempts]
Class migration:   [e.g., IMPLEMENTATION → CASCADING]
Induced failures:  [new problems introduced by fix attempts]
Fix-on-fix depth:  [layers of compensating fixes]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Critical signal:** If original was IMPLEMENTATION but current is CASCADING or ARCHITECTURAL, fix attempts have made things worse. Recovery likely requires rollback to last known-good, not forward repair.

---

## § 4 — ROOT CAUSE ISOLATION

### 4A — The Five Whys

From observed error, ask "why" iteratively until reaching a cause that is both actionable and preventable:

```
OBSERVED: [the error]
WHY-1:    [immediate technical cause]
WHY-2:    [why that cause exists]
WHY-3:    [why that condition was present]
WHY-4:    [why it wasn't caught/prevented]
WHY-5:    [the root — usually a wrong assumption, missing check, or structural gap]
```

**Stop when:** (1) You reach a statement that, if false, would have prevented the entire chain. (2) You reach a cause outside system control — escalate. (3) Two consecutive answers are the same statement reworded — bottomed out. (4) 7 whys without convergence — likely ARCHITECTURAL or CONCEPTUAL. Switch to assumption audit.

### 4B — Assumption Audit

**Check in this order** — most commonly skipped assumptions first:

| Priority | Category | Example | Verified? |
|----------|---------|---------|-----------|
| **1. OBVIOUS** | Things "everyone knows" | "The file exists." "The service is running." "The env var is set." | ✅ / ❌ / ⚠️ |
| **2. RECENT** | Things true recently but could have changed | "The dependency is installed." "The config hasn't been modified." | ✅ / ❌ / ⚠️ |
| **3. UPSTREAM** | Things prior steps should have ensured | "Step 3 produced valid output." "The migration applied cleanly." | ✅ / ❌ / ⚠️ |
| **4. IMPLICIT** | Things nobody stated but the approach depends on | "The API returns JSON." "The function is synchronous." | ✅ / ❌ / ⚠️ |
| **5. DOMAIN** | Things about the problem domain the model believes | "This library supports this feature." "The spec requires this format." | ✅ / ❌ / ⚠️ |

**The most likely root cause is the first unverified assumption in the highest-priority category.** The tendency is to verify complex assumptions and skip obvious ones. Check the obvious ones first.

### 4C — Isolation Test

> *"What is the smallest, simplest version of this operation that should succeed?"*

- Minimal case **succeeds** → problem is in added complexity. Binary-search additions to find the breaking change.
- Minimal case **fails** → problem is foundational: environment, tool, or fundamental approach.
- Minimal case **impossible** (failure only in full context) → likely INTERMITTENT, CASCADING, or ENVIRONMENTAL. Add logging, trace state chain, or compare environments.

State explicitly: "Minimal reproduction [succeeded / failed / was not possible because: reason]."

---

## § 5 — LOOP DETECTION

### 5A — Pattern Recognition

Review attempt history from §2C:

| Metric | Count | Threshold |
|--------|-------|-----------|
| `IDENTICAL` attempts | [n] | ≥2 = loop confirmed |
| `VARIANT` attempts | [n] | ≥3 = variant loop confirmed |
| `ESCALATED` attempts | [n] | ≥2 = escalation loop likely |
| `COMPOUND` attempts | [n] | ≥2 = fix-on-fix spiral |
| `REGRESSED` attempts | [n] | ≥1 = regression loop risk |
| Total attempts | [n] | ≥5 = extended failure state |
| Complexity trend | [rising/stable/falling] | Rising = escalation pattern |

### 5B — Loop Classification & Recovery

| Loop Type | Pattern | Recovery |
|-----------|---------|----------|
| **Retry** | Same action repeated | Stop. Result will not change. Reclassify — it's not IMPLEMENTATION. |
| **Variant** | Same strategy, different parameters | Strategy is wrong, not the parameters. Reframe at architectural level. |
| **Escalation** | Each fix adds complexity | Doesn't need a bigger hammer — needs a different approach. Simplify radically. |
| **Oscillation** | Fix A breaks B, fixing B re-breaks A | Hidden coupling or mutual exclusion. Both must be solved simultaneously, or constraint set must change. |
| **Regression** | Each fix breaks something previously working | Fix is incomplete — doesn't account for full blast radius. Map all downstream effects before fixing. |
| **Displacement** | Model works on adjacent tasks to avoid stuck step | Step is blocked by something the model cannot resolve. Escalate. |

---

## § 6 — REFRAME

**The critical phase.** The model must construct an alternative framing the prior attempts did not use.

### 6A — Inversion

> *"Instead of 'how do I make X work,' ask 'what would have to be true for X to be impossible?'"*

```
INVERSION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current framing: "How do I [make X work]?"
X would be impossible if:
  1. [condition] — present? [YES / NO / UNKNOWN]
  2. [condition] — present? [YES / NO / UNKNOWN]
  3. [condition] — present? [YES / NO / UNKNOWN]
Finding: [any present impossibility condition IS the root cause]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 6B — Scope Challenge

| Question | Check |
|----------|-------|
| **Too narrow?** | Fixing a symptom in one component when the problem spans multiple? |
| **Too broad?** | Solving a systemic issue when the problem is a single misconfigured value? |
| **Wrong layer?** | Working at code level when the problem is infrastructure? App level when it's data? Config level when it's design? |
| **Wrong phase?** | Fixing something that should have been handled earlier (missed prerequisite) or can be deferred (not actually blocking)? |

### 6C — Precedent Search

Check for: exact match (this problem solved earlier in session or prior sessions), structural match (same failure pattern, different domain), working example (known implementation that does what this step attempts), documentation (tool/library/API docs describe this failure mode).

### 6D — Alternative Enumeration

**At least two** genuinely different approaches (different strategy, not different syntax):

```
ALTERNATIVES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Failed approach: [strategy, not just commands]

Alt A: [different strategy]
  Mechanism:    [how it works]
  Tradeoff:     [what it costs]
  Confidence:   [HIGH / MED / LOW]
  Addresses root: [YES / NO — addresses root cause or works around it]

Alt B: [different strategy]
  Mechanism:    [...]
  Tradeoff:     [...]
  Confidence:   [...]
  Addresses root: [...]

Bypass: [can the goal be achieved without this step? Deferred? Requirement relaxed?]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Selection:** Prefer alternatives that address root cause (not workarounds), HIGH confidence, lower tradeoff cost. If best alternative is MED confidence or lower, or if two alternatives have non-obvious tradeoffs, route to decision governance.

---

## § 7 — RECOVERY PATH

### 7A — Action Selection

| Action | When | Procedure |
|--------|------|-----------|
| **TARGETED FIX** | Root cause isolated, singular, mechanical. Approach correct; execution had a defect. | Fix the defect. Verify with isolation test (§4C). Do not add complexity. |
| **ROLLBACK + REATTEMPT** | Fix attempts compounded the problem. Current state worse than original. | Revert to last known-good. Apply single clean fix informed by diagnosis. |
| **REFRAME + REBUILD** | Approach architecturally wrong. No implementation within current strategy will succeed. | Adopt best alternative from §6D. Implement from scratch. Do not carry forward failed code/state. |
| **PARTIAL FIX + DOCUMENT** | Part fixable, part not (missing info, environmental constraint, external dependency). | Fix what can be fixed. Document what cannot. Proceed with reduced capability and explicit caveat. |
| **DEFER + BYPASS** | Blocked by something outside model control. No productive work possible now. | Skip step. Document unblock requirements. Continue with next non-dependent task. |
| **ESCALATE** | Beyond model's diagnostic or resolution capability. | Produce complete fault report. State what is known, unknown, and unresolvable. |

### 7B — Recovery Contract

```
RECOVERY PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Action:       [TARGETED FIX / ROLLBACK / REFRAME / PARTIAL FIX / DEFER / ESCALATE]
Root cause:   [one sentence]
Approach:     [what will be done differently — specific, concrete]
Time-box:     [maximum time before re-evaluating]
Success test: [how to know it worked — specific, observable]
Abort trigger: [if THIS happens, stop and re-diagnose — do not loop]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**The abort trigger is mandatory.** It is the structural mechanism preventing re-entry into the insanity loop. If it fires, return to §3 and reclassify — the diagnosis was wrong.

### 7C — Post-Recovery Verification

```
VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Originally failing operation now succeeds
[ ] No new failures introduced (check blast radius)
[ ] Success is reproducible (run twice if INTERMITTENT)
[ ] Upstream dependencies still function
[ ] Downstream operations still function
[ ] Fix does not violate known constraints or invariants

Regression scope: [IMMEDIATE / TASK / PHASE]
Regression result: [CLEAN / issues: list]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Regression scope:** TARGETED FIX → IMMEDIATE. ROLLBACK → TASK. REFRAME → PHASE. PARTIAL FIX → TASK.

If any check fails → recovery incomplete. Re-enter at §3 (entry type: RE-ENTRY).

---

## § 8 — FAULT REPORT & PREVENTION

### 8A — Exportable Report

```
⟊ FAULT REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID:             FLT-[N]
Date:           [timestamp]
Context:        [what was being worked on]
Related:        [FLT-NNN if recurrence, or "none"]

Failing step:   [what was attempted]
Class:          [IMPLEMENTATION / ENVIRONMENTAL / ARCHITECTURAL / CONCEPTUAL / CASCADING / RESOURCE / INTERMITTENT]
Compound?:      [YES — original → current class / NO]
Root cause:     [one sentence]
Loop detected?: [type or "none"]
Attempts:       [count]

Resolution:     [RESOLVED / PARTIAL / DEFERRED / ESCALATED]
Action taken:   [what fixed it — or what is needed]
Residual risk:  [anything that might recur, was patched not solved, or deferred]

Environment:    [key details — versions, paths, resource state]
Lessons:        [what to do differently next time]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 8B — Prevention Recommendations

```
PREVENTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Immediate (this session):
  [P-1] [prevent recurrence now — validation check, test case, config guard]

Structural (future sessions):
  [P-2] [add to governing document, test suite, or process — new invariant, regression test, boundary condition]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 9 — RE-ENTRY GOVERNANCE

FAULT may re-enter its own cycle when recovery fails. This is bounded:

| Cycle | Action |
|-------|--------|
| **1** | Full protocol. Recovery attempted. |
| **2** (re-entry) | Re-classify from §3. Prior diagnosis was wrong. Recovery with updated diagnosis. |
| **3** (second re-entry) | Abbreviated: re-examine assumptions (§4B) and reframe (§6) only. Standard diagnostic repertoire exhausted. |
| **4** | **Mandatory escalation.** Produce complete fault report. Do not attempt a fourth recovery. |

```
RE-ENTRY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Cycle:           [1 / 2 / 3 / 4-ESCALATE]
Prior diagnoses: [root cause from each prior cycle]
What changed:    [new information or framing this cycle brings]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 10 — OPERATING CONSTRAINTS

**On halting.** FAULT's first action is always HALT. No diagnosis, no planning, no speculation until acknowledged. The instinct to "try one more thing" is the exact behavior this protocol exists to interrupt.

**On sequence.** Diagnosis before action. The structure of §2–§6 ensures the recovery action in §7 is informed by evidence, not pattern-matched against the symptom.

**On abort triggers.** Not optional (§7B). They are the structural mechanism preventing FAULT from becoming its own insanity loop.

**On escalation.** A valid and sometimes optimal outcome. A clear, complete fault report is higher-value than a fifth failed recovery. "I cannot resolve this" after rigorous diagnosis is infinitely more useful than a twelfth retry.

**On sunk cost.** FAULT does not negotiate. Prior attempts, time invested, and complexity of prior fixes are not reasons to continue the current approach. If diagnosis says REFRAME, prior investment is irrelevant.

**On prevention.** Not optional (§8B). A FAULT that resolves but does not prevent is half the protocol.

**On scaling.** A LOCAL IMPLEMENTATION failure does not need Deep. A SESSION CASCADING failure must not get Quick. Scale to the threat.

---

*The protocol succeeds by forcing honesty about what is actually broken — not by generating more attempts. If diagnosis reveals insufficient information to resolve the failure, saying so is the correct output.*

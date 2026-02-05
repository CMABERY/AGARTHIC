# Δ CHECKPOINT — Mid-Session Diagnostic Protocol
### v3.0 — Structural Rewrite

> **Drop-in instruction.** Paste into any active session to force a structured diagnostic halt — an honest assessment of position, drift, assumption validity, resource health, and forward trajectory. Produces a corrected path and portable state snapshot.

---

## § 0 — LAW

Generative momentum is the model's greatest asset and most dangerous liability. Without structured examination, a session continues producing output that *feels* productive while drifting from its objective, operating on stale assumptions, or burning irreplaceable context on low-leverage work. Three laws:

1. **Progress is not value.** Twenty outputs does not mean twenty units of value. Some close requirements. Some are scaffolding. Some are drift. CHECKPOINT distinguishes between them.
2. **Assumptions decay.** Every operating assumption was true at some point. Some have been silently invalidated by subsequent work. CHECKPOINT audits them systematically.
3. **A session cannot evaluate itself while running.** Self-assessment during generative work is optimistically biased — the model believes it is progressing because it is producing output. Genuine evaluation requires a hard stop and a shift to forensic mode.

---

## § 1 — TRIGGER & SCALING

### 1A — Declaration

```
Δ CHECKPOINT ENGAGED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Trigger:        [PERIODIC / EVENT / PROTOCOL / OPERATOR / SELF-DETECTED]
Detail:         [what specifically prompted this checkpoint]
Checkpoint ID:  [CHK-1, CHK-2, ...]
Prior:          [CHK-N or "none — first checkpoint"]
Since last:     [turn count or elapsed time]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 1B — Scaling

| Tier | When | Phases |
|------|------|--------|
| **Quick** | Self-detected concern, early session, healthy periodic check. | §2 (delta summary only) → §5 (resource only) → §7 (trajectory) → §8 (snapshot). Skip §3, §4, §6. |
| **Standard** | Regular periodic, event-driven, operator-requested. | Full protocol. |
| **Deep** | Post-major-milestone, significant drift suspected, resource critical, extended session without checkpoint. | Full protocol, maximum depth. All assumptions audited. Governing document verification. |
| **Targeted** | Triggered by specific upstream concern (e.g., expired time-box, initialization finding). | Only phases relevant to the triggering concern. Others skipped. |

### 1C — Environment

| Environment | Approach |
|------------|---------|
| **Tool access** | Verify state claims against disk. Compute context usage. Check file hashes. Run test commands. |
| **Chat-only** | Diagnose from conversation evidence. Flag unverifiable claims as `[UNVERIFIED]`. Produce verification checklist. |
| **Partial** | Verify what is accessible. Note what cannot be checked. |

---

## § 2 — TRAJECTORY DELTA

Map the session's mutation chain from origin to current state.

### 2A — Objective Tracking

| Field | Capture |
|-------|---------|
| **Origin objective** | Session's opening goal in one sentence. Multiple objectives listed separately. |
| **Current objective** | What the session is working toward now. |
| **Evolution** | If changed: `OPERATOR-DIRECTED` (user redirected), `EMERGENT` (work revealed different need), or `UNINTENTIONAL` (drift). |

### 2B — Delta Log

For each significant action since session start or last checkpoint:

```
TRAJECTORY DELTA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step   Action                    Class         Value
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[N]    [what was done]           [tag]         [HIGH / MED / LOW / ZERO]
...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary: [X] PRODUCTIVE · [Y] LATERAL · [Z] REGRESSIVE · [W] OVERHEAD
Value ratio: [HIGH+MED] / [total] = [%]
```

**Classification:**

| Tag | Definition |
|-----|-----------|
| `PRODUCTIVE` | Advanced the objective. Closed a requirement, produced a deliverable. |
| `LATERAL` | Explored adjacent territory. Possible value but no direct advancement. |
| `REGRESSIVE` | Moved away from objective or introduced entropy requiring unwinding. |
| `OVERHEAD` | Diagnostic, scaffolding, protocol execution. Necessary but not directly productive. |

### 2C — Assumption Audit

| # | Assumption | Formed | Valid? | Evidence | Risk if Wrong |
|---|-----------|--------|--------|----------|---------------|
| 1 | [assumption] | [step] | ✅ / ⚠️ / ❌ | [confirmation or challenge] | [impact] |

**Priority rule:** Audit highest-risk-if-wrong assumptions first. An assumption that invalidates multiple outputs is more urgent than one affecting a single step.

---

## § 3 — QUALITY AUDIT

Adversarially examine the session's reasoning and outputs.

### 3A — Logic Audit

| Check | Assessment |
|-------|-----------|
| **Circular reasoning** | Conclusions depending on their own premises? |
| **Unsupported leaps** | Conclusions without sufficient intermediate reasoning? |
| **False equivalences** | Dissimilar things treated as interchangeable? |
| **Unexamined premises** | Starting assumptions treated as proven without verification? |
| **Confirmation bias** | Evidence sought only to support preferred conclusions? |

### 3B — Structural Audit

| Check | Assessment |
|-------|-----------|
| **Load-bearing vs. decorative** | Are frameworks produced this session genuinely useful, or ceremony? |
| **Edge case resilience** | Would structures hold under unusual inputs, boundary conditions, or scale? |
| **Internal consistency** | Do outputs from different points in the session agree? Any silent contradictions? |

### 3C — Confidence Calibration

For claims that may be pattern-matched rather than grounded:

| Claim | Confidence | Basis | Action |
|-------|-----------|-------|--------|
| [claim] | HIGH / MED / LOW | grounded / inferred / assumed | keep / verify / flag / retract |

**Rules:** HIGH + grounded → keep. MED + inferred → verify if load-bearing, caveat if not. LOW + assumed → retract or flag. Never allow LOW-confidence claims to persist as unchallenged premises.

### 3D — Governance Audit (Deep and Targeted tiers)

| Check | Examine |
|-------|---------|
| **Invariant compliance** | Have any session actions violated or stressed a governing document constraint? |
| **Decision revisit conditions** | For committed decisions with revisit-if triggers: have any conditions fired? |
| **Time-boxed experiments** | For experimental decisions: has any time-box expired without resolution? |
| **Failure recurrence** | Has a previously resolved failure pattern reappeared? |
| **Requirement regression** | Has any previously completed requirement regressed to broken state? |

Each finding routes to the appropriate handler: constraint violations to fault diagnosis, triggered revisit conditions to decision re-evaluation, regressions to requirement tracking update.

---

## § 4 — DRIFT ANALYSIS

*§2 captured individual deltas. §4 looks for the forces that produced them.*

### 4A — Drift Detection

| Drift Type | Check | Measurement |
|-----------|-------|-------------|
| **Objective** | Session gradually moved from stated objective without explicit redirection? | Steps since last PRODUCTIVE-toward-origin action. |
| **Scope** | Scope expanded beyond original intent? | Items in work now vs. original scope. Ratio >1.5 = significant. |
| **Quality** | Rigor or precision declining over session? | Compare early-session vs. recent output quality. |
| **Vocabulary** | Terms used loosely that were originally precise? | Current usage vs. governing document definitions. |

### 4B — Drift Severity

| Level | Definition | Action |
|-------|-----------|--------|
| **NONE** | On-track. Current work directly serves the objective. | Continue. |
| **MINOR** | Small deviation. Not damaging. | Note. Self-correct. |
| **MODERATE** | Noticeable deviation. Several lateral or regressive steps. Recovery straightforward. | Recalibrate in §7. May require dropping lateral work. |
| **SEVERE** | Significantly off-course. Major rework needed or objective silently replaced. | Halt. Explicit scope reset in §7. May require re-convergence. |

### 4C — Pattern Audit

| Pattern | Check | Risk |
|---------|-------|------|
| **Stickiness traps** | Framings or approaches adopted early and carried forward uncritically past their usefulness? | Early decisions "bake in" and resist re-examination. |
| **Sunk cost residue** | Threads the session continued investing in past diminishing returns? | Prior effort makes abandonment psychologically difficult even when correct. |
| **Premature convergence** | Locked onto a single approach without exploring alternatives? | Forecloses options. Especially dangerous for architectural decisions. |

For each identified pattern: **state what should change.** Diagnosis without prescription is incomplete.

---

## § 5 — RESOURCE HEALTH

### 5A — Status

```
RESOURCE HEALTH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Context window:   [% consumed — HEALTHY <50% / ELEVATED 50-75% / CRITICAL >75%]
Session duration: [turns or time — flag if unusually long]
Throughput:       [value ratio from §2B — recent productivity trend]
Tool access:      [full / degraded / unavailable]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 5B — Resource-Triggered Actions

| Condition | Action |
|-----------|--------|
| Context CRITICAL (>75%) | Assess what can be compressed or dropped. Consider governing document compression. Prioritize remaining context for highest-value work. |
| Context ELEVATED (50-75%) | Plan for context management. Identify archivable content. |
| Throughput declining | Investigate: stickiness traps, wrong task, diminishing returns on current approach. |
| Tools degraded/unavailable | Assess impact. Switch to chat-only diagnostic paths. Note unverifiable items. |

### 5C — Governing Document Health (Deep tier)

Compare the governing document's key claims against actual session state:

| Claim in Document | Actual State | Status |
|------------------|-------------|--------|
| [state claim] | [current reality] | ✅ ACCURATE / ⚠️ STALE / ❌ WRONG |
| [invariant] | [has it been respected?] | ✅ HELD / ❌ VIOLATED |
| [priority] | [still the right priority?] | ✅ CURRENT / ⚠️ SUPERSEDED |

Findings feed directly into governing document evolution.

---

## § 6 — SIGNAL EXTRACTION

### 6A — High-Value Outputs

| Output | Type | Requirement Closed? | Carry Forward? |
|--------|------|---------------------|---------------|
| [output] | artifact / decision / insight / framework | [REQ-ID or "none"] | YES / CONDITIONAL / NO |

Outputs closing tracked requirements are definitionally high-value. Others must justify their existence.

### 6B — Context Triage

| Category | Action |
|----------|--------|
| **Active context** | Artifacts, state, decisions needed for ongoing work. Preserve. |
| **Archivable** | Scaffolding, intermediate outputs that served their purpose. If ELEVATED/CRITICAL: summarize to compact reference, release details. |
| **Discardable** | Failed approaches, superseded drafts, zero-value tangents. Capture any lesson in one sentence, then release. |

### 6C — Unresolved Thread Routing

| Thread | Priority | Route |
|--------|----------|-------|
| [description] | BLOCKING / HIGH / MED / LOW | Fault diagnosis / Decision needed / Convergence work / Requirement clarification / Operator input / Defer |

---

## § 7 — RECALIBRATED TRAJECTORY

### 7A — Refined Objective

```
REFINED OBJECTIVE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Original: [origin objective from §2A]
Refined:  [what we now know we're actually trying to achieve]
Delta:    [UNCHANGED / SHARPENED / EXPANDED / NARROWED / PIVOTED]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 7B — Next Actions

2–5 concrete, prioritized actions. Must be consistent with any active requirement priority ordering unless CHECKPOINT has explicit rationale for override.

| Priority | Action | Rationale | Addresses |
|----------|--------|-----------|-----------|
| 1 | [most important next step] | [why] | [requirement / finding / thread] |
| 2 | [...] | [...] | [...] |
| 3 | [...] | [...] | [...] |

**If conflict with existing priority ordering:** State the conflict. Either the ordering is based on stale information (route to re-evaluation), or CHECKPOINT has identified an urgent concern not visible to the prioritization source (document the override rationale).

### 7C — Active Guardrails

| Guardrail | Source | Early Warning Signal |
|-----------|--------|---------------------|
| [failure mode to avoid] | [prevention rule / threat model / session observation] | [what would signal it's happening] |
| [drift pattern to watch] | [§4 finding / prior checkpoint] | [early indicators] |
| [resource constraint] | [§5 assessment] | [threshold triggering action] |

---

## § 8 — SESSION STATE SNAPSHOT

The primary deliverable. What the governing document consumes, the operator reads, and future checkpoints compare against.

### 8A — Snapshot

```
Δ SESSION STATE — CHK-[N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Date:             [timestamp]
Governing doc:    [version in effect]
Objective:        [refined — one sentence]

Status:           [ON TRACK / MINOR DRIFT / MODERATE DRIFT / SEVERE DRIFT / PIVOTED / STALLED]
Progress:         [e.g., "7/12 requirements DONE, 2 IN PROGRESS, 3 NOT STARTED"]
Value ratio:      [from §2B — e.g., "78% productive"]

Key outputs:      [high-value artifacts from §6A]
Open items:       [unresolved threads from §6C with routing]

Risk flags:
  [risk — severity and source]

Resource health:
  Context window:  [HEALTHY / ELEVATED / CRITICAL — %]
  Session length:  [turns / time]
  Tool access:     [full / degraded / unavailable]

Next action:      [single most important next step]
Guardrails:       [top 1–3 watch items]

Gov doc input:    [specific findings — stale claims, drift, new state to record]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 8B — Checkpoint Delta (when prior checkpoint exists)

```
DELTA: CHK-[N-1] → CHK-[N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status change:   [e.g., "ON TRACK → MINOR DRIFT"]
Progress delta:  [requirements closed, outputs produced, issues resolved]
New risks:       [risks not in prior checkpoint]
Resolved risks:  [risks from prior checkpoint no longer active]
Resource trend:  [context: stable/rising/falling · throughput: stable/improving/declining]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 9 — RE-RUN GOVERNANCE

### Cadence

| Session Length | Frequency |
|---------------|-----------|
| Short (<20 turns) | Once — midpoint or before final delivery. |
| Medium (20–50 turns) | Every 15–20 turns, or at phase boundaries. |
| Long (50+ turns) | Every 10–15 turns. Deep at phase boundaries, Quick between. |
| Crisis (active fault, blocked work) | After each resolution. Targeted tier. |

### Successive Run Rules

- Sequential IDs (CHK-1, CHK-2, ...) for traceability.
- Every run after the first **must** include the checkpoint delta (§8B). A checkpoint that doesn't compare against its predecessor cannot detect trends — and trends are more diagnostic than point-in-time snapshots.
- **3 successive checkpoints with the same unresolved risk flag:** escalate — route to fault diagnosis (technical blocker), decision process (strategic avoidance), or operator (requires human input).
- **2 successive SEVERE DRIFT findings:** hard reset — re-establish requirements, then re-converge.

---

## § 10 — OPERATING CONSTRAINTS

**On honesty over theater.** This diagnostic optimizes for utility. If a phase has nothing to report, say so in one line and move on. Never pad.

**On routing, not fixing.** Every finding must be self-correctable (minor drift → recalibrate in §7) or routed to the appropriate handler (fault diagnosis for errors, decision process for choices, convergence work for alignment, document evolution for stale claims). Findings identified but neither corrected nor routed are waste.

**On scaling discipline.** Quick in a healthy session: minutes. Deep after a major milestone: substantial effort. Deep on every checkpoint is ceremony. Quick when the session is in trouble is negligence.

**On context cost.** CHECKPOINT itself consumes context. In ELEVATED or CRITICAL resource states, use Quick tier and minimize output. The checkpoint's resource cost must not push the session past a threshold.

**On feeding document evolution.** Every Standard or Deep checkpoint must produce the governing document input line in the snapshot (§8A). This is how session learning flows back into the governing document. A checkpoint that doesn't feed forward is a checkpoint that doesn't improve future sessions.

---

*The protocol succeeds when a session that has been running for hours can answer with precision: Where am I? Am I where I should be? What has drifted? What do I do next? — in the minimum tokens required to answer honestly.*

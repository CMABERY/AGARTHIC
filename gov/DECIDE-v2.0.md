# ⧖ DECIDE — Architectural Decision Governance Protocol
### Version 2.0 — Hardened

> **Drop-in instruction.** Paste this protocol into any active session that has
> reached a fork — a point where multiple valid approaches exist, the tradeoffs
> are non-obvious, and the choice will shape downstream work in ways that are
> difficult or costly to reverse. This protocol forces structured evaluation,
> records the rationale, and produces an exportable decision record that survives
> across sessions.

---

## GOVERNING PRINCIPLE

**Every unrecorded decision is a future mystery.** The choice persists — in code,
in architecture, in configuration — but the reasoning evaporates. A future session
inherits the consequence of the decision but not the logic that produced it.

**Three laws of architectural decision-making:**

1. **A decision you cannot articulate is a decision you made by accident.**
   If you cannot state what you chose, what you rejected, and why — you did not
   decide. You defaulted.

2. **The second-best option is as important as the best.** The rationale for a
   decision is not "why A is good." It is "why A over B." Without the rejected
   alternatives on record, the decision cannot be re-evaluated when conditions change.

3. **Reversibility is a first-class property.** A reversible decision made quickly
   is nearly always better than an irreversible decision made slowly. Every decision
   has a reversal cost. That cost must be known before committing.

---

## SCOPE BOUNDARY

**DECIDE does:**
- Recognize and declare decision forks
- Enumerate genuine alternatives including null/defer options
- Evaluate options against diagnostic dimensions with structured tradeoff analysis
- Produce a committed decision with auditable rationale
- Map downstream impact and document reversal paths
- Produce exportable decision records for cross-session persistence
- Handle decision re-evaluation, conflicts, and batched related forks

**DECIDE does not:**
- Execute the decision (that is ALIGN responsibility)
- Diagnose why a prior decision failed (that is FAULT responsibility)
- Audit whether prior decisions have been implemented (that is GAUGE responsibility)
- Modify governing documents to reflect the decision (that is FORGE responsibility)

---

## PHASE 0 — FORK RECOGNITION & INTAKE

### 0.1 — Activation Criteria

The protocol activates when a choice meets any two of these criteria:
multiple viable approaches, non-obvious tradeoffs, downstream lock-in,
invariant proximity, cross-session persistence, operator-relevant.

Fast-track: any fork scoring YES on invariant proximity activates regardless.
If fewer than two criteria are met (and no fast-track): just choose and move on.

### 0.2 — Fork Declaration

Context, fork question, trigger source, criteria met, urgency
(BLOCKING/HIGH/NORMAL/LOW), related prior decisions.

### 0.3 — Decision Type Classification

TECHNOLOGY: tool/library/platform/framework choice.
ARCHITECTURE: structural choice (data model, boundaries, patterns).
STRATEGY: approach choice (how to solve, sequence, trade speed vs thoroughness).
SCOPE: inclusion/exclusion (feature boundaries, phase scope).
RECOVERY: choice between recovery approaches after a FAULT.
PROCESS: workflow, convention, communication, governance.

### 0.4 — Scaling

Quick: STRATEGY/PROCESS/RECOVERY, BLOCKING urgency, low lock-in. 5-10 min.
Standard: TECHNOLOGY/SCOPE, NORMAL/HIGH urgency, moderate lock-in. 15-30 min.
Deep: ARCHITECTURE, invariant proximity, high lock-in. 30-45 min. Operator handshake.

### 0.5 — Environment & Information Check

All info available: proceed normally.
Info gaps: investigate if quick; otherwise flag as assumptions, choose PROVISIONAL.
External data needed: produce evaluation with gap flagged, present to operator.

---

## PHASE 1 — OPTION ENUMERATION

### 1.1 — Genuine Alternatives

List every viable option (minimum 2, maximum 5). "Viable" means could actually
be implemented and is not trivially inferior.

Anti-anchoring check: "If someone told me my preferred option was off the table,
what would I do instead?"

For each option: name, approach description, and precedent.

### 1.2 — Null Option (Mandatory)

Always include applicable null options:
- DEFER: decide later (what is the cost of delay?)
- AVOID: restructure to eliminate the fork entirely
- ACCEPT: do nothing (is the current state actually acceptable?)

---

## PHASE 2 — EVALUATION FRAMEWORK

### 2.1 — Dimension Selection

Select 3-6 dimensions that actually differentiate the options. Common dimensions:
invariant compliance, trajectory alignment, complexity cost, reversibility,
dependency footprint, proven ground, blast radius, effort cost, timeline impact,
risk profile, information gain, operator preference.

### 2.2 — Evaluation Matrix

Score each option per dimension using three levels:
- Strong (performs well)
- Acceptable (manageable tradeoffs)
- Weak (performs poorly or introduces clear risk)

Tie-breaking: prefer higher reversibility, then lower complexity,
then commit as PROVISIONAL.

### 2.3 — Disqualification Check

Hard disqualifiers: invariant violation, resource constraint violation,
operator explicit veto. Flagged (not disqualified): trajectory foreclosure,
reversal cost exceeds threshold. If all options disqualified: return to
Phase 1 or escalate constraint set to operator.

---

## PHASE 3 — TRADEOFF ARTICULATION

### 3.1 — Per-Option Tradeoff Narrative

For each surviving option: strengths, costs, assumptions (verified/unverified),
and reversal description.

### 3.2 — Head-to-Head Differentiator

For two-option decisions, state directly:
"Choosing A over B means accepting [cost of A] in exchange for [advantage of A]."
"Choosing B over A means accepting [cost of B] in exchange for [advantage of B]."

For three+ options: pairwise comparisons of top contenders (max 3 pairs).
If you cannot complete these sentences, the evaluation is not yet sharp enough.

---

## PHASE 4 — DECISION

### 4.1 — Selection

Choose one option. State it clearly: DECISION: Option [X] — [Name].

Decision method guidance: dominant option = select; one weakness on non-critical
dimension = select leader; genuine tie = tie-breaking rules; matrix vs gut
disagree = investigate the un-modeled dimension; no good option = defer or
PROVISIONAL least-bad; operator-relevant = present evaluation and let operator decide.

### 4.2 — Rationale

Three questions only:
1. Why this option? (positive case)
2. Why not the runner-up? (comparative case)
3. Under what conditions would this decision change? (revisit-if conditions)

### 4.3 — Commitment Level

LOCKED: final for current phase. Reversal requires new DECIDE with new info.
PROVISIONAL: best current choice, explicitly open to revision.
EXPERIMENTAL: chosen to gather information. Time-boxed. Minimal commitment.

---

## PHASE 5 — IMPACT MAPPING

### 5.1 — Downstream Impact

For each impact area, document effect and action required:
existing code/artifacts, active invariants, in-progress work,
system prompt claims, dependency chain, timeline, resource requirements,
risk profile.

### 5.2 — Reversal Plan

Trigger (linked to revisit-if), point of no return (if applicable),
full reversal path and cost (LOW/MEDIUM/HIGH/IRREVERSIBLE),
artifacts affected, regression verification needed.
Partial reversal option: what to keep, what to change, cost.

---

## PHASE 6 — DECISION RECORD

The exportable artifact. Primary deliverable of the protocol.

Record contains: ID (DEC-NNN), date, type, urgency, context, fork question,
related prior decisions, options considered (with disqualified noted),
decision and commitment level, rationale (why this, why not runner-up,
revisit-if conditions, monitored by), impact (modifies, preserves, enables,
forecloses, timeline), reversal (cost, point of no return, path),
stakeholder status (OPERATOR CONFIRMED / INFORMED / MODEL AUTONOMOUS).

---

## DECISION RE-EVALUATION

When a revisit-if condition fires (detected by CHECKPOINT, GAUGE, or observation):

1. Declare re-entry: original decision ID, which condition fired, evidence.
2. Re-read original record. Is the rationale still valid?
3. If rationale holds: reaffirm with note. Decision stands.
4. If rationale no longer holds: new DECIDE cycle. Original rejected options
   available as starting points. New record references original as superseded.
5. LOCKED decisions: re-evaluation requires new information or changed constraints.
   Disliking the outcome is not grounds for reopening.

---

## DECISION CONFLICT HANDLING

When a new decision contradicts a prior LOCKED decision:

Nature types:
- CONTRADICTS: directly opposite commitments. Cannot coexist.
- UNDERMINES: weakens prior decision value. Log as risk.
- SUPERSEDES: new information makes prior obsolete. Retire prior.

Resolution: SUPERSEDES = retire prior. CONTRADICTS = re-evaluate or escalate.
UNDERMINES = flag tension, re-evaluate at next phase boundary.

---

## BATCH DECISION SUPPORT

When multiple related forks surface simultaneously:

1. Identify dependencies between forks (some constrain others).
2. Sequence by dependency order.
3. Identify interactions (where best option for Fork A depends on Fork B).
4. Maximum batch size: 3. Beyond 3, group into sub-batches.
5. Each fork gets its own decision record (independently reversible).

---

## PROTOCOL COMPOSITION

Upstream triggers:
- ALIGN gap classified as DECIDE (multiple valid closing approaches).
- FAULT alternative enumeration produces options with non-obvious tradeoffs.
- GAUGE contradictory requirements or multiple valid implementation paths.
- CHECKPOINT revisit-if condition fires on a prior decision.
- BOOT state discrepancy resolvable multiple ways.
- Operator explicitly asks to evaluate a choice.

Downstream routing:
- Decision record to FORGE (prompt evolution, architectural history).
- Impact map to ALIGN (adjust closing vectors).
- Implementation requirement to GAUGE (track whether decisions are implemented).
- Revisit-if conditions to CHECKPOINT (monitor during health checks).
- Reversal plan to FAULT (starting point if decision proves wrong).
- Experimental time-box to CHECKPOINT (monitor for expiration).

---

## OPERATING CONSTRAINTS

- This protocol does not make the decision for the operator. It structures
  evaluation, articulates tradeoffs, and produces a recommendation.
- Operator-absent autonomy: model may decide autonomously for STRATEGY/PROCESS
  with PROVISIONAL commitment. ARCHITECTURE/SCOPE with LOCKED commitment
  requires operator confirmation.
- Decision urgency governs pace, not depth. BLOCKING = faster, not shallower.
- Gut instinct is data, not governance. Note it, then verify it survives
  the evaluation framework.
- Not every fork is a protocol activation. Phase 0 filters trivial choices.
- Decision records accumulate into design history. FORGE treats the collection
  as first-class source material for system prompt evolution.

> Closing constraint: This protocol succeeds when a future session, reading
> the decision record, can answer: "Would I have made the same choice given
> the same information? And if conditions have changed, do I now have grounds
> to revisit?" If the record cannot support both questions, sharpen the
> rationale before committing.

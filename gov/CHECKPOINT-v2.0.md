# ⟁ CHECKPOINT — Mid-Session Diagnostic & Health Audit Protocol
### Version 2.0 — Hardened

> **Drop-in instruction.** Paste this protocol into any active session to force a structured diagnostic halt — an honest assessment of where the session is, whether it has drifted, whether its assumptions still hold, and whether its trajectory is sound. This protocol audits the session itself: its progress, its reasoning quality, its resource health, and the integrity of its governing instruments. It produces a corrected forward path and a portable state snapshot.

---

## GOVERNING PRINCIPLE

**A session in motion stays in motion — including when it's moving in the wrong direction.** Generative momentum is the model's greatest asset and its most dangerous liability. Without periodic, structured examination, a session will continue producing output that feels productive but may be drifting from the objective, operating on stale assumptions, or consuming irreplaceable resources on low-leverage work.

This protocol exists to interrupt momentum with honesty.

**Three laws of session diagnostics:**

1. **Progress is not the same as value.** A session that has produced twenty outputs has not necessarily delivered twenty units of value. Some outputs close requirements. Some outputs are scaffolding. Some outputs are drift. CHECKPOINT distinguishes between them.

2. **Assumptions decay.** Every assumption the session is operating on was true at some point. Some are still true. Some have been silently invalidated by work done since they were formed. CHECKPOINT audits assumptions the way FAULT audits error states — systematically, not hopefully.

3. **The session cannot evaluate itself while running.** Self-assessment during generative work is optimistically biased by design — the model believes it is making progress because it is producing output. Genuine evaluation requires a hard stop and a shift to forensic mode.

---

## SCOPE BOUNDARY

**CHECKPOINT does:**
- Force a diagnostic halt and shift to forensic auditor mode
- Capture the session's trajectory delta (origin to current state)
- Audit reasoning quality, assumption validity, and structural soundness of outputs
- Detect drift, stickiness traps, and sunk cost patterns
- Monitor DECIDE revisit-if conditions and EXPERIMENTAL time-boxes
- Assess resource health (context window, session duration, throughput)
- Verify governing document accuracy against actual state
- Assess protocol health (active ALIGN/FAULT/DECIDE runs)
- Produce a corrected forward path aligned with GAUGE priorities
- Output a portable session state snapshot for FORGE consumption

**CHECKPOINT does not:**
- Fix the problems it finds (it routes to FAULT, ALIGN, DECIDE, or FORGE as appropriate)
- Extract or audit the full requirement set (that is GAUGE responsibility)
- Make architectural decisions (that is DECIDE responsibility)
- Modify the governing document (that is FORGE responsibility)
- Recover from errors (that is FAULT responsibility)

---

## PHASE 0 — TRIGGER & INTAKE

### 0.1 — Trigger Classification

PERIODIC: Scheduled at regular intervals.
EVENT-DRIVEN: A significant event occurred.
PROTOCOL-TRIGGERED: Another protocol explicitly invoked CHECKPOINT.
OPERATOR-REQUESTED: The operator explicitly asked for a diagnostic.
SELF-DETECTED: The model recognizes signs of drift or diminishing returns.

### 0.2 — Checkpoint Declaration

Checkpoint number, trigger type, trigger detail, prior checkpoint reference,
session duration since start or last checkpoint.

### 0.3 — Scaling Declaration

Quick: Abbreviated (Phases 1,4,6,7 only). 5-10 minutes.
Standard: Full protocol, standard depth. 15-30 minutes.
Deep: Full protocol, maximum depth. All assumptions audited. 30-45 minutes.
Targeted: Only phases relevant to the triggering concern. 5-15 minutes.

### 0.4 — Environment Check

Tool access available: Full diagnostic with file inspection.
Chat-only session: Diagnose from conversation evidence. Produce verification checklist.
Partial tool access: Verify what is accessible. Note what cannot be checked.

---

## PHASE 1 — TRAJECTORY DELTA

### 1.1 — Objective Tracking

Origin objective, current objective, and objective evolution
(OPERATOR-DIRECTED, EMERGENT, or UNINTENTIONAL).

### 1.2 — Delta Log

For each significant action since start or last checkpoint:
Step, Action, Classification (PRODUCTIVE/LATERAL/REGRESSIVE/OVERHEAD),
Value Assessment (HIGH/MEDIUM/LOW/ZERO).
Summary with value ratio = (HIGH+MEDIUM count) / total.

### 1.3 — Assumption Audit

Surface assumptions still being relied upon. For each:
assumption, when formed, still valid, evidence, risk if wrong.
Priority: check highest risk-if-wrong first.

---

## PHASE 2 — QUALITY AUDIT

### 2.1 — Logic & Reasoning Audit

Check for: circular reasoning, unsupported leaps, false equivalences,
unexamined premises, confirmation bias.

### 2.2 — Structural Audit

Check for: load-bearing vs decorative structures, edge case resilience,
consistency between outputs at different session points.

### 2.3 — Confidence Calibration

For claims generated from pattern-matching rather than grounded knowledge:
claim, confidence (HIGH/MEDIUM/LOW), basis (grounded/inferred/assumed), action.
HIGH+grounded = keep. MEDIUM+inferred = verify if load-bearing.
LOW+assumed = retract or flag for operator.

### 2.4 — Protocol-Specific Audit (Deep and Targeted tiers)

Invariant compliance, DECIDE revisit-if monitoring, DECIDE experimental
time-boxes, FAULT recurrence detection, GAUGE requirement regression.

---

## PHASE 3 — DRIFT ANALYSIS

### 3.1 — Drift Detection

Objective drift, scope drift, quality drift, vocabulary drift.
Severity: NONE / MINOR / MODERATE / SEVERE.
SEVERE = halt and recalibrate with explicit scope reset.

### 3.2 — Stickiness & Sunk Cost Audit

Stickiness traps (framings carried forward uncritically),
sunk cost residue (continuing past diminishing returns),
premature convergence (locked onto single approach).
For each: state what should change going forward.

---

## PHASE 4 — RESOURCE & HEALTH ASSESSMENT

### 4.1 — Resource Monitoring

Context window: HEALTHY (<50%) / ELEVATED (50-75%) / CRITICAL (>75%).
Session duration, throughput (value ratio), tool availability.
CRITICAL context = compress or drop; prioritize highest-value work.
ELEVATED context = plan for management.

### 4.2 — Protocol Health Check (Standard and Deep tiers)

Active ALIGN runs, active FAULT runs, pending DECIDE records,
GAUGE currency, governing document accuracy.

### 4.3 — Governing Document Health (Deep tier)

Compare document claims against actual state.
Findings route to FORGE for correction.

---

## PHASE 5 — SIGNAL EXTRACTION

### 5.1 — High-Value Outputs

List concrete artifacts, decisions, insights worth carrying forward.
For each: output, type, GAUGE requirement, carry forward (YES/CONDITIONAL/NO).
Outputs that close requirements are definitionally high-value.

### 5.2 — Context Management

Active context: must remain accessible. Preserve.
Archivable context: served its purpose. Summarize and release if context elevated.
Discardable context: no value. Capture lesson in one sentence, then discard.

### 5.3 — Unresolved Thread Routing

For each open question or ambiguity:
thread, priority (BLOCKING/HIGH/MEDIUM/LOW),
route (FAULT/DECIDE/ALIGN/GAUGE/OPERATOR/DEFER).

---

## PHASE 6 — RECALIBRATED TRAJECTORY

### 6.1 — Refined Objective

Restate the goal: sharper, more precise, stripped of early-session fog.
Original, Refined, Delta (UNCHANGED/SHARPENED/EXPANDED/NARROWED/PIVOTED).

### 6.2 — Recommended Next Actions

2-5 concrete, prioritized actions. Must be consistent with GAUGE ordering
unless CHECKPOINT has explicit rationale for override.

### 6.3 — Active Guardrails

Failure modes, drift patterns, and threats to watch.
For each: guardrail, source, monitoring signal.

---

## PHASE 7 — SESSION STATE SNAPSHOT

### 7.1 — Snapshot

Checkpoint number, date, governing doc version, session objective, status
(ON TRACK / MINOR DRIFT / MODERATE DRIFT / SEVERE DRIFT / PIVOTED / STALLED),
progress summary, value ratio, key outputs, open items with routing,
risk flags, resource health, protocol health, next action, guardrails,
FORGE input.

### 7.2 — Checkpoint Delta (when prior checkpoint exists)

Status change, progress delta, new risks, resolved risks, resource trend.

---

## RE-RUN GOVERNANCE

Short session (<20 turns): once at midpoint or before delivery.
Medium session (20-50 turns): every 15-20 turns or at phase boundaries.
Long session (50+ turns): every 10-15 turns. Deep at boundaries, Quick between.
Crisis session: after each FAULT resolution. Targeted tier.

Sequential IDs (CHK-1, CHK-2). Each includes delta vs prior.
3 successive unresolved risk flags = escalate.
2 successive SEVERE DRIFT = hard reset (GAUGE + ALIGN).

---

## PROTOCOL COMPOSITION

CHECKPOINT is the session monitoring layer. It observes all other protocols
and routes findings to the appropriate handler.

Upstream triggers:
- Periodic cadence: Standard CHECKPOINT at scheduled intervals.
- DECIDE experimental time-box expires: Targeted CHECKPOINT, routes to DECIDE.
- BOOT initialization completes: Quick CHECKPOINT for baseline.
- GAUGE phase boundary reached: Deep CHECKPOINT for phase readiness.
- FAULT resolution completes: Targeted CHECKPOINT to verify no drift.
- Operator requests status: Standard or Deep per need.

Downstream routing:
- Session state snapshot to FORGE (document evolution).
- Governing document findings to FORGE (patch or evolve).
- DECIDE revisit-if triggered to DECIDE (re-evaluation).
- Invariant violation to FAULT (diagnosis and recovery).
- FAULT recurrence to FAULT (related fault entry).
- Stalled ALIGN target to ALIGN (replanning).
- Requirement regression to GAUGE (status update).
- Recalibrated priorities to GAUGE (if ordering is stale).
- Unresolved threads to routing table (FAULT/DECIDE/ALIGN/GAUGE/OPERATOR).

---

## OPERATING CONSTRAINTS

- This diagnostic is a tool, not a performance. Optimize for honesty.
  If a phase has nothing to report, say so in one line. Never pad.
- CHECKPOINT does not fix — it routes. Every finding must be corrected
  or routed. Findings neither corrected nor routed are waste.
- CHECKPOINT does not override GAUGE without explicit rationale.
- Scaling is mandatory. Quick for healthy sessions. Deep for trouble.
- Frequency is governed. Catch drift before severe, but do not let
  overhead dominate productive work.
- Context window awareness. CHECKPOINT itself consumes context.
  In ELEVATED or CRITICAL states, use Quick tier.
- Successive comparison is mandatory after the first checkpoint.
- FORGE input is not optional for Standard or Deep tiers.

> Closing constraint: This protocol succeeds when a session can answer
> with precision: Where am I? Am I where I should be? What has drifted?
> What do I do next? Too shallow if it cannot answer all four. Too deep
> if it costs more than the remaining session can afford.

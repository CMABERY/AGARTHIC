# ⧖ DECIDE — Architectural Decision Protocol
### v3.0 — Structural Rewrite

> **Drop-in instruction.** Paste into any session that has reached a fork — multiple valid approaches, non-obvious tradeoffs, and a choice that shapes downstream work in ways difficult or costly to reverse. Forces structured evaluation, records rationale, and produces a portable decision record that survives across sessions.

---

## § 0 — LAW

Every unrecorded decision is a future mystery. The choice persists in code and architecture, but the reasoning evaporates. A future session inherits the consequence without the logic. When conditions change, it cannot evaluate whether the original reasoning still holds. Three laws:

1. **A decision you cannot articulate is a decision you made by accident.** If you cannot state what you chose, what you rejected, and why — you defaulted. Defaults compound into architecture no one designed.
2. **The runner-up is as important as the winner.** The rationale is not "why A is good" — it is "why A over B." Without rejected alternatives on record, the decision cannot be re-evaluated when conditions change.
3. **Reversibility is a first-class property.** A reversible decision made quickly is nearly always better than an irreversible decision made slowly. Every decision has a reversal cost. That cost must be known before committing.

---

## § 1 — FORK RECOGNITION

### 1A — Activation Criteria

Not every choice is a decision point. The protocol activates when a choice meets **any two** of these criteria:

| Criterion | Signal |
|-----------|--------|
| **Multiple viable approaches** | ≥2 genuinely different strategies, not syntactic variants of one. |
| **Non-obvious tradeoffs** | Each option has advantages and costs. No option strictly dominates. |
| **Downstream lock-in** | The choice constrains future decisions. Switching later requires rework, not a parameter change. |
| **Invariant proximity** | The choice touches, tests, or stresses a system constraint or boundary condition. |
| **Cross-session persistence** | The choice embeds in artifacts that outlive this session. |
| **Operator-relevant** | The operator would want to know or have input. |

**Fast-track:** Any fork scoring YES on `Invariant proximity` activates regardless of other criteria.

**If fewer than two (and no fast-track):** Choose and move on. Over-governing trivial choices produces decision fatigue and dilutes the signal value of records that matter.

### 1B — Fork Declaration

```
⧖ DECISION POINT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Context:      [work being done when the fork emerged]
Fork:         [the choice, stated as a question]
Trigger:      [session work / gap analysis / fault alternative / requirement conflict / health audit / operator request]
Criteria met: [which activation criteria]
Urgency:      [BLOCKING — work stopped until decided]
              [HIGH — decide this session, affects priorities]
              [NORMAL — important but not time-sensitive]
              [LOW — deferrable without cost]
Related:      [DEC-NNN or "none"]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 1C — Classification & Scaling

| Type | Definition | Typical Scale |
|------|-----------|---------------|
| `TECHNOLOGY` | Tool, library, platform, framework, language feature. | Standard |
| `ARCHITECTURE` | Data model, component boundaries, communication patterns, abstraction layer. | Standard or Deep |
| `STRATEGY` | How to solve a problem, sequence work, trade speed vs. thoroughness. | Quick or Standard |
| `SCOPE` | What to include or exclude — feature boundaries, requirement interpretation, phase scope. | Standard |
| `RECOVERY` | Choice between recovery approaches after a fault. | Quick |
| `PROCESS` | Workflow, convention, communication, governance. | Quick |

| Tier | When | Phases |
|------|------|--------|
| **Quick** | STRATEGY/PROCESS/RECOVERY, urgency BLOCKING, low lock-in, easily reversible. | §2 (2–3 options) → §4B (head-to-head only) → §5 (decision + rationale) → §7 (compact record). Skip §3, §6. |
| **Standard** | TECHNOLOGY/SCOPE, NORMAL or HIGH urgency, moderate lock-in. | Full protocol. |
| **Deep** | ARCHITECTURE, invariant proximity, high lock-in, irreversible/near-irreversible, operator-relevant. | Full protocol, maximum depth. All options fully evaluated. Impact mapping mandatory. Operator confirmation before committing. |

### 1D — Information Gaps

| Situation | Approach |
|-----------|---------|
| All information available | Proceed through standard phases. |
| Resolvable gaps | Investigate first (targeted research). Then proceed. |
| Unresolvable gaps | Flag as assumptions in §4. Choose PROVISIONAL or EXPERIMENTAL commitment. |
| External data needed | Produce evaluation with gap flagged. Present to operator for completion. |

---

## § 2 — OPTION ENUMERATION

### 2A — Genuine Alternatives

List every viable option. "Viable" = could be implemented, is not trivially inferior, and the session could defend it if challenged.

**Constraints:** Minimum 2. If you cannot find two: either the path is forced (exit protocol, proceed) or you are anchored on one approach (the most dangerous state). Maximum 5. Beyond 5, group similar approaches and evaluate groups, then drill into the best.

**Anti-anchoring check:** If you arrived with a preferred option:

> *"If someone told me my preferred option was off the table, what would I do instead?"*

That answer is a genuine alternative.

For each option:

```
OPTION [A/B/C]: [Name — 2-5 words]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Approach:   [What it does. How it works. What it looks like built.]
Precedent:  [Used before in this project or similar context? Outcome?]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2B — Null Options (Mandatory)

Always evaluate options that avoid or defer the decision. Include whichever are genuinely defensible:

| Null Type | Question |
|-----------|----------|
| **DEFER** | What happens if postponed? Will more information emerge? What is the cost of delay? |
| **AVOID** | Can the work be restructured so this decision is unnecessary? Can the requirement be decomposed or the constraint relaxed? |
| **ACCEPT** | What happens if nothing changes? Is the current state actually acceptable? |

Mark inapplicable null options as such. Do not force-fit them.

---

## § 3 — EVALUATION FRAMEWORK

### 3A — Dimension Selection

Select 3–6 dimensions that **actually differentiate** the options. If all options score identically on a dimension, it is not diagnostic — omit it.

**Dimension library** (select only what differentiates for this fork):

| Dimension | Measures |
|-----------|---------|
| **Invariant compliance** | Does this satisfy all active constraints? |
| **Trajectory alignment** | Does this keep the project compatible with its stated direction? |
| **Complexity cost** | How much complexity introduced — code, config, mental model, maintenance? |
| **Reversibility** | How difficult to switch away later? What is the reversal cost? |
| **Dependency footprint** | What new dependencies introduced? |
| **Proven ground** | Builds on patterns already proven in this project? |
| **Blast radius** | If wrong, how much is affected? Contained or propagating? |
| **Effort cost** | Work required to implement? |
| **Timeline impact** | Effect on schedule? |
| **Risk profile** | New risks introduced? Existing risks mitigated? |
| **Information gain** | Produces useful information regardless of whether it's the final choice? |
| **Operator preference** | Has the operator expressed a bearing preference? |

### 3B — Evaluation Matrix

Three-level scale — finer gradations create false precision:

| Symbol | Meaning |
|--------|---------|
| ✅ | Strong — performs well on this dimension |
| ⚠️ | Acceptable — manageable tradeoffs or unknowns |
| ❌ | Weak — performs poorly or introduces clear risk |

```
EVALUATION MATRIX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Dimension           Option A   Option B   Option N
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[dimension 1]          ✅         ⚠️         ✅
[dimension 2]          ✅         ✅         ⚠️
[dimension 3]          ⚠️         ✅         ✅
[dimension 4]          ❌         ✅         ⚠️
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Tie-breaking cascade:** (1) Re-examine dimensions — a tie often means the differentiating axis was omitted. (2) Prefer higher reversibility. (3) Prefer lower complexity. (4) If still tied, select either and commit PROVISIONAL.

### 3C — Disqualification Check

| Disqualifier | Rule |
|-------------|------|
| **Invariant violation** | ❌ on invariant compliance → **Disqualified.** Invariants are boundaries, not tradeoffs. |
| **Resource impossibility** | Requires demonstrably unavailable resources → **Disqualified.** |
| **Operator veto** | Operator has explicitly excluded this approach → **Disqualified.** |
| **Trajectory foreclosure** | ❌ on trajectory alignment → **Flagged.** Not disqualified, but record must acknowledge what is foreclosed. |
| **Irreversible at threshold** | Reversal cost exceeds what the project can absorb → **Flagged.** Only selectable with LOCKED commitment and operator awareness. |

**If all options disqualified:** The option set is incomplete. Return to §2. If no compliant alternative exists after good-faith enumeration, the constraint set itself may need re-examination — escalate to operator.

---

## § 4 — TRADEOFF ARTICULATION

### 4A — Per-Option Narrative

For each surviving option:

```
OPTION [A]: [Name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Strengths:    [What this does better than alternatives. Specific — not "simpler"
               but "requires no new dependencies and builds on the proven
               handler pattern from §8."]
Costs:        [What this sacrifices. Specific — not "more complex" but
               "introduces a second data path requiring sync, creating drift risk."]
Assumptions:  Verified: [confirmed with evidence]
              Unverified: [not confirmed — these are risks]
Reversal:     [If wrong, what does rollback look like? Hours of rework?
               Config change? Complete redesign? What is salvageable?]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4B — Head-to-Head Differentiator

**Two options:** State the core tradeoff directly:

> *"Choosing A over B means accepting [cost of A] in exchange for [advantage of A over B]."*
> *"Choosing B over A means accepting [cost of B] in exchange for [advantage of B over A]."*

**Three+ options:** Pairwise comparisons for top contenders (maximum 3 pairs).

This formulation forces honesty about what is being traded. If you cannot complete these sentences, the evaluation is not yet sharp enough.

---

## § 5 — DECISION

### 5A — Selection

```
DECISION: Option [X] — [Name]
```

**When the matrix doesn't produce a clear winner:**

| Situation | Method |
|-----------|--------|
| One option dominates | Select it. |
| Leader with one weakness | If weakness is on a non-critical dimension, select the leader. |
| Genuine tie | Use tie-breaking cascade from §3B. |
| Matrix favors A, gut favors B | Investigate — the gut may be weighing an un-modeled dimension. Add it and re-evaluate. If matrix still favors A, go with A. |
| No option clearly good enough | Is DEFER viable? If not, select least-bad with PROVISIONAL commitment. |
| Operator-relevant | Present completed evaluation. Model recommends; operator decides. |

### 5B — Rationale

Three questions — and only these three:

```
RATIONALE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Why [X]:      [the positive case — 2-3 sentences]
Why not [Y]:  [the comparative case — what specific cost of Y was
               unacceptable, or what advantage of X was decisive]
Revisit if:   [falsifiable conditions that reopen this decision]
              - [condition 1]
              - [condition 2]
Monitored by: [health audit / progress assessment / specific trigger]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 5C — Commitment Level

| Level | Meaning | When | Governance |
|-------|---------|------|-----------|
| `LOCKED` | Final for current phase. Reversal requires new DECIDE with new information. | High lock-in. Operator confirmed. Assumptions verified. | Record in governing document. Revisit-if is the only reopening mechanism. |
| `PROVISIONAL` | Best current choice, open to revision. | Unverified assumptions, time pressure, incomplete information. | Record in session state. Re-evaluate at next health audit or when assumptions can be checked. |
| `EXPERIMENTAL` | Chosen to gather information. Expected to be revisited. | Multiple viable options; information gain will differentiate. | Time-box the experiment. Set review trigger. Isolate implementation. |

---

## § 6 — IMPACT MAPPING

### 6A — Downstream Impact

| Impact Area | Effect | Action Required |
|------------|--------|-----------------|
| Existing artifacts | [what changes, what unaffected] | [specific modifications] |
| Active constraints | [which constraints this interacts with] | [verification needed] |
| In-progress work | [affected open items] | [adjustments] |
| Governing document claims | [state claims now stale] | [flag for document evolution] |
| Dependency chain | [unblocks or blocks other decisions] | [update dependencies] |
| Timeline | [accelerates, delays, or neutral] | [priority adjustment if needed] |
| Risk profile | [new risks introduced, existing risks mitigated] | [update risk tracking] |

### 6B — Reversal Plan

Even for LOCKED decisions — *especially* for LOCKED decisions:

```
REVERSAL PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Trigger:             [linked to revisit-if conditions]
Point of no return:  [if applicable — when reversal becomes infeasible]
Full reversal cost:  [LOW / MEDIUM / HIGH / IRREVERSIBLE]
  Artifacts affected: [files, configs, tests, docs]
  Re-verification:   [what must be re-tested after reversal]
Partial reversal:    [if full reversal too costly — what to keep, what to change, cost]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 7 — DECISION RECORD

The primary deliverable. What survives across sessions, what the governing document consumes, what future sessions use to understand *why*.

```
⧖ DECISION RECORD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID:           DEC-[N]
Date:         [timestamp]
Type:         [TECHNOLOGY / ARCHITECTURE / STRATEGY / SCOPE / RECOVERY / PROCESS]
Urgency:      [BLOCKING / HIGH / NORMAL / LOW]
Context:      [what surfaced this — 1-2 sentences]
Fork:         [the question]
Related:      [DEC-NNN or "none"]

Options considered:
  [A] [Name] — [one-line summary]
  [B] [Name] — [one-line summary]
  [N] [Null type] — [one-line summary]
  Disqualified: [list + reason, or "none"]

Decision:     Option [X] — [Name]
Commitment:   [LOCKED / PROVISIONAL / EXPERIMENTAL]

Rationale:
  Why [X]:      [2-3 sentences]
  Why not [Y]:  [1-2 sentences]
  Revisit if:   [conditions]
  Monitored by: [what checks revisit-if conditions]

Impact:
  Modifies:     [artifacts affected]
  Preserves:    [constraints verified unaffected]
  Enables:      [what this unblocks]
  Forecloses:   [what this makes harder — "none" if none]
  Timeline:     [schedule impact — "none" if none]

Reversal:
  Cost:              [LOW / MEDIUM / HIGH / IRREVERSIBLE]
  Point of no return: [if applicable]
  Path:              [brief reversal description]

Stakeholder:  [OPERATOR CONFIRMED / OPERATOR INFORMED / MODEL AUTONOMOUS]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 8 — RE-EVALUATION

When a revisit-if condition fires — detected by health audit, progress assessment, or session observation — the decision is formally reopened.

### 8A — Re-entry

```
⧖ RE-EVALUATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Original:    DEC-[N]
Triggered:   [which revisit-if condition fired]
Evidence:    [what changed]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 8B — Procedure

1. Re-read the original record. Is the rationale still valid under new conditions?
2. **If rationale holds:** Reaffirm. Append note: "Re-evaluated [date] due to [trigger]. Rationale confirmed."
3. **If rationale no longer holds:** New DECIDE cycle. Original rejected options available as starting points. New record references original as `Related: DEC-N (superseded)`.
4. **If decision was LOCKED:** Re-evaluation requires new information or changed constraints. Disliking the outcome is not grounds for reopening.

---

## § 9 — CONFLICT HANDLING

When a new decision contradicts a prior LOCKED decision:

```
⧖ CONFLICT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
New:          DEC-[new] — [option]
Conflicts:    DEC-[prior] — [what it decided]
Nature:       [SUPERSEDES / CONTRADICTS / UNDERMINES]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

| Nature | Resolution |
|--------|-----------|
| `SUPERSEDES` | New information makes prior obsolete. Retire prior. New record references it as superseded. |
| `CONTRADICTS` | Both cannot coexist. Re-evaluate prior via §8, or escalate to operator if both were operator-confirmed. |
| `UNDERMINES` | Both can coexist but combination is suboptimal. Log as risk. Re-evaluate at next phase boundary. |

---

## § 10 — BATCH DECISIONS

When multiple related forks surface simultaneously:

**Rules:**
1. **Identify dependencies.** If Fork A's answer determines which options are viable for Fork B, decide A first.
2. **Sequence by dependency.** Each decision's record is context for downstream decisions.
3. **Identify interactions.** If best option for A depends on choice for B (and vice versa), decide them together.
4. **Maximum batch: 3.** Beyond 3, group into sub-batches ordered by dependency.
5. **Each fork gets its own record.** Batch processing is for analysis efficiency — each decision is independently recorded, reversible, and re-evaluable.

```
BATCH DECIDE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Forks:
  1: [question] — depends on: [nothing / Fork N]
  2: [question] — depends on: [Fork 1]
  3: [question] — interacts with: [Fork 2]
Order: 1 → 2+3 (together due to interaction)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 11 — OPERATING CONSTRAINTS

**On operator authority.** This protocol structures evaluation, articulates tradeoffs, and produces a recommendation. When the decision is operator-relevant, the operator is presented with the completed evaluation and given the choice.

**On autonomous authority (operator absent):**

| Condition | Authority |
|-----------|----------|
| STRATEGY/PROCESS type, PROVISIONAL/EXPERIMENTAL commitment | Model decides. Record as `MODEL AUTONOMOUS`. |
| TECHNOLOGY type, urgency BLOCKING | Model decides PROVISIONAL. Flag for operator review. |
| ARCHITECTURE/SCOPE type, LOCKED commitment | **Do not commit without operator confirmation.** Present evaluation and wait, or commit PROVISIONAL and flag for upgrade. |
| Any decision foreclosing trajectory or touching invariants | **Do not commit without operator confirmation.** |

**On pace.** Urgency governs speed, not depth. A BLOCKING decision uses Quick tier but does not skip evaluation — speed comes from abbreviating documentation, not skipping analysis.

**On intuition.** Gut instinct is data, not governance. Note it, then verify it survives the framework. Intuitions that survive structured evaluation are usually correct. Those that don't are the ones that would have caused the most damage.

**On protocol economy.** This protocol should take minutes, not hours. If analysis exceeds 45 minutes, either the fork is genuinely complex (Deep tier) or analysis has lost focus. The head-to-head differentiator (§4B) forces clarity quickly.

**On activation discipline.** §1A exists to filter trivial choices. The protocol's value is inversely proportional to how often it runs on decisions that don't need it.

**On accumulation.** Decision records are the "why" layer no codebase captures on its own. The governing document should treat this collection as first-class source material.

---

*The protocol succeeds when a future session, reading the decision record, can answer: "Would I have made the same choice given the same information? And if conditions have changed, do I now have grounds to revisit?" If the record cannot support both questions, the rationale is insufficiently captured.*

# ⟐ FORGE — Governing Document Protocol
### v3.0 — Structural Rewrite

> **Drop-in instruction.** Paste into any session where a governing document must be created, evolved, or patched. Self-orients from available materials. No project-specific configuration required.

---

## § 0 — LAW

A governing document is a constitutional instrument. A model initialized with it makes architecturally sound decisions on turn one — not turn ten. Three laws:

1. **Every sentence carries load or gets cut.** No restatement, no throat-clearing, no filler that echoes what a table already shows.
2. **The document does not invent state.** Unproven capabilities are marked unproven. Optimistic claims are the primary drift vector.
3. **The document expects succession.** It versions itself, declares lineage, and is structured to be *evolved* — not rewritten.

---

## § 1 — MODE SELECTION

Determine mode before any other work.

| Mode | Trigger | Scope |
|------|---------|-------|
| **CREATE** | No prior document exists, or the existing one is fundamentally misaligned with reality. | Full construction: §1–§8. |
| **EVOLVE** | Prior version exists; stale across multiple sections or structurally deficient. | Delta analysis (§3) → selective reconstruction. |
| **PATCH** | ≤3 sections affected. Targeted correction, integration, or deprecation. | Differential update (§3D) only. |

---

## § 2 — MATERIAL INGESTION

**Consume everything before writing anything.**

### 2A — Inventory

For every available source, record: present → consumed → key extractions.

Applicable source types: prior governing document, audit/scorecard outputs, fault/failure reports, decision records, alignment/convergence records, health assessments, initialization session findings, project documentation, code/schemas/configs, conversation transcripts, operator instructions.

**Rule:** Every source marked present must be consumed before composition begins. If a source cannot be fully consumed, note what was sampled and what was missed.

### 2B — Extraction Dimensions

Extract and tag across these dimensions from every consumed input:

| Dimension | Extract |
|-----------|---------|
| **Proven state** | What is built, tested, confirmed working — and what evidence exists? |
| **Active work** | What is in progress? What is the immediate next step? |
| **Decisions** | What design choices were made, why, and what was rejected? |
| **Invariants** | What rules are non-negotiable regardless of context? |
| **Threats** | What can go wrong? What attack surfaces, failure modes, and open boundaries exist? |
| **Vocabulary** | What terms carry precise project-specific meaning? |
| **Trajectory** | Where is this heading? What future capabilities are planned? |
| **Drift events** | What went wrong previously? What was repaired? What was learned? |
| **Role** | What must the model do? What is it forbidden from doing? |

PATCH mode: extract only dimensions relevant to the targeted change.

### 2C — Environment Capability

| Environment | Verification Approach |
|------------|----------------------|
| **Tool access** | Verify all state claims against actual system state. File paths, configs, versions — checked on disk. |
| **Chat-only** | Produce document from conversation evidence. Flag unverifiable claims as `[UNVERIFIED]`. Produce verification checklist for operator. |
| **Partial access** | Verify what is accessible. Flag everything else. |

---

## § 3 — DELTA ANALYSIS

*CREATE mode: skip to §4.*

### 3A — State Drift (EVOLVE)

| Drift Class | Check Against |
|------------|---------------|
| **Overstated claims** | What the prior document calls "proven" that has been invalidated, rolled back, or was never confirmed. |
| **Understated progress** | Achievements since last version: new capabilities, closed threats, sealed phases. |
| **Stale references** | File paths, version numbers, configs, schema locations that have changed. |
| **Vocabulary drift** | Terms redefined, introduced, or deprecated since last version. |
| **Unintegrated decisions** | Committed decisions not yet reflected in the document. |
| **Unintegrated prevention** | Failure-prevention recommendations not yet incorporated as constraints or boundary conditions. |

### 3B — Structural Drift (EVOLVE)

Check for: missing sections (new information categories with no home), misaligned priorities, orphaned content (completed phases, deprecated features — dead weight), trajectory misalignment, structural inadequacy (sections too large, too granular, or poorly grouped for current complexity).

### 3C — Delta Classification (EVOLVE)

Classify every identified delta:

| Class | Meaning | Priority |
|-------|---------|----------|
| `PRESERVE` | Current, accurate, load-bearing. Keep as-is. | — |
| `CORRECT` | Factual error in sound structure. Fix the error only. | 1 |
| `INTEGRATE` | New information must be added from upstream outputs. | 2 |
| `NEW` | Information exists in inputs but has no representation in the document. | 2 |
| `REFACTOR` | Partially correct; needs restructuring or significant rewrite. | 3 |
| `TRAJECTORY` | Forward-looking context to add (clearly marked as trajectory, not proven). | 3 |
| `DEPRECATE` | No longer relevant. Remove with rationale in version notes. | 4 |

### 3D — Differential Update (PATCH)

```
⟐ PATCH
Prior version:      [version ID]
Change type:        [CORRECT / INTEGRATE / DEPRECATE]
Sections affected:  [list]
Change description: [what + why]
Source:             [upstream reference]
```

Procedure: locate affected sections → apply surgical change → increment patch version → update header → verify internal consistency on affected sections only → deliver with patch notes.

**Escalation rule:** If a PATCH reveals >3 sections need changes or structural reorganization is required, escalate to EVOLVE.

---

## § 4 — STRUCTURAL ARCHITECTURE

### 4A — Canonical Sections

Evaluate each. Include what carries load; omit what doesn't.

```
HEADER
  Version · Status · Environment · Lineage
│
├── ROLE DEFINITION
│   What the model is, does, and does not do.
│
├── GOVERNING PRINCIPLES
│   Non-negotiable commitments. The "why" behind constraints.
│
├── INVARIANTS
│   Hard rules. Referenced by number. Binary pass/fail.
│
├── THREAT MODEL
│   Failure modes, attack surfaces, countermeasures.
│   Referenced by class number.
│
├── VOCABULARY
│   Project-specific definitions. One sentence each.
│
├── PROVEN STATE
│   What exists and works. Evidence level per claim:
│   proven · tested · assumed [UNVERIFIED].
│   File paths, configs, versions — specific, not vague.
│
├── ARCHITECTURE
│   How the system is wired. The navigation map.
│
├── DECISION HISTORY
│   Committed decisions: what, why, revisit-if.
│
├── EXECUTION PRIORITIES
│   What to work on, in what order. Blockers. Next actions.
│
├── BEHAVIORAL CONSTRAINTS
│   Session-scoped rules. Prohibited patterns. Known failure modes.
│
├── BOUNDARY CONDITIONS
│   Known risks not yet mitigated.
│   "Named residual risk is governed. Unnamed is a time bomb."
│
├── OPERATIONAL RUNBOOK
│   Procedures, learned patterns, prevention recommendations.
│
├── GATE CONDITIONS
│   Phase closure criteria. Binary. No partial credit.
│
├── EXTERNAL DEPENDENCIES
│   State of systems this project depends on.
│
├── ROADMAP
│   Phased. Dependency-mapped. Status per item.
│
└── FOOTER
    Version lineage · Context window cost · Hash
```

### 4B — Section Inclusion Test

For each canonical section, three questions:

1. **"Missing this, could the model make an incorrect architectural decision on turn one?"** → Yes: **REQUIRED.**
2. **"Missing this, could the model drift into incorrect behavior over a long session?"** → Yes: **INCLUDE** (lighter treatment acceptable).
3. **"Does this duplicate information available elsewhere in the document or in accessible artifacts?"** → Yes: **CONSOLIDATE.** Reference the canonical location.

### 4C — Scale Calibration

| Scale | Minimum Sections | Expand If Warranted |
|-------|-----------------|---------------------|
| **Small** — single task/session | Role, Invariants, Proven State, Priorities | Vocabulary, Behavioral Constraints |
| **Medium** — multi-session | Role, Principles, Invariants, Proven State, Architecture, Priorities, Vocabulary | Threat Model, Decisions, Gates, Runbook |
| **Large** — multi-phase | Evaluate all. Omit only what genuinely carries no load. | Boundary Conditions, Roadmap, Dependencies |

### 4D — Density Rules

| Section Type | Rule |
|-------------|------|
| Proven state | Maximally specific: paths, counts, hashes, exact config. Vagueness forces guessing. |
| Role / Principles | Precise, not verbose. One sharp paragraph beats ten hedged ones. |
| Invariants / Threats | Numbered tables. The model must cite "I-3" or "Class 7" — not describe from memory. |
| Decisions | Condensed: decision, rationale, revisit-if. Not the full evaluation. |
| Roadmap | Tables with status and dependencies. Not narrative. |
| Vocabulary | One-sentence definitions that could serve as compiler checks. |

---

## § 5 — COMPOSITION

### 5A — Writing Law

1. **Every sentence carries load or gets cut.**

2. **Optimize for random access, not linear reading.** The model re-reads specific sections mid-conversation. Structural precision over narrative flow.

3. **Imperative for constraints. Declarative for state.** "Do not expand scope beyond the declared phase." / "The kernel lives at `~/kernel/v2/`."

4. **Mark epistemics explicitly.**
   - **Proven** — tested, evidence exists, verified this version.
   - **Designed** — specified, not yet implemented.
   - **Planned** — on roadmap, not yet designed.
   - **Trajectory** — directional intent, may change.
   - **Assumed** — believed true, not verified. Flag: `[UNVERIFIED]`.

5. **Anchor temporally.** Never "recently" or "currently" without a version or date. "As of v3.0, 47 test cases pass" is verifiable. "Many tests pass" is noise.

6. **Resolve contradictions.** When sources disagree, the document resolves — not presents both. Use authority hierarchy: primary directives > binding constraints > reference material > informational context.

7. **Respect context budget.** Every line consumes tokens. If 5 lines suffice, 15 is waste — those 10 lines displace working context in future sessions.

8. **Uncertainty is signal.** `[ASSUMED — needs verification]` is more trustworthy than confident language papering over gaps.

### 5B — Composition Order

**CREATE — build in evidence order, deliver in reader order:**

*Build sequence:* Header → Proven State → Invariants & Threats → Role → Architecture → Decisions → Priorities & Gates → Behavioral Constraints → Vocabulary → Boundary Conditions → Roadmap → Runbook → Footer.

*Delivery order:* Role → Principles → Invariants → Threats → Vocabulary → Proven State → Architecture → Decisions → Priorities → Behavioral Constraints → Boundary Conditions → Runbook → Gates → Dependencies → Roadmap → Footer.

**EVOLVE — do not recompose from scratch:**
1. Preserve all `PRESERVE` sections verbatim.
2. Apply `CORRECT` (factual fixes).
3. Apply `INTEGRATE` and `NEW` (additions).
4. Apply `REFACTOR` (structural improvements).
5. Apply `DEPRECATE` (removals).
6. Verify cross-references hold across all changes.

**PATCH:** Per §3D. Touch only affected sections.

---

## § 6 — INTEGRITY VERIFICATION

### 6A — Internal Consistency

| Check | Method |
|-------|--------|
| Every cross-referenced section number exists | Scan all internal references |
| Every invariant ID referenced elsewhere is defined | Cross-reference I-[N] occurrences against definitions |
| File paths are consistent across sections | Deduplicate and compare; verify on disk if tool access available |
| Status markers match latest known state | Compare against most recent audit/scorecard output |
| Version numbers in header match body and footer | Direct comparison |
| Vocabulary terms are used consistently throughout | Search for each defined term |
| Decision records match committed upstream outputs | Compare record IDs |

### 6B — Completeness

- Every consumed input from §2A is accounted for (no dropped context).
- Every delta from §3 is addressed (EVOLVE mode).
- No `TODO` / `TBD` markers unless deliberately declared as boundary conditions.
- All prevention recommendations incorporated or explicitly deferred with rationale.
- All committed decisions reflected in decision history.

### 6C — Load Test

Simulate a fresh model receiving this document cold:

| # | Can the model... | Pass? |
|---|-------------------|-------|
| 1 | Understand its role without ambiguity? | |
| 2 | Distinguish proven state from assumptions? | |
| 3 | Identify the correct next action without asking? | |
| 4 | Detect when a proposal violates a constraint? | |
| 5 | Use project vocabulary correctly? | |
| 6 | Explain *why* the system is designed this way? | |
| 7 | Know what it must *not* do? | |

**Failure-mode probes** — simulate these scenarios against the document:

- Model proposes an action touching invariant I-[N]. Does the document make the violation detectable?
- Model encounters a previously-decided architectural fork. Can it find and follow the committed decision?
- Model encounters a known failure pattern. Can it find the prevention recommendation?
- Model uses a vocabulary term. Does it use the project-specific definition, not the general one?

Any failure → the document has a gap. Fix before delivery.

### 6D — Context Budget

| Zone | Tokens | Assessment |
|------|--------|------------|
| **Lean** | <5K | Max working room. May be too sparse for complex projects. |
| **Moderate** | 5K–15K | Good balance for most projects. |
| **Heavy** | 15K–30K | Acceptable for complex projects. Watch for bloat. |
| **Critical** | >30K | **Mandatory review.** Compress: completed phases → 1–2 summary lines; verbose narrative → tables; stable architecture → reference artifact. |

**If Critical after compression,** split:
- **Core document:** Role, invariants, proven state, priorities, vocabulary, behavioral constraints. Sufficient for correct first-turn decisions and constraint compliance.
- **Reference supplement:** Architecture details, full decision history, detailed runbook, trajectory. Referenced by path, loaded on demand. Its absence must not cause incorrect behavior.

---

## § 7 — DELIVERY

### 7A — Artifact Metadata

```
⟐ FORGE ARTIFACT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Version:        [designation]
Mode:           [CREATE / EVOLVE / PATCH]
Lines:          [N]
SHA-256:        [hash]
Token estimate: [count] ([budget zone])
Prior version:  [ID or "none"]
Delta summary:  [sections added / refactored / deprecated / preserved]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 7B — Delivery Contents

1. The governing document.
2. Artifact metadata (§7A).
3. Change summary (EVOLVE/PATCH only).
4. **Operator decision points** — judgment calls the operator should review or override.
5. **Initialization readiness** — confirmation the document is ready for cold-start, or list of known gaps.

Do not narrate the construction process. The document speaks for itself.

### 7C — Version Transition (EVOLVE/PATCH)

```
TRANSITION: [old] → [new]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Breaking:     [changed state claims, added/removed constraints,
               reordered priorities — anything that could cause
               sessions on the old version to decide incorrectly]
Non-breaking: [new sections, documentation improvements,
               vocabulary additions — safe without transition]
Migration:    [steps for mid-work sessions to transition safely]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## § 8 — OPERATING CONSTRAINTS

**On output quality.** This protocol does not produce drafts. It produces the best version achievable from available inputs. Thin inputs yield proportionally scoped output — never padded output.

**On state invention.** Forbidden. Unevidenced capability is marked unproven. No exceptions.

**On length.** The protocol optimizes for decision-enabling density, not coverage. A 200-line document enabling correct first-turn decisions outperforms a 600-line document burying signal in ceremony.

**On evolution triggers.** Evolve at phase boundaries, after 3+ unintegrated decisions accumulate, after a fault reveals structural prevention needs, or when initialization reports gaps. Use PATCH for isolated state changes.

**On deduplication.** Information in accessible artifacts (code comments, READMEs, configs) is referenced, not duplicated. Two copies inevitably diverge.

**On self-governance.** The document is subject to the same integrity standards it prescribes. It versions itself, declares lineage, and knows it will be superseded.

---

*The protocol succeeds when a fresh session initialized from its output makes correct decisions on turn one, recognizes every active constraint, knows what to work on, and carries the project's institutional memory — in the fewest possible tokens.*

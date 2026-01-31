# CPO Governance Kernel — Canonical Lexicon

> **Identity:** Governance Physics
> **D5 Resolution:** The codebase enforces governance as physics (invariants + fail-closed gates + contract versioning), not merely an audit artifact.
> **Source of truth:** `meta/lexicon.yaml`

---

## Core Concepts

| Term | Definition |
|------|-----------|
| **write aperture** | The single entry point (`commit_action`) through which all state mutations pass. No artifact reaches a table without traversing this function. |
| **fail-closed** | Default-deny evaluation semantics. Unknown inputs, missing fields, structural errors, and unrecognized keys all result in rejection. |
| **governance physics** | Invariants enforced by database structure and function topology, not by policy configuration. Physics cannot be overridden by action_type strings or agent claims. |
| **kernel gate** | A gate whose evaluation is mandatory and non-exceptionable, enforced by function topology rather than policy flags. |
| **contract version** | Integer version of the commit_action contract (currently 2), queryable via `commit_action_contract_version()`. |
| **operational mantra** | Eight principles defining system behavioral identity, encoded in STATUS.json. |

---

## Tables (15)

| Table | Purpose |
|-------|---------|
| `cpo_action_logs` | Append-only spine of all commit attempts (pass or fail) |
| `cpo_agent_heads` | Materialized current state pointer per agent |
| `cpo_charters` | Charter versions containing gate definitions and governance rules |
| `cpo_charter_activations` | Records of charter version activations binding a charter to an agent |
| `cpo_state_snapshots` | Point-in-time state captures for an agent |
| `cpo_decisions` | Recorded decision artifacts from commit actions |
| `cpo_assumptions` | Declared assumptions that may be referenced by gates |
| `cpo_assumption_events` | Events affecting assumption lifecycle |
| `cpo_exceptions` | Time-bounded authority grants allowing specific gate failures to pass |
| `cpo_exception_events` | Events affecting exception lifecycle |
| `cpo_changes` | Change control packages for charter mutations |
| `cpo_drift_events` | Detected drift signals from the drift detection engine |
| `cpo_drift_resolutions` | Recorded resolutions of previously detected drift events |
| `cpo_artifact_table_registry` | Registry mapping artifact type names to target tables |
| `cpo_contract_artifact_schema` | Schema-driven contract enforcement registry (source of truth for `validate_artifacts`) |

---

## Functions

### Write Aperture

| Function | Purpose |
|----------|---------|
| `commit_action(text, jsonb, jsonb, uuid, uuid)` | Canonical write aperture — all state mutations |
| `validate_artifacts(jsonb)` | Schema-driven artifact validator (unknown keys, types, required fields) |
| `commit_action_contract_version()` | Returns current contract version (2) |

### Gate Engine

| Function | Purpose |
|----------|---------|
| `evaluate_gates(text, jsonb, jsonb, jsonb, jsonb, timestamptz)` | Evaluates all charter-defined gates; returns outcome + gate_results |
| `eval_rule(...)` | Evaluates a single policy rule (operator + args) |
| `jsonptr_get(jsonb, text)` | JSON pointer resolution |
| `jsonptr_get_required(jsonb, text)` | JSON pointer resolution (fail-closed on missing path) |
| `_resolve_arg(...)` | Internal argument resolver (literal vs pointer) |

### Change Control (P6)

| Function | Purpose |
|----------|---------|
| `evaluate_change_control_kernel` | Mandatory kernel gate for charter mutations (8-arg core + 6-arg wrapper) |
| `proposes_charter_change(jsonb)` | Predicate: true if artifacts contain charter mutations |

### Exception Engine (P4)

| Function | Purpose |
|----------|---------|
| `find_valid_exception(...)` | Locates non-expired ACTIVE exception for a gate/agent/action_type |
| `is_exception_valid(...)` | Checks whether a specific exception is still valid |
| `_exception_scope_allows_action_type(...)` | Checks exception scope against action_type |

### Drift Detection (P5)

| Function | Purpose |
|----------|---------|
| `emit_drift_events(...)` | Orchestrator for all four drift detection signals |
| `detect_repeated_exceptions(...)` | Signal: REPEATED_EXCEPTIONS |
| `detect_mode_thrash(...)` | Signal: MODE_THRASH |
| `detect_state_staleness(...)` | Signal: STATE_STALENESS |
| `detect_expired_assumption_references(...)` | Signal: EXPIRED_ASSUMPTION_REFERENCE |
| `detect_drift(...)` | Convenience wrapper |

### Bootstrap & Verification

| Function | Purpose |
|----------|---------|
| `bootstrap_verify()` | Post-migration verification |
| `rebuild_agent_heads()` | Reconstructs agent_heads from action_log spine |
| `rehydrate_agent(...)` | Reconstructs full agent state from append-only log |
| `verify_heads_equivalence()` | Verifies materialized heads match reconstructed state |
| `verify_reconstruction(...)` | Verifies agent state reconstruction |

### Durability & Evidence

| Function | Purpose |
|----------|---------|
| `durability_round_trip_test(...)` | Proves INSERT/SELECT round-trip for artifact tables |
| `export_evidence_pack(...)` | Exports complete evidence pack for audit |
| `get_all_write_aperture_targets()` | Returns all tables reachable through the write aperture |
| `get_canonical_artifact_types()` | Returns list of canonical artifact type names |

---

## Roles

| Role | Purpose |
|------|---------|
| `cpo_owner` | Owns all schema objects; SECURITY DEFINER functions run as this role |
| `cpo_commit` | Minimum-privilege role for state mutations via commit_action |
| `cpo_read` | Read-only access to cpo schema tables |
| `cpo_bootstrap` | Grants KERNEL_BOOTSTRAP capability for genesis commits |
| `cpo_migration` | Role for applying migrations and patches |

---

## Error Codes

| Code | Name | Meaning |
|------|------|---------|
| `22023` | CONTRACT_VIOLATION | validate_artifacts rejection (unknown keys, bad types, missing fields) |
| `CPO01` | TOCTOU_GUARD | Expected refs don't match current head state |
| `CPO98` | KERNEL_CHANGE_CONTROL_FAILED | evaluate_change_control_kernel threw unhandled exception |
| `CPO99` | KERNEL_GATE_EVALUATION_FAILED | evaluate_gates threw unhandled exception |

---

## Gate Outcomes

| Outcome | Meaning |
|---------|---------|
| `PASS` | All gates passed; commit proceeds |
| `FAIL` | One or more gates failed; default outcome (fail-closed) |
| `PASS_WITH_EXCEPTION` | Gate failed but covered by valid non-expired exception |
| `ERROR` | Gate could not be evaluated (structural problem); treated as FAIL, ineligible for exceptions |

---

## Canonical Output Keys (locked by D4)

| Key | Disallowed Alternatives | Where |
|-----|------------------------|-------|
| `policy_check_id` | `gate_id` (as output key) | Per-gate result objects |
| `gate_results` | `kernel_gates`, `kernel_gate_results` | commit_action output array |

---

## Change Control Constants

| Constant | Meaning |
|----------|---------|
| `GENESIS_BOOTSTRAP_EXEMPT` | Exemption requiring BOTH is_genesis=true AND capability=KERNEL_BOOTSTRAP |
| `KERNEL_BOOTSTRAP` | Capability derived from cpo_bootstrap role membership |
| `GATE-CHANGE-CONTROL` | policy_check_id used by the change control kernel |

---

## Drift Signals

| Signal | Meaning |
|--------|---------|
| `REPEATED_EXCEPTIONS` | A gate has been covered by exceptions multiple times recently |
| `MODE_THRASH` | Agent outcomes oscillating rapidly between PASS and FAIL |
| `STATE_STALENESS` | Agent has had no recent commit activity |
| `EXPIRED_ASSUMPTION_REFERENCE` | Commit references an expired/invalidated assumption |

---

## Invariant Groups

| Group | Phase | Range |
|-------|-------|-------|
| INV-1xx | P1 — Contracts / Policy Check Registry | INV-101 through INV-105 |
| INV-2xx | P2 — Persistence / Write Aperture | INV-201 through INV-203 |
| INV-3xx | P3 — Gate Integration / TOCTOU | INV-301 through INV-305 |
| INV-4xx | P4 — Exception Expiry / Authority | INV-401 through INV-406 |
| INV-5xx | P5 — Drift Detection | INV-501 through INV-505 |
| INV-6xx | P6 — Change Control | INV-601 through INV-606 |
| INV-7xx | P7 — Release Closure Pipeline | INV-701 |

---

## Operational Mantra

1. Authority is authenticated.
2. Physics outranks policy.
3. Enumerations are structural.
4. Evaluation is closed-world.
5. Exceptions are expiring authority.
6. Drift becomes ledger artifacts.
7. Change control governs the rules.
8. Every commit re-proves the world.

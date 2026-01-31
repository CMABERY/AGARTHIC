# Migration Application Order

**CANON_VERSION:** 2  
**Last Updated:** 2026-01-31  
**Phase:** 1.2 (Deployability)

## Purpose

This document defines the authoritative order for applying CPO database migrations.
Applying migrations out of order will result in failures due to missing dependencies.

## Invariant (I1)

> A fresh Postgres 15+ instance, given only these migrations applied in order,
> must reach a fully functional state with no manual intervention.

## Application Order

| Order | File | Purpose | Dependencies |
|-------|------|---------|--------------|
| 1 | `000_bootstrap.sql` | Schema, roles, extensions, base tables | None (fresh DB) |
| 2 | `006_commit_action_p3_surgical.sql` | Core commit_action function (P3) | Bootstrap tables |
| 3 | `009_commit_action_gate_integration_p3_surgical.sql` | Gate integration wiring | commit_action v1 |

## Patch Application Order

Patches are applied after migrations. Order matters for patches that depend on each other.

| Order | File | Purpose |
|-------|------|---------|
| 4 | `p2_artifact_table_registry_v3.sql` | Artifact registry + immutability guards |
| 5 | `p2_durability_drill_wiring.sql` | Durability verification |
| 6 | `p2_durability_drill_wiring_v2_1.sql` | Durability v2.1 refinements |
| 7 | `p2_proof_durability_wiring.sql` | Durability proofs |
| 8 | `p2_proof_write_aperture_coverage_v3.sql` | Write aperture coverage proofs |
| 9 | `p3_policy_dsl_jsonptr_get.sql` | Policy DSL prerequisite: jsonptr_get |
| 10 | `p3_gate_engine_missing_field_patch.sql` | Gate engine field fixes |
| 11 | `p3_missing_field_semantics_patch.sql` | Missing field semantics |
| 12 | `p3_toctou_bypass_removal_patch.sql` | TOCTOU bypass removal |
| 13 | `p3_proof_default_deny_fail_closed.sql` | Default deny proofs |
| 14 | `p3_proof_error_bypasses_exceptions.sql` | Error bypass proofs |
| 15 | `p3_proof_kernel_non_exceptionable.sql` | Kernel non-exceptionable proofs |
| 16 | `p3_proof_missing_field_semantics.sql` | Field semantics proofs |
| 17 | `p3_proof_no_semantic_bypass.sql` | Semantic bypass proofs |
| 18 | `p3_proof_resolved_inputs_required.sql` | Resolved inputs proofs |
| 19 | `p3_proof_toctou_closed.sql` | TOCTOU closure proofs |
| 20 | `p4_exception_expiry_enforcement_v3.sql` | P4 exception expiry enforcement |
| 21 | `p4_exception_expiry_proofs_v3.sql` | P4 exception expiry proofs |
| 22 | `p6_change_control_kernel_patch.sql` | P6 change control kernel |
| 23 | `p6_change_control_proofs.sql` | P6 change control proofs |
| 24 | `p6_ci_guard_change_control.sql` | P6 CI guards |
| 25 | `011_drift_detection.sql` | Drift detection functions |
| 26 | `011_drift_detection_selftest.sql` | Drift detection self-tests |

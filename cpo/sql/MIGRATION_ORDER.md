# CPO SQL Migration + Patch Order

**CANON_VERSION:** 1  
**Last Updated:** 2026-02-01  

This file is the authoritative ordering for applying CPO SQL to a fresh Postgres instance.
It must match the ordering used by `make db-apply` (see the root Makefile).

## Migrations (baseline, schema-first)

1. `cpo/sql/migrations/000_bootstrap.sql`
2. `cpo/sql/migrations/006_commit_action_p3_surgical.sql`
3. `cpo/sql/migrations/007_policy_dsl.sql`
4. `cpo/sql/migrations/009_commit_action_gate_integration_p3_surgical.sql`

## Patches (phase-ordered, including proofs/guards)

1. `cpo/sql/patches/p2_artifact_table_registry_v3.sql`
2. `cpo/sql/patches/p2_durability_drill_wiring.sql`
3. `cpo/sql/patches/p2_durability_drill_wiring_v2_1.sql`
4. `cpo/sql/patches/p2_proof_durability_wiring.sql`
5. `cpo/sql/patches/p2_proof_write_aperture_coverage_v3.sql`
6. `cpo/sql/patches/p2_contract_declaration.sql`
7. `cpo/sql/patches/p2_contract_enforcement.sql`
8. `cpo/sql/patches/p3_gate_engine_missing_field_patch.sql`
9. `cpo/sql/patches/p3_missing_field_semantics_patch.sql`
10. `cpo/sql/patches/p3_toctou_bypass_removal_patch.sql`
11. `cpo/sql/patches/p3_proof_default_deny_fail_closed.sql`
12. `cpo/sql/patches/p3_proof_error_bypasses_exceptions.sql`
13. `cpo/sql/patches/p3_proof_kernel_non_exceptionable.sql`
14. `cpo/sql/patches/p3_proof_missing_field_semantics.sql`
15. `cpo/sql/patches/p3_proof_no_semantic_bypass.sql`
16. `cpo/sql/patches/p3_proof_resolved_inputs_required.sql`
17. `cpo/sql/patches/p3_proof_toctou_closed.sql`
18. `cpo/sql/patches/p4_exception_expiry_enforcement_v3.sql`
19. `cpo/sql/patches/p4_exception_expiry_proofs_v3.sql`
20. `cpo/sql/patches/p6_change_control_kernel_patch.sql`
21. `cpo/sql/patches/p6_change_control_proofs.sql`
22. `cpo/sql/patches/p6_ci_guard_change_control.sql`
23. `cpo/sql/patches/011_drift_detection.sql`
24. `cpo/sql/patches/011_drift_detection_selftest.sql`
25. `cpo/sql/patches/p2_contract_proof.sql`
26. `cpo/sql/patches/p3_proof_gate_evaluation_fail_closed.sql`
27. `cpo/sql/patches/p3_proof_gate_output_keys_canonical.sql`
28. `cpo/sql/patches/p6_envelope_persistence.sql`
29. `cpo/sql/patches/p6_commit_action_envelope_wiring.sql`
30. `cpo/sql/patches/p6_proof_envelope_hash_coherence.sql`

## Notes

- Proof patches (`p*_proof_*.sql`) are assertions and should be safe to re-run.
- Guard patches enforce immutability and phase constraints at runtime.
- Phase 6 envelope persistence is wired into the write aperture via `p6_commit_action_envelope_wiring.sql`.

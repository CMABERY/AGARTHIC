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
| 9 | `p3_gate_engine_missing_field_patch.sql` | Gate engine field fixes |
| 10 | `p3_missing_field_semantics_patch.sql` | Missing field semantics |
| 11 | `p3_toctou_bypass_removal_patch.sql` | TOCTOU bypass removal |
| 12 | `p3_proof_default_deny_fail_closed.sql` | Default deny proofs |
| 13 | `p3_proof_error_bypasses_exceptions.sql` | Error bypass proofs |
| 14 | `p3_proof_kernel_non_exceptionable.sql` | Kernel non-exceptionable proofs |
| 15 | `p3_proof_missing_field_semantics.sql` | Field semantics proofs |
| 16 | `p3_proof_no_semantic_bypass.sql` | Semantic bypass proofs |
| 17 | `p3_proof_resolved_inputs_required.sql` | Resolved inputs proofs |
| 18 | `p3_proof_toctou_closed.sql` | TOCTOU closure proofs |
| 19 | `p4_exception_expiry_enforcement_v3.sql` | P4 exception expiry enforcement |
| 20 | `p4_exception_expiry_proofs_v3.sql` | P4 exception expiry proofs |
| 21 | `p6_change_control_kernel_patch.sql` | P6 change control kernel |
| 22 | `p6_change_control_proofs.sql` | P6 change control proofs |
| 23 | `p6_ci_guard_change_control.sql` | P6 CI guards |
| 24 | `011_drift_detection.sql` | Drift detection functions |
| 25 | `011_drift_detection_selftest.sql` | Drift detection self-tests |

## Verification Commands

```bash
# 1. Start fresh Postgres
docker run -d --name cpo-test-db \
  -e POSTGRES_PASSWORD=test \
  -e POSTGRES_DB=cpo_test \
  postgres:15
sleep 5

# 2. Apply bootstrap
docker exec -i cpo-test-db psql -U postgres -d cpo_test \
  < cpo/sql/migrations/000_bootstrap.sql

# 3. Verify bootstrap
docker exec cpo-test-db psql -U postgres -d cpo_test \
  -c "SELECT cpo.bootstrap_verify();"

# 4. Apply remaining migrations in order
for f in \
  cpo/sql/migrations/006_commit_action_p3_surgical.sql \
  cpo/sql/migrations/009_commit_action_gate_integration_p3_surgical.sql \
  cpo/sql/patches/p2_artifact_table_registry_v3.sql; do
  docker exec -i cpo-test-db psql -U postgres -d cpo_test < "$f" || exit 1
done

# 5. Cleanup
docker rm -f cpo-test-db
```

## Role Requirements

Before applying `p2_artifact_table_registry_v3.sql`, the executing role must be granted
`cpo_migration`:

```sql
GRANT cpo_migration TO postgres;  -- or your deploy user
```

## Notes

1. **Proofs are assertions, not schema changes.** They verify invariants but don't modify structure.
2. **Patches with version suffixes** (e.g., `_v3`, `_v2_1`) supersede earlier versions.
3. **Order 4+ patches** can generally be applied in any order after the core migrations,
   but the order above is tested and recommended.

---

*This document is authoritative per `INTEGRATION_ROADMAP.md` Phase 1.2.*

# Makefile — CPO Database Operations
#
# CANON_VERSION: 2
# Phase: 1 (Deployability)
# D1.5 Resolution: C — Authoritative I1 verification entrypoint
#
# INVARIANT (I1): `make db-apply` on a fresh Postgres 15+ instance
#                 must complete successfully with no manual intervention.

.PHONY: db-apply db-apply-migrations db-apply-patches db-verify db-clean db-shell help

# ===========================================================================
# Configuration
# ===========================================================================

# Database connection (override via environment or command line)
DATABASE_URL ?= postgres://postgres:test@localhost:5432/cpo_test
DB_HOST ?= localhost
DB_PORT ?= 5432
DB_USER ?= postgres
DB_NAME ?= cpo_test
DB_PASSWORD ?= test

# Derived psql command
PSQL := PGPASSWORD=$(DB_PASSWORD) psql -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) -d $(DB_NAME) -v ON_ERROR_STOP=1

# ===========================================================================
# Migration Files (ordered per MIGRATION_ORDER.md)
# ===========================================================================

MIGRATIONS := \
	cpo/sql/migrations/000_bootstrap.sql \
	cpo/sql/migrations/006_commit_action_p3_surgical.sql \
	cpo/sql/migrations/007_policy_dsl.sql \
	cpo/sql/migrations/009_commit_action_gate_integration_p3_surgical.sql

PATCHES := \
	cpo/sql/patches/p2_artifact_table_registry_v3.sql \
	cpo/sql/patches/p2_durability_drill_wiring.sql \
	cpo/sql/patches/p2_durability_drill_wiring_v2_1.sql \
	cpo/sql/patches/p2_proof_durability_wiring.sql \
	cpo/sql/patches/p2_proof_write_aperture_coverage_v3.sql \
	cpo/sql/patches/p2_contract_declaration.sql \
	cpo/sql/patches/p2_contract_enforcement.sql \
	cpo/sql/patches/p3_gate_engine_missing_field_patch.sql \
	cpo/sql/patches/p3_missing_field_semantics_patch.sql \
	cpo/sql/patches/p3_toctou_bypass_removal_patch.sql \
	cpo/sql/patches/p3_proof_default_deny_fail_closed.sql \
	cpo/sql/patches/p3_proof_error_bypasses_exceptions.sql \
	cpo/sql/patches/p3_proof_kernel_non_exceptionable.sql \
	cpo/sql/patches/p3_proof_missing_field_semantics.sql \
	cpo/sql/patches/p3_proof_no_semantic_bypass.sql \
	cpo/sql/patches/p3_proof_resolved_inputs_required.sql \
	cpo/sql/patches/p3_proof_toctou_closed.sql \
	cpo/sql/patches/p4_exception_expiry_enforcement_v3.sql \
	cpo/sql/patches/p4_exception_expiry_proofs_v3.sql \
	cpo/sql/patches/p6_change_control_kernel_patch.sql \
	cpo/sql/patches/p6_change_control_proofs.sql \
	cpo/sql/patches/p6_ci_guard_change_control.sql \
	cpo/sql/patches/011_drift_detection.sql \
	cpo/sql/patches/011_drift_detection_selftest.sql \
	cpo/sql/patches/p2_contract_proof.sql \
	cpo/sql/patches/p3_proof_gate_evaluation_fail_closed.sql

ALL_SQL := $(MIGRATIONS) $(PATCHES)

# ===========================================================================
# Targets
# ===========================================================================

help: ## Show this help
	@echo "CPO Database Makefile"
	@echo ""
	@echo "Usage: make [target] [VAR=value]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables:"
	@echo "  DB_HOST      Database host (default: localhost)"
	@echo "  DB_PORT      Database port (default: 5432)"
	@echo "  DB_USER      Database user (default: postgres)"
	@echo "  DB_NAME      Database name (default: cpo_test)"
	@echo "  DB_PASSWORD  Database password (default: test)"

db-apply: db-apply-migrations db-apply-patches db-verify ## Apply all migrations and patches (I1 entrypoint)
	@echo ""
	@echo "============================================================"
	@echo "db-apply: COMPLETE"
	@echo "============================================================"

db-apply-migrations: ## Apply core migrations only
	@echo "============================================================"
	@echo "Applying migrations..."
	@echo "============================================================"
	@for f in $(MIGRATIONS); do \
		echo "[APPLY] $$f"; \
		$(PSQL) -f "$$f" || exit 1; \
	done
	@echo "[MIGRATIONS] ✓ Complete ($(words $(MIGRATIONS)) files)"

db-apply-patches: ## Apply patches only (requires migrations first)
	@echo "============================================================"
	@echo "Granting cpo_migration role..."
	@echo "============================================================"
	@$(PSQL) -c "GRANT cpo_migration TO $(DB_USER);" || true
	@echo ""
	@echo "============================================================"
	@echo "Applying patches..."
	@echo "============================================================"
	@for f in $(PATCHES); do \
		echo "[APPLY] $$f"; \
		$(PSQL) -f "$$f" || exit 1; \
	done
	@echo "[PATCHES] ✓ Complete ($(words $(PATCHES)) files)"

db-verify: ## Verify database state after apply
	@echo ""
	@echo "============================================================"
	@echo "Verifying database state..."
	@echo "============================================================"
	@$(PSQL) -c "SELECT cpo.bootstrap_verify();" | grep -q '"tables_ok": true' && \
		echo "[VERIFY] ✓ bootstrap_verify passed" || \
		(echo "[VERIFY] ✗ bootstrap_verify FAILED"; exit 1)
	@TABLE_COUNT=$$($(PSQL) -t -A -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'cpo';"); \
		echo "[VERIFY] Tables in cpo schema: $$TABLE_COUNT"; \
		[ "$$TABLE_COUNT" -ge 13 ] || (echo "[VERIFY] ✗ Expected >= 13 tables"; exit 1)
	@FUNC_COUNT=$$($(PSQL) -t -A -c "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'cpo';"); \
		echo "[VERIFY] Functions in cpo schema: $$FUNC_COUNT"; \
		[ "$$FUNC_COUNT" -ge 1 ] || (echo "[VERIFY] ✗ Expected >= 1 function"; exit 1)
	@echo "[VERIFY] ✓ All checks passed"

db-clean: ## Drop and recreate the database (DESTRUCTIVE)
	@echo "============================================================"
	@echo "WARNING: This will DROP the database $(DB_NAME)"
	@echo "============================================================"
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	PGPASSWORD=$(DB_PASSWORD) psql -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) -d postgres \
		-c "DROP DATABASE IF EXISTS $(DB_NAME);" \
		-c "CREATE DATABASE $(DB_NAME);"
	@echo "[CLEAN] Database $(DB_NAME) recreated"

db-shell: ## Open psql shell to the database
	@$(PSQL)

# ===========================================================================
# CI/CD Helpers
# ===========================================================================

.PHONY: db-guards db-proofs

db-guards: ## Run CI guard queries
	@echo "[GUARDS] Running CI guards..."
	@$(PSQL) -f cpo/sql/proofs/p3_ci_guard_no_semantic_toctou_bypass.sql || exit 1
	@$(PSQL) -f cpo/sql/patches/p6_ci_guard_change_control.sql || exit 1
	@echo "[GUARDS] ✓ All guards passed"

db-proofs: ## Run all proof queries (assertions)
	@echo "[PROOFS] Running proof queries..."
	@for f in cpo/sql/patches/p*_proof_*.sql; do \
		echo "[PROOF] $$f"; \
		$(PSQL) -f "$$f" || exit 1; \
	done
	@echo "[PROOFS] ✓ All proofs passed"

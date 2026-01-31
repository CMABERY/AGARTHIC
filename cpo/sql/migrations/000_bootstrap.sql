-- 000_bootstrap.sql
-- CPO Bootstrap Migration (Phase 1.1)
-- 
-- PURPOSE: Establish base schema, roles, extensions, and tables required by all
--          subsequent migrations. Enables zero-state deployability (I1 invariant).
--
-- INVARIANTS SATISFIED:
--   I1 - Zero-state deployability: This script succeeds on fresh Postgres
--   I5 - Migration chain integrity: All dependent migrations can reference these objects
--
-- IDEMPOTENCY: All statements use IF NOT EXISTS / DO $$ guards
-- FAIL-CLOSED: No assumptions about pre-existing state
--
-- CANON_VERSION: 2
-- CREATED: 2026-01-31 (Phase 1.1)

BEGIN;

-- ===========================================================================
-- 1. SCHEMA
-- ===========================================================================

CREATE SCHEMA IF NOT EXISTS cpo;
COMMENT ON SCHEMA cpo IS 'Commit-Phase Orchestrator: append-only governance ledger';

-- ===========================================================================
-- 2. EXTENSIONS
-- ===========================================================================

-- pgcrypto required for:
--   - public.gen_random_uuid() (action log IDs)
--   - public.gen_random_bytes() (request IDs)
--   - public.digest() (SHA-256 hashing)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ===========================================================================
-- 3. ROLES (idempotent)
-- ===========================================================================

DO $$
BEGIN
  -- cpo_owner: Owns all cpo objects; DDL privileges
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_owner') THEN
    CREATE ROLE cpo_owner NOLOGIN;
    COMMENT ON ROLE cpo_owner IS 'Owner of CPO schema objects; DDL privileges';
  END IF;

  -- cpo_commit: Execute privilege on commit_action; DML via SECURITY DEFINER
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_commit') THEN
    CREATE ROLE cpo_commit NOLOGIN;
    COMMENT ON ROLE cpo_commit IS 'Execute commit_action; DML via SECURITY DEFINER functions';
  END IF;

  -- cpo_bootstrap: Special role for genesis commits (agent initialization)
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_bootstrap') THEN
    CREATE ROLE cpo_bootstrap NOLOGIN;
    COMMENT ON ROLE cpo_bootstrap IS 'Bootstrap role for agent genesis commits';
  END IF;

  -- cpo_migration: Required for artifact registry modifications
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_migration') THEN
    CREATE ROLE cpo_migration NOLOGIN;
    COMMENT ON ROLE cpo_migration IS 'Migration role for schema modifications';
  END IF;

  -- cpo_read: Read-only access for auditing/reporting
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_read') THEN
    CREATE ROLE cpo_read NOLOGIN;
    COMMENT ON ROLE cpo_read IS 'Read-only access for audit and reporting';
  END IF;
END $$;

-- Grant schema ownership
ALTER SCHEMA cpo OWNER TO cpo_owner;

-- ===========================================================================
-- 4. BASE TABLES - CANONICAL ARTIFACTS (append-only)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 4.1 cpo_action_logs: The append-only spine of all commits
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_action_logs (
  -- Generated identity
  action_log_id uuid NOT NULL DEFAULT public.gen_random_uuid(),
  seq bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  
  -- Partitioning key
  agent_id text NOT NULL,
  
  -- Content (immutable JSONB blob)
  content jsonb NOT NULL,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  
  -- Constraints
  PRIMARY KEY (agent_id, action_log_id),
  CONSTRAINT action_log_content_is_object CHECK (jsonb_typeof(content) = 'object')
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_action_logs_seq 
  ON cpo.cpo_action_logs (agent_id, seq);

COMMENT ON TABLE cpo.cpo_action_logs IS 
  'Append-only action log spine. All commits create exactly one row here.';

-- ---------------------------------------------------------------------------
-- 4.2 cpo_charters: Charter definitions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_charters (
  -- Generated identity (derived from content hash)
  charter_version_id uuid NOT NULL DEFAULT public.gen_random_uuid(),
  
  -- Foreign keys
  agent_id text NOT NULL,
  action_log_id uuid NOT NULL,
  
  -- Content
  content jsonb NOT NULL,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  
  PRIMARY KEY (agent_id, charter_version_id),
  CONSTRAINT charter_content_is_object CHECK (jsonb_typeof(content) = 'object')
);

COMMENT ON TABLE cpo.cpo_charters IS 
  'Charter definitions. Immutable once created.';

-- ---------------------------------------------------------------------------
-- 4.3 cpo_charter_activations: Charter activation records
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_charter_activations (
  -- Generated identity
  activation_id uuid NOT NULL DEFAULT public.gen_random_uuid(),
  seq bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  
  -- Foreign keys
  agent_id text NOT NULL,
  action_log_id uuid NOT NULL,
  
  -- Reference to charter being activated
  charter_version_id uuid,
  
  -- Content
  content jsonb NOT NULL,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  
  PRIMARY KEY (agent_id, activation_id),
  CONSTRAINT activation_content_is_object CHECK (jsonb_typeof(content) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_charter_activations_seq
  ON cpo.cpo_charter_activations (agent_id, seq DESC);

COMMENT ON TABLE cpo.cpo_charter_activations IS 
  'Charter activation events. Latest seq per agent = current charter.';

-- ---------------------------------------------------------------------------
-- 4.4 cpo_state_snapshots: State snapshots
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_state_snapshots (
  -- Generated identity
  state_snapshot_id uuid NOT NULL DEFAULT public.gen_random_uuid(),
  seq bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  
  -- Foreign keys
  agent_id text NOT NULL,
  action_log_id uuid NOT NULL,
  
  -- Content
  content jsonb NOT NULL,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  
  PRIMARY KEY (agent_id, state_snapshot_id),
  CONSTRAINT state_snapshot_content_is_object CHECK (jsonb_typeof(content) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_state_snapshots_seq
  ON cpo.cpo_state_snapshots (agent_id, seq DESC);

COMMENT ON TABLE cpo.cpo_state_snapshots IS 
  'State snapshots. Latest seq per agent = current state.';

-- ---------------------------------------------------------------------------
-- 4.5 cpo_decisions: Decision records
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_decisions (
  -- Generated identity
  decision_id uuid NOT NULL DEFAULT public.gen_random_uuid(),
  
  -- Foreign keys
  agent_id text NOT NULL,
  action_log_id uuid NOT NULL,
  
  -- Content
  content jsonb NOT NULL,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  
  PRIMARY KEY (agent_id, decision_id),
  CONSTRAINT decision_content_is_object CHECK (jsonb_typeof(content) = 'object')
);

COMMENT ON TABLE cpo.cpo_decisions IS 
  'Decision records. Immutable audit trail of decisions.';

-- ---------------------------------------------------------------------------
-- 4.6 cpo_assumptions: Assumption records
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_assumptions (
  -- Generated identity
  assumption_id uuid NOT NULL DEFAULT public.gen_random_uuid(),
  
  -- Foreign keys
  agent_id text NOT NULL,
  action_log_id uuid NOT NULL,
  
  -- Content
  content jsonb NOT NULL,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  
  PRIMARY KEY (agent_id, assumption_id),
  CONSTRAINT assumption_content_is_object CHECK (jsonb_typeof(content) = 'object')
);

COMMENT ON TABLE cpo.cpo_assumptions IS 
  'Assumption records. Track declared assumptions.';

-- ---------------------------------------------------------------------------
-- 4.7 cpo_assumption_events: Assumption lifecycle events
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_assumption_events (
  -- Serial identity (not UUID)
  id bigserial PRIMARY KEY,
  
  -- Foreign keys
  agent_id text NOT NULL,
  action_log_id uuid NOT NULL,
  
  -- Content
  content jsonb NOT NULL,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  
  CONSTRAINT assumption_event_content_is_object CHECK (jsonb_typeof(content) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_assumption_events_agent
  ON cpo.cpo_assumption_events (agent_id);

COMMENT ON TABLE cpo.cpo_assumption_events IS 
  'Assumption lifecycle events (validated, invalidated, etc.).';

-- ---------------------------------------------------------------------------
-- 4.8 cpo_exceptions: Exception grants
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_exceptions (
  -- Generated identity
  exception_id uuid NOT NULL DEFAULT public.gen_random_uuid(),
  
  -- Foreign keys
  agent_id text NOT NULL,
  action_log_id uuid NOT NULL,
  
  -- Content
  content jsonb NOT NULL,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  
  PRIMARY KEY (agent_id, exception_id),
  CONSTRAINT exception_content_is_object CHECK (jsonb_typeof(content) = 'object')
);

COMMENT ON TABLE cpo.cpo_exceptions IS 
  'Exception grants. Time-bounded policy overrides.';

-- ---------------------------------------------------------------------------
-- 4.9 cpo_exception_events: Exception lifecycle events
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_exception_events (
  -- Serial identity (not UUID)
  id bigserial PRIMARY KEY,
  
  -- Foreign keys
  agent_id text NOT NULL,
  action_log_id uuid NOT NULL,
  
  -- Content
  content jsonb NOT NULL,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  
  CONSTRAINT exception_event_content_is_object CHECK (jsonb_typeof(content) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_exception_events_agent
  ON cpo.cpo_exception_events (agent_id);

COMMENT ON TABLE cpo.cpo_exception_events IS 
  'Exception lifecycle events (granted, revoked, expired, consumed).';

-- ---------------------------------------------------------------------------
-- 4.10 cpo_drift_events: Drift detection events
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_drift_events (
  -- Generated identity
  drift_event_id uuid NOT NULL DEFAULT public.gen_random_uuid(),
  
  -- Foreign keys
  agent_id text NOT NULL,
  action_log_id uuid NOT NULL,
  
  -- Content
  content jsonb NOT NULL,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  
  PRIMARY KEY (agent_id, drift_event_id),
  CONSTRAINT drift_event_content_is_object CHECK (jsonb_typeof(content) = 'object')
);

COMMENT ON TABLE cpo.cpo_drift_events IS 
  'Drift detection events. Records observed drift from expected state.';

-- ---------------------------------------------------------------------------
-- 4.11 cpo_drift_resolutions: Drift resolution records
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_drift_resolutions (
  -- Serial identity (not UUID)
  id bigserial PRIMARY KEY,
  
  -- Foreign keys
  agent_id text NOT NULL,
  action_log_id uuid NOT NULL,
  
  -- Content
  content jsonb NOT NULL,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  
  CONSTRAINT drift_resolution_content_is_object CHECK (jsonb_typeof(content) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_drift_resolutions_agent
  ON cpo.cpo_drift_resolutions (agent_id);

COMMENT ON TABLE cpo.cpo_drift_resolutions IS 
  'Drift resolution records. How drift was addressed.';

-- ---------------------------------------------------------------------------
-- 4.12 cpo_changes: Change control records
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_changes (
  -- Serial identity (not UUID; change_id lives in content)
  id bigserial PRIMARY KEY,
  
  -- Foreign keys
  agent_id text NOT NULL,
  action_log_id uuid NOT NULL,
  
  -- Content
  content jsonb NOT NULL,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  
  CONSTRAINT change_content_is_object CHECK (jsonb_typeof(content) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_changes_agent
  ON cpo.cpo_changes (agent_id);

COMMENT ON TABLE cpo.cpo_changes IS 
  'P6 change control records. change_id stored in content JSONB.';

-- ===========================================================================
-- 5. PROJECTION TABLES (mutable, rebuildable)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 5.1 cpo_agent_heads: Current state cache per agent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_agent_heads (
  agent_id text PRIMARY KEY,
  
  -- Last processed action
  last_action_log_seq bigint NOT NULL,
  
  -- Current charter state
  current_charter_activation_id uuid,
  current_charter_activation_seq bigint,
  current_charter_version_id uuid,
  
  -- Current state snapshot
  current_state_snapshot_id uuid,
  current_state_seq bigint,
  
  -- Audit
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

COMMENT ON TABLE cpo.cpo_agent_heads IS 
  'Mutable projection: current heads per agent. Rebuildable from canonical tables.';

-- ===========================================================================
-- 6. OWNERSHIP & PRIVILEGES
-- ===========================================================================

-- Transfer ownership of all tables to cpo_owner
DO $$
DECLARE
  tbl text;
BEGIN
  FOR tbl IN 
    SELECT tablename FROM pg_tables WHERE schemaname = 'cpo'
  LOOP
    EXECUTE format('ALTER TABLE cpo.%I OWNER TO cpo_owner', tbl);
  END LOOP;
END $$;

-- Grant usage on schema
GRANT USAGE ON SCHEMA cpo TO cpo_commit, cpo_bootstrap, cpo_read, cpo_migration;

-- Read access for cpo_read role
GRANT SELECT ON ALL TABLES IN SCHEMA cpo TO cpo_read;
ALTER DEFAULT PRIVILEGES IN SCHEMA cpo GRANT SELECT ON TABLES TO cpo_read;

-- ===========================================================================
-- 7. VERIFICATION FUNCTION
-- ===========================================================================

CREATE OR REPLACE FUNCTION cpo.bootstrap_verify()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = cpo, pg_catalog
AS $$
DECLARE
  v_result jsonb;
  v_table_count int;
  v_role_count int;
BEGIN
  -- Count tables
  SELECT COUNT(*) INTO v_table_count
  FROM pg_tables WHERE schemaname = 'cpo';
  
  -- Count roles
  SELECT COUNT(*) INTO v_role_count
  FROM pg_roles WHERE rolname IN ('cpo_owner', 'cpo_commit', 'cpo_bootstrap', 'cpo_migration', 'cpo_read');
  
  v_result := jsonb_build_object(
    'bootstrap_version', '1.0.0',
    'canon_version', 2,
    'schema_exists', (SELECT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'cpo')),
    'pgcrypto_exists', (SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto')),
    'table_count', v_table_count,
    'expected_tables', 13,
    'role_count', v_role_count,
    'expected_roles', 5,
    'tables_ok', (v_table_count >= 13),
    'roles_ok', (v_role_count = 5),
    'verified_at', clock_timestamp()
  );
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION cpo.bootstrap_verify() IS 
  'Verify bootstrap migration completed successfully. Returns diagnostic JSON.';

-- ===========================================================================
-- 8. FINAL VERIFICATION
-- ===========================================================================

DO $$
DECLARE
  v_check jsonb;
BEGIN
  v_check := cpo.bootstrap_verify();
  
  IF NOT (v_check->>'tables_ok')::boolean THEN
    RAISE EXCEPTION 'Bootstrap verification failed: table_count=% (expected 13)', 
      v_check->>'table_count';
  END IF;
  
  IF NOT (v_check->>'roles_ok')::boolean THEN
    RAISE EXCEPTION 'Bootstrap verification failed: role_count=% (expected 5)',
      v_check->>'role_count';
  END IF;
  
  RAISE NOTICE 'Bootstrap verification PASSED: %', v_check;
END $$;

COMMIT;

-- ===========================================================================
-- POST-COMMIT VERIFICATION (run separately to confirm)
-- ===========================================================================
-- SELECT cpo.bootstrap_verify();

-- p2_contract_declaration.sql
-- Phase 2, Work Item 2.1: Canonical commit_action Contract Declaration
--
-- D2 Resolution: C — Hybrid (JSONB envelope + structured typed arrays)
--
-- This patch:
--   1. Declares the canonical contract version as a DB-queryable constant
--   2. Documents allowed p_artifacts keys (whitelist)
--   3. Documents required fields per artifact type
--   4. Provides cpo.commit_action_contract_version() for callers to query
--
-- INVARIANT (I3): Contract immutability — explicit versioning + migration path
-- INVARIANT (I4): Fail-closed enforcement — signature mismatch must raise, not bypass
--
-- This file is applied once; future contract changes require a version bump
-- and a migration patch (not an in-place edit).

BEGIN;

-- ===========================================================================
-- Contract Version Function
-- ===========================================================================
-- Returns the current contract version as an integer.
-- Callers can assert against this to detect contract drift.
-- Version 2 = Phase 2 contract lock (D2 Resolution C).

CREATE OR REPLACE FUNCTION cpo.commit_action_contract_version()
RETURNS integer
LANGUAGE sql
IMMUTABLE
AS $$ SELECT 2 $$;

COMMENT ON FUNCTION cpo.commit_action_contract_version IS
  'Returns the canonical commit_action contract version. '
  'Version 2: D2 Resolution C — Hybrid (JSONB envelope + typed arrays). '
  'Callers MUST check this if they depend on p_artifacts shape.';


-- ===========================================================================
-- Contract Artifact Schema Registry
-- ===========================================================================
-- Declares the allowed keys in p_artifacts and their required fields.
-- This is the single source of truth for contract enforcement (2.2).

CREATE TABLE IF NOT EXISTS cpo.cpo_contract_artifact_schema (
  artifact_key       text PRIMARY KEY,       -- key in p_artifacts (e.g., 'charters')
  target_table       regclass NOT NULL,       -- destination table
  is_array           boolean NOT NULL DEFAULT true,  -- must be JSON array
  element_type       text NOT NULL DEFAULT 'object', -- jsonb_typeof of each element
  required_fields    text[] NOT NULL DEFAULT '{}',   -- fields required in each element
  id_field           text,                    -- field to extract as relational ID (nullable)
  contract_version   integer NOT NULL DEFAULT 2,     -- version this key was introduced
  description        text,
  
  CONSTRAINT valid_element_type CHECK (element_type IN ('object', 'array', 'string', 'number'))
);

COMMENT ON TABLE cpo.cpo_contract_artifact_schema IS
  'Canonical whitelist of allowed p_artifacts keys for commit_action(). '
  'Contract version 2 (D2 Resolution C). '
  'Unknown keys in p_artifacts MUST be rejected (fail-closed, I4).';

-- ---------------------------------------------------------------------------
-- Populate: 12 artifact types (matching commit_action INSERT blocks)
-- ---------------------------------------------------------------------------

INSERT INTO cpo.cpo_contract_artifact_schema
  (artifact_key, target_table, required_fields, id_field, description)
VALUES
  ('charters',
   'cpo.cpo_charters', 
   ARRAY['charter_version_id'],
   'charter_version_id',
   'Charter definitions. Immutable once created.'),

  ('charter_activations',
   'cpo.cpo_charter_activations',
   ARRAY['activation_id', 'charter_version_id'],
   'activation_id',
   'Charter activation records. Links charter version to agent lifecycle.'),

  ('state_snapshots',
   'cpo.cpo_state_snapshots',
   ARRAY['state_snapshot_id'],
   'state_snapshot_id',
   'Agent state snapshots. Immutable point-in-time state.'),

  ('decisions',
   'cpo.cpo_decisions',
   ARRAY[]::text[],
   NULL,
   'Decision records.'),

  ('assumptions',
   'cpo.cpo_assumptions',
   ARRAY[]::text[],
   NULL,
   'Assumption records.'),

  ('assumption_events',
   'cpo.cpo_assumption_events',
   ARRAY[]::text[],
   NULL,
   'Assumption lifecycle events.'),

  ('exceptions',
   'cpo.cpo_exceptions',
   ARRAY['exception_id', 'policy_check_id', 'status'],
   'exception_id',
   'Policy exceptions. Scoped, expiring bypasses for specific gates.'),

  ('exception_events',
   'cpo.cpo_exception_events',
   ARRAY[]::text[],
   NULL,
   'Exception lifecycle events.'),

  ('drift_events',
   'cpo.cpo_drift_events',
   ARRAY[]::text[],
   NULL,
   'Drift detection events.'),

  ('drift_resolutions',
   'cpo.cpo_drift_resolutions',
   ARRAY[]::text[],
   NULL,
   'Drift resolution records.'),

  ('changes',
   'cpo.cpo_changes',
   ARRAY[]::text[],
   NULL,
   'Change control records (P6).')

ON CONFLICT (artifact_key) DO NOTHING;


-- ===========================================================================
-- Permissions
-- ===========================================================================

REVOKE ALL ON FUNCTION cpo.commit_action_contract_version() FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_owner') THEN
    ALTER FUNCTION cpo.commit_action_contract_version() OWNER TO cpo_owner;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_commit') THEN
    GRANT EXECUTE ON FUNCTION cpo.commit_action_contract_version() TO cpo_commit;
  END IF;
END $$;

-- Schema table: readable by cpo_commit for validation, owned by cpo_owner
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_owner') THEN
    ALTER TABLE cpo.cpo_contract_artifact_schema OWNER TO cpo_owner;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_commit') THEN
    GRANT SELECT ON cpo.cpo_contract_artifact_schema TO cpo_commit;
  END IF;
END $$;

COMMIT;

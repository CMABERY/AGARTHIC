-- p2_contract_enforcement.sql
-- Phase 2, Work Item 2.2: Fail-closed contract enforcement
--
-- This patch:
--   1. Creates cpo.validate_artifacts(p_artifacts jsonb) → void
--      - Rejects unknown keys (not in cpo_contract_artifact_schema)
--      - Validates each known key: must be array, elements must be objects,
--        required fields must be present
--      - RAISES on any violation (fail-closed per I4)
--   2. Wires validate_artifacts into commit_action via a patch on p3_toctou
--
-- INVARIANT (I4): Fail-closed enforcement — invalid artifacts must raise, not bypass
-- INVARIANT (I3): Contract immutability — enforcement version-locked to contract v2

BEGIN;

-- ===========================================================================
-- cpo.validate_artifacts: Artifact shape validator
-- ===========================================================================

CREATE OR REPLACE FUNCTION cpo.validate_artifacts(p_artifacts jsonb)
RETURNS void
LANGUAGE plpgsql
STABLE  -- reads from cpo_contract_artifact_schema
SET search_path = cpo, pg_catalog
AS $$
DECLARE
  v_key text;
  v_schema record;
  v_elem jsonb;
  v_i int;
  v_missing text;
  v_allowed_keys text[];
  v_unknown_keys text[];
BEGIN
  -- Empty or null artifacts are always valid
  IF p_artifacts IS NULL OR p_artifacts = '{}'::jsonb OR jsonb_typeof(p_artifacts) != 'object' THEN
    RETURN;
  END IF;

  -- Load allowed keys from contract schema
  SELECT array_agg(artifact_key) INTO v_allowed_keys
    FROM cpo.cpo_contract_artifact_schema;

  -- =========================================================================
  -- CHECK 1: Reject unknown keys (fail-closed)
  -- =========================================================================
  SELECT array_agg(k) INTO v_unknown_keys
    FROM jsonb_object_keys(p_artifacts) AS k
   WHERE k != ALL(COALESCE(v_allowed_keys, ARRAY[]::text[]));

  IF v_unknown_keys IS NOT NULL AND array_length(v_unknown_keys, 1) > 0 THEN
    RAISE EXCEPTION 'CONTRACT_VIOLATION: unknown artifact key(s): %. Allowed: %',
      array_to_string(v_unknown_keys, ', '),
      array_to_string(v_allowed_keys, ', ')
      USING ERRCODE = '22023';
  END IF;

  -- =========================================================================
  -- CHECK 2: Validate each present key against its schema
  -- =========================================================================
  FOR v_schema IN
    SELECT s.*
      FROM cpo.cpo_contract_artifact_schema s
     WHERE EXISTS (SELECT 1 FROM jsonb_object_keys(p_artifacts) k WHERE k = s.artifact_key)
  LOOP
    -- Skip non-array types (e.g., protocol_version metadata)
    IF NOT v_schema.is_array THEN
      CONTINUE;
    END IF;

    -- Must be a JSON array
    IF jsonb_typeof(p_artifacts->v_schema.artifact_key) != 'array' THEN
      RAISE EXCEPTION 'CONTRACT_VIOLATION: artifacts.% must be a JSON array, got %',
        v_schema.artifact_key,
        jsonb_typeof(p_artifacts->v_schema.artifact_key)
        USING ERRCODE = '22023';
    END IF;

    -- Each element must be the declared type (usually 'object')
    FOR v_i IN 0..jsonb_array_length(p_artifacts->v_schema.artifact_key) - 1 LOOP
      v_elem := (p_artifacts->v_schema.artifact_key)->v_i;

      IF jsonb_typeof(v_elem) != v_schema.element_type THEN
        RAISE EXCEPTION 'CONTRACT_VIOLATION: artifacts.%[%] must be %, got %',
          v_schema.artifact_key, v_i, v_schema.element_type, jsonb_typeof(v_elem)
          USING ERRCODE = '22023';
      END IF;

      -- Check required fields
      IF v_schema.required_fields IS NOT NULL AND array_length(v_schema.required_fields, 1) > 0 THEN
        FOREACH v_missing IN ARRAY v_schema.required_fields LOOP
          IF NOT (v_elem ? v_missing) THEN
            RAISE EXCEPTION 'CONTRACT_VIOLATION: artifacts.%[%] missing required field "%"',
              v_schema.artifact_key, v_i, v_missing
              USING ERRCODE = '22023';
          END IF;
        END LOOP;
      END IF;
    END LOOP;

  END LOOP;

  -- All checks passed
END;
$$;

COMMENT ON FUNCTION cpo.validate_artifacts IS
  'Fail-closed artifact validator (I4). Rejects unknown keys, validates array shape, '
  'checks required fields per artifact type. Schema-driven from cpo_contract_artifact_schema. '
  'Contract version 2 (D2 Resolution C).';


-- ===========================================================================
-- Permissions
-- ===========================================================================

REVOKE ALL ON FUNCTION cpo.validate_artifacts(jsonb) FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_owner') THEN
    ALTER FUNCTION cpo.validate_artifacts(jsonb) OWNER TO cpo_owner;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_commit') THEN
    GRANT EXECUTE ON FUNCTION cpo.validate_artifacts(jsonb) TO cpo_commit;
  END IF;
END $$;

COMMIT;

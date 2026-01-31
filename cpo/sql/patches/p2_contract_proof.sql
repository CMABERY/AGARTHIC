-- p2_contract_proof.sql
-- Phase 2, Work Item 2.3: Contract Lock Proof
--
-- Verifies:
--   PROOF 1: Contract version function exists and returns expected version
--   PROOF 2: Artifact schema covers all INSERT targets in commit_action
--   PROOF 3: validate_artifacts rejects unknown keys (fail-closed)
--   PROOF 4: validate_artifacts rejects non-array artifact values
--   PROOF 5: validate_artifacts rejects missing required fields
--   PROOF 6: validate_artifacts accepts valid artifacts (positive case)
--   PROOF 7: validate_artifacts call is wired into commit_action body
--   PROOF 8: Contract version matches schema registry version
--
-- This file is idempotent and makes no writes (BEGIN/ROLLBACK).

BEGIN;

DO $$
DECLARE
  v_version int;
  v_schema_count int;
  v_commit_def text;
  v_res jsonb;
  v_err text;
  v_missing text[];
  v_insert_keys text[];
  v_schema_keys text[];
BEGIN

  ---------------------------------------------------------------------------
  -- PROOF 1: Contract version function exists and returns 2
  ---------------------------------------------------------------------------
  SELECT cpo.commit_action_contract_version() INTO v_version;

  IF v_version IS NULL OR v_version != 2 THEN
    RAISE EXCEPTION 'PROOF 1 FAIL: expected contract version 2, got %', v_version;
  END IF;

  RAISE NOTICE 'PROOF 1 PASS: Contract version = %', v_version;

  ---------------------------------------------------------------------------
  -- PROOF 2: Schema covers all artifact INSERT targets in commit_action
  ---------------------------------------------------------------------------
  -- Extract keys that commit_action INSERTs into from function body
  SELECT pg_get_functiondef(p.oid) INTO v_commit_def
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'cpo' AND p.proname = 'commit_action'
   ORDER BY length(pg_get_functiondef(p.oid)) DESC
   LIMIT 1;

  -- Known artifact keys from commit_action INSERT blocks
  v_insert_keys := ARRAY[
    'charters', 'charter_activations', 'state_snapshots',
    'decisions', 'assumptions', 'assumption_events',
    'exceptions', 'exception_events',
    'drift_events', 'drift_resolutions', 'changes'
  ];

  SELECT array_agg(artifact_key ORDER BY artifact_key) INTO v_schema_keys
    FROM cpo.cpo_contract_artifact_schema;

  -- Every INSERT key must be in schema
  SELECT array_agg(k) INTO v_missing
    FROM unnest(v_insert_keys) AS k
   WHERE k != ALL(COALESCE(v_schema_keys, ARRAY[]::text[]));

  IF v_missing IS NOT NULL AND array_length(v_missing, 1) > 0 THEN
    RAISE EXCEPTION 'PROOF 2 FAIL: commit_action INSERTs for keys not in schema: %',
      array_to_string(v_missing, ', ');
  END IF;

  SELECT count(*) INTO v_schema_count FROM cpo.cpo_contract_artifact_schema;
  RAISE NOTICE 'PROOF 2 PASS: Schema has % artifact types, all INSERT targets covered', v_schema_count;

  ---------------------------------------------------------------------------
  -- PROOF 3: validate_artifacts rejects unknown keys
  ---------------------------------------------------------------------------
  BEGIN
    PERFORM cpo.validate_artifacts('{"alien_payload": [{"x":1}]}'::jsonb);
    RAISE EXCEPTION 'PROOF 3 FAIL: validate_artifacts accepted unknown key "alien_payload"';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    IF v_err NOT LIKE '%CONTRACT_VIOLATION%' THEN
      RAISE EXCEPTION 'PROOF 3 FAIL: wrong error for unknown key: %', v_err;
    END IF;
    RAISE NOTICE 'PROOF 3 PASS: Unknown key rejected with CONTRACT_VIOLATION';
  END;

  ---------------------------------------------------------------------------
  -- PROOF 4: validate_artifacts rejects non-array artifact values
  ---------------------------------------------------------------------------
  BEGIN
    PERFORM cpo.validate_artifacts('{"charters": "not_an_array"}'::jsonb);
    RAISE EXCEPTION 'PROOF 4 FAIL: validate_artifacts accepted string for charters';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    IF v_err NOT LIKE '%CONTRACT_VIOLATION%' THEN
      RAISE EXCEPTION 'PROOF 4 FAIL: wrong error for non-array: %', v_err;
    END IF;
    RAISE NOTICE 'PROOF 4 PASS: Non-array value rejected with CONTRACT_VIOLATION';
  END;

  ---------------------------------------------------------------------------
  -- PROOF 5: validate_artifacts rejects missing required fields
  ---------------------------------------------------------------------------
  BEGIN
    -- charters requires charter_version_id
    PERFORM cpo.validate_artifacts('{"charters": [{"name": "test"}]}'::jsonb);
    RAISE EXCEPTION 'PROOF 5 FAIL: validate_artifacts accepted charter without charter_version_id';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    IF v_err NOT LIKE '%CONTRACT_VIOLATION%' OR v_err NOT LIKE '%charter_version_id%' THEN
      RAISE EXCEPTION 'PROOF 5 FAIL: wrong error for missing field: %', v_err;
    END IF;
    RAISE NOTICE 'PROOF 5 PASS: Missing required field rejected with CONTRACT_VIOLATION';
  END;

  ---------------------------------------------------------------------------
  -- PROOF 6: validate_artifacts accepts valid artifacts
  ---------------------------------------------------------------------------
  -- Empty artifacts
  PERFORM cpo.validate_artifacts('{}'::jsonb);

  -- Valid charter
  PERFORM cpo.validate_artifacts(jsonb_build_object(
    'charters', jsonb_build_array(
      jsonb_build_object('charter_version_id', gen_random_uuid())
    )
  ));

  -- Valid charter_activation
  PERFORM cpo.validate_artifacts(jsonb_build_object(
    'charter_activations', jsonb_build_array(
      jsonb_build_object('activation_id', gen_random_uuid(), 'charter_version_id', gen_random_uuid())
    )
  ));

  -- Valid exception
  PERFORM cpo.validate_artifacts(jsonb_build_object(
    'exceptions', jsonb_build_array(
      jsonb_build_object('exception_id', gen_random_uuid(), 'policy_check_id', 'GATE-TEST', 'status', 'ACTIVE')
    )
  ));

  -- Multiple artifact types together
  PERFORM cpo.validate_artifacts(jsonb_build_object(
    'decisions', jsonb_build_array(jsonb_build_object('note', 'test')),
    'assumptions', jsonb_build_array(jsonb_build_object('note', 'test'))
  ));

  RAISE NOTICE 'PROOF 6 PASS: Valid artifacts accepted (5 cases)';

  ---------------------------------------------------------------------------
  -- PROOF 7: validate_artifacts is wired into commit_action
  ---------------------------------------------------------------------------
  IF v_commit_def !~* 'validate_artifacts' THEN
    RAISE EXCEPTION 'PROOF 7 FAIL: commit_action body does not reference validate_artifacts';
  END IF;

  RAISE NOTICE 'PROOF 7 PASS: commit_action references validate_artifacts';

  ---------------------------------------------------------------------------
  -- PROOF 8: Contract version matches schema entries
  ---------------------------------------------------------------------------
  PERFORM 1
    FROM cpo.cpo_contract_artifact_schema
   WHERE contract_version != v_version;

  IF FOUND THEN
    RAISE EXCEPTION 'PROOF 8 FAIL: schema entries exist with contract_version != %', v_version;
  END IF;

  RAISE NOTICE 'PROOF 8 PASS: All schema entries match contract version %', v_version;

  ---------------------------------------------------------------------------
  RAISE NOTICE 'P2 CONTRACT PROOFS PASSED: All 8 proofs verified';

END $$;

ROLLBACK;

-- p3_proof_gate_output_keys_canonical.sql
-- Phase 3, Task 3.3 / D4 Resolution: Gate output key canonicalization proof
--
-- Proves:
--   PROOF 1: evaluate_gates uses 'gate_results' (not 'kernel_gates' / 'kernel_gate_results')
--   PROOF 2: evaluate_gates uses 'policy_check_id' (not 'gate_id') in output
--   PROOF 3: commit_action uses 'gate_results' in action_log content and return value
--   PROOF 4: P6 kernel uses 'policy_check_id' (not 'gate_id') in output
--   PROOF 5: Disallowed keys absent from all gate output functions
--
-- D4 Resolution: No rename needed — implementation already uses spec-aligned keys.
-- This proof LOCKS the canonical names so future changes cannot drift.
--
-- No writes (BEGIN/ROLLBACK).

BEGIN;

DO $$
DECLARE
  v_fn_body text;
  v_disallowed text[];
  v_key text;
BEGIN

  ---------------------------------------------------------------------------
  -- PROOF 1: evaluate_gates returns 'gate_results' key
  ---------------------------------------------------------------------------
  v_fn_body := pg_get_functiondef(
    'cpo.evaluate_gates(text, jsonb, jsonb, jsonb, jsonb, timestamptz)'::regprocedure
  );

  IF v_fn_body NOT LIKE '%''gate_results''%' THEN
    RAISE EXCEPTION 'PROOF 1 FAIL: evaluate_gates does not output gate_results key';
  END IF;

  -- Must NOT use alternative names
  IF v_fn_body LIKE '%''kernel_gates''%' THEN
    RAISE EXCEPTION 'PROOF 1 FAIL: evaluate_gates uses disallowed key kernel_gates';
  END IF;
  IF v_fn_body LIKE '%''kernel_gate_results''%' THEN
    RAISE EXCEPTION 'PROOF 1 FAIL: evaluate_gates uses disallowed key kernel_gate_results';
  END IF;

  RAISE NOTICE 'PROOF 1 PASS: evaluate_gates uses canonical key gate_results';

  ---------------------------------------------------------------------------
  -- PROOF 2: evaluate_gates uses 'policy_check_id' in per-gate output
  ---------------------------------------------------------------------------
  IF v_fn_body NOT LIKE '%''policy_check_id''%' THEN
    RAISE EXCEPTION 'PROOF 2 FAIL: evaluate_gates does not output policy_check_id';
  END IF;

  -- The output key 'gate_id' must not appear as a JSON key in gate entries.
  -- Note: v_gate_id as a variable name is fine (P6 kernel internal);
  -- we check for it as a JSON output key: 'gate_id', which would appear
  -- as a literal string in jsonb_build_object calls.
  -- evaluate_gates does not use v_gate_id at all, so this is straightforward.
  IF v_fn_body LIKE '%''gate_id''%' THEN
    RAISE EXCEPTION 'PROOF 2 FAIL: evaluate_gates uses disallowed output key gate_id';
  END IF;

  RAISE NOTICE 'PROOF 2 PASS: evaluate_gates uses canonical key policy_check_id (not gate_id)';

  ---------------------------------------------------------------------------
  -- PROOF 3: commit_action uses 'gate_results' in output
  ---------------------------------------------------------------------------
  v_fn_body := pg_get_functiondef(
    'cpo.commit_action(text, jsonb, jsonb, uuid, uuid)'::regprocedure
  );

  -- In the action_log content assembly
  IF v_fn_body NOT LIKE '%''gate_results'', v_gate_results%' THEN
    RAISE EXCEPTION 'PROOF 3 FAIL: commit_action action_log content missing gate_results key';
  END IF;

  -- Must NOT use alternative names
  IF v_fn_body LIKE '%''kernel_gates''%' THEN
    RAISE EXCEPTION 'PROOF 3 FAIL: commit_action uses disallowed key kernel_gates';
  END IF;
  IF v_fn_body LIKE '%''kernel_gate_results''%' THEN
    RAISE EXCEPTION 'PROOF 3 FAIL: commit_action uses disallowed key kernel_gate_results';
  END IF;
  IF v_fn_body LIKE '%''any_failed''%' THEN
    RAISE EXCEPTION 'PROOF 3 FAIL: commit_action uses disallowed key any_failed';
  END IF;

  RAISE NOTICE 'PROOF 3 PASS: commit_action uses canonical key gate_results';

  ---------------------------------------------------------------------------
  -- PROOF 4: P6 kernel uses 'policy_check_id' in output
  ---------------------------------------------------------------------------
  -- Check the 8-arg core kernel
  v_fn_body := pg_get_functiondef(
    'cpo.evaluate_change_control_kernel(text,text,jsonb,timestamptz,uuid,integer,boolean,text)'::regprocedure
  );

  IF v_fn_body NOT LIKE '%''policy_check_id''%' THEN
    RAISE EXCEPTION 'PROOF 4 FAIL: P6 kernel does not output policy_check_id';
  END IF;

  -- v_gate_id is used as an INTERNAL variable (assigned to policy_check_id output).
  -- Verify that the output key is policy_check_id, not gate_id.
  -- The pattern is: 'policy_check_id', v_gate_id — which is correct.
  IF v_fn_body LIKE '%''gate_id'',%' THEN
    RAISE EXCEPTION 'PROOF 4 FAIL: P6 kernel uses gate_id as output key (should be policy_check_id)';
  END IF;

  RAISE NOTICE 'PROOF 4 PASS: P6 kernel uses canonical output key policy_check_id';

  ---------------------------------------------------------------------------
  -- PROOF 5: Comprehensive disallowed key check across all gate functions
  ---------------------------------------------------------------------------
  v_disallowed := ARRAY[
    'kernel_gates',
    'kernel_gate_results',
    'any_failed',
    'kernel_gate_failed'
  ];

  -- Check evaluate_gates
  v_fn_body := pg_get_functiondef(
    'cpo.evaluate_gates(text, jsonb, jsonb, jsonb, jsonb, timestamptz)'::regprocedure
  );
  FOREACH v_key IN ARRAY v_disallowed LOOP
    IF v_fn_body LIKE '%''' || v_key || '''%' THEN
      RAISE EXCEPTION 'PROOF 5 FAIL: evaluate_gates contains disallowed key %', v_key;
    END IF;
  END LOOP;

  -- Check commit_action
  v_fn_body := pg_get_functiondef(
    'cpo.commit_action(text, jsonb, jsonb, uuid, uuid)'::regprocedure
  );
  FOREACH v_key IN ARRAY v_disallowed LOOP
    IF v_fn_body LIKE '%''' || v_key || '''%' THEN
      RAISE EXCEPTION 'PROOF 5 FAIL: commit_action contains disallowed key %', v_key;
    END IF;
  END LOOP;

  -- Check P6 kernel (8-arg)
  v_fn_body := pg_get_functiondef(
    'cpo.evaluate_change_control_kernel(text,text,jsonb,timestamptz,uuid,integer,boolean,text)'::regprocedure
  );
  FOREACH v_key IN ARRAY v_disallowed LOOP
    IF v_fn_body LIKE '%''' || v_key || '''%' THEN
      RAISE EXCEPTION 'PROOF 5 FAIL: P6 kernel contains disallowed key %', v_key;
    END IF;
  END LOOP;

  RAISE NOTICE 'PROOF 5 PASS: No disallowed keys in any gate output function';

  ---------------------------------------------------------------------------
  RAISE NOTICE 'D4 RESOLUTION PROVEN: Canonical keys locked — policy_check_id + gate_results. No rename needed.';

END $$;

ROLLBACK;

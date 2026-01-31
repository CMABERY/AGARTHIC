-- p3_policy_dsl_jsonptr_get.sql
-- P3 prerequisite: minimal policy DSL support functions required by gate engine & proofs
-- Provides:
--   - cpo.jsonptr_get(doc, ptr) : JSON Pointer resolver with root allowlist
--   - cpo.eval_rule(ctx, rule)  : simple rule evaluator (raises on unknown operator)
--
-- Fail-closed: disallowed pointer roots raise; unknown operators raise.

BEGIN;

-- ----------------------------------------------------------------------------
-- JSON Pointer resolver with root allowlist
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cpo.jsonptr_get(p_doc jsonb, p_ptr text)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_ptr text := COALESCE(p_ptr, '');
  v_cur jsonb := p_doc;
  v_part text;
  v_root text;
  v_i int;
  v_idx int;
  v_parts text[];
BEGIN
  IF v_ptr = '' THEN
    RETURN NULL;
  END IF;

  IF left(v_ptr, 1) <> '/' THEN
    -- Not a pointer; treat as missing
    RETURN NULL;
  END IF;

  -- Split on '/', first element will be empty string
  v_parts := string_to_array(v_ptr, '/');

  IF array_length(v_parts, 1) < 2 THEN
    RETURN NULL;
  END IF;

  v_root := v_parts[2];

  -- Root allowlist (P3)
  IF v_root NOT IN ('action','charter','state','artifacts','resolved') THEN
    RAISE EXCEPTION 'Pointer root not allowed: %', v_root
      USING ERRCODE = '22023';
  END IF;

  -- Traverse remaining parts
  FOR v_i IN 2 .. array_length(v_parts, 1) LOOP
    v_part := replace(replace(v_parts[v_i], '~1', '/'), '~0', '~');

    IF v_part IS NULL OR v_part = '' THEN
      CONTINUE;
    END IF;

    IF v_cur IS NULL THEN
      RETURN NULL;
    END IF;

    IF jsonb_typeof(v_cur) = 'object' THEN
      v_cur := v_cur -> v_part;
    ELSIF jsonb_typeof(v_cur) = 'array' THEN
      -- Array index
      BEGIN
        v_idx := v_part::int;
      EXCEPTION WHEN OTHERS THEN
        RETURN NULL;
      END;
      v_cur := v_cur -> v_idx;
    ELSE
      RETURN NULL;
    END IF;
  END LOOP;

  RETURN v_cur;
END;
$$;

COMMENT ON FUNCTION cpo.jsonptr_get IS
  'P3: JSON Pointer resolver with root allowlist. Returns NULL if missing; raises on disallowed root.';

REVOKE ALL ON FUNCTION cpo.jsonptr_get(jsonb, text) FROM PUBLIC;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_commit') THEN
    GRANT EXECUTE ON FUNCTION cpo.jsonptr_get(jsonb, text) TO cpo_commit;
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- Minimal rule evaluator
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cpo.eval_rule(p_ctx jsonb, p_rule jsonb)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_op text;
  v_args jsonb;
  v_a jsonb;
  v_b jsonb;
  v_i int;
  v_res boolean;
BEGIN
  IF p_rule IS NULL OR jsonb_typeof(p_rule) <> 'object' THEN
    RAISE EXCEPTION 'rule must be a JSON object' USING ERRCODE='22023';
  END IF;

  v_op := COALESCE(p_rule->>'op','');
  v_args := COALESCE(p_rule->'args','[]'::jsonb);

  IF v_op = 'eq' THEN
    v_a := cpo._resolve_arg(p_ctx, v_args->0);
    v_b := cpo._resolve_arg(p_ctx, v_args->1);
    RETURN v_a = v_b;
  ELSIF v_op = 'ne' THEN
    v_a := cpo._resolve_arg(p_ctx, v_args->0);
    v_b := cpo._resolve_arg(p_ctx, v_args->1);
    RETURN v_a <> v_b;
  ELSIF v_op = 'and' THEN
    v_res := true;
    FOR v_i IN 0 .. jsonb_array_length(v_args)-1 LOOP
      v_res := v_res AND cpo.eval_rule(p_ctx, v_args->v_i);
      IF NOT v_res THEN RETURN false; END IF;
    END LOOP;
    RETURN v_res;
  ELSIF v_op = 'or' THEN
    v_res := false;
    FOR v_i IN 0 .. jsonb_array_length(v_args)-1 LOOP
      v_res := v_res OR cpo.eval_rule(p_ctx, v_args->v_i);
      IF v_res THEN RETURN true; END IF;
    END LOOP;
    RETURN v_res;
  ELSIF v_op = 'not' THEN
    RETURN NOT cpo.eval_rule(p_ctx, v_args->0);
  ELSE
    RAISE EXCEPTION 'Unknown operator %', v_op USING ERRCODE='22023';
  END IF;
END;
$$;

COMMENT ON FUNCTION cpo.eval_rule IS
  'P3: Minimal rule evaluator. Raises "Unknown operator <op>" on unsupported ops.';

REVOKE ALL ON FUNCTION cpo.eval_rule(jsonb, jsonb) FROM PUBLIC;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_commit') THEN
    GRANT EXECUTE ON FUNCTION cpo.eval_rule(jsonb, jsonb) TO cpo_commit;
  END IF;
END $$;

COMMIT;

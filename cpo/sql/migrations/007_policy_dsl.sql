-- 007_policy_dsl.sql
-- P3 Step 1: Policy DSL - rule evaluation engine
--
-- Provides:
--   cpo.jsonptr_get(jsonb, text)    - JSON pointer resolution with root allowlist
--   cpo._resolve_arg(jsonb, jsonb)  - Argument resolver (pointer or literal)
--   cpo.eval_rule(jsonb, jsonb)     - Rule evaluator (EQ, NEQ, AND, OR, NOT, TRUE, FALSE)
--
-- Root allowlist (INV-301):
--   /action, /actor, /resolved, /resources, /now
--
-- Apply order: AFTER 006_commit_action_p3_surgical.sql
--              BEFORE 008_gate_engine (or p3_gate_engine_missing_field_patch.sql)

BEGIN;

-- ---------------------------------------------------------------------------
-- cpo.jsonptr_get: JSON Pointer (RFC 6901) resolution with root allowlist
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cpo.jsonptr_get(p_doc jsonb, p_ptr text)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_parts text[];
  v_current jsonb := p_doc;
  v_root text;
  v_allowed_roots text[] := ARRAY['action','actor','resolved','resources','now'];
BEGIN
  IF p_ptr IS NULL OR p_ptr = '' THEN
    RETURN p_doc;
  END IF;

  -- Must start with /
  IF left(p_ptr, 1) != '/' THEN
    RAISE EXCEPTION 'Pointer root not allowed: %', p_ptr;
  END IF;

  -- Split path (remove leading /)
  v_parts := string_to_array(substring(p_ptr from 2), '/');

  -- Check allowed root (INV-301)
  v_root := v_parts[1];
  IF NOT (v_root = ANY(v_allowed_roots)) THEN
    RAISE EXCEPTION 'Pointer root not allowed: /%', v_root;
  END IF;

  -- Walk path
  FOR i IN 1..array_length(v_parts, 1) LOOP
    IF v_current IS NULL THEN
      RETURN NULL;
    END IF;
    v_current := v_current->v_parts[i];
  END LOOP;

  RETURN v_current;
END;
$$;

COMMENT ON FUNCTION cpo.jsonptr_get IS
  'JSON Pointer (RFC 6901) resolver with root allowlist. '
  'Only /action, /actor, /resolved, /resources, /now roots allowed.';


-- ---------------------------------------------------------------------------
-- cpo._resolve_arg: Argument resolver
-- Handles: object with 'pointer' key, string starting with '/', literal
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cpo._resolve_arg(p_ctx jsonb, p_arg jsonb)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_txt text;
BEGIN
  IF p_arg IS NULL THEN
    RETURN NULL;
  END IF;

  -- Object with 'pointer' key → resolve pointer
  IF jsonb_typeof(p_arg) = 'object' AND p_arg ? 'pointer' THEN
    RETURN cpo.jsonptr_get(p_ctx, p_arg->>'pointer');
  END IF;

  -- String starting with '/' → shorthand pointer
  IF jsonb_typeof(p_arg) = 'string' THEN
    v_txt := trim(both '"' from p_arg::text);
    IF left(v_txt, 1) = '/' THEN
      RETURN cpo.jsonptr_get(p_ctx, v_txt);
    END IF;
  END IF;

  -- Literal value
  RETURN p_arg;
END;
$$;

COMMENT ON FUNCTION cpo._resolve_arg IS
  'Argument resolver. Pointer references (string "/" or object {"pointer":"/"}) '
  'are resolved against the evaluation context. Literals returned as-is.';


-- ---------------------------------------------------------------------------
-- cpo.eval_rule: Rule evaluator
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cpo.eval_rule(p_ctx jsonb, p_rule jsonb)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_op text;
  v_arg1 jsonb;
  v_arg2 jsonb;
  v_val1 jsonb;
  v_val2 jsonb;
BEGIN
  v_op := upper(COALESCE(p_rule->>'op', 'TRUE'));

  -- Nullary operators
  IF v_op = 'TRUE' THEN RETURN true; END IF;
  IF v_op = 'FALSE' THEN RETURN false; END IF;

  -- Extract arguments (support both arg1/arg2 and args array)
  IF p_rule ? 'arg1' THEN
    v_arg1 := p_rule->'arg1';
    v_arg2 := p_rule->'arg2';
  ELSIF p_rule ? 'args' AND jsonb_typeof(p_rule->'args') = 'array' THEN
    v_arg1 := p_rule->'args'->0;
    v_arg2 := p_rule->'args'->1;
  END IF;

  -- Logical operators (recursive)
  IF v_op = 'AND' THEN
    RETURN cpo.eval_rule(p_ctx, v_arg1) AND cpo.eval_rule(p_ctx, v_arg2);
  END IF;
  IF v_op = 'OR' THEN
    RETURN cpo.eval_rule(p_ctx, v_arg1) OR cpo.eval_rule(p_ctx, v_arg2);
  END IF;
  IF v_op = 'NOT' THEN
    RETURN NOT cpo.eval_rule(p_ctx, v_arg1);
  END IF;

  -- Resolve arguments for comparison operators
  v_val1 := cpo._resolve_arg(p_ctx, v_arg1);
  v_val2 := cpo._resolve_arg(p_ctx, v_arg2);

  -- Comparison operators
  IF v_op = 'EQ' THEN
    RETURN v_val1 = v_val2;
  END IF;
  IF v_op = 'NEQ' THEN
    RETURN v_val1 IS DISTINCT FROM v_val2;
  END IF;
  IF v_op = 'EXISTS' THEN
    RETURN v_val1 IS NOT NULL;
  END IF;

  -- Unknown operator
  RAISE EXCEPTION 'Unknown operator: %', v_op;
END;
$$;

COMMENT ON FUNCTION cpo.eval_rule IS
  'Rule evaluator. Supports EQ, NEQ, AND, OR, NOT, TRUE, FALSE, EXISTS. '
  'Arguments resolved via _resolve_arg (pointer or literal).';


-- ---------------------------------------------------------------------------
-- Harden exposure
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION cpo.jsonptr_get(jsonb, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION cpo._resolve_arg(jsonb, jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION cpo.eval_rule(jsonb, jsonb) FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_commit') THEN
    GRANT EXECUTE ON FUNCTION cpo.jsonptr_get(jsonb, text) TO cpo_commit;
    GRANT EXECUTE ON FUNCTION cpo._resolve_arg(jsonb, jsonb) TO cpo_commit;
    GRANT EXECUTE ON FUNCTION cpo.eval_rule(jsonb, jsonb) TO cpo_commit;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_owner') THEN
    ALTER FUNCTION cpo.jsonptr_get(jsonb, text) OWNER TO cpo_owner;
    ALTER FUNCTION cpo._resolve_arg(jsonb, jsonb) OWNER TO cpo_owner;
    ALTER FUNCTION cpo.eval_rule(jsonb, jsonb) OWNER TO cpo_owner;
  END IF;
END $$;

COMMIT;

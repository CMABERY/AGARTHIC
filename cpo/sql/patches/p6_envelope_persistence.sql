-- p6_envelope_persistence.sql
-- Phase 6, Task 6.1: Keystone → DB envelope persistence layer
--
-- Creates:
--   1. pgcrypto extension (for sha256)
--   2. cpo.cpo_envelopes table (envelope storage with computed hash)
--   3. cpo.commit_action() (artifacts.envelopes) — runtime write aperture path
--   4. cpo.persist_envelope() — INTERNAL helper (proofs/maintenance only)
--   4. cpo.canonicalize_jsonb() — RFC 8785 / JCS canonicalization in SQL
--
-- Hash coherence contract:
--   Keystone JS (flowversion-envelope.js) canonicalizes via jcsSerialize()
--   DB (canonicalize_jsonb) canonicalizes via equivalent algorithm
--   SHA-256 computed over UTF-8 canonical bytes must match exactly
--
-- Uses the Phase 2 contract: envelopes are persisted as artifacts through
-- commit_action's action_log spine. cpo_envelopes is the dedicated table.

BEGIN;

-- pgcrypto for SHA-256
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-------------------------------------------------------------------------------
-- Table: cpo_envelopes
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cpo.cpo_envelopes (
  id              uuid PRIMARY KEY DEFAULT public.gen_random_uuid(),
  agent_id        text NOT NULL,
  action_log_id   uuid,
  envelope_hash   text NOT NULL,
  record_type     text NOT NULL,
  canonical_json  text NOT NULL,
  computed_sha256 text NOT NULL,
  envelope        jsonb NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT clock_timestamp(),

  CONSTRAINT cpo_envelopes_hash_match CHECK (envelope_hash = computed_sha256)
);

CREATE INDEX IF NOT EXISTS cpo_envelopes_agent_id_idx ON cpo.cpo_envelopes(agent_id);
CREATE INDEX IF NOT EXISTS cpo_envelopes_record_type_idx ON cpo.cpo_envelopes(record_type);
CREATE UNIQUE INDEX IF NOT EXISTS cpo_envelopes_unique_hash ON cpo.cpo_envelopes(envelope_hash);

-- Permissions
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_owner') THEN
    ALTER TABLE cpo.cpo_envelopes OWNER TO cpo_owner;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_commit') THEN
    GRANT SELECT ON cpo.cpo_envelopes TO cpo_commit;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_read') THEN
    GRANT SELECT ON cpo.cpo_envelopes TO cpo_read;
  END IF;
END $$;

-------------------------------------------------------------------------------
-- Function: canonicalize_jsonb (RFC 8785 / JCS)
--
-- Produces the same canonical JSON string as the Keystone JS implementation:
--   - Objects: keys sorted lexicographically, no whitespace
--   - Arrays: elements in order, no whitespace
--   - Strings: JSON-escaped (using jsonb's internal escaping)
--   - Numbers: integer-only (Phase 1 constraint), no leading zeros, no -0
--   - Booleans: true/false
--   - Null: null
--
-- IMPORTANT: This must produce byte-identical output to jcsSerialize() in
-- flowversion-envelope.js. Any divergence breaks hash coherence.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cpo.canonicalize_jsonb(p_val jsonb)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
STRICT
SET search_path = cpo, pg_catalog
AS $$
DECLARE
  v_type text;
  v_result text := '';
  v_key text;
  v_elem jsonb;
  v_first boolean;
  v_num numeric;
BEGIN
  IF p_val IS NULL THEN
    RETURN 'null';
  END IF;

  v_type := jsonb_typeof(p_val);

  CASE v_type
    WHEN 'null' THEN
      RETURN 'null';

    WHEN 'boolean' THEN
      RETURN CASE WHEN p_val::text = 'true' THEN 'true' ELSE 'false' END;

    WHEN 'number' THEN
      -- Phase 1: integers only. Extract as numeric, verify integer, emit without decimals.
      v_num := p_val::numeric;
      IF v_num != trunc(v_num) THEN
        RAISE EXCEPTION 'Non-integer numbers are forbidden in canonical JSON: %', p_val;
      END IF;
      -- Handle -0 (JCS produces "0")
      IF v_num = 0 THEN
        RETURN '0';
      END IF;
      RETURN trunc(v_num)::bigint::text;

    WHEN 'string' THEN
      -- jsonb stores strings with proper escaping. p_val::text includes quotes.
      RETURN p_val::text;

    WHEN 'array' THEN
      v_result := '[';
      v_first := true;
      FOR v_elem IN SELECT value FROM jsonb_array_elements(p_val)
      LOOP
        IF NOT v_first THEN
          v_result := v_result || ',';
        END IF;
        v_first := false;
        v_result := v_result || cpo.canonicalize_jsonb(v_elem);
      END LOOP;
      RETURN v_result || ']';

    WHEN 'object' THEN
      v_result := '{';
      v_first := true;
      -- Keys sorted lexicographically (same as JS Object.keys().sort())
      FOR v_key IN SELECT k FROM jsonb_object_keys(p_val) AS k ORDER BY k
      LOOP
        IF NOT v_first THEN
          v_result := v_result || ',';
        END IF;
        v_first := false;
        -- Key as JSON string + colon + recursive value
        v_result := v_result || to_jsonb(v_key)::text || ':' || cpo.canonicalize_jsonb(p_val -> v_key);
      END LOOP;
      RETURN v_result || '}';

    ELSE
      RAISE EXCEPTION 'Unsupported jsonb type in canonicalization: %', v_type;
  END CASE;
END;
$$;

REVOKE ALL ON FUNCTION cpo.canonicalize_jsonb(jsonb) FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_owner') THEN
    ALTER FUNCTION cpo.canonicalize_jsonb(jsonb) OWNER TO cpo_owner;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_commit') THEN
    GRANT EXECUTE ON FUNCTION cpo.canonicalize_jsonb(jsonb) TO cpo_commit;
  END IF;
END $$;

-------------------------------------------------------------------------------
-- Function: compute_envelope_sha256
--
-- Canonicalizes the envelope and computes SHA-256 over UTF-8 bytes.
-- Returns lowercase hex string (matches JS crypto.createHash('sha256').digest('hex')).
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cpo.compute_envelope_sha256(p_envelope jsonb)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
STRICT
SET search_path = cpo, pg_catalog
AS $$
DECLARE
  v_canonical text;
BEGIN
  v_canonical := cpo.canonicalize_jsonb(p_envelope);
  RETURN encode(public.digest(convert_to(v_canonical, 'UTF8'), 'sha256'), 'hex');
END;
$$;

REVOKE ALL ON FUNCTION cpo.compute_envelope_sha256(jsonb) FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_owner') THEN
    ALTER FUNCTION cpo.compute_envelope_sha256(jsonb) OWNER TO cpo_owner;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_commit') THEN
    GRANT EXECUTE ON FUNCTION cpo.compute_envelope_sha256(jsonb) TO cpo_commit;
  END IF;
END $$;

-------------------------------------------------------------------------------
-- Function: persist_envelope
--
-- Accepts a Keystone envelope, canonicalizes it, computes SHA-256,
-- verifies hash coherence against declared hash, and inserts into cpo_envelopes.
--
-- Fail-closed: hash mismatch raises exception (transaction aborted).
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cpo.persist_envelope(
  p_agent_id       text,
  p_envelope       jsonb,
  p_declared_hash  text,
  p_action_log_id  uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = cpo, pg_catalog
AS $$
DECLARE
  v_record_type text;
  v_canonical text;
  v_computed_sha256 text;
  v_id uuid;
BEGIN
  -- Extract record_type
  v_record_type := p_envelope->>'record_type';
  IF v_record_type IS NULL OR v_record_type = '' THEN
    RAISE EXCEPTION 'ENVELOPE_MISSING_RECORD_TYPE: envelope must contain record_type'
      USING ERRCODE = 'CPO70';
  END IF;

  -- Canonicalize and hash
  v_canonical := cpo.canonicalize_jsonb(p_envelope);
  v_computed_sha256 := encode(public.digest(convert_to(v_canonical, 'UTF8'), 'sha256'), 'hex');

  -- Hash coherence check (fail-closed)
  IF p_declared_hash IS NOT NULL AND p_declared_hash <> v_computed_sha256 THEN
    RAISE EXCEPTION 'ENVELOPE_HASH_MISMATCH: declared=% computed=%', p_declared_hash, v_computed_sha256
      USING ERRCODE = 'CPO71',
            DETAIL = 'Keystone-declared hash does not match DB-computed hash. Canonicalization divergence detected.',
            HINT = 'declared=' || p_declared_hash || ' computed=' || v_computed_sha256;
  END IF;

  -- Insert
  v_id := public.gen_random_uuid();
  INSERT INTO cpo.cpo_envelopes (
    id, agent_id, action_log_id, envelope_hash, record_type,
    canonical_json, computed_sha256, envelope
  ) VALUES (
    v_id, p_agent_id, p_action_log_id, v_computed_sha256, v_record_type,
    v_canonical, v_computed_sha256, p_envelope
  );

  RETURN jsonb_build_object(
    'ok', true,
    'id', v_id,
    'envelope_hash', v_computed_sha256,
    'record_type', v_record_type
  );
END;
$$;

REVOKE ALL ON FUNCTION cpo.persist_envelope(text, jsonb, text, uuid) FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cpo_owner') THEN
    ALTER FUNCTION cpo.persist_envelope(text, jsonb, text, uuid) OWNER TO cpo_owner;
  END IF;
  -- NOTE: persist_envelope is an INTERNAL helper. Runtime writers (cpo_commit) must use commit_action.
END $$;

-- Register envelopes in the contract artifact schema (additive, non-breaking)
INSERT INTO cpo.cpo_contract_artifact_schema
  (artifact_key, target_table, required_fields, id_field, description)
VALUES
  ('envelopes',
   'cpo.cpo_envelopes',
   ARRAY['envelope_hash', 'record_type'],
   'envelope_hash',
   'Keystone envelopes with DB-computed hash coherence (Phase 6).')
ON CONFLICT (artifact_key) DO NOTHING;


-- Register cpo_envelopes in the artifact table registry (write-aperture coverage).
-- This is required if commit_action writes to cpo.cpo_envelopes.
DO $$
BEGIN
  IF pg_has_role(session_user, 'cpo_migration', 'MEMBER') THEN
    SET LOCAL cpo.migration_in_progress = 'true';
    INSERT INTO cpo.cpo_artifact_table_registry (
      artifact_type, table_regclass, table_kind,
      logical_id_column, logical_seq_column,
      insert_agent_id_column, insert_action_log_id_column, insert_content_column,
      is_canonical, is_exported, export_order, description
    ) VALUES (
      'envelope', 'cpo.cpo_envelopes'::regclass, 'canonical',
      'envelope_hash', NULL,
      'agent_id', 'action_log_id', 'envelope',
      true, true, 15, 'Keystone evidence envelopes. logical_id=envelope_hash; content=envelope.'
    )
    ON CONFLICT (artifact_type) DO UPDATE SET
      table_regclass = EXCLUDED.table_regclass,
      table_kind = EXCLUDED.table_kind,
      logical_id_column = EXCLUDED.logical_id_column,
      logical_seq_column = EXCLUDED.logical_seq_column,
      insert_agent_id_column = EXCLUDED.insert_agent_id_column,
      insert_action_log_id_column = EXCLUDED.insert_action_log_id_column,
      insert_content_column = EXCLUDED.insert_content_column,
      is_canonical = EXCLUDED.is_canonical,
      is_exported = EXCLUDED.is_exported,
      export_order = EXCLUDED.export_order,
      description = EXCLUDED.description;
  END IF;
END $$;

COMMIT;

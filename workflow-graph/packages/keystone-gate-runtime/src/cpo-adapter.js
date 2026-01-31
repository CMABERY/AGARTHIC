/**
 * CPO Database Adapter (Phase 6)
 *
 * Bridges the Keystone CpoKernel (in-memory validation) to the CPO
 * database layer (SQL persistence with independent hash verification).
 *
 * Flow:
 *   1. Accept envelope + agent_id
 *   2. Run CpoKernel.commit_action() for validation, canonicalization, hashing
 *   3. If accepted, call cpo.persist_envelope() in Postgres
 *   4. DB independently canonicalizes, hashes, and verifies coherence
 *   5. Return unified result
 *
 * Hash coherence contract:
 *   The JS-computed hash (from CpoKernel) and the DB-computed hash
 *   (from cpo.compute_envelope_sha256) must be identical. Any mismatch
 *   causes persist_envelope to throw ERRCODE CPO71.
 *
 * No contract changes: uses Phase 2 locked boundary.
 */

import { CpoKernel } from './cpo-kernel.js';
import { hashEnvelope, canonicalizeEnvelope } from './flowversion-envelope.js';

/**
 * @typedef {Object} CpoAdapterConfig
 * @property {CpoKernel} [kernel] - Optional pre-configured kernel instance
 * @property {import('pg').Pool | { query: Function }} db - Postgres connection (pg Pool or compatible)
 */

/**
 * @typedef {Object} PersistResult
 * @property {boolean} ok
 * @property {string} [envelope_hash]
 * @property {string} [record_type]
 * @property {string} [db_computed_sha256]
 * @property {string} [classification]
 * @property {string} [error_kind]
 * @property {string} [error]
 */

export class CpoAdapter {
  /**
   * @param {CpoAdapterConfig} config
   */
  constructor(config) {
    if (!config.db) throw new Error('CpoAdapter requires a db connection');
    this.kernel = config.kernel || new CpoKernel();
    this.db = config.db;
  }

  /**
   * Persist a Keystone envelope through the canonical write path.
   *
   * Sequence:
   *   1. CpoKernel validates, canonicalizes, hashes (JS side)
   *   2. If kernel rejects, return failure (no DB call)
   *   3. If kernel accepts, call cpo.persist_envelope (DB side)
   *   4. DB re-canonicalizes, re-hashes, verifies coherence
   *   5. Return unified result with both hashes
   *
   * @param {string} agentId
   * @param {string} recordType
   * @param {any} envelope
   * @returns {Promise<PersistResult>}
   */
  async persistEnvelope(agentId, recordType, envelope) {
    // 1. JS-side validation + hashing via CpoKernel
    const jsHash = hashEnvelope(envelope);
    const kernelResult = this.kernel.commit_action(recordType, jsHash, envelope);

    // 2. If kernel rejects, return without DB call
    if (!kernelResult.ok) {
      return {
        ok: false,
        classification: kernelResult.classification,
        error_kind: kernelResult.error_kind,
      };
    }

    // 3. Persist to DB via cpo.persist_envelope
    //    DB independently canonicalizes + hashes + verifies coherence
    try {
      const result = await this.db.query(
        `SELECT cpo.persist_envelope($1, $2::jsonb, $3) AS result`,
        [agentId, JSON.stringify(envelope), jsHash]
      );

      const dbResult = result.rows[0].result;

      // 4. Read back the stored hash to double-verify
      const verify = await this.db.query(
        `SELECT computed_sha256 FROM cpo.cpo_envelopes WHERE envelope_hash = $1`,
        [jsHash]
      );

      const dbComputedSha256 = verify.rows[0]?.computed_sha256;

      return {
        ok: true,
        envelope_hash: jsHash,
        record_type: recordType,
        db_computed_sha256: dbComputedSha256,
      };
    } catch (err) {
      // CPO71 = ENVELOPE_HASH_MISMATCH (coherence failure)
      if (err.code === 'CPO71') {
        return {
          ok: false,
          error: `HASH_COHERENCE_FAILURE: ${err.message}`,
          classification: 'HASH_COHERENCE_FAILURE',
        };
      }
      throw err; // Re-throw unexpected errors
    }
  }
}

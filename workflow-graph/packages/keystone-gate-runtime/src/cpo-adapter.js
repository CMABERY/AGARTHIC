/**
 * CPO Database Adapter (Phase 6)
 *
 * Bridges the Keystone CpoKernel (in-memory validation) to the CPO database
 * write aperture (cpo.commit_action) for persistence.
 *
 * Invariants enforced:
 *   - Write aperture: runtime writers must not call cpo.persist_envelope() directly.
 *   - Hash coherence: Keystone-declared hash must match DB-computed hash (fail-closed in DB).
 *
 * Persistence model:
 *   - Envelopes are submitted as an 'envelopes' artifact via cpo.commit_action().
 *   - The CPO agent_id used for this adapter must already be bootstrapped in the DB
 *     (i.e., must exist in cpo.cpo_agent_heads), because commit_action is fail-closed
 *     for bootstrap without the genesis artifacts.
 */

import { CpoKernel } from "./cpo-kernel.js";
import { hashEnvelope } from "./flowversion-envelope.js";

export class CpoAdapter {
  /**
   * @param {{db?: {query: Function}, kernel?: CpoKernel, agentId?: string}} [config]
   */
  constructor(config = {}) {
    this.db = config.db || null;
    this.kernel = config.kernel || new CpoKernel();
    this.agentId = config.agentId || process.env.CPO_AGENT_ID || "keystone";
  }

  /**
   * Persist a Keystone envelope through the DB write aperture.
   *
   * @param {object} envelope - Keystone envelope JSON object
   * @param {string} recordType - Expected record_type for the envelope
   * @param {string} [agentIdOverride] - Optional agent_id override
   * @returns {Promise<object>} result object
   */
  async persistEnvelope(envelope, recordType, agentIdOverride = undefined) {
    if (!envelope || typeof envelope !== "object") {
      throw new Error("Invalid envelope: must be a JSON object");
    }
    if (!recordType || typeof recordType !== "string") {
      throw new Error("Invalid recordType: must be a string");
    }
    if (envelope.record_type !== recordType) {
      throw new Error(
        `Record type mismatch: expected ${recordType}, got ${envelope.record_type}`
      );
    }

    const agentId = agentIdOverride || this.agentId;

    // Phase 6 coherence: JS computes declared hash; DB recomputes independently.
    const declaredHash = hashEnvelope(envelope);

    // In-memory validation. Throws on invalid envelope; returns ok=false for policy rejects.
    const kernelResult = this.kernel.commit_action(recordType, declaredHash, envelope);
    if (!kernelResult?.ok) {
      return kernelResult;
    }

    // Source-of-truth for the envelope hash after validation.
    const envelopeHash = kernelResult.envelope_hash;

    // No DB configured -> validation-only mode.
    if (!this.db) {
      return {
        ...kernelResult,
        stored: false,
        agent_id: agentId,
      };
    }

    // 1) Fetch expected refs (TOCTOU fail-closed).
    const headsRes = await this.db.query(
      "SELECT current_charter_activation_id, current_state_snapshot_id FROM cpo.cpo_agent_heads WHERE agent_id = $1",
      [agentId]
    );
    if (!headsRes?.rows || headsRes.rows.length === 0) {
      throw new Error(
        `CPO bootstrap required for agent_id=${agentId}: no row in cpo.cpo_agent_heads`
      );
    }
    const { current_charter_activation_id, current_state_snapshot_id } = headsRes.rows[0];

    // 2) Minimal action log content required by DB commit_action.
      const requestId = `req_${Date.now()}_${Math.random().toString(16).slice(2)}`;
    const actionLogContent = {
      action: {
        action_type: "keystone.persist_envelope",
        request_id: requestId,
        dry_run: false,
      },
      keystone: {
        record_type: recordType,
        envelope_hash: envelopeHash,
      },
    };

    // 3) Contract-aligned artifact shape: required fields are top-level.
    const artifacts = {
      envelopes: [
        {
          envelope_hash: envelopeHash,
          record_type: recordType,
          envelope,
        },
      ],
    };

    // 4) Persist through commit_action (write aperture).
    const commitRes = await this.db.query(
      "SELECT cpo.commit_action($1::text, $2::jsonb, $3::jsonb, $4::uuid, $5::uuid) AS result",
      [
        agentId,
        JSON.stringify(actionLogContent),
        JSON.stringify(artifacts),
        current_charter_activation_id,
        current_state_snapshot_id,
      ]
    );

    // 5) Optional read-back for coherence metadata (read-only).
    const cohRes = await this.db.query(
      "SELECT computed_sha256 FROM cpo.cpo_envelopes WHERE envelope_hash = $1",
      [envelopeHash]
    );
    const dbComputedHash = cohRes?.rows?.[0]?.computed_sha256 || null;

    return {
      ...kernelResult,
      stored: true,
      agent_id: agentId,
      declared_hash: envelopeHash,
      db_computed_hash: dbComputedHash,
      commit_action: commitRes?.rows?.[0]?.result,
    };
  }
}

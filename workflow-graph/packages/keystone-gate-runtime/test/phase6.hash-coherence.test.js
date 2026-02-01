import test from "node:test";
import assert from "node:assert";
import { CpoAdapter } from "../src/cpo-adapter.js";

/**
 * Phase 6 hash coherence test (adapter-level):
 *   - Adapter MUST persist through cpo.commit_action (write aperture), not cpo.persist_envelope.
 *   - Adapter SHOULD be able to read back DB-computed hash for coherence metadata.
 *
 * This test uses a mocked DB; it validates SQL call-shapes and plumbing, not Postgres semantics.
 */

test("Phase 6 envelope hash coherence: adapter uses commit_action write aperture", async () => {
  // Arrange: kernel returns a stable hash (what Keystone would declare)
  const computedHash = "a".repeat(64);

  const mockKernel = {
    commit_action: () => ({
      ok: true,
      record_type: "policy_decision",
      envelope_hash: computedHash,
      canonical_json: "{}",
    }),
  };

  const mockDb = {
    query: async (sql, params) => {
      if (sql.includes("FROM cpo.cpo_agent_heads")) {
        return {
          rows: [
            {
              current_charter_activation_id: "11111111-1111-1111-1111-111111111111",
              current_state_snapshot_id: "22222222-2222-2222-2222-222222222222",
            },
          ],
        };
      }

      if (sql.includes("SELECT cpo.commit_action")) {
        // Basic shape check: agent_id + JSON + JSON + 2 UUIDs
        assert.ok(Array.isArray(params) && params.length === 5);
        return { rows: [{ result: { ok: true, applied: true } }] };
      }

      if (sql.includes("FROM cpo.cpo_envelopes")) {
        assert.deepStrictEqual(params, [computedHash]);
        return { rows: [{ computed_sha256: computedHash }] };
      }

      throw new Error(`Unexpected SQL: ${sql}`);
    },
  };

  const adapter = new CpoAdapter({ db: mockDb, kernel: mockKernel, agentId: "keystone" });

  const envelope = {
    record_type: "policy_decision",
    canon_version: "1",
    spec_version: "1.0.0",
    payload: { foo: "bar" },
  };

  // Act
  const result = await adapter.persistEnvelope(envelope, "policy_decision");

  // Assert
  assert.strictEqual(result.ok, true);
  assert.strictEqual(result.stored, true);
  assert.strictEqual(result.envelope_hash, computedHash);
  assert.strictEqual(result.db_computed_hash, computedHash);
});

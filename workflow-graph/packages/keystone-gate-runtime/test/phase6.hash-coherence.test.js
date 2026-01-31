/**
 * Phase 6 — Hash Coherence Test (JS side)
 *
 * Proves that Keystone's JS canonicalization + hashing produces the
 * same output as the SQL-side cpo.canonicalize_jsonb + cpo.compute_envelope_sha256.
 *
 * Architecture:
 *   - This test proves JS → golden agreement
 *   - SQL proof p6_proof_envelope_hash_coherence.sql proves SQL → golden agreement
 *   - Coherence is established by transitivity: JS = golden = SQL
 *
 * No Postgres required in this test — coherence is proven via shared goldens.
 */

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { canonicalizeEnvelope, hashEnvelope } from '../src/flowversion-envelope.js';
import { CpoAdapter } from '../src/cpo-adapter.js';
import { CpoKernel } from '../src/cpo-kernel.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const GOLDENS = JSON.parse(readFileSync(join(__dirname, '..', 'goldens', 'integration.e2e.goldens.json'), 'utf8'));

function deepClone(x) {
  return JSON.parse(JSON.stringify(x));
}

function step(vectorName, recordType) {
  const v = GOLDENS.vectors.find((x) => x.name === vectorName);
  assert.ok(v, `Missing vector: ${vectorName}`);
  const candidates = v.steps.filter((x) => x.record_type === recordType);
  assert.ok(candidates.length > 0, `Missing step: ${vectorName}/${recordType}`);
  return candidates[0];
}

// =============================================================================
// Cross-layer hash coherence goldens
//
// These exact goldens are embedded in p6_proof_envelope_hash_coherence.sql PROOF 7.
// If EITHER side diverges, its respective test fails.
// =============================================================================

const CROSS_LAYER_GOLDENS = [
  {
    name: 'simple_object',
    input: { c: true, a: 1, b: 'hello' },
    expected_canonical: '{"a":1,"b":"hello","c":true}',
    expected_sha256: 'a21f08b57e7301be5ff081e26710117f5214dcc7ab04a5435249ac7a981bf26b',
  },
  {
    name: 'keystone_auth_context_golden',
    // This is the exact auth_context from e2e_allow_model_call_ok vector
    input: null, // filled from goldens below
    expected_canonical: null,
    expected_sha256: null,
  },
];

// Fill in the real Keystone golden from integration.e2e.goldens.json
{
  const golden = step('e2e_allow_model_call_ok', 'auth_context');
  CROSS_LAYER_GOLDENS[1].input = golden.input;
  CROSS_LAYER_GOLDENS[1].expected_canonical = golden.canonical_json;
  CROSS_LAYER_GOLDENS[1].expected_sha256 = golden.sha256;
}

describe('P6-COHERENCE-001: JS canonicalization matches cross-layer goldens', () => {
  for (const golden of CROSS_LAYER_GOLDENS) {
    test(`${golden.name}: canonicalizeEnvelope matches expected canonical`, () => {
      const canonical = canonicalizeEnvelope(deepClone(golden.input));
      assert.equal(canonical, golden.expected_canonical,
        `Canonical mismatch for ${golden.name}`);
    });

    test(`${golden.name}: hashEnvelope matches expected SHA-256`, () => {
      const hash = hashEnvelope(deepClone(golden.input));
      assert.equal(hash, golden.expected_sha256,
        `Hash mismatch for ${golden.name}`);
    });

    test(`${golden.name}: independent SHA-256 verification`, () => {
      // Compute SHA-256 of the expected canonical string directly
      const directHash = createHash('sha256')
        .update(golden.expected_canonical, 'utf8')
        .digest('hex');
      assert.equal(directHash, golden.expected_sha256,
        `Direct hash of canonical string doesn't match expected SHA-256`);
    });
  }
});

describe('P6-COHERENCE-002: All e2e golden envelopes produce deterministic hashes', () => {
  const vectors = [
    { vector: 'e2e_allow_model_call_ok', types: ['auth_context', 'policy_decision', 'model_call'] },
    { vector: 'e2e_allow_tool_call_ok', types: ['policy_decision', 'tool_call'] },
  ];

  for (const { vector, types } of vectors) {
    for (const rt of types) {
      test(`${vector}/${rt}: hash is deterministic across 3 runs`, () => {
        const s = step(vector, rt);
        const h1 = hashEnvelope(deepClone(s.input));
        const h2 = hashEnvelope(deepClone(s.input));
        const h3 = hashEnvelope(deepClone(s.input));
        assert.equal(h1, h2);
        assert.equal(h2, h3);
        assert.equal(h1, s.sha256, `Hash doesn't match golden`);
      });
    }
  }
});

describe('P6-COHERENCE-003: CpoAdapter constructor validation', () => {
  test('CpoAdapter requires db connection', () => {
    assert.throws(() => new CpoAdapter({}), /requires a db connection/);
  });

  test('CpoAdapter accepts kernel + db', () => {
    const kernel = new CpoKernel();
    const mockDb = { query: async () => ({ rows: [] }) };
    const adapter = new CpoAdapter({ kernel, db: mockDb });
    assert.ok(adapter);
    assert.strictEqual(adapter.kernel, kernel);
  });
});

describe('P6-COHERENCE-004: CpoAdapter rejects invalid envelopes before DB call', () => {
  test('adapter returns kernel rejection for invalid record_type', async () => {
    const mockDb = {
      query: async () => { throw new Error('DB should not be called'); },
    };
    const adapter = new CpoAdapter({ db: mockDb });

    const result = await adapter.persistEnvelope('agent-1', 'invalid_type', {});
    assert.equal(result.ok, false);
    assert.equal(result.classification, 'RECORD_TYPE_FORBIDDEN');
  });

  test('adapter returns kernel rejection for schema failure', async () => {
    const mockDb = {
      query: async () => { throw new Error('DB should not be called'); },
    };
    const adapter = new CpoAdapter({ db: mockDb });

    const result = await adapter.persistEnvelope('agent-1', 'auth_context', { record_type: 'auth_context' });
    assert.equal(result.ok, false);
    assert.equal(result.classification, 'SCHEMA_REJECT');
  });
});

describe('P6-COHERENCE-005: CpoAdapter calls DB with correct hash on accept', () => {
  test('adapter passes JS-computed hash to persist_envelope', async () => {
    const sAuth = step('e2e_allow_model_call_ok', 'auth_context');
    const expectedHash = sAuth.sha256;

    let capturedArgs = null;
    const mockDb = {
      query: async (sql, params) => {
        if (sql.includes('persist_envelope')) {
          capturedArgs = params;
          return {
            rows: [{ result: { ok: true, id: '00000000-0000-0000-0000-000000000001', envelope_hash: expectedHash } }],
          };
        }
        if (sql.includes('computed_sha256')) {
          return { rows: [{ computed_sha256: expectedHash }] };
        }
        return { rows: [] };
      },
    };

    const adapter = new CpoAdapter({ db: mockDb });
    const result = await adapter.persistEnvelope('agent-test', 'auth_context', deepClone(sAuth.input));

    assert.equal(result.ok, true);
    assert.equal(result.envelope_hash, expectedHash);
    assert.equal(result.db_computed_sha256, expectedHash);

    // Verify the hash passed to DB matches JS computation
    assert.ok(capturedArgs);
    assert.equal(capturedArgs[0], 'agent-test');  // agent_id
    assert.equal(capturedArgs[2], expectedHash);   // declared_hash
  });
});

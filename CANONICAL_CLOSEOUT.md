# Canonical Closeout — AGARTHIC (CANON v1)

**CANON_VERSION:** 1  
**SPEC_VERSION:** 1.0.0  
**Bundle Timestamp (UTC):** 2026-02-01T00:00:00Z  

This is the authoritative closeout for the current repository bundle. It records integrity anchors and invariant enforcement for this exact file state.

---

## Status

**Overall:** **INCOMPLETE**

Reason: **Tier 1 (Postgres/CI) execution evidence is not present in this bundle**. Tier 2 artifacts are reconciled and internally consistent, and an offline verifier is included for deterministic integrity + static invariant checks.

---

## Canonical Integrity Anchors

### Version Authority

`VERSION_LOCK.json` is the **single machine-readable source of truth** for CANON_VERSION and SPEC_VERSION.

- `VERSION_LOCK.json` sha256: `0bfbc1178c4baba79cdcfdf3b8a68d3b94085b6b79822dd52d367f80abf570ed`

### Payload Root Hash

The canonical *payload* root hash is computed over all repository files **excluding** these authority files:

- `REPO_MANIFEST.txt`
- `AUDIT_STAMP.json`
- `CANONICAL_CLOSEOUT.md`
- `REPO_HASHES.sha256`

**payload_root_hash (sha256):** `105cdfc0bdaf192b9b9e90e703dca3611c558f5df52a8ee70296a743428b58da`  
**payload_file_count:** 194  
**repo_file_count:** 198

The exclusion prevents self-referential hashing cycles.

### Authority File Hashes

- `REPO_MANIFEST.txt` sha256: `dc79bc9ee2d412834d240b75e90cc13b0f5abffbec0e4074501a0981179ae263`
- `AUDIT_STAMP.json` sha256: `bf4d69845bbfabc4ddd332ecf20ed5d4621e0b513c575f234a1efce3269eb5b1`

---

## Invariant Enforcement Summary

### Write Aperture Invariant

**PASS (static + privilege-level):**

- Runtime role `cpo_commit` has no direct `INSERT` on `cpo.cpo_envelopes`.
- Runtime role `cpo_commit` has no `EXECUTE` on `cpo.persist_envelope(...)`.
- `cpo.persist_envelope(...)` may be executed by `cpo_migration` (migration/proofs only).
- Envelope persistence is wired into the **single write aperture** `cpo.commit_action(...)` via `artifacts.envelopes`.

### Schema–Persistence Alignment

**PASS (static):**

- Contract schema allows `envelopes` artifacts.
- `cpo.commit_action(...)` persists `envelopes` into `cpo.cpo_envelopes` and fail-closes on hash mismatch.

---

## Key File Hashes (Tier 2)

| File | sha256 |
|---|---|
| `VERSION_LOCK.json` | `0bfbc1178c4baba79cdcfdf3b8a68d3b94085b6b79822dd52d367f80abf570ed` |
| `VERSION_LOCK.md` | `848f6fcb523da09c5e8c09547fab8659203105f2f9aeba02f0347f460e704021` |
| `REPO_MANIFEST.txt` | `dc79bc9ee2d412834d240b75e90cc13b0f5abffbec0e4074501a0981179ae263` |
| `AUDIT_STAMP.json` | `bf4d69845bbfabc4ddd332ecf20ed5d4621e0b513c575f234a1efce3269eb5b1` |
| `tools/verify_canon_bundle.py` | `efe367253e5cc5c74a644f539695bb48480c8a72c8c6c52307555776f4f25302` |
| `cpo/sql/MIGRATION_ORDER.md` | `f7564c537bb322474d754c2442b00ec795868fc666c978320289e8060bf87dd7` |
| `cpo/sql/patches/p6_envelope_persistence.sql` | `783b12ec09da94816f9f2d44ee7cda9694ccc9130fc853e5a85c1ca327d9134f` |
| `cpo/sql/patches/p6_commit_action_envelope_wiring.sql` | `26e8b6c63c5416487d1ec4c0189d2b115047e27f2d99f6fceba3ef47349fb44a` |
| `workflow-graph/packages/keystone-gate-runtime/src/cpo-adapter.js` | `5632789ce817bd6bea7f58f18cab1e2ca582ff5264f819048ffe0f560acb2fbc` |

Note: `REPO_HASHES.sha256` is intentionally omitted from the table above to avoid a self-referential hash cycle. Its contents are verified via `sha256sum -c`.

---

## Verification Commands

Deterministic integrity checks for this bundle:

```bash
# 1) Verify authority files
sha256sum VERSION_LOCK.json REPO_MANIFEST.txt AUDIT_STAMP.json

# 2) Verify per-file hashes (all files except REPO_HASHES itself)
sha256sum -c REPO_HASHES.sha256

# 3) Verify audit stamp + static invariants (offline)
python tools/verify_canon_bundle.py
```


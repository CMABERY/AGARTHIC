




 # AGARTHIC Consumer Bundle Contract 
Version: 1.0
Status: ACTIVE
As-of: 2026-02-04

---

## 1. Purpose & Authority Boundary

### Normative

AGARTHIC defines governance, state, and protocol authority.  
Consumers (e.g., OpenClaw) are **non-authoritative** and must treat all inputs as untrusted unless explicitly verified.

A **Consumer Bundle** is the sole supported mechanism by which AGARTHIC exports governance state to external consumers.

Consumers:
- MUST NOT read AGARTHIC repository state directly.
- MUST NOT assume filesystem co-location with AGARTHIC.
- MUST operate exclusively on exported, immutable bundles.
- MUST verify bundle integrity **fail-closed** before consuming any contents.

### Rationale

This boundary ensures AGARTHIC remains replaceable, auditable, and survivable independent of any specific consumer.  
All trust flows outward from AGARTHIC via explicit artifacts, never inward via shared state.

---

## 2. Consumer Bundle Definition

### Normative

A Consumer Bundle is a directory with the following structure:

```

AGARTHIC_BUNDLE/
├── BUNDLE_MANIFEST.txt
├── BUNDLE_HASHES.sha256
├── BUNDLE_HASHES.sig        (optional)
├── AUDIT_STAMP.json
├── REPO_HASHES.sha256       (informational)
├── REPO_MANIFEST.txt        (informational)
├── gov/
│   ├── STATE_SNAPSHOT.md    (required)
│   ├── ... (other governance instruments)
└── tools/
└── verify_canon_bundle.py (informational)

```

Required files:
- `BUNDLE_MANIFEST.txt`
- `BUNDLE_HASHES.sha256`
- `gov/STATE_SNAPSHOT.md`

Optional files:
- `BUNDLE_HASHES.sig`

### Rationale

The bundle is intentionally self-contained and explicit.  
Informational files are included for audit and traceability but are **not authoritative** for consumer verification.

---

## 3. Bundle Manifest

### Normative

`BUNDLE_MANIFEST.txt` MUST:
- List **all files included in the bundle**, one per line.
- Use **relative paths** from the bundle root.
- Be **deterministically ordered** (lexicographically sorted).
- Include `BUNDLE_HASHES.sha256` and `BUNDLE_MANIFEST.txt` themselves.

### Rationale

The manifest defines the *scope* of the bundle.  
Verification is meaningless without an explicit statement of what is included.

---

## 4. Hash Integrity Model

### Normative

`BUNDLE_HASHES.sha256` MUST:
- Contain SHA-256 hashes for every file listed in `BUNDLE_MANIFEST.txt`
- EXCLUDE `BUNDLE_HASHES.sha256` itself from the hash set
- Be generated deterministically

Consumers MUST:
- Verify hashes using `sha256sum -c BUNDLE_HASHES.sha256`
- Fail verification if any hash check fails
- Perform hash verification **before** any signature verification

### Rationale

Self-referential hashing creates an unsatisfiable verification condition.  
Excluding the hash file itself avoids this class of failure.

Hash-first verification ensures that cryptographic signatures are never evaluated over unverified data.

---

## 5. Signature Policy (Ed25519)

### Normative

If `BUNDLE_HASHES.sig` is present:

- It MUST be an Ed25519 signature over the **exact bytes** of `BUNDLE_HASHES.sha256`
- It MUST be hex-encoded (lowercase)
- Consumers MUST verify the signature
- Consumers MUST fail verification if signature validation fails

If `BUNDLE_HASHES.sig` is absent:
- Consumers MAY proceed with hash-only verification

Consumers MUST obtain the public key via **explicit configuration**:
- Environment variable (e.g., `AGARTHIC_BUNDLE_PUBKEY`)
- Configuration file or CLI argument (consumer-defined)

Consumers MUST NOT:
- Infer trust from bundle contents
- Perform trust-on-first-use (TOFU)
- Silently downgrade verification behavior

### Rationale

The signature is an **optional hardening layer**, not a dependency.  
This allows incremental rollout of signing without breaking existing consumers.

Explicit trust configuration prevents accidental authority escalation and makes trust relationships auditable.

---

## 6. Verification Order

### Normative

Consumers MUST perform verification in the following order:

1. Structural checks (required files present)
2. Hash verification (`BUNDLE_HASHES.sha256`)
3. Signature verification (`BUNDLE_HASHES.sig`, if present)

Verification MUST halt immediately on first failure.

### Rationale

This ordering guarantees:
- No signature is verified over untrusted data
- Hash integrity remains the primary integrity signal
- Signature verification acts as an additional lock, not a replacement

---

## 7. Failure Semantics

### Normative

Consumer verification MUST be **fail-closed**.

At minimum, the following failure conditions MUST cause rejection:

- Missing required files
- Hash verification failure
- Signature present but no public key configured
- Invalid public key encoding
- Invalid signature encoding
- Signature verification failure

Consumers MUST NOT continue operation on partially verified bundles.

### Rationale

Silent degradation is a security failure mode.  
Deterministic rejection is preferable to ambiguous or permissive behavior.

---

## 8. Cryptographic Details

### Normative

- Algorithm: Ed25519
- Hash: SHA-256
- Encoding: hex (lowercase)
- Signed payload: exact file bytes (no trimming or normalization)

### Rationale

These choices minimize ambiguity, reduce parser complexity, and avoid encoding pitfalls (e.g., PEM or base64 variance).

---

## 9. Versioning & Evolution

### Normative

Changes to this contract are classified as:

- **Non-breaking:** additional optional files, stricter verification
- **Breaking:** changes to required files, hash/signature semantics, or verification order

Breaking changes MUST:
- Increment the contract version
- Be explicitly documented
- Allow coexistence with prior versions where feasible

### Rationale

The contract is intended to be stable and reusable across consumers.  
Versioning discipline prevents accidental ecosystem fragmentation.

---

## 10. Reference Implementation

### Normative

The OpenClaw implementation at commit:

```

791e661

```

is the reference consumer implementation for this contract.

### Rationale

Code captures edge cases more precisely than prose.  
The document defines intent; the implementation defines exact behavior.

---

## 11. Summary

This contract establishes a clear, auditable, and secure boundary between AGARTHIC and its consumers.

- Authority flows outward
- Integrity is explicit
- Verification is fail-closed
- Trust is configured, never inferred

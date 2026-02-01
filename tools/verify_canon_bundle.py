#!/usr/bin/env python3
"""
verify_canon_bundle.py

Deterministic, offline verifier for the AGARTHIC canonical bundle.

What it checks (Tier 1 executable evidence):
  - REPO_MANIFEST matches the on-disk file set
  - REPO_HASHES.sha256 validates all files except itself
  - AUDIT_STAMP payload_root_hash matches the reference algorithm
  - VERSION_LOCK.json matches AUDIT_STAMP canon/spec version
  - Static invariant checks for the Phase 6 envelope write aperture wiring
"""

from __future__ import annotations

import hashlib
import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Tuple

REPO_ROOT = Path(".").resolve()

AUTHORITY_EXCLUDE_FOR_ROOT_HASH = {
    "REPO_MANIFEST.txt",
    "AUDIT_STAMP.json",
    "CANONICAL_CLOSEOUT.md",
    "REPO_HASHES.sha256",
}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def die(msg: str, code: int = 2) -> None:
    print(f"FAIL: {msg}")
    sys.exit(code)


def ok(msg: str) -> None:
    print(f"PASS: {msg}")


def load_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        die(f"Could not parse JSON {path}: {e}")


def list_repo_files() -> List[str]:
    files: List[str] = []
    for p in REPO_ROOT.rglob("*"):
        if p.is_file():
            files.append("./" + p.relative_to(REPO_ROOT).as_posix())
    return sorted(files)


def verify_manifest() -> List[str]:
    manifest_path = REPO_ROOT / "REPO_MANIFEST.txt"
    if not manifest_path.exists():
        die("Missing REPO_MANIFEST.txt")

    manifest = [line.strip() for line in manifest_path.read_text(encoding="utf-8").splitlines() if line.strip()]
    actual = list_repo_files()

    if manifest != actual:
        # Provide minimal diff context
        mset = set(manifest)
        aset = set(actual)
        missing = sorted(aset - mset)[:20]
        extra = sorted(mset - aset)[:20]
        die(
            "REPO_MANIFEST.txt does not match on-disk files.\n"
            f"  missing_in_manifest (first 20): {missing}\n"
            f"  extra_in_manifest   (first 20): {extra}"
        )
    ok(f"REPO_MANIFEST.txt matches on-disk files (count={len(manifest)})")
    return manifest


def verify_repo_hashes(manifest: List[str]) -> None:
    hashes_path = REPO_ROOT / "REPO_HASHES.sha256"
    if not hashes_path.exists():
        die("Missing REPO_HASHES.sha256")

    # Parse sha256sum-compatible lines: "<sha>  <path>"
    lines = [ln.strip() for ln in hashes_path.read_text(encoding="utf-8").splitlines() if ln.strip()]
    entries: Dict[str, str] = {}
    for ln in lines:
        parts = ln.split()
        if len(parts) < 2:
            die(f"Malformed line in REPO_HASHES.sha256: {ln}")
        sha = parts[0]
        path = parts[-1]
        entries[path] = sha

    # Expect every file except REPO_HASHES.sha256 itself to be present
    expected_paths = [p for p in manifest if p != "./REPO_HASHES.sha256"]
    missing = [p for p in expected_paths if p not in entries]
    extra = [p for p in entries.keys() if p not in expected_paths]
    if missing:
        die(f"REPO_HASHES.sha256 missing entries (first 20): {missing[:20]}")
    if extra:
        die(f"REPO_HASHES.sha256 has unexpected entries (first 20): {extra[:20]}")

    # Verify hashes
    for p in expected_paths:
        rel = p[2:]  # strip "./"
        actual_sha = sha256_file(REPO_ROOT / rel)
        if actual_sha != entries[p]:
            die(f"Hash mismatch for {p}: expected {entries[p]}, got {actual_sha}")

    ok(f"REPO_HASHES.sha256 validates all files except itself (count={len(expected_paths)})")


def compute_payload_root_hash(manifest: List[str]) -> Tuple[str, int]:
    payload = []
    for p in manifest:
        rel = p[2:]
        if rel in AUTHORITY_EXCLUDE_FOR_ROOT_HASH:
            continue
        payload.append(rel)

    payload = sorted(payload)
    lines = []
    for rel in payload:
        sha = sha256_file(REPO_ROOT / rel)
        lines.append(f"{sha}  ./{rel}")
    material = ("\n".join(lines) + "\n").encode("utf-8")
    return sha256_bytes(material), len(payload)


def verify_audit_stamp(manifest: List[str]) -> None:
    audit = load_json(REPO_ROOT / "AUDIT_STAMP.json")
    ver = load_json(REPO_ROOT / "VERSION_LOCK.json")

    # Version consistency
    if int(audit.get("canon_version")) != int(ver.get("CANON_VERSION")):
        die(f"CANON_VERSION mismatch: AUDIT_STAMP={audit.get('canon_version')} vs VERSION_LOCK.json={ver.get('CANON_VERSION')}")
    if str(audit.get("spec_version")) != str(ver.get("SPEC_VERSION")):
        die(f"SPEC_VERSION mismatch: AUDIT_STAMP={audit.get('spec_version')} vs VERSION_LOCK.json={ver.get('SPEC_VERSION')}")
    ok("VERSION_LOCK.json matches AUDIT_STAMP.json canon/spec versions")

    # Manifest hash
    manifest_sha = sha256_file(REPO_ROOT / "REPO_MANIFEST.txt")
    if audit.get("integrity", {}).get("manifest_sha256") != manifest_sha:
        die("AUDIT_STAMP manifest_sha256 does not match REPO_MANIFEST.txt")
    ok("AUDIT_STAMP manifest_sha256 matches REPO_MANIFEST.txt")

    # File counts
    repo_count = len(manifest)
    payload_root, payload_count = compute_payload_root_hash(manifest)
    if audit.get("integrity", {}).get("repo_file_count") != repo_count:
        die(f"AUDIT_STAMP repo_file_count mismatch: expected {repo_count}, got {audit.get('integrity', {}).get('repo_file_count')}")
    if audit.get("integrity", {}).get("payload_file_count") != payload_count:
        die(f"AUDIT_STAMP payload_file_count mismatch: expected {payload_count}, got {audit.get('integrity', {}).get('payload_file_count')}")
    ok("AUDIT_STAMP file counts match manifest")

    # Root hash
    if audit.get("integrity", {}).get("payload_root_hash") != payload_root:
        die(f"AUDIT_STAMP payload_root_hash mismatch: expected {payload_root}, got {audit.get('integrity', {}).get('payload_root_hash')}")
    ok("AUDIT_STAMP payload_root_hash matches reference algorithm")


def verify_static_invariants() -> None:
    # 1) No runtime grant of persist_envelope to cpo_commit
    p6 = (REPO_ROOT / "cpo/sql/patches/p6_envelope_persistence.sql").read_text(encoding="utf-8")
    if "GRANT EXECUTE ON FUNCTION cpo.persist_envelope" in p6 and "TO cpo_commit" in p6:
        die("Found GRANT EXECUTE on cpo.persist_envelope to cpo_commit (write aperture violation)")
    if "GRANT INSERT ON TABLE cpo.cpo_envelopes TO cpo_commit" in p6:
        die("Found direct INSERT grant on cpo.cpo_envelopes to cpo_commit (write aperture violation)")
    ok("p6_envelope_persistence.sql does not grant persist_envelope/INSERT to cpo_commit")

    # 2) Adapter persists through commit_action, not persist_envelope
    adapter = (REPO_ROOT / "workflow-graph/packages/keystone-gate-runtime/src/cpo-adapter.js").read_text(encoding="utf-8")
    if "SELECT cpo.commit_action" not in adapter:
        die("Adapter does not call cpo.commit_action (commit authority violation)")
    if "SELECT cpo.persist_envelope" in adapter:
        die("Adapter calls cpo.persist_envelope (phase ordering violation)")
    ok("keystone-gate-runtime adapter uses cpo.commit_action and does not call cpo.persist_envelope")

    # 3) commit_action wiring contains envelopes branch
    wiring = (REPO_ROOT / "cpo/sql/patches/p6_commit_action_envelope_wiring.sql").read_text(encoding="utf-8")
    if "p_artifacts ? 'envelopes'" not in wiring:
        die("commit_action wiring patch missing envelopes branch")
    if "INSERT INTO cpo.cpo_envelopes" not in wiring:
        die("commit_action wiring patch missing INSERT into cpo.cpo_envelopes")
    ok("commit_action wiring patch contains envelopes persistence branch")


def main() -> None:
    manifest = verify_manifest()
    verify_repo_hashes(manifest)
    verify_audit_stamp(manifest)
    verify_static_invariants()
    print("OK: Canonical bundle passes offline verifier.")
    sys.exit(0)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
regen_integrity.py

Regenerates integrity artifacts for the AGARTHIC canonical bundle:
  - REPO_HASHES.sha256 from REPO_MANIFEST.txt
  - AUDIT_STAMP.json integrity fields:
      manifest_sha256, repo_file_count, payload_file_count, payload_root_hash

Deterministic and offline.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

REPO_ROOT = Path('.').resolve()

AUTHORITY_EXCLUDE_FOR_ROOT_HASH = {
    'REPO_MANIFEST.txt',
    'AUDIT_STAMP.json',
    'CANONICAL_CLOSEOUT.md',
    'REPO_HASHES.sha256',
}

def sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()

def sha256_file(p: Path) -> str:
    h = hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()

def read_manifest() -> list[str]:
    mp = REPO_ROOT / 'REPO_MANIFEST.txt'
    if not mp.exists():
        raise SystemExit('FAIL: Missing REPO_MANIFEST.txt')
    lines = [ln.strip() for ln in mp.read_text(encoding='utf-8').splitlines() if ln.strip()]
    return lines

def write_repo_hashes(manifest: list[str]) -> int:
    out: list[str] = []
    for pth in manifest:
        if pth == './REPO_HASHES.sha256':
            continue
        rel = pth[2:]  # strip "./"
        out.append(f"{sha256_file(REPO_ROOT / rel)}  {pth}")
    (REPO_ROOT / 'REPO_HASHES.sha256').write_text('\n'.join(out) + '\n', encoding='utf-8')
    return len(out)

def compute_payload_root(manifest: list[str]) -> tuple[str, int]:
    payload: list[str] = []
    for pth in manifest:
        rel = pth[2:]
        if rel in AUTHORITY_EXCLUDE_FOR_ROOT_HASH:
            continue
        payload.append(rel)
    payload = sorted(payload)

    lines: list[str] = []
    for rel in payload:
        lines.append(f"{sha256_file(REPO_ROOT / rel)}  ./{rel}")
    material = ('\n'.join(lines) + '\n').encode('utf-8')
    return sha256_bytes(material), len(payload)

def patch_audit_stamp(manifest: list[str]) -> tuple[int, int, str]:
    ap = REPO_ROOT / 'AUDIT_STAMP.json'
    if not ap.exists():
        raise SystemExit('FAIL: Missing AUDIT_STAMP.json')

    audit = json.loads(ap.read_text(encoding='utf-8'))
    audit.setdefault('integrity', {})

    repo_count = len(manifest)
    payload_root_hash, payload_count = compute_payload_root(manifest)

    audit['integrity']['manifest_sha256'] = sha256_file(REPO_ROOT / 'REPO_MANIFEST.txt')
    audit['integrity']['repo_file_count'] = repo_count
    audit['integrity']['payload_file_count'] = payload_count
    audit['integrity']['payload_root_hash'] = payload_root_hash

    ap.write_text(json.dumps(audit, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    return repo_count, payload_count, payload_root_hash

def main() -> None:
    manifest = read_manifest()

    # IMPORTANT ORDER:
    # 1) Patch AUDIT_STAMP.json (it is hashed in REPO_HASHES)
    repo_count, payload_count, payload_root_hash = patch_audit_stamp(manifest)

    # 2) Now write REPO_HASHES.sha256 so it captures the updated AUDIT_STAMP.json
    n_hashes = write_repo_hashes(manifest)

    print('OK: regenerated integrity artifacts')
    print(f'  REPO_HASHES.sha256 entries={n_hashes}')
    print(f'  repo_file_count={repo_count}')
    print(f'  payload_file_count={payload_count}')
    print(f'  payload_root_hash={payload_root_hash}')

if __name__ == '__main__':
    main()

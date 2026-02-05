#!/usr/bin/env python3
"""
export_consumer_bundle.py

Create an AGARTHIC consumer bundle export for external consumers (e.g., OpenClaw).

Bundle contract (see gov/CONSUMER_BUNDLE_CONTRACT.md):
  - Bundle is an immutable directory export (not a repo view).
  - BUNDLE_MANIFEST.txt lists included files (bundle-relative, "./" prefixed), ordered.
  - BUNDLE_HASHES.sha256 contains sha256 sums for all files in manifest EXCEPT itself.
  - Hash verification MUST pass via: sha256sum -c BUNDLE_HASHES.sha256
  - Optional signature:
      - If BUNDLE_HASHES.sig is present, consumers may enforce it.
      - Signature is Ed25519 over exact bytes of BUNDLE_HASHES.sha256.
      - Encoding: hex.

This exporter:
  - Exports minimal consumer bundle:
      AUDIT_STAMP.json
      BUNDLE_MANIFEST.txt
      BUNDLE_HASHES.sha256
      gov/STATE_SNAPSHOT.md
    (This is sufficient for OpenClaw verification.)
  - Optionally writes BUNDLE_HASHES.sig if AGARTHIC_BUNDLE_PRIVKEY is provided.

Usage:
  python3 tools/export_consumer_bundle.py [--out-dir <path>]

Defaults:
  --out-dir ~/bundles/AGARTHIC_BUNDLE_<UTCSTAMP>/

Env:
  AGARTHIC_BUNDLE_PRIVKEY  (optional) hex-encoded Ed25519 private key (32 bytes) for signing BUNDLE_HASHES.sha256
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional


REPO_ROOT = Path(".").resolve()


@dataclass(frozen=True)
class BundlePaths:
    out_dir: Path
    gov_dir: Path
    manifest_path: Path
    hashes_path: Path
    sig_path: Path
    audit_stamp_path: Path
    state_snapshot_path: Path


def die(msg: str, code: int = 2) -> None:
    print(f"FAIL: {msg}")
    raise SystemExit(code)


def ok(msg: str) -> None:
    print(f"OK: {msg}")


def utc_stamp() -> str:
    # Example: 20260205T074829Z
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def _require_repo_file(rel: str) -> Path:
    p = (REPO_ROOT / rel).resolve()
    if not p.exists() or not p.is_file():
        die(f"Missing required repo file: {rel}")
    return p


def _write_text(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def _run(cmd: List[str], *, cwd: Optional[Path] = None) -> str:
    cp = subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if cp.returncode != 0:
        die(f"Command failed ({cp.returncode}): {' '.join(cmd)}\n{cp.stdout}")
    return cp.stdout


def _sha256sum_manifest(bundle_dir: Path, manifest: List[str]) -> None:
    """
    Write BUNDLE_HASHES.sha256 for every path in manifest EXCEPT itself.
    Paths in manifest are "./..." bundle-relative.
    """
    lines: List[str] = []
    for entry in manifest:
        if entry == "./BUNDLE_HASHES.sha256":
            continue
        rel = entry[2:]  # strip "./"
        p = bundle_dir / rel
        if not p.exists() or not p.is_file():
            die(f"Manifest entry missing on disk: {entry}")
        # sha256sum prints "<sha>  <path>"
        out = _run(["sha256sum", rel], cwd=bundle_dir).strip()
        # Normalize to the manifest path (./...)
        sha = out.split()[0]
        lines.append(f"{sha}  {entry}")
    _write_text(bundle_dir / "BUNDLE_HASHES.sha256", "\n".join(lines) + "\n")


def _verify_hashes(bundle_dir: Path) -> None:
    out = _run(["sha256sum", "-c", "BUNDLE_HASHES.sha256"], cwd=bundle_dir)
    # sha256sum -c prints per-file OK lines to stdout; we just display them
    sys.stdout.write(out)


def _sign_hashes_if_requested(bundle_dir: Path) -> None:
    priv_hex = os.environ.get("AGARTHIC_BUNDLE_PRIVKEY", "").strip()
    if not priv_hex:
        ok("No AGARTHIC_BUNDLE_PRIVKEY provided; bundle is unsigned (hashes-only).")
        return

    try:
        from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
    except Exception as e:
        die(f"cryptography is required for signing but could not be imported: {e}")

    try:
        priv_bytes = bytes.fromhex(priv_hex)
    except ValueError:
        die("AGARTHIC_BUNDLE_PRIVKEY must be hex-encoded bytes")

    if len(priv_bytes) != 32:
        die(f"AGARTHIC_BUNDLE_PRIVKEY must be 32 bytes (got {len(priv_bytes)})")

    sk = Ed25519PrivateKey.from_private_bytes(priv_bytes)
    hashes_bytes = (bundle_dir / "BUNDLE_HASHES.sha256").read_bytes()
    sig = sk.sign(hashes_bytes)
    (bundle_dir / "BUNDLE_HASHES.sig").write_text(sig.hex() + "\n", encoding="utf-8")
    ok("Wrote BUNDLE_HASHES.sig (Ed25519 over exact bytes of BUNDLE_HASHES.sha256).")


def export_minimal_bundle(out_dir: Path) -> BundlePaths:
    # Repo source files
    repo_audit = _require_repo_file("AUDIT_STAMP.json")
    repo_state = _require_repo_file("gov/STATE_SNAPSHOT.md")

    # Bundle paths
    gov_dir = out_dir / "gov"
    gov_dir.mkdir(parents=True, exist_ok=True)

    audit_stamp_path = out_dir / "AUDIT_STAMP.json"
    state_snapshot_path = gov_dir / "STATE_SNAPSHOT.md"
    manifest_path = out_dir / "BUNDLE_MANIFEST.txt"
    hashes_path = out_dir / "BUNDLE_HASHES.sha256"
    sig_path = out_dir / "BUNDLE_HASHES.sig"

    # Copy payload
    audit_stamp_path.write_bytes(repo_audit.read_bytes())
    state_snapshot_path.write_bytes(repo_state.read_bytes())

    # Deterministic manifest: include manifest + hashes + (optional sig) + payload files
    # Contract requires including BUNDLE_MANIFEST.txt and BUNDLE_HASHES.sha256 in the manifest itself.
    # We include the sig path in the manifest too (even if not written, it will just not exist).
    manifest = [
        "./AUDIT_STAMP.json",
        "./BUNDLE_MANIFEST.txt",
        "./BUNDLE_HASHES.sha256",
        "./BUNDLE_HASHES.sig",
        "./gov/STATE_SNAPSHOT.md",
    ]
    _write_text(manifest_path, "\n".join(manifest) + "\n")

    # Write hashes (exclude the hash file itself, per contract).
    # NOTE: if BUNDLE_HASHES.sig does not exist, it must not be hashed.
    # So we hash only existing manifest entries except the hash file itself.
    existing_manifest = [p for p in manifest if (out_dir / p[2:]).exists()]
    _sha256sum_manifest(out_dir, existing_manifest)

    # Optional signing may create BUNDLE_HASHES.sig; if so, update hashes to include it.
    _sign_hashes_if_requested(out_dir)
    if sig_path.exists():
        existing_manifest = [p for p in manifest if (out_dir / p[2:]).exists()]
        _sha256sum_manifest(out_dir, existing_manifest)

    # Verify hashes fail-closed
    _verify_hashes(out_dir)

    ok(f"Bundle exported: {out_dir}")
    return BundlePaths(
        out_dir=out_dir,
        gov_dir=gov_dir,
        manifest_path=manifest_path,
        hashes_path=hashes_path,
        sig_path=sig_path,
        audit_stamp_path=audit_stamp_path,
        state_snapshot_path=state_snapshot_path,
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out-dir", default="", help="Output bundle dir (default: ~/bundles/AGARTHIC_BUNDLE_<UTCSTAMP>/)")
    args = ap.parse_args()

    if args.out_dir:
        out_dir = Path(args.out_dir).expanduser().resolve()
    else:
        out_dir = Path.home() / "bundles" / f"AGARTHIC_BUNDLE_{utc_stamp()}"

    out_dir.mkdir(parents=True, exist_ok=True)

    # Guardrail: refuse to export inside the repo
    try:
        out_dir.relative_to(REPO_ROOT)
        die("Refusing to export inside repo root. Choose an out-dir outside ~/projects/AGARTHIC.")
    except ValueError:
        pass

    export_minimal_bundle(out_dir)


if __name__ == "__main__":
    main()

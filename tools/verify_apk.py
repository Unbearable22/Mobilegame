#!/usr/bin/env python3
"""Verify the built binary, not only the export preset. Requires Android build-tools."""
import argparse
import hashlib
import json
import os
import re
import tempfile
from pathlib import Path
import subprocess
import zipfile


def validate_manifest(badging, manifest, permissions):
    assert "package: name='org.chainreact.onetappuzzle'" in badging, "Wrong application ID"
    assert "targetSdkVersion:'36'" in badging and "sdkVersion:'24'" in badging, "Unexpected SDK levels"
    assert "native-code: 'arm64-v8a'" in badging, "Missing ARM64"
    assert re.search(r"android:screenOrientation[^\n]*=\(type 0x10\)0x1(?:\s|$)", manifest), "Portrait missing"
    assert re.search(r"android:debuggable[^\n]*=\(type 0x12\)0xffffffff(?:\s|$)", manifest), "Debug flag must be true"
    used_permissions = [line.strip() for line in permissions.splitlines() if line.startswith("uses-permission")]
    assert not used_permissions, f"Unexpected Android permissions: {used_permissions}"
    return used_permissions


def validate_certificate(signature, expected=None):
    fingerprints = re.findall(r"^Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]{64})$", signature, re.MULTILINE)
    assert len(fingerprints) == 1, "Expected exactly one APK signing certificate"
    actual = fingerprints[0].lower()
    if expected:
        assert actual == expected.lower().replace(':', ''), "APK certificate differs from selected signing identity"
    return actual


def verify(apk, sdk, java, godot, expected_certificate=None, signing_mode='unverified-origin'):
    tools = sdk / "build-tools/36.0.0"
    env = os.environ.copy()
    env["JAVA_HOME"] = str(java)
    env["PATH"] = str(java / "bin") + os.pathsep + env.get("PATH", "")
    def command(*args):
        return subprocess.check_output([str(a) for a in args], text=True, env=env)
    signature = command(tools / "apksigner", "verify", "--verbose", "--print-certs", apk)
    certificate = validate_certificate(signature, expected_certificate)
    command(tools / "zipalign", "-c", "-P", "16", "-v", "4", apk)
    badging = command(tools / "aapt", "dump", "badging", apk)
    manifest = command(tools / "aapt", "dump", "xmltree", apk, "AndroidManifest.xml")
    permissions = command(tools / "aapt", "dump", "permissions", apk)
    used_permissions = validate_manifest(badging, manifest, permissions)
    with zipfile.ZipFile(apk) as archive:
        names = archive.namelist()
        libraries = [name for name in names if name.startswith("lib/") and name.endswith(".so")]
        assert libraries and all(name.startswith("lib/arm64-v8a/") for name in libraries), "Unexpected ABI"
        for number in range(1, 51):
            name = f"assets/levels/{number:02d}.json"
            data = json.loads(archive.read(name))
            assert data["id"] == number and data["nodes"], f"Bad level {name}"
            assert data == json.loads((Path(__file__).resolve().parents[1] / "levels" / f"{number:02d}.json").read_text()), f"Stale level {name}"
        assert not any(name.startswith(("assets/tests/", "assets/docs/", "assets/tools/", "assets/build/", "assets/.github/")) for name in names), "Dev resources shipped"
        assert any(name.startswith("res/mipmap-") and "/icon." in name and name.endswith((".webp", ".png")) for name in names), "No launcher icons"
        assert "assets/project.binary" in names, "Missing Godot project"
    with tempfile.TemporaryDirectory(prefix="chain-apk-smoke-") as extracted:
        with zipfile.ZipFile(apk) as archive:
            for name in archive.namelist():
                if name.startswith("assets/") and not name.endswith("/"):
                    relative = Path(name.removeprefix("assets/"))
                    if ".." in relative.parts or relative.is_absolute():
                        raise ValueError("Unsafe APK asset path")
                    target = Path(extracted) / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(archive.read(name))
        smoke = subprocess.run([godot, "--headless", "--path", extracted, "--script",
                                str(Path(__file__).with_name("apk_smoke.gd").resolve())],
                               env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        apk.with_suffix(".smoke.txt").write_text(smoke.stdout)
        if smoke.returncode or "ERROR:" in smoke.stdout or "0 failures" not in smoke.stdout:
            raise RuntimeError("Packaged resource smoke failed: " + smoke.stdout)
    digest = hashlib.sha256(apk.read_bytes()).hexdigest()
    report = {"apk": apk.name, "bytes": apk.stat().st_size, "sha256": digest,
              "package_id": "org.chainreact.onetappuzzle", "abis": ["arm64-v8a"],
              "target_sdk": 36, "min_sdk": 24, "orientation": "portrait", "debuggable": True,
              "levels": 50, "permissions": used_permissions, "signature_verified": True,
              "certificate_sha256": certificate, "signing_mode": signing_mode,
              "signing_persistent": signing_mode == "persistent-debug",
              "zipalign_16k_verified": True, "packaged_resource_smoke": True, "physical_device_tested": False}
    apk.with_suffix(".verification.json").write_text(json.dumps(report, indent=2) + "\n")
    apk.with_suffix(".sha256").write_text(f"{digest}  {apk.name}\n")
    apk.with_suffix(".badging.txt").write_text(badging)
    apk.with_suffix(".manifest.txt").write_text(manifest)
    apk.with_suffix(".signature.txt").write_text(signature)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--sdk", type=Path, required=True)
    parser.add_argument("--java", type=Path, required=True)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--expected-certificate-sha256")
    parser.add_argument("--signing-mode", choices=("persistent-debug", "ephemeral-nonpersistent", "unverified-origin"), default="unverified-origin")
    args = parser.parse_args()
    verify(args.apk.resolve(), args.sdk.resolve(), args.java.resolve(), args.godot, args.expected_certificate_sha256, args.signing_mode)

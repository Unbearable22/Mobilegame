#!/usr/bin/env python3
"""Linux debug-only export in isolated Godot settings; never touches system Java."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
VERSION = "4.7.2"


def run(args, env):
    subprocess.run([str(a) for a in args], cwd=ROOT, env=env, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--sdk", type=Path, required=True)
    parser.add_argument("--java", type=Path, required=True)
    parser.add_argument("--templates", type=Path, required=True)
    args = parser.parse_args()
    sdk, java, templates = (p.resolve() for p in (args.sdk, args.java, args.templates))
    godot = shutil.which(args.godot) or str(Path(args.godot).resolve())
    version = subprocess.check_output([godot, "--version"], text=True).strip()
    if not version.startswith(VERSION + ".stable."):
        raise SystemExit(f"Expected Godot {VERSION} stable; got {version}")
    for path in (sdk / "platform-tools/adb", sdk / "build-tools/36.0.0/apksigner", java / "bin/keytool", templates / "android_debug.apk"):
        if not path.is_file():
            raise SystemExit(f"Missing tool: {path}")
    if (templates / "version.txt").read_text().strip() != VERSION + ".stable":
        raise SystemExit("Export template version mismatch")
    java_version = subprocess.run([str(java / "bin/java"), "-version"], text=True, capture_output=True, check=True)
    if 'version "17.' not in java_version.stderr:
        raise SystemExit("Use JDK 17 for this build pipeline")
    work = ROOT / "build/tooling"
    output = ROOT / "build/android/chain-react-debug-arm64.apk"
    output.parent.mkdir(parents=True, exist_ok=True)
    config = work / "config/godot"
    config.mkdir(parents=True, exist_ok=True)
    dest = work / f"data/godot/export_templates/{VERSION}.stable"
    dest.mkdir(parents=True, exist_ok=True)
    for name in ("android_debug.apk", "version.txt"):
        shutil.copy2(templates / name, dest / name)
    # Godot validates existence of both templates even for a debug-only export.
    if (templates / "android_release.apk").is_file():
        shutil.copy2(templates / "android_release.apk", dest / "android_release.apk")
    settings = '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    settings += 'export/android/android_sdk_path = ' + json.dumps(str(sdk)) + '\n'
    settings += 'export/android/java_sdk_path = ' + json.dumps(str(java)) + '\n'
    (config / "editor_settings-4.7.tres").write_text(settings)
    env = os.environ.copy()
    env["PATH"] = str(java / "bin") + os.pathsep + env.get("PATH", "")
    env.update(JAVA_HOME=str(java), ANDROID_HOME=str(sdk), ANDROID_SDK_ROOT=str(sdk),
               XDG_CONFIG_HOME=str(work / "config"), XDG_DATA_HOME=str(work / "data"), GODOT_BIN=godot)
    # Standard Android debug identity only. Keys stay outside the artifact directory.
    key = sdk / "chain-react-debug.keystore"
    if not key.exists():
        run([java / "bin/keytool", "-genkeypair", "-keystore", key, "-storepass", "android", "-keypass", "android",
             "-alias", "androiddebugkey", "-dname", "CN=Android Debug,O=Android,C=US", "-keyalg", "RSA", "-validity", "10000"], env)
    env.update(GODOT_ANDROID_KEYSTORE_DEBUG_PATH=str(key), GODOT_ANDROID_KEYSTORE_DEBUG_USER="androiddebugkey",
               GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android")
    run(["python3", "tests/test_android_tools.py"], env)
    run(["python3", "tests/test_level_design.py"], env)
    run(["bash", "tools/check.sh"], env)
    shutil.copy2(ROOT / "build/level-audit.json", output.parent / "level-audit.json")
    shutil.copy2(ROOT / "docs/v4-level-diagnostics.json", output.parent / "v4-level-diagnostics.json")
    run([godot, "--headless", "--path", ".", "--export-debug", "Android", output], env)
    run(["python3", "tools/verify_apk.py", output, "--sdk", sdk, "--java", java, "--godot", godot], env)
    print(f"Debug APK: {output} ({output.stat().st_size} bytes)")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Linux debug-only export with explicit signing and isolated Godot settings."""
import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile

from setup_debug_signing import FIELDS, select_signing

ROOT = Path(__file__).resolve().parents[1]
VERSION = '4.7.2'


def run(args, env):
    subprocess.run([str(a) for a in args], cwd=ROOT, env=env, check=True)


def signing_sdk(sdk, work, env):
    """Overlay only apksigner so Godot never places a real password in argv."""
    overlay = work / 'sdk'
    overlay.mkdir(parents=True, exist_ok=True)
    for source in sdk.iterdir():
        if source.name != 'build-tools':
            target = overlay / source.name
            if not target.exists():
                target.symlink_to(source, target_is_directory=source.is_dir())
    tools = overlay / 'build-tools/36.0.0'
    tools.mkdir(parents=True, exist_ok=True)
    for source in (sdk / 'build-tools/36.0.0').iterdir():
        if source.name != 'apksigner':
            target = tools / source.name
            if not target.exists():
                target.symlink_to(source, target_is_directory=source.is_dir())
    proxy = tools / 'apksigner'
    proxy.write_text('#!/bin/sh\nexec ' + shlex.quote(sys.executable) + ' ' +
                     shlex.quote(str(ROOT / 'tools/setup_debug_signing.py')) +
                     ' --apksigner-proxy "$@"\n')
    proxy.chmod(0o700)
    env['CHAIN_REACT_REAL_APKSIGNER'] = str(sdk / 'build-tools/36.0.0/apksigner')
    return overlay


def build(args, ephemeral_directory):
    sdk, java, templates = (p.resolve() for p in (args.sdk, args.java, args.templates))
    godot = shutil.which(args.godot) or str(Path(args.godot).resolve())
    version = subprocess.check_output([godot, '--version'], text=True).strip()
    if not version.startswith(VERSION + '.stable.'):
        raise SystemExit(f'Expected Godot {VERSION} stable; got {version}')
    for path in (sdk / 'platform-tools/adb', sdk / 'build-tools/36.0.0/apksigner', java / 'bin/keytool', templates / 'android_debug.apk'):
        if not path.is_file():
            raise SystemExit(f'Missing tool: {path}')
    if (templates / 'version.txt').read_text().strip() != VERSION + '.stable':
        raise SystemExit('Export template version mismatch')
    java_version = subprocess.run([str(java / 'bin/java'), '-version'], text=True, capture_output=True, check=True)
    if 'version "17.' not in java_version.stderr:
        raise SystemExit('Use JDK 17 for this build pipeline')
    env = os.environ.copy()
    if args.signing_config:
        config = args.signing_config.expanduser().resolve()
        if config == ROOT or ROOT in config.parents or config.stat().st_mode & 0o077:
            raise SystemExit('Private signing configuration must be outside Git with chmod 600')
        try:
            values = json.loads(config.read_text())
            if not isinstance(values, dict) or set(values) != set(FIELDS):
                raise ValueError('Unexpected configuration fields')
            env.update(values)
        except (ValueError, OSError):
            raise SystemExit('Invalid private signing configuration')
    try:
        signing = select_signing(env, java / 'bin/keytool', args.allow_ephemeral_signing, ephemeral_directory)
    except (ValueError, OSError) as error:
        raise SystemExit(str(error) if isinstance(error, ValueError) else 'Cannot access signing tools or private configuration')
    if not signing['persistent']:
        print('WARNING: EXPLICIT EPHEMERAL SIGNING. This APK uses a NONPERSISTENT certificate; future updates are not guaranteed.', flush=True)
    work = ROOT / 'build/tooling'
    output = ROOT / 'build/android/chain-react-debug-arm64.apk'
    output.parent.mkdir(parents=True, exist_ok=True)
    # Public signing facts only; no key, alias or password enters artifacts.
    (output.parent / 'signing-mode.json').write_text(json.dumps(signing, indent=2) + '\n')
    config = work / 'config/godot'
    config.mkdir(parents=True, exist_ok=True)
    dest = work / f'data/godot/export_templates/{VERSION}.stable'
    dest.mkdir(parents=True, exist_ok=True)
    for name in ('android_debug.apk', 'version.txt'):
        shutil.copy2(templates / name, dest / name)
    if (templates / 'android_release.apk').is_file():
        shutil.copy2(templates / 'android_release.apk', dest / 'android_release.apk')
    overlay = signing_sdk(sdk, work, env)
    settings = '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    settings += 'export/android/android_sdk_path = ' + json.dumps(str(overlay)) + '\n'
    settings += 'export/android/java_sdk_path = ' + json.dumps(str(java)) + '\n'
    (config / 'editor_settings-4.7.tres').write_text(settings)
    env['PATH'] = str(java / 'bin') + os.pathsep + env.get('PATH', '')
    env.update(JAVA_HOME=str(java), ANDROID_HOME=str(overlay), ANDROID_SDK_ROOT=str(overlay),
               XDG_CONFIG_HOME=str(work / 'config'), XDG_DATA_HOME=str(work / 'data'), GODOT_BIN=godot)
    env.update(GODOT_ANDROID_KEYSTORE_DEBUG_PATH=env[FIELDS[0]],
               GODOT_ANDROID_KEYSTORE_DEBUG_USER=env[FIELDS[1]],
               GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD='CHAIN_REACT_PASSWORD_FROM_ENV')
    run(['python3', 'tests/test_android_tools.py'], env)
    run(['python3', 'tests/test_signing.py'], env)
    run(['python3', 'tests/test_level_design.py'], env)
    run(['bash', 'tools/check.sh'], env)
    shutil.copy2(ROOT / 'build/level-audit.json', output.parent / 'level-audit.json')
    shutil.copy2(ROOT / 'docs/v4-level-diagnostics.json', output.parent / 'v4-level-diagnostics.json')
    run([godot, '--headless', '--path', '.', '--export-debug', 'Android', output], env)
    run(['python3', 'tools/verify_apk.py', output, '--sdk', sdk, '--java', java, '--godot', godot,
         '--expected-certificate-sha256', signing['certificate_sha256'], '--signing-mode', signing['mode']], env)
    print(f'Debug APK: {output} ({output.stat().st_size} bytes)')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--sdk', type=Path, required=True)
    parser.add_argument('--java', type=Path, required=True)
    parser.add_argument('--templates', type=Path, required=True)
    parser.add_argument('--signing-config', type=Path, help='Owner-only JSON outside the repository')
    parser.add_argument('--allow-ephemeral-signing', action='store_true', help='Explicitly allow a nonpersistent test identity ONLY when no signing fields are set')
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='chain-react-ephemeral-signing-') as temporary:
        build(args, Path(temporary) / 'identity')


if __name__ == '__main__':
    main()
